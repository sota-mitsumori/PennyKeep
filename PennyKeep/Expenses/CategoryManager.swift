import Foundation
import SwiftUI

class CategoryManager: ObservableObject {
    @Published var expenseCategories: [String] = [] {
        didSet {
            saveExpenseCategories()
        }
    }
    
    @Published var incomeCategories: [String] = [] {
        didSet {
            saveIncomeCategories()
        }
    }
    
    private let expenseCategoriesKey = "expenseCategories"
    private let incomeCategoriesKey = "incomeCategories"
    
    init() {
        loadCategories()
    }
    
    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: expenseCategoriesKey),
           let savedExpense = try? JSONDecoder().decode([String].self, from: data) {
            expenseCategories = savedExpense
        } else {
            // If no saved data exists, initialize with default categories.
            expenseCategories = ["Transportation", "Grocery", "Entertainment", "Other"]
        }
        
        if let data = UserDefaults.standard.data(forKey: incomeCategoriesKey),
           let savedExpense = try? JSONDecoder().decode([String].self, from: data) {
            incomeCategories = savedExpense
        } else {
            // If no saved data exists, initialize with default categories.
            incomeCategories = ["Salary", "Investments", "Gifts", "Other"]
        }
    }
    
    private func saveExpenseCategories() {
        if let encoded = try? JSONEncoder().encode(expenseCategories) {
            UserDefaults.standard.set(encoded, forKey: expenseCategoriesKey)
        }
    }
    
    private func saveIncomeCategories() {
        if let encoded = try? JSONEncoder().encode(incomeCategories) {
            UserDefaults.standard.set(encoded, forKey: incomeCategoriesKey)
        }
    }
    
    // Methods for managing expense categories.
    func addExpenseCategory(_ category: String) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        expenseCategories.append(trimmed)
    }
    
    func deleteExpenseCategory(at offsets: IndexSet) {
        expenseCategories.remove(atOffsets: offsets)
    }
    
    func moveExpenseCategory(from source: IndexSet, to destination: Int) {
        expenseCategories.move(fromOffsets: source, toOffset: destination)
    }
    
    // Methods for managing income categories.
    func addIncomeCategory(_ category: String) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        incomeCategories.append(trimmed)
    }
    
    func deleteIncomeCategory(at offsets: IndexSet) {
        incomeCategories.remove(atOffsets: offsets)
    }
    
    func moveIncomeCategory(from source: IndexSet, to destination: Int) {
        incomeCategories.move(fromOffsets: source, toOffset: destination)
    }
}

