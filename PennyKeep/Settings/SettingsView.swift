import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var syncManager: SupabaseSyncManager
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var authManager: SupabaseAuthManager
    
    @State private var showProfile = false
    
    private var lastSyncText: String {
        guard let date = syncManager.lastSyncDate else {
            return "Not synced yet"
        }
        
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        let relativeText = relative.localizedString(for: date, relativeTo: Date())
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(relativeText) • \(formatter.string(from: date))"
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
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 10) {
                            Label(syncManager.isConnected ? "Connected" : "Not Connected",
                                  systemImage: syncManager.isConnected ? "checkmark.seal.fill" : "wifi.slash")
                            .font(.callout.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundColor(syncManager.isConnected ? .green : .orange)
                            .background((syncManager.isConnected ? Color.green.opacity(0.12) : Color.orange.opacity(0.12)), in: Capsule())
                            
                            Spacer()
                            
                            if syncManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label {
                                Text(lastSyncText)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "clock.arrow.2.circlepath")
                            }
                            .font(.caption)
                            
                            if !authManager.isSignedIn {
                                Label("Sign in to enable sync", systemImage: "person.crop.circle.badge.exclamationmark")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await syncManager.manualSync()
                                // Reload data after sync attempt (success or failure)
                                transactionStore.refreshTransactions()
                                categoryManager.refreshCategories()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if syncManager.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                    Text("Syncing...")
                                } else {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                    Text("Sync Now")
                                }
                                Spacer()
                            }
                        }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .disabled(syncManager.isSyncing || !authManager.isSignedIn)
                        
                        if let error = syncManager.syncError {
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text(error)
                                        .font(.caption)
                                } icon: {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                }
                                .foregroundColor(.red)
                                
                                Button(action: {
                                    syncManager.clearSyncError()
                                }) {
                                    Text("Dismiss")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
//                        Button {
//                            Task {
//                                await syncManager.cleanupDuplicateTransactions()
//                                transactionStore.refreshTransactions()
//                                categoryManager.refreshCategories()
//                            }
//                        } label: {
//                            Label("Remove Duplicates", systemImage: "trash")
//                                .frame(maxWidth: .infinity)
//                        }
//                        .controlSize(.large)
//                        .buttonStyle(.bordered)
//                        .disabled(syncManager.isSyncing)
                    }
                    .listRowBackground(Color(.systemGroupedBackground))
                }
                
                Section(header: Text("Version")) {
                    Text("Version 1.4.0 (2025.12.20)")
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
                    .environmentObject(appSettings)
                    .environmentObject(syncManager)
                    .environmentObject(transactionStore)
                    .environmentObject(categoryManager)
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
