import SwiftUI

@main
struct PennyKeepApp: App {
    @StateObject private var expenseStore = TransactionStore()
    @StateObject private var categoryManager = CategoryManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(categoryManager)
                .environmentObject(expenseStore)
        }
    }
}
