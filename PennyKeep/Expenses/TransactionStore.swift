import Foundation

class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = [] {
        didSet {
            saveTransactions()
        }
    }
    
    private let transactionsKey = "transactions"
    
    init() {
        loadTransactions()
    }
    
    private func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let saved = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = saved
        }
    }
    
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }
}

