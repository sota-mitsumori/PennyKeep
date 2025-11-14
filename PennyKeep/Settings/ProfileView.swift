import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    if authManager.isSignedIn {
                        HStack {
                            AvatarView(
                                name: authManager.userFullName,
                                email: authManager.userEmail,
                                size: 50
                            )
                            VStack(alignment: .leading, spacing: 4) {
                                if let fullName = authManager.userFullName {
                                    Text("\(fullName.givenName ?? "") \(fullName.familyName ?? "")")
                                        .font(.headline)
                                } else {
                                    Text("Signed in with Apple")
                                        .font(.headline)
                                }
                                
                                if let email = authManager.userEmail {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Account Status: Active")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        // CloudKit linking status
                        HStack {
                            if authManager.isLinkingCloudKit {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Linking with CloudKit...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if authManager.cloudKitUserRecordID != nil {
                                Image(systemName: "icloud.fill")
                                    .foregroundColor(.blue)
                                Text("CloudKit: Linked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "icloud.slash")
                                    .foregroundColor(.orange)
                                Text("CloudKit: Not linked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        if authManager.cloudKitUserRecordID == nil && !authManager.isLinkingCloudKit {
                            Button(action: {
                                Task {
                                    await authManager.retryCloudKitLinking()
                                }
                            }) {
                                Text("Link with CloudKit")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Sign in to your account")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Sign in with Apple to sync your data across devices and access additional features.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    authManager.handleSignInResult(result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                    }
                }
                
                if authManager.isSignedIn {
                    Section(header: Text("Account Information")) {
                        if let userIdentifier = authManager.userIdentifier {
                            HStack {
                                Text("User ID")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(userIdentifier.prefix(8) + "...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let email = authManager.userEmail {
                            HStack {
                                Text("Email")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            authManager.signOut()
                        }) {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager())
    }
}
