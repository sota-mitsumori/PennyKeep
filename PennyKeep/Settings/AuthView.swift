import SwiftUI

enum AuthMode {
    case signUp
    case signIn
}

/// Email/password sign-up and sign-in screen, presented as a sheet.
struct AuthView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AuthMode
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showPassword = false
    @State private var showResetPassword = false
    @State private var confirmationEmail: String?

    // Validation display state
    @State private var touchedFields: Set<Field> = []
    @State private var attemptedSubmit = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case firstName, lastName, email, password
    }

    init(mode: AuthMode = .signIn) {
        _mode = State(initialValue: mode)
    }

    private var isSignUp: Bool { mode == .signUp }

    var body: some View {
        NavigationStack {
            Group {
                if let confirmationEmail {
                    EmailConfirmationView(email: confirmationEmail) {
                        self.confirmationEmail = nil
                        switchMode(to: .signIn)
                    }
                } else {
                    form
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .sheet(isPresented: $showResetPassword) {
            PasswordResetView(initialEmail: email)
                .environmentObject(authManager)
        }
        .onAppear { authManager.clearError() }
        .onChange(of: authManager.isSignedIn) { signedIn in
            if signedIn { dismiss() }
        }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                VStack(spacing: 16) {
                    if isSignUp {
                        HStack(alignment: .top, spacing: 12) {
                            AuthField(label: "First name (optional)") {
                                TextField("First name", text: $firstName)
                                    .textContentType(.givenName)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .firstName)
                                    .submitLabel(.next)
                            }
                            AuthField(label: "Last name (optional)") {
                                TextField("Last name", text: $lastName)
                                    .textContentType(.familyName)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .lastName)
                                    .submitLabel(.next)
                            }
                        }
                    }

                    AuthField(label: "Email", message: emailMessage) {
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                    }

                    AuthField(label: "Password", message: passwordMessage) {
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .textContentType(isSignUp ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                    }

                    if isSignUp && passwordMessage == nil {
                        Text("At least \(AuthValidation.minimumPasswordLength) characters.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, -8)
                    }

                    if !isSignUp {
                        Button("Forgot password?") {
                            showResetPassword = true
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                if let error = authManager.authError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: 16) {
                    Button {
                        submit()
                    } label: {
                        if authManager.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(authManager.isLoading)

                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button(isSignUp ? "Sign In" : "Create one") {
                            switchMode(to: isSignUp ? .signIn : .signUp)
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    if isSignUp {
                        // Markdown links must be literal; an interpolated URL isn't parsed as a link.
                        Text("By creating an account, you agree to our [Privacy Policy](https://pennykeep.vercel.app/).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
        .onSubmit(handleSubmit)
        .onChange(of: focusedField) { previous, _ in
            // Mark the field the user just left as touched so its validation shows.
            if let previous { touchedFields.insert(previous) }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            AppLogoView(size: 64)
            Text(isSignUp ? "Create your account" : "Welcome back")
                .font(.title.bold())
            Text(isSignUp
                 ? "Back up your data and sync it across your devices."
                 : "Sign in to sync your PennyKeep data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Validation

    private func shouldShowError(for field: Field) -> Bool {
        attemptedSubmit || touchedFields.contains(field)
    }

    private var emailError: String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Enter your email address." }
        if !AuthValidation.isValidEmail(trimmed) { return "Enter a valid email address." }
        return nil
    }

    private var passwordError: String? {
        if password.isEmpty { return "Enter your password." }
        if isSignUp && password.count < AuthValidation.minimumPasswordLength {
            return "Password must be at least \(AuthValidation.minimumPasswordLength) characters."
        }
        return nil
    }

    private var emailMessage: String? {
        shouldShowError(for: .email) ? emailError : nil
    }

    private var passwordMessage: String? {
        shouldShowError(for: .password) ? passwordError : nil
    }

    // MARK: - Actions

    private func handleSubmit() {
        switch focusedField {
        case .firstName: focusedField = .lastName
        case .lastName: focusedField = .email
        case .email: focusedField = .password
        case .password, .none: submit()
        }
    }

    private func switchMode(to newMode: AuthMode) {
        authManager.clearError()
        password = ""
        attemptedSubmit = false
        touchedFields = []
        withAnimation(.easeInOut(duration: 0.2)) { mode = newMode }
    }

    private func submit() {
        attemptedSubmit = true
        guard emailError == nil, passwordError == nil else {
            focusedField = emailError != nil ? .email : .password
            return
        }
        focusedField = nil
        Task { await performAuth() }
    }

    private func performAuth() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if isSignUp {
            var fullName: PersonNameComponents?
            let given = firstName.trimmingCharacters(in: .whitespaces)
            let family = lastName.trimmingCharacters(in: .whitespaces)
            if !given.isEmpty || !family.isEmpty {
                var components = PersonNameComponents()
                components.givenName = given.isEmpty ? nil : given
                components.familyName = family.isEmpty ? nil : family
                fullName = components
            }
            do {
                let signedIn = try await authManager.signUp(email: trimmedEmail, password: password, fullName: fullName)
                if !signedIn {
                    // Email confirmation is required before the user can sign in.
                    confirmationEmail = trimmedEmail
                }
            } catch {
                // Error is surfaced through authManager.authError
            }
        } else {
            do {
                try await authManager.signIn(email: trimmedEmail, password: password)
            } catch {
                // Error is surfaced through authManager.authError
            }
        }
    }
}

// MARK: - Email confirmation

private struct EmailConfirmationView: View {
    let email: String
    let onBackToSignIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("Check your email")
                .font(.title2.bold())
            Text("We sent a confirmation link to **\(email)**. Open it, then sign in.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Back to Sign In", action: onBackToSignIn)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}

// MARK: - Password reset

struct PasswordResetView: View {
    @EnvironmentObject var authManager: SupabaseAuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isSending = false
    @State private var didSend = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    init(initialEmail: String) {
        _email = State(initialValue: initialEmail)
    }

    private var isValid: Bool {
        AuthValidation.isValidEmail(email.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        VStack(spacing: 20) {
            if didSend {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .padding(.top, 8)
                Text("Email sent")
                    .font(.title2.bold())
                Text("If an account exists for **\(email.trimmingCharacters(in: .whitespaces))**, you'll receive a link to reset your password.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                Button("Done") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                VStack(spacing: 8) {
                    Text("Reset password")
                        .font(.title2.bold())
                    Text("Enter your email and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                AuthField(label: "Email", message: errorMessage) {
                    TextField("you@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .submitLabel(.send)
                        .onSubmit { Task { await send() } }
                }

                Spacer(minLength: 0)

                Button {
                    Task { await send() }
                } label: {
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isValid || isSending)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { isFocused = !didSend }
    }

    private func send() async {
        guard isValid, !isSending else { return }
        isSending = true
        errorMessage = nil
        do {
            try await authManager.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            withAnimation { didSend = true }
        } catch {
            errorMessage = "Couldn't send the email. Please try again."
        }
        isSending = false
    }
}

#Preview("Sign Up") {
    AuthView(mode: .signUp)
        .environmentObject(SupabaseAuthManager())
}

#Preview("Sign In") {
    AuthView(mode: .signIn)
        .environmentObject(SupabaseAuthManager())
}
