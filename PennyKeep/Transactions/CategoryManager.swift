import Foundation
import SwiftUI
import SwiftData

class CategoryManager: ObservableObject {
    @Published var expenseCategories: [String] = [] {
        didSet {
            print("Expense categories updated: \(expenseCategories)")
        }
    }
    @Published var incomeCategories: [String] = [] {
        didSet {
            print("Income categories updated: \(incomeCategories)")
        }
    }
    var modelContext: ModelContext?
    
    // Static reference to the main model context
    private static var sharedModelContext: ModelContext?
    
    init() {
        // ModelContext will be injected from the app
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Self.sharedModelContext = context // Store as static reference
        initializeDefaultCategoriesIfNeeded()
        cleanupDuplicateCategories() // Clean up any duplicates
        loadCategories()
        
        // Force a UI update after loading categories
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    private func initializeDefaultCategoriesIfNeeded() {
        guard let context = modelContext else { return }
        
        let expenseDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "expense" }
        )
        let incomeDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "income" }
        )
        
        let existingExpenseCategories = (try? context.fetch(expenseDescriptor)) ?? []
        let existingIncomeCategories = (try? context.fetch(incomeDescriptor)) ?? []
        
        if existingExpenseCategories.isEmpty {
            let defaultExpenseCategories = ["Transportation", "Grocery", "Entertainment", "Other"]
            for (index, categoryName) in defaultExpenseCategories.enumerated() {
                let category = Category(name: categoryName, type: .expense, order: index)
                context.insert(category)
            }
            print("Created default expense categories")
        } else {
            print("Expense categories already exist: \(existingExpenseCategories.map { $0.name })")
        }
        
        if existingIncomeCategories.isEmpty {
            let defaultIncomeCategories = ["Salary", "Investments", "Gifts", "Other"]
            for (index, categoryName) in defaultIncomeCategories.enumerated() {
                let category = Category(name: categoryName, type: .income, order: index)
                context.insert(category)
            }
            print("Created default income categories")
        } else {
            print("Income categories already exist: \(existingIncomeCategories.map { $0.name })")
        }
        
        do {
            try context.save()
            print("Successfully saved default categories")
        } catch {
            print("Failed to save default categories: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let context = modelContext else { 
            print("loadCategories: No model context available")
            return 
        }
        print("loadCategories: Model context available, fetching categories")
        
        let expenseDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "expense" },
            sortBy: [SortDescriptor(\.order)]
        )
        let incomeDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "income" },
            sortBy: [SortDescriptor(\.order)]
        )
        
        let fetchedExpenseCategories = (try? context.fetch(expenseDescriptor)) ?? []
        let fetchedIncomeCategories = (try? context.fetch(incomeDescriptor)) ?? []
        
        // Remove duplicates and maintain order
        var seenExpense = Set<String>()
        var seenIncome = Set<String>()
        
        expenseCategories = fetchedExpenseCategories.compactMap { category in
            if seenExpense.contains(category.name) {
                return nil
            } else {
                seenExpense.insert(category.name)
                return category.name
            }
        }
        
        incomeCategories = fetchedIncomeCategories.compactMap { category in
            if seenIncome.contains(category.name) {
                return nil
            } else {
                seenIncome.insert(category.name)
                return category.name
            }
        }
        
        print("Loaded \(expenseCategories.count) expense categories: \(expenseCategories)")
        print("Loaded \(incomeCategories.count) income categories: \(incomeCategories)")
    }
    
    // Public method to refresh categories from UI
    func refreshCategories() {
        print("refreshCategories called - modelContext is \(modelContext != nil ? "available" : "nil")")
        
        // If modelContext is nil, try to use the shared context
        if modelContext == nil {
            if let sharedContext = Self.sharedModelContext {
                print("Using shared model context")
                self.modelContext = sharedContext
            } else {
                print("No model context available")
                return
            }
        }
        
        loadCategories()
        // Force UI update
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    // Method to clean up duplicate categories
    func cleanupDuplicateCategories() {
        guard let context = modelContext else { return }
        
        let expenseDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "expense" },
            sortBy: [SortDescriptor(\.order)]
        )
        let incomeDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "income" },
            sortBy: [SortDescriptor(\.order)]
        )
        
        let allExpenseCategories = (try? context.fetch(expenseDescriptor)) ?? []
        let allIncomeCategories = (try? context.fetch(incomeDescriptor)) ?? []
        
        // Remove duplicate expense categories
        var seenExpense = Set<String>()
        for category in allExpenseCategories {
            if seenExpense.contains(category.name) {
                context.delete(category)
                print("Removed duplicate expense category: \(category.name)")
            } else {
                seenExpense.insert(category.name)
            }
        }
        
        // Remove duplicate income categories
        var seenIncome = Set<String>()
        for category in allIncomeCategories {
            if seenIncome.contains(category.name) {
                context.delete(category)
                print("Removed duplicate income category: \(category.name)")
            } else {
                seenIncome.insert(category.name)
            }
        }
        
        try? context.save()
        loadCategories()
    }
    
    // Methods for managing expense categories.
    func addExpenseCategory(_ category: String) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Check if category already exists
        if expenseCategories.contains(trimmed) {
            print("Expense category '\(trimmed)' already exists")
            return
        }
        
        guard let context = modelContext else { 
            print("No model context available for adding expense category")
            return 
        }
        let newCategory = Category(name: trimmed, type: .expense, order: expenseCategories.count)
        context.insert(newCategory)
        do {
            try context.save()
            print("Successfully added expense category: \(trimmed)")
        } catch {
            print("Failed to save expense category: \(error)")
        }
        loadCategories()
    }
    
    func deleteExpenseCategory(at offsets: IndexSet) {
        guard let context = modelContext else { return }
        
        let expenseDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "expense" },
            sortBy: [SortDescriptor(\.order)]
        )
        let categories = (try? context.fetch(expenseDescriptor)) ?? []
        
        for index in offsets {
            if index < categories.count {
                print("Deleting expense category: \(categories[index].name)")
                context.delete(categories[index])
            }
        }
        
        do {
            try context.save()
            print("Expense category deleted successfully")
        } catch {
            print("Failed to delete expense category: \(error)")
        }
        
        loadCategories()
    }
    
    func moveExpenseCategory(from source: IndexSet, to destination: Int) {
        guard let context = modelContext else { return }
        
        let expenseDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "expense" },
            sortBy: [SortDescriptor(\.order)]
        )
        var categories = (try? context.fetch(expenseDescriptor)) ?? []
        categories.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, category) in categories.enumerated() {
            category.order = index
        }
        try? context.save()
        loadCategories()
    }
    
    // Methods for managing income categories.
    func addIncomeCategory(_ category: String) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Check if category already exists
        if incomeCategories.contains(trimmed) {
            print("Income category '\(trimmed)' already exists")
            return
        }
        
        guard let context = modelContext else { 
            print("No model context available for adding income category")
            return 
        }
        let newCategory = Category(name: trimmed, type: .income, order: incomeCategories.count)
        context.insert(newCategory)
        do {
            try context.save()
            print("Successfully added income category: \(trimmed)")
        } catch {
            print("Failed to save income category: \(error)")
        }
        loadCategories()
    }
    
    func deleteIncomeCategory(at offsets: IndexSet) {
        guard let context = modelContext else { return }
        
        let incomeDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "income" },
            sortBy: [SortDescriptor(\.order)]
        )
        let categories = (try? context.fetch(incomeDescriptor)) ?? []
        
        for index in offsets {
            if index < categories.count {
                print("Deleting income category: \(categories[index].name)")
                context.delete(categories[index])
            }
        }
        
        do {
            try context.save()
            print("Income category deleted successfully")
        } catch {
            print("Failed to delete income category: \(error)")
        }
        
        loadCategories()
    }
    
    func moveIncomeCategory(from source: IndexSet, to destination: Int) {
        guard let context = modelContext else { return }
        
        let incomeDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.typeRawValue == "income" },
            sortBy: [SortDescriptor(\.order)]
        )
        var categories = (try? context.fetch(incomeDescriptor)) ?? []
        categories.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, category) in categories.enumerated() {
            category.order = index
        }
        try? context.save()
        loadCategories()
    }
}

