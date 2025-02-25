import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "selectedCurrency")
        }
    }
    
    init() {
        self.selectedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "$"
    }
}
