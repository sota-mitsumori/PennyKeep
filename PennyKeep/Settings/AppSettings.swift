import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "selectedCurrency")
        }
    }
    
    @Published var tempCurrency: String {
        didSet {
            UserDefaults.standard.set(tempCurrency, forKey: "tempCurrency")
        }
    }
    
    init() {
        self.selectedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        self.tempCurrency = UserDefaults.standard.string(forKey: "tempCurrency") ?? "USD"
    }
}
