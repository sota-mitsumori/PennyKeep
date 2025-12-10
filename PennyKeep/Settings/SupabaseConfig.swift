import Foundation

/// Supabase設定管理
struct SupabaseConfig {
    /// SupabaseプロジェクトのURL
    /// Info.plistまたは環境変数から読み込み
    static var supabaseURL: String? {
        // Info.plistから読み込む
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
            return url
        }
        // 環境変数から読み込む（Xcode Scheme設定用）
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            return url
        }
        // 設定が見つからない場合はnilを返す（アプリはオフラインで動作可能）
        return nil
    }
    
    /// Supabase Anon Key
    /// Info.plistまたは環境変数から読み込み
    static var supabaseAnonKey: String? {
        // Info.plistから読み込む
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        // 環境変数から読み込む（Xcode Scheme設定用）
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty {
            return key
        }
        // 設定が見つからない場合はnilを返す（アプリはオフラインで動作可能）
        return nil
    }
    
    /// Supabaseが設定されているかどうか
    static var isConfigured: Bool {
        return supabaseURL != nil && supabaseAnonKey != nil
    }
    
    /// パスワードリセットのリダイレクトURL
    /// アプリのURLスキームに合わせて設定してください
    static let passwordResetRedirectURL: String = {
        return "pennykeep://reset-password"
    }()
}

