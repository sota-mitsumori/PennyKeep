import Foundation

enum TransactionType: String, Codable {
    case expense
    case income
}

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var type: TransactionType = .expense // Default is expense
}

