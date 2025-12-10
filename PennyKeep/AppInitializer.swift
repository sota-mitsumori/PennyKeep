import SwiftUI
import SwiftData

struct AppInitializer: View {
    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var categoryManager = CategoryManager()
    @StateObject private var appSettings = AppSettings()
    @StateObject private var syncManager = SupabaseSyncManager()
    @StateObject private var authManager = SupabaseAuthManager()
    
    let modelContainer: ModelContainer
    @State private var isInitialized = false
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    var body: some View {
        Group {
            if isInitialized {
                ContentView()
                    .environmentObject(categoryManager)
                    .environmentObject(transactionStore)
                    .environmentObject(appSettings)
                    .environmentObject(syncManager)
                    .environmentObject(authManager)
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        initializeApp()
                    }
            }
        }
    }
    
    private func initializeApp() {
        let context = modelContainer.mainContext
        
        // Perform migration from UserDefaults to SwiftData FIRST
        DataMigration.migrateFromUserDefaults(to: context)
        
        // Set up the stores with SwiftData context
        transactionStore.setModelContext(context)
        transactionStore.setSyncManager(syncManager)
        categoryManager.setModelContext(context)
        categoryManager.setSyncManager(syncManager)
        syncManager.setModelContext(context)
        syncManager.setAuthManager(authManager)
        // AppSettings uses UserDefaults, no SwiftData context needed
        
        print("App initialized with model contexts")
        
        // Mark as initialized
        DispatchQueue.main.async {
            isInitialized = true
        }
    }
    
}
