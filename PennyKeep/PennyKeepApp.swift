import SwiftUI

@main
struct PennyKeepApp: App {
    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var categoryManager = CategoryManager()
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(categoryManager)
                .environmentObject(transactionStore)
                .environmentObject(appSettings)
        }
    }
}
