import Foundation

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = [] {
        didSet {
            saveExpenses()
        }
    }

    init() {
        loadExpenses()
    }
    
    private let expensesKey = "expenses"

    func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: expensesKey) {
            if let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
                self.expenses = decoded
            }
        }
    }
    
    func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }
}

