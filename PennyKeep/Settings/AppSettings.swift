import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    private static let symbolToCode: [String: String] = [
        "$": "USD",
        "€": "EUR",
        "£": "GBP",
        "¥": "JPY",
        "₹": "INR"
    ]
    
    @Published var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "selectedCurrency")
        }
    }
    
    
    init() {
        let raw = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "$"
        if currencyItems.contains(where: { $0.code == raw }) {
            selectedCurrency = raw
        } else if let mapped = Self.symbolToCode[raw] {
            selectedCurrency = mapped
            UserDefaults.standard.set(mapped, forKey: "selectedCurrency")
        } else {
            selectedCurrency = "USD"
        }
    }
}
