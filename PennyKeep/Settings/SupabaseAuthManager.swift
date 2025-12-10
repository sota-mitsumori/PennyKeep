import Foundation
import SwiftUI
import Supabase
import PostgREST

class SupabaseAuthManager: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var userFullName: PersonNameComponents?
    @Published var isLoading = false
    @Published var authError: String?
    
    private var supabase: SupabaseClient?
    
    override init() {
        super.init()
        setupSupabase()
        loadSession()
    }
    
    private func setupSupabase() {
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            print("⚠️ Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
            return
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
    
    // MARK: - セッション管理
    
    /// 保存されたセッションを読み込む
    private func loadSession() {
        Task {
            guard let supabase = supabase else { return }
            
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    updateUserState(from: session)
                }
            } catch {
                // セッションなし
                await MainActor.run {
                    isSignedIn = false
                }
            }
        }
    }
    
    /// セッションからユーザー状態を更新
    private func updateUserState(from session: Session) {
        isSignedIn = true
        userEmail = session.user.email
        
        // ユーザー名を取得（Supabaseのuser_metadataから）
        let userMetadata = session.user.userMetadata
        var nameComponents = PersonNameComponents()
        
        if let firstName = userMetadata["first_name"],
           case .string(let firstNameString) = firstName {
            nameComponents.givenName = firstNameString
        }
        
        if let lastName = userMetadata["last_name"],
           case .string(let lastNameString) = lastName {
            nameComponents.familyName = lastNameString
        }
        
        if nameComponents.givenName != nil || nameComponents.familyName != nil {
            userFullName = nameComponents
        }
    }
    
    // MARK: - メール/パスワード認証
    
    /// メール/パスワードでアカウント作成
    func signUp(email: String, password: String, fullName: PersonNameComponents?) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        await MainActor.run {
            isLoading = true
            authError = nil
        }
        
        do {
            var userMetadata: [String: AnyJSON] = [:]
            if let fullName = fullName {
                if let givenName = fullName.givenName {
                    userMetadata["first_name"] = .string(givenName)
                }
                if let familyName = fullName.familyName {
                    userMetadata["last_name"] = .string(familyName)
                }
            }
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: userMetadata.isEmpty ? nil : userMetadata
            )
            
            await MainActor.run {
                if let session = response.session {
                    updateUserState(from: session)
                }
                isLoading = false
            }
        } catch {
            let errorMessage = parseAuthError(error)
            await MainActor.run {
                authError = errorMessage
                isLoading = false
            }
            throw error
        }
    }
    
    /// メール/パスワードでログイン
    func signIn(email: String, password: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        await MainActor.run {
            isLoading = true
            authError = nil
        }
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                updateUserState(from: session)
                isLoading = false
            }
        } catch {
            let errorMessage = parseAuthError(error)
            await MainActor.run {
                authError = errorMessage
                isLoading = false
            }
            throw error
        }
    }
    
    /// パスワードリセットメールを送信
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        guard let redirectURL = URL(string: SupabaseConfig.passwordResetRedirectURL) else {
            throw AuthError.invalidRedirectURL
        }
        
        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: redirectURL
        )
    }
    
    // MARK: - サインアウト
    
    func signOut() async {
        guard let supabase = supabase else { return }
        
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                isSignedIn = false
                userEmail = nil
                userFullName = nil
            }
        } catch {
            print("⚠️ Failed to sign out: \(error)")
        }
    }
    
    // MARK: - エラー処理
    
    func clearError() {
        authError = nil
    }
    
    /// Supabaseのエラーメッセージを解析してユーザーフレンドリーなメッセージに変換
    private func parseAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("invalid login credentials") || errorString.contains("invalid credentials") {
            return AuthError.invalidCredentials.localizedDescription
        } else if errorString.contains("user already registered") || errorString.contains("already exists") {
            return AuthError.emailAlreadyExists.localizedDescription
        } else if errorString.contains("password") && errorString.contains("weak") {
            return AuthError.weakPassword.localizedDescription
        } else if errorString.contains("email") {
            return "メールアドレスの形式が正しくありません"
        }
        
        return error.localizedDescription
    }
}

enum AuthError: LocalizedError {
    case supabaseNotConfigured
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case invalidRedirectURL
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "認証システムが設定されていません"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .emailAlreadyExists:
            return "このメールアドレスは既に使用されています"
        case .weakPassword:
            return "パスワードが弱すぎます（6文字以上）"
        case .invalidRedirectURL:
            return "リダイレクトURLが無効です"
        }
    }
}

