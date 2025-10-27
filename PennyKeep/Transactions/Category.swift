import Foundation
import SwiftData

@Model
class Category {
    var name: String
    var type: CategoryType
    var typeRawValue: String
    var order: Int
    
    init(name: String, type: CategoryType, order: Int = 0) {
        self.name = name
        self.type = type
        self.typeRawValue = type.rawValue
        self.order = order
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case expense
    case income
}