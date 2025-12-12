import SwiftUI

struct BeautifulAuthView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var isSignUpMode: Bool = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedCurrency: String = "USD"
    @State private var showPassword = false
    @State private var showResetPassword = false
    @State private var resetPasswordEmail = ""
    
    var body: some View {
        ZStack {
            // White/Black background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Main content card
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.primary)
                            .padding(.top, 32)
                        
                        // Title
                        Text(isSignUpMode ? "Get Started with PennyKeep" : "Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Subtitle
                        Text(isSignUpMode ? "Create your secure wallet in just a few steps." : "Sign in to continue managing your finances.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Input fields
                        VStack(spacing: 16) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                TextField("Enter email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            // Name fields (only for sign up)
                            if isSignUpMode {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("First Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        TextField("First name", text: $firstName)
                                            .textContentType(.givenName)
                                            .autocorrectionDisabled()
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Last Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        TextField("Last name", text: $lastName)
                                            .textContentType(.familyName)
                                            .autocorrectionDisabled()
                                            .padding()
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                }
                                
                                // Currency selection (only for sign up)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Default Currency")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Menu {
                                        ForEach(currencyItems) { currency in
                                            Button(action: {
                                                selectedCurrency = currency.code
                                            }) {
                                                HStack {
                                                    Text("\(currency.code) – \(currency.name)")
                                                    if selectedCurrency == currency.code {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(currencyItems.first(where: { $0.code == selectedCurrency })?.name ?? "Select Currency")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 12))
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
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
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Confirm password (only for sign up)
                            if isSignUpMode {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if showPassword {
                                        TextField("Confirm password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Confirm password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error message
                        if let error = authManager.authError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Primary action button
                        Button(action: {
                            Task {
                                await performAuth()
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemBackground)))
                                } else {
                                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(.systemBackground))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(16)
                        }
                        .disabled(!isFormValid || authManager.isLoading)
                        .opacity(isFormValid && !authManager.isLoading ? 1.0 : 0.6)
                        .padding(.horizontal, 24)
                        
                        // Toggle between sign up and sign in
                        HStack(spacing: 4) {
                            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                authManager.clearError()
                                isSignUpMode.toggle()
                                password = ""
                                confirmPassword = ""
                            }) {
                                Text(isSignUpMode ? "Log In" : "Sign Up")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Forgot password (only for sign in)
                        if !isSignUpMode {
                            Button(action: {
                                resetPasswordEmail = email
                                showResetPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Skip button (continue without account)
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Continue without account")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, isSignUpMode ? 0 : 16)
                        
                        // Terms & Privacy (only for sign up)
                        if isSignUpMode {
                            Text("By creating an account, you agree to our **Terms & Conditions** and **Privacy Policy**.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 16)
                                .padding(.bottom, 32)
                        } else {
                            Spacer()
                                .frame(height: 32)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Reset Password", isPresented: $showResetPassword) {
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
            // Initialize currency selection with current app settings
            selectedCurrency = appSettings.selectedCurrency
        }
        .onChange(of: authManager.isSignedIn) { signedIn in
            if signedIn {
                dismiss()
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        
        // Email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else { return false }
        
        if isSignUpMode {
            return password == confirmPassword && password.count >= 6
        }
        
        return true
    }
    
    // MARK: - Authentication
    
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
                // Set default currency after successful sign up
                appSettings.selectedCurrency = selectedCurrency
            } catch {
                // Error is set in authManager.authError
            }
        } else {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                // Error is set in authManager.authError
            }
        }
    }
    
    private func resetPassword() async {
        guard !resetPasswordEmail.isEmpty else { return }
        
        do {
            try await authManager.resetPassword(email: resetPasswordEmail)
            await MainActor.run {
                showResetPassword = false
            }
        } catch {
            // Error is set in authManager.authError
        }
    }
}

#Preview {
    BeautifulAuthView()
        .environmentObject(SupabaseAuthManager())
        .environmentObject(AppSettings())
}

