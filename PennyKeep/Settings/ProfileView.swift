import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var syncManager: SupabaseSyncManager
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var categoryManager: CategoryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showAuthView = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    
                    if authManager.isSignedIn {
                        accountInfoSection
                        signOutButton
                    } else {
                        signInOptionsView
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAuthView) {
                BeautifulAuthView()
                    .environmentObject(authManager)
                    .environmentObject(appSettings)
            }
        }
    }
    
    // MARK: - Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            AvatarView(
                name: authManager.userFullName,
                email: authManager.userEmail,
                size: 72
            )
            
            Text(displayName)
                .font(.title3.weight(.semibold))
            
            if let email = authManager.userEmail {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Label(authManager.isSignedIn ? "Signed In" : "Signed Out",
                  systemImage: authManager.isSignedIn ? "checkmark.seal.fill" : "xmark.seal.fill")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(authManager.isSignedIn ? .green : .secondary)
            .background((authManager.isSignedIn ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12)), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.12))
        )
    }
    
    private var displayName: String {
        if let fullName = authManager.userFullName {
            let given = fullName.givenName ?? ""
            let family = fullName.familyName ?? ""
            let combined = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
            if !combined.isEmpty {
                return combined
            }
        }
        return authManager.userEmail ?? "Welcome"
    }
    
    // MARK: - サインインオプション
    private var signInOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stay in sync across devices.")
                .font(.headline)
            
            Text("Sign in to back up your data securely and keep categories and transactions aligned.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showAuthView = true
            } label: {
                Label("Sign in or Sign up", systemImage: "person.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - アカウント情報セクション
    private var accountInfoSection: some View {
        Group {
            GroupBox("Account Information") {
                if let email = authManager.userEmail {
                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(email)
                            .font(.callout)
                    }
                }
            }
        }
    }
    
    private var signOutButton: some View {
        Button(role: .destructive) {
            showSignOutConfirmation = true
        } label: {
            Label("Sign Out", systemImage: "arrow.right.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.red)
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Delete Local Data", role: .destructive) {
                Task {
                    await signOut(clearLocalData: true)
                }
            }
            
            Button("Keep Local Data") {
                Task {
                    await signOut(clearLocalData: false)
                }
            }
            
            Button("Cancel", role: .cancel) {
                // Do nothing
            }
        } message: {
            Text("What would you like to do with your local data?")
        }
    }
    
    private func signOut(clearLocalData: Bool) async {
        if clearLocalData {
            // ローカルデータを削除してからサインアウト
            await syncManager.clearLocalData()
            transactionStore.refreshTransactions()
            categoryManager.refreshCategories()
        }
        // サインアウト
        await authManager.signOut()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SupabaseAuthManager())
            .environmentObject(AppSettings())
            .environmentObject(SupabaseSyncManager())
            .environmentObject(TransactionStore())
            .environmentObject(CategoryManager())
    }
}
