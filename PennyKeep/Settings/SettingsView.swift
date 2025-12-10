import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var syncManager: SupabaseSyncManager
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var authManager: SupabaseAuthManager
    
    @State private var showProfile = false
    
    private var lastSyncText: String {
        if let date = syncManager.lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return "Not synced yet"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Currency")) {
                    Picker("Currency", selection: $appSettings.selectedCurrency) {
                        ForEach(currencyItems) { item in
                            Text("\(item.code) – \(item.name)")
                                .tag(item.code)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                
                Section(header: Text("Sync")) {
                    // Connection Status
                    HStack {
                        Text("Connection Status:")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: syncManager.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(syncManager.isConnected ? .green : .orange)
                            Text(syncManager.isConnected ? "Connected" : "Not Connected")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    
                    // Sync button
                    Button(action: {
                        Task {
                            await syncManager.manualSync()
                            // Reload data after sync attempt (success or failure)
                            transactionStore.refreshTransactions()
                            categoryManager.refreshCategories()
                        }
                    }) {
                        HStack {
                            if syncManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(syncManager.isSyncing ? "Syncing..." : "Sync Now")
                        }
                    }
                    .disabled(syncManager.isSyncing || !authManager.isSignedIn)
                    
                    if !authManager.isSignedIn {
                        Text("Please sign in to sync data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let error = syncManager.syncError {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Spacer()
                            }
                            Button(action: {
                                syncManager.clearSyncError()
                            }) {
                                Text("Dismiss")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Text("Last Sync:")
                        Spacer()
                        Text(lastSyncText)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                
                Section(header: Text("Version")) {
                    Text("Version 1.3.4 (2025.11.14)")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        if authManager.isSignedIn {
                            AvatarView(
                                name: authManager.userFullName,
                                email: authManager.userEmail,
                                size: 32
                            )
                        } else {
                            Image(systemName: "person.circle")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(authManager)
            }
            .onAppear {
                // Check connection status when view appears
                Task {
                    await syncManager.checkConnection()
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
            .environmentObject(SupabaseSyncManager())
            .environmentObject(TransactionStore())
            .environmentObject(CategoryManager())
            .environmentObject(SupabaseAuthManager())
    }
}
