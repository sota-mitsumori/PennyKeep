import Foundation
import SwiftUI

class CategoryManager: ObservableObject {
    @Published var categories: [String] = [] {
        didSet {
            saveCategories()
        }
    }
    
    private let categoriesKey = "categories"
    
    init() {
        loadCategories()
    }
    
    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let savedCategories = try? JSONDecoder().decode([String].self, from: data) {
            categories = savedCategories
        } else {
            // If no saved data exists, initialize with default categories.
            categories = ["Transportation", "Grocery", "Entertainment", "Other"]
        }
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }
    
    // Methods for managing the categories.
    func add(category: String) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        categories.append(trimmed)
    }
    
    func delete(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
    }
}

