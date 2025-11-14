import Foundation
import SwiftUI
import AuthenticationServices
import CloudKit

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userFullName: PersonNameComponents?
    @Published var cloudKitUserRecordID: CKRecord.ID?
    @Published var isLinkingCloudKit = false
    
    private let userIdentifierKey = "appleSignInUserIdentifier"
    private let userEmailKey = "appleSignInUserEmail"
    private let userGivenNameKey = "appleSignInUserGivenName"
    private let userFamilyNameKey = "appleSignInUserFamilyName"
    private let cloudKitUserRecordIDKey = "cloudKitUserRecordID"
    
    override init() {
        super.init()
        loadSavedCredentials()
    }
    
    /// Load saved credentials from UserDefaults
    private func loadSavedCredentials() {
        if let identifier = UserDefaults.standard.string(forKey: userIdentifierKey) {
            self.userIdentifier = identifier
            self.isSignedIn = true
            self.userEmail = UserDefaults.standard.string(forKey: userEmailKey)
            
            // Load saved name components
            let givenName = UserDefaults.standard.string(forKey: userGivenNameKey)
            let familyName = UserDefaults.standard.string(forKey: userFamilyNameKey)
            if givenName != nil || familyName != nil {
                var nameComponents = PersonNameComponents()
                nameComponents.givenName = givenName
                nameComponents.familyName = familyName
                self.userFullName = nameComponents
            }
            
            // Load CloudKit User Record ID if available
            if UserDefaults.standard.bool(forKey: cloudKitUserRecordIDKey),
               let recordName = UserDefaults.standard.string(forKey: "cloudKitUserRecordName") {
                // CloudKit User Record ID is always in the default zone
                let zoneID = CKRecordZone.default().zoneID
                self.cloudKitUserRecordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
                
                // Verify CloudKit connection on load
                Task {
                    await verifyCloudKitConnection()
                }
            }
        }
    }
    
    /// Save credentials to UserDefaults
    private func saveCredentials(identifier: String, email: String?, fullName: PersonNameComponents?) {
        UserDefaults.standard.set(identifier, forKey: userIdentifierKey)
        if let email = email {
            UserDefaults.standard.set(email, forKey: userEmailKey)
        }
        
        // Save name components if provided
        if let fullName = fullName {
            UserDefaults.standard.set(fullName.givenName, forKey: userGivenNameKey)
            UserDefaults.standard.set(fullName.familyName, forKey: userFamilyNameKey)
            self.userFullName = fullName
        }
        
        self.userIdentifier = identifier
        self.userEmail = email
        self.isSignedIn = true
        
        // Link with CloudKit after saving credentials
        Task {
            await linkWithCloudKit()
        }
    }
    
    /// Link Sign in with Apple account with CloudKit
    private func linkWithCloudKit() async {
        await MainActor.run {
            isLinkingCloudKit = true
        }
        
        let container = CKContainer.default()
        
        do {
            // Get CloudKit User Record ID
            let userRecordID = try await container.userRecordID()
            
            await MainActor.run {
                self.cloudKitUserRecordID = userRecordID
                // Save CloudKit User Record ID
                UserDefaults.standard.set(userRecordID.recordName, forKey: "cloudKitUserRecordName")
                UserDefaults.standard.set(userRecordID.zoneID.zoneName, forKey: "cloudKitUserRecordZoneName")
                UserDefaults.standard.set(true, forKey: cloudKitUserRecordIDKey)
                isLinkingCloudKit = false
            }
            
            // Save user information to CloudKit User Record
            await saveUserInfoToCloudKit(userRecordID: userRecordID)
            
            print("✅ Successfully linked Sign in with Apple to CloudKit")
            print("   CloudKit User Record ID: \(userRecordID.recordName)")
        } catch {
            await MainActor.run {
                isLinkingCloudKit = false
            }
            print("⚠️ Failed to link with CloudKit: \(error.localizedDescription)")
            // Don't fail the sign-in if CloudKit linking fails
        }
    }
    
    /// Save user information to CloudKit User Record
    private func saveUserInfoToCloudKit(userRecordID: CKRecord.ID) async {
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        do {
            // Fetch existing user record or create new one
            let userRecord = try await database.record(for: userRecordID)
            
            // Update user record with Sign in with Apple information
            if let userIdentifier = self.userIdentifier {
                userRecord["appleSignInUserID"] = userIdentifier
            }
            
            if let email = self.userEmail {
                userRecord["email"] = email
            }
            
            if let fullName = self.userFullName {
                if let givenName = fullName.givenName {
                    userRecord["givenName"] = givenName
                }
                if let familyName = fullName.familyName {
                    userRecord["familyName"] = familyName
                }
            }
            
            // Save the updated record
            _ = try await database.save(userRecord)
            print("✅ User information saved to CloudKit User Record")
        } catch {
            print("⚠️ Failed to save user info to CloudKit: \(error.localizedDescription)")
        }
    }
    
    /// Clear saved credentials
    private func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: userIdentifierKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userGivenNameKey)
        UserDefaults.standard.removeObject(forKey: userFamilyNameKey)
        UserDefaults.standard.removeObject(forKey: cloudKitUserRecordIDKey)
        UserDefaults.standard.removeObject(forKey: "cloudKitUserRecordName")
        UserDefaults.standard.removeObject(forKey: "cloudKitUserRecordZoneName")
        self.userIdentifier = nil
        self.userEmail = nil
        self.userFullName = nil
        self.cloudKitUserRecordID = nil
        self.isSignedIn = false
    }
    
    /// Manually link with CloudKit (for retry purposes)
    func retryCloudKitLinking() async {
        guard isSignedIn else {
            print("⚠️ Cannot link with CloudKit: User is not signed in")
            return
        }
        await linkWithCloudKit()
    }
    
    /// Verify CloudKit connection
    private func verifyCloudKitConnection() async {
        guard let savedRecordID = self.cloudKitUserRecordID else {
            return
        }
        
        let container = CKContainer.default()
        do {
            let currentRecordID = try await container.userRecordID()
            // Verify the saved record ID matches the current one
            if currentRecordID.recordName != savedRecordID.recordName {
                // User might have changed, update the record ID
                await MainActor.run {
                    self.cloudKitUserRecordID = currentRecordID
                    UserDefaults.standard.set(currentRecordID.recordName, forKey: "cloudKitUserRecordName")
                }
            }
        } catch {
            print("⚠️ Failed to verify CloudKit connection: \(error.localizedDescription)")
            // Clear invalid record ID
            await MainActor.run {
                self.cloudKitUserRecordID = nil
                UserDefaults.standard.removeObject(forKey: cloudKitUserRecordIDKey)
            }
        }
    }
    
    /// Sign out
    func signOut() {
        clearCredentials()
    }
    
    /// Handle sign in result
    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                
                // Save credentials (including fullName if provided)
                saveCredentials(identifier: userIdentifier, email: email, fullName: fullName)
                
                print("✅ Sign in with Apple successful")
            }
        case .failure(let error):
            print("❌ Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
            // Save credentials (including fullName if provided)
            saveCredentials(identifier: userIdentifier, email: email, fullName: fullName)
            
            print("✅ Sign in with Apple successful")
            print("   User ID: \(userIdentifier)")
            if let email = email {
                print("   Email: \(email)")
            }
            
        default:
            break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Sign in with Apple failed: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}
