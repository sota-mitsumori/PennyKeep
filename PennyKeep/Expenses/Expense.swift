import Foundation

struct Expense: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var date: Date
    var category: String
}

