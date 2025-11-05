import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    
    @State private var dataCount: (transactionCount: Int, categoryCount: Int)?
    
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
                
                Section(header: Text("iCloud Sync")) {
                    // iCloud Status
                    HStack {
                        Text("iCloud Status:")
                        Spacer()
                        if syncManager.isCheckingStatus {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: syncManager.iCloudAccountStatus == .available ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(syncManager.iCloudAccountStatus == .available ? .green : .orange)
                                Text(syncManager.iCloudStatusDescription)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .font(.caption)
                    
                    Button(action: {
                        Task {
                            await syncManager.checkiCloudStatus()
                            // Also update data count
                            dataCount = await syncManager.checkDataInCloud()
                        }
                    }) {
                        Text("Check iCloud Status")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .disabled(syncManager.isCheckingStatus)
                    
                    // Data count
                    if let dataCount = dataCount {
                        HStack {
                            Text("Local Data:")
                            Spacer()
                            Text("\(dataCount.transactionCount) transactions, \(dataCount.categoryCount) categories")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                    
                    // Sync button
                    Button(action: {
                        Task {
                            await syncManager.manualSync()
                            // Reload data after sync attempt (success or failure)
                            transactionStore.refreshTransactions()
                            categoryManager.refreshCategories()
                            // Update data count
                            dataCount = await syncManager.checkDataInCloud()
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
                    .disabled(syncManager.isSyncing)
                    
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
                    Text("Version 1.3.3 (2025.11.05)")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Check iCloud status and load data count when view appears
                Task {
                    await syncManager.checkiCloudStatus()
                    dataCount = await syncManager.checkDataInCloud()
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
            .environmentObject(SyncManager())
            .environmentObject(TransactionStore())
            .environmentObject(CategoryManager())
    }
}
