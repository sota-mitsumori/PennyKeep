import Foundation
import SwiftUI
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
}

@Model
class Transaction {
    var idString: String = ""
    var id: UUID {
        get {
            UUID(uuidString: idString) ?? UUID()
        }
        set {
            idString = newValue.uuidString
        }
    }
    var title: String = ""
    var amount: Double = 0.0
    /// The original transaction amount before any conversion
    var originalAmount: Double = 0.0
    var date: Date = Date()
    var category: String = ""
    var typeRawValue: String = "expense"
    var type: TransactionType {
        get {
            TransactionType(rawValue: typeRawValue) ?? .expense
        }
        set {
            typeRawValue = newValue.rawValue
        }
    }
    var currency: String = "USD"

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
        self.idString = id.uuidString
        self.title = title
        self.amount = amount
        self.originalAmount = originalAmount
        self.date = date
        self.category = category
        self.typeRawValue = type.rawValue
        self.currency = currency
    }
}

// Extension to make Transaction conform to Identifiable for SwiftUI
extension Transaction: Identifiable {}
