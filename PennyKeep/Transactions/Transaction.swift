import Foundation
import SwiftUI
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case bankTransfer = "bank_transfer"
    case digitalWallet = "digital_wallet"
    case qrCode = "qr_code"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .cash: return "Cash"
        case .bankTransfer: return "Bank Transfer"
        case .digitalWallet: return "Digital Wallet"
        case .qrCode: return "QR Code"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard.trianglebadge.exclamationmark.fill"
        case .cash: return "banknote.fill"
        case .bankTransfer: return "arrow.left.arrow.right.circle.fill"
        case .digitalWallet: return "wallet.pass.fill"
        case .qrCode: return "qrcode"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
class Transaction {
    var idString: String = ""
    var id: UUID {
        get {
            if let uuid = UUID(uuidString: idString) {
                return uuid
            }
            let newId = UUID()
            idString = newId.uuidString   // ensure we persist a stable id
            return newId
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
    var paymentMethodRawValue: String = PaymentMethod.cash.rawValue
    
    var paymentMethod: PaymentMethod {
        get {
            PaymentMethod(rawValue: paymentMethodRawValue) ?? .cash
        }
        set {
            paymentMethodRawValue = newValue.rawValue
        }
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
        currency: String,
        paymentMethod: PaymentMethod = .cash
    ) {
        self.idString = id.uuidString
        self.title = title
        self.amount = amount
        self.originalAmount = originalAmount
        self.date = date
        self.category = category
        self.typeRawValue = type.rawValue
        self.currency = currency
        self.paymentMethodRawValue = paymentMethod.rawValue
    }
}

// Extension to make Transaction conform to Identifiable for SwiftUI
extension Transaction: Identifiable {}
