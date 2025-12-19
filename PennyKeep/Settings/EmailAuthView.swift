import SwiftUI

enum EmailAuthMode {
    case signIn
    case signUp
}

struct EmailAuthView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @Environment(\.dismiss) var dismiss
    let initialMode: EmailAuthMode
    @State private var isSignUpMode: Bool
    
    init(mode: EmailAuthMode) {
        self.initialMode = mode
        self._isSignUpMode = State(initialValue: mode == .signUp)
        print("EmailAuthView initialized with mode: \(mode)")
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showPassword = false
    @State private var showResetPassword = false
    @State private var resetPasswordEmail = ""
    @State private var showResetPasswordAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    if isSignUpMode {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .autocorrectionDisabled()
                        
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .textContentType(isSignUpMode ? .newPassword : .password)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(isSignUpMode ? .newPassword : .password)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isSignUpMode {
                        HStack {
                            if showPassword {
                                TextField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        }
                    }
                } header: {
                    Text(isSignUpMode ? "Create Account" : "Sign In")
                }
                
                if let error = authManager.authError {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await performAuth()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                            } else {
                                Text(isSignUpMode ? "Sign Up" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                }
                
                if !isSignUpMode {
                    Section {
                        Button(action: {
                            resetPasswordEmail = email
                            showResetPasswordAlert = true
                        }) {
                            Text("Forgot Password?")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(isSignUpMode ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.clearError()
                        dismiss()
                    }
                }
            }
            .alert("Reset Password", isPresented: $showResetPasswordAlert) {
                TextField("Email", text: $resetPasswordEmail)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                Button("Send Reset Link") {
                    Task {
                        await resetPassword()
                    }
                }
                Button("Cancel", role: .cancel) {
                    resetPasswordEmail = ""
                }
            } message: {
                Text("Enter your email address to receive a password reset link.")
            }
            .onAppear {
                // シートが表示される時にモードを確認・リセット
                print("EmailAuthView onAppear - isSignUpMode: \(isSignUpMode)")
            }
            .onChange(of: authManager.isSignedIn) { signedIn in
                if signedIn {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - バリデーション
    
    private var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        
        // メールアドレスの基本的なバリデーション
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else { return false }
        
        if isSignUpMode {
            return password == confirmPassword && password.count >= 6
        }
        
        return true
    }
    
    // MARK: - 認証処理
    
    private func performAuth() async {
        if isSignUpMode {
            var fullName: PersonNameComponents?
            if !firstName.isEmpty || !lastName.isEmpty {
                var nameComponents = PersonNameComponents()
                nameComponents.givenName = firstName.isEmpty ? nil : firstName
                nameComponents.familyName = lastName.isEmpty ? nil : lastName
                fullName = nameComponents
            }
            
            do {
                try await authManager.signUp(
                    email: email,
                    password: password,
                    fullName: fullName
                )
            } catch {
                // エラーはauthManager.authErrorに設定される
            }
        } else {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                // エラーはauthManager.authErrorに設定される
            }
        }
    }
    
    private func resetPassword() async {
        guard !resetPasswordEmail.isEmpty else { return }
        
        do {
            try await authManager.resetPassword(email: resetPasswordEmail)
            await MainActor.run {
                showResetPasswordAlert = false
                // 成功メッセージを表示（必要に応じて）
            }
        } catch {
            // エラーはauthManager.authErrorに設定される
        }
    }
}

