import Foundation
import SwiftData
import SwiftUI

class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    var modelContext: ModelContext?
    
    // Static reference to the main model context
    private static var sharedModelContext: ModelContext?
    
    init() {
        // ModelContext will be injected from the app
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Self.sharedModelContext = context // Store as static reference
        loadTransactions()
    }
    
    private func loadTransactions() {
        // Use the instance context first, fallback to shared context
        let context = modelContext ?? Self.sharedModelContext
        guard let context = context else { 
            print("No model context available for loading transactions")
            return 
        }
        
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let fetchedTransactions = (try? context.fetch(descriptor)) ?? []
        print("Loaded \(fetchedTransactions.count) transactions from SwiftData")
        transactions = fetchedTransactions
    }
    
    func addTransaction(_ transaction: Transaction) {
        // Use the instance context first, fallback to shared context
        let context = modelContext ?? Self.sharedModelContext
        guard let context = context else { 
            print("No model context available for adding transaction")
            return 
        }
        
        print("Adding transaction: \(transaction.title) - \(transaction.amount)")
        context.insert(transaction)
        
        do {
            try context.save()
            print("Transaction saved successfully")
        } catch {
            print("Failed to save transaction: \(error)")
        }
        
        loadTransactions() // Refresh the published array
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        // Use the instance context first, fallback to shared context
        let context = modelContext ?? Self.sharedModelContext
        guard let context = context else { 
            print("No model context available for deleting transaction")
            return 
        }
        
        print("Deleting transaction: \(transaction.title) - \(transaction.amount)")
        context.delete(transaction)
        
        do {
            try context.save()
            print("Transaction deleted successfully")
        } catch {
            print("Failed to delete transaction: \(error)")
        }
        
        loadTransactions() // Refresh the published array
    }
    
    func updateTransaction(_ transaction: Transaction) {
        // Use the instance context first, fallback to shared context
        let context = modelContext ?? Self.sharedModelContext
        guard let context = context else { return }
        
        do {
            try context.save()
            print("Transaction updated successfully")
        } catch {
            print("Failed to update transaction: \(error)")
        }
        
        loadTransactions() // Refresh the published array
    }
    
    // Public method to refresh transactions from UI
    func refreshTransactions() {
        print("Refreshing transactions - modelContext is \(modelContext != nil ? "available" : "nil")")
        
        // If modelContext is nil, try to use the shared context
        if modelContext == nil {
            if let sharedContext = Self.sharedModelContext {
                print("Using shared model context for refresh")
                self.modelContext = sharedContext
            } else {
                print("No model context available for refresh")
                return
            }
        }
        
        loadTransactions()
        // Force UI update
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

