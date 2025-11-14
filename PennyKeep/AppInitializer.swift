import SwiftUI
import SwiftData

struct AppInitializer: View {
    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var categoryManager = CategoryManager()
    @StateObject private var appSettings = AppSettings()
    @StateObject private var syncManager = SyncManager()
    @StateObject private var authManager = AuthenticationManager()
    
    let modelContainer: ModelContainer
    @State private var isInitialized = false
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    var body: some View {
        Group {
            if isInitialized {
                ContentView()
                    .environmentObject(categoryManager)
                    .environmentObject(transactionStore)
                    .environmentObject(appSettings)
                    .environmentObject(syncManager)
                    .environmentObject(authManager)
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        initializeApp()
                    }
            }
        }
    }
    
    private func initializeApp() {
        let context = modelContainer.mainContext
        
        // Perform migration from UserDefaults to SwiftData FIRST
        DataMigration.migrateFromUserDefaults(to: context)
        
        // Fix existing data: ensure typeRawValue is set correctly
        fixTransactionTypeRawValues(in: context)
        
        // Set up the stores with SwiftData context
        transactionStore.setModelContext(context)
        categoryManager.setModelContext(context)
        syncManager.setModelContext(context)
        // AppSettings uses UserDefaults, no SwiftData context needed
        
        print("App initialized with model contexts")
        
        // Mark as initialized
        DispatchQueue.main.async {
            isInitialized = true
        }
    }
    
    /// Fix typeRawValue for existing transactions that might have incorrect values
    /// Uses category to infer the correct type if typeRawValue is incorrect
    private func fixTransactionTypeRawValues(in context: ModelContext) {
        let descriptor = FetchDescriptor<Transaction>()
        guard let transactions = try? context.fetch(descriptor) else {
            return
        }
        
        // Get category lists to infer transaction type
        let expenseDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "expense" }
        )
        let incomeDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "income" }
        )
        let expenseCategories = (try? context.fetch(expenseDescriptor)) ?? []
        let incomeCategories = (try? context.fetch(incomeDescriptor)) ?? []
        
        let expenseCategoryNames = Set(expenseCategories.map { $0.name })
        let incomeCategoryNames = Set(incomeCategories.map { $0.name })
        
        var needsSave = false
        for transaction in transactions {
            let currentRawValue = transaction.typeRawValue
            
            // Try to infer from category if typeRawValue is expense (default)
            // This helps fix transactions that were incorrectly set to expense
            if currentRawValue == "expense" && incomeCategoryNames.contains(transaction.category) {
                print("Fixing transaction typeRawValue: '\(transaction.title)' category: '\(transaction.category)' from 'expense' to 'income'")
                transaction.typeRawValue = "income"
                needsSave = true
            } else if currentRawValue == "income" && expenseCategoryNames.contains(transaction.category) {
                print("Fixing transaction typeRawValue: '\(transaction.title)' category: '\(transaction.category)' from 'income' to 'expense'")
                transaction.typeRawValue = "expense"
                needsSave = true
            } else if currentRawValue != "expense" && currentRawValue != "income" {
                // If typeRawValue is invalid, infer from category
                let inferredType: TransactionType
                if incomeCategoryNames.contains(transaction.category) {
                    inferredType = .income
                } else {
                    inferredType = .expense
                }
                print("Fixing invalid transaction typeRawValue: '\(transaction.title)' category: '\(transaction.category)' from '\(currentRawValue)' to '\(inferredType.rawValue)'")
                transaction.typeRawValue = inferredType.rawValue
                needsSave = true
            }
        }
        
        if needsSave {
            do {
                try context.save()
                print("Fixed transaction typeRawValues")
            } catch {
                print("Failed to save fixed transaction types: \(error)")
            }
        } else {
            print("All transaction typeRawValues are correct")
        }
    }
}
