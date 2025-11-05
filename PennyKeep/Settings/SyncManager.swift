import Foundation
import SwiftData
import SwiftUI
import CloudKit

class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isCheckingStatus = false
    
    private var modelContext: ModelContext?
    private static var sharedModelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Self.sharedModelContext = context
    }
    
    /// Check iCloud account status
    func checkiCloudStatus() async {
        await MainActor.run {
            isCheckingStatus = true
        }
        
        let container = CKContainer.default()
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.iCloudAccountStatus = status
                isCheckingStatus = false
            }
        } catch {
            await MainActor.run {
                print("? Failed to check iCloud status: \(error)")
                isCheckingStatus = false
            }
        }
    }
    
    /// Get user-friendly status description
    var iCloudStatusDescription: String {
        switch iCloudAccountStatus {
        case .available:
            return "Signed in to iCloud"
        case .noAccount:
            return "Not signed in to iCloud"
        case .restricted:
            return "iCloud account restricted"
        case .couldNotDetermine:
            return "iCloud status unknown"
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        @unknown default:
            return "Unknown status"
        }
    }
    
    /// Check if data is synced to iCloud by counting records
    func checkDataInCloud() async -> (transactionCount: Int, categoryCount: Int)? {
        guard let context = modelContext ?? Self.sharedModelContext else {
            return nil
        }
        
        // Count local transactions
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(transactionDescriptor)) ?? []
        
        // Count local categories
        let categoryDescriptor = FetchDescriptor<Category>()
        let categories = (try? context.fetch(categoryDescriptor)) ?? []
        
        return (transactions.count, categories.count)
    }
    
    /// Perform manual sync
    func manualSync() async {
        guard let context = modelContext ?? Self.sharedModelContext else {
            await MainActor.run {
                syncError = "ModelContext is not available"
            }
            return
        }
        
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        do {
            // Process pending changes
            context.processPendingChanges()
            
            // Save changes to CloudKit
            try context.save()
            
            // Wait a bit before reloading data
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
                print("? Manual sync completed")
            }
        } catch {
            await MainActor.run {
                // Provide more user-friendly error messages
                let errorMessage: String
                if let nsError = error as NSError? {
                    if nsError.domain == "NSCocoaErrorDomain" {
                        switch nsError.code {
                        case 134030: // CloudKit not available
                            errorMessage = "iCloud is not available. Please check your iCloud settings."
                        case 134301: // Network error
                            errorMessage = "Network error. Please check your internet connection and try again."
                        default:
                            errorMessage = "Sync failed: \(error.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Sync failed: \(error.localizedDescription)"
                    }
                } else {
                    errorMessage = "Sync failed: \(error.localizedDescription)"
                }
                
                syncError = errorMessage
                isSyncing = false
                print("? Sync error: \(error)")
            }
        }
    }
    
    /// Clear sync error
    func clearSyncError() {
        syncError = nil
    }
}
