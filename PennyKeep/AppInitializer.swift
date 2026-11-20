import SwiftUI
import SwiftData
import GoogleMobileAds

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
    
    @State private var showOnboarding = false
    @State private var hasCheckedInitialSync = false

    // Whether the first-launch onboarding has been completed
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // Legacy flag from the old first-launch auth sheet; users who saw it skip onboarding
    @AppStorage("hasShownInitialAuthSheet") private var hasShownInitialAuthSheet = false

    var body: some View {
        Group {
            if isInitialized {
                ContentView()
                    .environmentObject(categoryManager)
                    .environmentObject(transactionStore)
                    .environmentObject(appSettings)
                    .environmentObject(syncManager)
                    .environmentObject(authManager)
                    .onAppear {
                        // Existing users (saw the old auth sheet or already signed in) skip onboarding
                        if hasShownInitialAuthSheet || authManager.isSignedIn {
                            hasCompletedOnboarding = true
                        }
                        if !hasCompletedOnboarding {
                            showOnboarding = true
                        }
                        
                        // Check if user is already signed in on app launch and sync
                        // Use normal sync (not forceFullSync) since this device may have local data
                        if authManager.isSignedIn && !hasCheckedInitialSync {
                            hasCheckedInitialSync = true
                            Task {
                                await syncManager.manualSync(forceFullSync: false)
                                // Refresh data after sync
                                transactionStore.refreshTransactions()
                                categoryManager.refreshCategories()
                            }
                        }
                    }
                    .onChange(of: authManager.isSignedIn) { signedIn in
                        if signedIn {
                            // User just signed in - sync all data from Supabase (force full sync)
                            // This ensures data from other devices is downloaded
                            Task {
                                await syncManager.manualSync(forceFullSync: true)
                                // Refresh data after sync
                                transactionStore.refreshTransactions()
                                categoryManager.refreshCategories()
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showOnboarding) {
                        OnboardingView {
                            hasCompletedOnboarding = true
                            showOnboarding = false
                        }
                        .environmentObject(authManager)
                        .environmentObject(appSettings)
                    }
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
        
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start(completionHandler: nil)
        print("✅ Google Mobile Ads SDK initialized")
        
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
