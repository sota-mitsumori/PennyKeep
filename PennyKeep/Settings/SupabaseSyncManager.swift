import Foundation
import SwiftData
import SwiftUI
import Supabase
import PostgREST

class SupabaseSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isConnected = false
    
    private var modelContext: ModelContext?
    private var supabase: SupabaseClient?
    private var authManager: SupabaseAuthManager?
    
    // 同期状態を追跡するためのキー
    private let lastSyncDateKey = "supabaseLastSyncDate"
    
    init() {
        // UserDefaultsから最終同期日時を読み込む
        if let savedDate = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            self.lastSyncDate = savedDate
        }
        setupSupabase()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func setAuthManager(_ authManager: SupabaseAuthManager) {
        self.authManager = authManager
    }
    
    private func setupSupabase() {
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            print("⚠️ Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
            return
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        // 接続状態を確認
        Task {
            await checkConnection()
        }
    }
    
    // MARK: - 接続確認
    
    func checkConnection() async {
        guard let supabase = supabase else {
            await MainActor.run {
                isConnected = false
            }
            return
        }
        
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                isConnected = session != nil
            }
        } catch {
            await MainActor.run {
                isConnected = false
            }
        }
    }
    
    // MARK: - 同期処理
    
    /// 手動同期（双方向）
    func manualSync() async {
        guard let context = modelContext else {
            await MainActor.run {
                syncError = "ModelContext is not available"
            }
            return
        }
        
        guard let supabase = supabase else {
            await MainActor.run {
                syncError = "Supabase is not configured"
            }
            return
        }
        
        // 認証状態を確認
        guard let authManager = authManager, authManager.isSignedIn else {
            await MainActor.run {
                syncError = "Please sign in to sync data"
            }
            return
        }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        do {
            // ユーザーIDを取得
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            // 1. Supabaseから最新データを取得してローカルに同期
            try await syncFromSupabase(to: context, userId: userId)
            
            // 2. ローカルの変更をSupabaseに送信
            try await syncToSupabase(from: context, userId: userId)
            
            // 3. 最終同期日時を更新
            let now = Date()
            UserDefaults.standard.set(now, forKey: lastSyncDateKey)
            
            await MainActor.run {
                lastSyncDate = now
                isSyncing = false
                print("✅ Manual sync completed")
            }
        } catch {
            let errorMessage = parseSyncError(error)
            await MainActor.run {
                syncError = errorMessage
                isSyncing = false
                print("❌ Sync error: \(error)")
            }
        }
    }
    
    /// Supabaseからデータを取得してローカルに同期
    private func syncFromSupabase(to context: ModelContext, userId: UUID) async throws {
        guard let supabase = supabase else { return }
        
        // 最終同期日時を取得
        let lastSync = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date
        
        // Transactionsを取得
        var transactionQuery = supabase.from("transactions")
            .select()
            .eq("user_id", value: userId.uuidString)
        
        if let lastSync = lastSync {
            // 最終同期以降の変更のみ取得
            transactionQuery = transactionQuery.gte("updated_at", value: lastSync.ISO8601Format())
        }
        
        let transactions: [SupabaseTransaction] = try await transactionQuery.execute().value
        
        // Categoriesを取得
        var categoryQuery = supabase.from("categories")
            .select()
            .eq("user_id", value: userId.uuidString)
        
        if let lastSync = lastSync {
            categoryQuery = categoryQuery.gte("updated_at", value: lastSync.ISO8601Format())
        }
        
        let categories: [SupabaseCategory] = try await categoryQuery.execute().value
        
        // ローカルデータとマージ
        await MainActor.run {
            mergeTransactions(transactions, into: context)
            mergeCategories(categories, into: context)
        }
    }
    
    /// ローカルの変更をSupabaseに送信
    private func syncToSupabase(from context: ModelContext, userId: UUID) async throws {
        guard let supabase = supabase else { return }
        
        // ローカルの全データを取得
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let categoryDescriptor = FetchDescriptor<Category>()
        
        let localTransactions = (try? context.fetch(transactionDescriptor)) ?? []
        let localCategories = (try? context.fetch(categoryDescriptor)) ?? []
        
        // Supabaseに送信（upsertを使用）
        for transaction in localTransactions {
            let supabaseTransaction = SupabaseTransaction(from: transaction, userId: userId)
            try await supabase.from("transactions")
                .upsert(supabaseTransaction, onConflict: "id")
                .execute()
        }
        
        // Categoriesはname + type + user_idの組み合わせでユニークなので、別の方法で処理
        for category in localCategories {
            let supabaseCategory = SupabaseCategory(from: category, userId: userId)
            // 既存のカテゴリを検索
            let existing: [SupabaseCategory] = try await supabase.from("categories")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("name", value: category.name)
                .eq("type_raw_value", value: category.typeRawValue)
                .execute()
                .value
            
            if existing.isEmpty {
                // 新規作成
                try await supabase.from("categories")
                    .insert(supabaseCategory)
                    .execute()
            } else {
                // 更新（order_indexのみ）
                try await supabase.from("categories")
                    .update(["order_index": category.order])
                    .eq("id", value: existing.first!.id.uuidString)
                    .execute()
            }
        }
    }
    
    // MARK: - データマージ
    
    private func mergeTransactions(_ supabaseTransactions: [SupabaseTransaction], into context: ModelContext) {
        for supabaseTransaction in supabaseTransactions {
            // 既存のトランザクションを検索
            let descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { $0.idString == supabaseTransaction.id.uuidString }
            )
            
            if let existing = try? context.fetch(descriptor).first {
                // Supabaseのデータで更新（競合解決はSupabase側のupdated_atを優先）
                // 簡略化のため、常にSupabaseのデータで更新
                existing.title = supabaseTransaction.title
                existing.amount = supabaseTransaction.amount
                existing.originalAmount = supabaseTransaction.originalAmount
                existing.date = supabaseTransaction.date
                existing.category = supabaseTransaction.category
                existing.typeRawValue = supabaseTransaction.typeRawValue
                existing.currency = supabaseTransaction.currency
            } else {
                // 新規作成
                let transaction = supabaseTransaction.toTransaction()
                context.insert(transaction)
            }
        }
        
        try? context.save()
    }
    
    private func mergeCategories(_ supabaseCategories: [SupabaseCategory], into context: ModelContext) {
        for supabaseCategory in supabaseCategories {
            let descriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { $0.name == supabaseCategory.name && $0.typeRawValue == supabaseCategory.typeRawValue }
            )
            
            if let existing = try? context.fetch(descriptor).first {
                // Supabaseのデータで更新
                existing.order = supabaseCategory.orderIndex
            } else {
                // 新規作成
                let category = supabaseCategory.toCategory()
                context.insert(category)
            }
        }
        
        try? context.save()
    }
    
    // MARK: - エラー処理
    
    func clearSyncError() {
        syncError = nil
    }
    
    private func parseSyncError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("network") || errorString.contains("connection") {
            return "ネットワークエラー。インターネット接続を確認してください。"
        } else if errorString.contains("unauthorized") || errorString.contains("authentication") {
            return "認証エラー。再度ログインしてください。"
        } else if errorString.contains("not found") {
            return "データが見つかりませんでした。"
        }
        
        return "同期エラー: \(error.localizedDescription)"
    }
}

