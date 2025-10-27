import Foundation
import SwiftUI
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
}

@Model
class Transaction {
    var id: UUID
    var title: String
    var amount: Double
    /// The original transaction amount before any conversion
    var originalAmount: Double
    var date: Date
    var category: String
    var type: TransactionType
    var currency: String

    /// Designated initializer for creating new transactions
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        originalAmount: Double,
        date: Date,
        category: String,
        type: TransactionType = .expense,
        currency: String
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.originalAmount = originalAmount
        self.date = date
        self.category = category
        self.type = type
        self.currency = currency
    }
}

// Extension to make Transaction conform to Identifiable for SwiftUI
extension Transaction: Identifiable {}
