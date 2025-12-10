import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showEmailAuth = false
    @State private var emailAuthMode: EmailAuthMode = .signIn
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    if authManager.isSignedIn {
                        signedInView
                    } else {
                        signInOptionsView
                    }
                }
                
                if authManager.isSignedIn {
                    accountInfoSection
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
            .sheet(isPresented: $showEmailAuth, onDismiss: {
                // シートが閉じられた時に状態をリセット
                emailAuthMode = .signIn
            }) {
                EmailAuthView(mode: emailAuthMode)
                    .environmentObject(authManager)
            }
        }
    }
    
    // MARK: - サインイン済みビュー
    
    private var signedInView: some View {
        VStack(spacing: 12) {
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
                    } else if let email = authManager.userEmail {
                        Text(email)
                            .font(.headline)
                                } else {
                        Text("Account")
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
        }
    }
    
    // MARK: - サインインオプション
    
    private var signInOptionsView: some View {
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Sign in to your account")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
            Text("Sign in to sync your data across devices and access additional features.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
            // メール/パスワード認証ボタン
            Button(action: {
                // Sign Inモードに設定してからシートを表示
                emailAuthMode = .signIn
                showEmailAuth = true
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Sign in with Email")
                }
                .frame(maxWidth: .infinity)
                            .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                            .cornerRadius(8)
            }
                            .padding(.horizontal)
                
            // アカウント作成リンク
                            HStack {
                Text("Don't have an account?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                Button(action: {
                    // Sign Upモードに設定してからシートを表示
                    emailAuthMode = .signUp
                    showEmailAuth = true
                }) {
                    Text("Sign up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                            }
                        }
        .padding(.vertical, 20)
    }
    
    // MARK: - アカウント情報セクション
    
    private var accountInfoSection: some View {
        Group {
            Section(header: Text("Account Information")) {
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
                    Task {
                        await authManager.signOut()
                    }
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
    
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SupabaseAuthManager())
    }
}
