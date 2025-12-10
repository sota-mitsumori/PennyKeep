import Foundation

/// Supabase設定管理
struct SupabaseConfig {
    /// SupabaseプロジェクトのURL
    /// Info.plistまたは環境変数から読み込み
    static let supabaseURL: String = {
        // Info.plistから読み込む
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
            return url
        }
        // 環境変数から読み込む（Xcode Scheme設定用）
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            return url
        }
        // フォールバック（開発用）
        fatalError("SUPABASE_URL is not set. Please configure it in Info.plist or environment variables.")
    }()
    
    /// Supabase Anon Key
    /// Info.plistまたは環境変数から読み込み
    static let supabaseAnonKey: String = {
        // Info.plistから読み込む
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        // 環境変数から読み込む（Xcode Scheme設定用）
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty {
            return key
        }
        // フォールバック（開発用）
        fatalError("SUPABASE_ANON_KEY is not set. Please configure it in Info.plist or environment variables.")
    }()
    
    /// パスワードリセットのリダイレクトURL
    /// アプリのURLスキームに合わせて設定してください
    static let passwordResetRedirectURL: String = {
        return "pennykeep://reset-password"
    }()
}

