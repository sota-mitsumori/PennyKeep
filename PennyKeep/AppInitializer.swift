import SwiftUI
import SwiftData
import UIKit

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
    
    @State private var showAuthView = false
    @State private var hasCheckedInitialSync = false
    @State private var showPayPayImport = false
    @State private var pendingCSVURL: URL?
    
    // UserDefaultsキー: 初回ログインシート表示フラグ
    private let hasShownInitialAuthSheetKey = "hasShownInitialAuthSheet"
    
    // App Group identifier
    private let appGroupIdentifier = "group.com.pennykeep"
    
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
                        // Show auth view if not signed in (only once, first time app is opened)
                        let hasShownBefore = UserDefaults.standard.bool(forKey: hasShownInitialAuthSheetKey)
                        if !authManager.isSignedIn && !hasShownBefore && !showAuthView {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showAuthView = true
                                UserDefaults.standard.set(true, forKey: hasShownInitialAuthSheetKey)
                            }
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
                        
                        // Check for incoming PayPay CSV from Share Extension
                        checkForIncomingPayPayCSV()
                    }
                    .onChange(of: isInitialized) { _ in
                        if isInitialized {
                            // Check for incoming PayPay CSV when app becomes initialized
                            checkForIncomingPayPayCSV()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        // Check for incoming PayPay CSV when app enters foreground
                        checkForIncomingPayPayCSV()
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
                    .sheet(isPresented: $showAuthView) {
                        BeautifulAuthView()
                            .environmentObject(authManager)
                            .environmentObject(appSettings)
                            .onDisappear {
                                // Mark as shown so it doesn't appear again
                                showAuthView = false
                            }
                    }
                    .sheet(isPresented: $showPayPayImport) {
                        if let csvURL = pendingCSVURL {
                            PayPayImportView(csvURL: csvURL)
                                .environmentObject(transactionStore)
                                .environmentObject(categoryManager)
                                .environmentObject(appSettings)
                                .onDisappear {
                                    // Clear the flag after import view is dismissed
                                    clearIncomingPayPayCSVFlag()
                                }
                        }
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
    
    private func checkForIncomingPayPayCSV() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Failed to access shared UserDefaults")
            return
        }
        
        let hasIncomingCSV = sharedDefaults.bool(forKey: "hasIncomingPayPayCSV")
        
        if hasIncomingCSV {
            // Get the file name
            guard let fileName = sharedDefaults.string(forKey: "incomingPayPayCSVFileName") else {
                print("No file name found for incoming CSV")
                clearIncomingPayPayCSVFlag()
                return
            }
            
            // Get the file from shared container
            guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                print("Failed to get shared container URL")
                clearIncomingPayPayCSVFlag()
                return
            }
            
            let fileURL = sharedContainerURL.appendingPathComponent("IncomingPayPayCSV").appendingPathComponent(fileName)
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("File does not exist at: \(fileURL.path)")
                clearIncomingPayPayCSVFlag()
                return
            }
            
            // Set the pending CSV URL and show import view
            pendingCSVURL = fileURL
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showPayPayImport = true
            }
        }
    }
    
    private func clearIncomingPayPayCSVFlag() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        sharedDefaults.removeObject(forKey: "hasIncomingPayPayCSV")
        sharedDefaults.removeObject(forKey: "incomingPayPayCSVFileName")
        sharedDefaults.synchronize()
        pendingCSVURL = nil
    }
    
}
