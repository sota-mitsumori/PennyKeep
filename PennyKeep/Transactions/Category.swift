import Foundation
import SwiftData

@Model
class Category {
    var name: String = ""
    var typeRawValue: String = "expense"
    var type: CategoryType {
        get {
            CategoryType(rawValue: typeRawValue) ?? .expense
        }
        set {
            typeRawValue = newValue.rawValue
        }
    }
    var order: Int = 0
    
    init(name: String, type: CategoryType, order: Int = 0) {
        self.name = name
        self.typeRawValue = type.rawValue
        self.order = order
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case expense
    case income
}