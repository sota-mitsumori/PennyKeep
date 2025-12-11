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
        guard let urlString = SupabaseConfig.supabaseURL,
              let supabaseURL = URL(string: urlString),
              let supabaseKey = SupabaseConfig.supabaseAnonKey else {
            print("⚠️ Supabase is not configured. App will work in offline mode.")
            return
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        // 接続状態を確認（非ブロッキング）
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
        
        // Supabaseに送信（バッチ upsert でリクエスト回数を削減）
        let supabaseTransactions = localTransactions.map { SupabaseTransaction(from: $0, userId: userId) }
        if !supabaseTransactions.isEmpty {
            try await supabase.from("transactions")
                .upsert(supabaseTransactions, onConflict: "id")
                .execute()
        }
        
        // カテゴリの同期：既存のカテゴリを検索してIDを取得してからupsert
        var categoriesToUpsert: [SupabaseCategory] = []
        
        for localCategory in localCategories {
            var supabaseCategory = SupabaseCategory(from: localCategory, userId: userId)
            
            // IDがまだ設定されていない場合、Supabaseで既存カテゴリを検索
            if localCategory.idString.isEmpty {
                let existing: [SupabaseCategory] = try await supabase.from("categories")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .eq("name", value: localCategory.name)
                    .eq("type_raw_value", value: localCategory.typeRawValue)
                    .execute()
                    .value
                
                if let existingCategory = existing.first {
                    // 既存カテゴリのIDを使用
                    supabaseCategory = SupabaseCategory(
                        id: existingCategory.id,
                        name: localCategory.name,
                        typeRawValue: localCategory.typeRawValue,
                        orderIndex: localCategory.order,
                        userId: userId,
                        createdAt: existingCategory.createdAt,
                        updatedAt: existingCategory.updatedAt
                    )
                    // ローカルのカテゴリにもIDを保存
                    localCategory.idString = existingCategory.id.uuidString
                }
            }
            
            categoriesToUpsert.append(supabaseCategory)
        }
        
        if !categoriesToUpsert.isEmpty {
            // カテゴリをupsert（name + type_raw_value + user_id でユニーク）
            try await supabase.from("categories")
                .upsert(categoriesToUpsert, onConflict: "name,type_raw_value,user_id")
                .execute()
            
            // ローカルの変更を保存
            try? context.save()
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
            // IDで検索（優先）
            let idDescriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { $0.idString == supabaseCategory.id.uuidString }
            )
            
            if let existing = try? context.fetch(idDescriptor).first {
                // Supabaseのデータで更新
                existing.order = supabaseCategory.orderIndex
                existing.name = supabaseCategory.name
                existing.typeRawValue = supabaseCategory.typeRawValue
                // IDが設定されていない場合は設定
                if existing.idString.isEmpty {
                    existing.idString = supabaseCategory.id.uuidString
                }
            } else {
                // name + type で検索（フォールバック）
                let nameDescriptor = FetchDescriptor<Category>(
                    predicate: #Predicate<Category> { $0.name == supabaseCategory.name && $0.typeRawValue == supabaseCategory.typeRawValue }
                )
                
                if let existing = try? context.fetch(nameDescriptor).first {
                    // 既存カテゴリにIDを設定して更新
                    existing.idString = supabaseCategory.id.uuidString
                    existing.order = supabaseCategory.orderIndex
                } else {
                    // 新規作成
                    let category = supabaseCategory.toCategory()
                    context.insert(category)
                }
            }
        }
        
        try? context.save()
    }
    
    // MARK: - エラー処理
    
    func clearSyncError() {
        syncError = nil
    }
    
    // MARK: - 重複データクリーンアップ
    /// title/amount/date/category/type/currency が同一の取引を重複として扱い、ローカルとSupabaseから削除
    func cleanupDuplicateTransactions() async {
        guard let context = modelContext else {
            await MainActor.run { syncError = "ModelContext is not available" }
            return
        }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        do {
            let descriptor = FetchDescriptor<Transaction>()
            let allTransactions = (try? context.fetch(descriptor)) ?? []
            
            var firstSeen: [String: Transaction] = [:]
            var duplicates: [Transaction] = []
            
            for tx in allTransactions {
                let key = [
                    tx.title,
                    String(tx.amount),
                    String(tx.date.timeIntervalSince1970),
                    tx.category,
                    tx.typeRawValue,
                    tx.currency
                ].joined(separator: "|")
                
                if firstSeen[key] == nil {
                    firstSeen[key] = tx
                } else {
                    duplicates.append(tx)
                }
            }
            
            // ローカル削除
            for dup in duplicates {
                context.delete(dup)
            }
            try? context.save()
            
            // Supabaseからも削除（サインイン済みかつ設定済みのとき）
            if let supabase = supabase,
               let authManager = authManager,
               authManager.isSignedIn,
               !duplicates.isEmpty {
                let ids = duplicates.map { $0.idString }
                try await supabase.from("transactions")
                    .delete()
                    .in("id", value: ids)
                    .execute()
            }
            
            await MainActor.run {
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                syncError = parseSyncError(error)
                isSyncing = false
            }
        }
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

