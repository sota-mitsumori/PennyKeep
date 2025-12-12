import Foundation
import Supabase
import PostgREST

// MARK: - Supabase Transaction Model

struct SupabaseTransaction: Codable {
    let id: UUID
    let title: String
    let amount: Double
    let originalAmount: Double
    let date: Date
    let category: String
    let typeRawValue: String
    let currency: String
    let userId: UUID
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case originalAmount = "original_amount"
        case date
        case category
        case typeRawValue = "type_raw_value"
        case currency
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from transaction: Transaction, userId: UUID) {
        self.id = transaction.id
        self.title = transaction.title
        self.amount = transaction.amount
        self.originalAmount = transaction.originalAmount
        self.date = transaction.date
        self.category = transaction.category
        self.typeRawValue = transaction.typeRawValue
        self.currency = transaction.currency
        self.userId = userId
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    func toTransaction() -> Transaction {
        return Transaction(
            id: id,
            title: title,
            amount: amount,
            originalAmount: originalAmount,
            date: date,
            category: category,
            type: TransactionType(rawValue: typeRawValue) ?? .expense,
            currency: currency
        )
    }
}

// MARK: - Supabase Category Model

struct SupabaseCategory: Codable {
    let id: UUID
    let name: String
    let typeRawValue: String
    let orderIndex: Int
    let userId: UUID
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case typeRawValue = "type_raw_value"
        case orderIndex = "order_index"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from category: Category, userId: UUID) {
        // 既存のIDがあれば使用、なければ空文字列（Supabaseが自動生成）
        self.id = category.idString.isEmpty ? UUID() : category.id
        self.name = category.name
        self.typeRawValue = category.typeRawValue
        self.orderIndex = category.order
        self.userId = userId
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    init(id: UUID, name: String, typeRawValue: String, orderIndex: Int, userId: UUID, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.typeRawValue = typeRawValue
        self.orderIndex = orderIndex
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toCategory() -> Category {
        return Category(
            name: name,
            type: CategoryType(rawValue: typeRawValue) ?? .expense,
            order: orderIndex,
            id: id
        )
    }
}


