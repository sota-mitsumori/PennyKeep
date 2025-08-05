import Foundation
import SwiftUI

enum TransactionType: String, Codable {
    case expense
    case income
}

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    /// The original transaction amount before any conversion
    var originalAmount: Double
    var date: Date
    var category: String
    var type: TransactionType = .expense // Default is expense
    var currency: String

    enum CodingKeys: String, CodingKey {
        case id, title, amount, originalAmount, date, category, type, currency
    }

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

    /// Custom decoder to supply a default currency for legacy records
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id       = try container.decode(UUID.self,       forKey: .id)
        title    = try container.decode(String.self,     forKey: .title)
        amount   = try container.decode(Double.self,     forKey: .amount)
        originalAmount = try container.decodeIfPresent(Double.self, forKey: .originalAmount) ?? amount
        date     = try container.decode(Date.self,       forKey: .date)
        category = try container.decode(String.self,     forKey: .category)
        type     = try container.decode(TransactionType.self, forKey: .type)
        // If `currency` was missing in old data, fall back to the app default
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
                   ?? AppSettings().selectedCurrency
    }
}
