import Foundation
import SwiftData

// Codable version of Transaction for migration from UserDefaults
struct CodableTransaction: Codable {
    var id: UUID
    var title: String
    var amount: Double
    var originalAmount: Double
    var date: Date
    var category: String
    var type: TransactionType
    var currency: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, amount, originalAmount, date, category, type, currency
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        originalAmount = try container.decodeIfPresent(Double.self, forKey: .originalAmount) ?? amount
        date = try container.decode(Date.self, forKey: .date)
        category = try container.decode(String.self, forKey: .category)
        type = try container.decode(TransactionType.self, forKey: .type)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
    }
}

class DataMigration {
    static func migrateFromUserDefaults(to context: ModelContext) {
        // Check if we already have data in SwiftData
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let categoryDescriptor = FetchDescriptor<Category>()
        
        let existingTransactions = (try? context.fetch(transactionDescriptor)) ?? []
        let existingCategories = (try? context.fetch(categoryDescriptor)) ?? []
        
        // Only migrate if we don't have any existing data
        if existingTransactions.isEmpty && existingCategories.isEmpty {
            print("Starting migration from UserDefaults to SwiftData")
            
            // Migrate transactions
            migrateTransactions(to: context)
            
            // Migrate categories
            migrateCategories(to: context)
            
            // App settings (currency) will remain in UserDefaults
            
            // Clear UserDefaults after successful migration
            clearUserDefaults()
            
            print("Migration completed")
        } else {
            print("Data already exists in SwiftData, skipping migration")
        }
    }
    
    private static func migrateTransactions(to context: ModelContext) {
        let transactionsKey = "transactions"
        
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let savedTransactions = try? JSONDecoder().decode([CodableTransaction].self, from: data) {
            
            for codableTransaction in savedTransactions {
                let transaction = Transaction(
                    id: codableTransaction.id,
                    title: codableTransaction.title,
                    amount: codableTransaction.amount,
                    originalAmount: codableTransaction.originalAmount,
                    date: codableTransaction.date,
                    category: codableTransaction.category,
                    type: codableTransaction.type,
                    currency: codableTransaction.currency
                )
                context.insert(transaction)
            }
            
            try? context.save()
            print("Migrated \(savedTransactions.count) transactions from UserDefaults to SwiftData")
        }
    }
    
    private static func migrateCategories(to context: ModelContext) {
        let expenseCategoriesKey = "expenseCategories"
        let incomeCategoriesKey = "incomeCategories"
        
        // Migrate expense categories
        if let data = UserDefaults.standard.data(forKey: expenseCategoriesKey),
           let savedExpenseCategories = try? JSONDecoder().decode([String].self, from: data) {
            
            for (index, categoryName) in savedExpenseCategories.enumerated() {
                let category = Category(name: categoryName, type: .expense, order: index)
                context.insert(category)
            }
        }
        
        // Migrate income categories
        if let data = UserDefaults.standard.data(forKey: incomeCategoriesKey),
           let savedIncomeCategories = try? JSONDecoder().decode([String].self, from: data) {
            
            for (index, categoryName) in savedIncomeCategories.enumerated() {
                let category = Category(name: categoryName, type: .income, order: index)
                context.insert(category)
            }
        }
        
        try? context.save()
        print("Migrated categories from UserDefaults to SwiftData")
    }
    
    
    private static func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "transactions")
        UserDefaults.standard.removeObject(forKey: "expenseCategories")
        UserDefaults.standard.removeObject(forKey: "incomeCategories")
        // Keep selectedCurrency in UserDefaults
        print("Cleared UserDefaults data after migration (kept selectedCurrency)")
    }
}