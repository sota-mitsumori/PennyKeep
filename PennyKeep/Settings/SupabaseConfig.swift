import Foundation

/// Supabase設定管理
struct SupabaseConfig {
    /// SupabaseプロジェクトのURL
    /// Settings/Environment.swiftから読み込み（ビルド時に環境変数から注入される）
    static var supabaseURL: String? {
        // Settings/Environment.swiftから読み込む
        let url = SupabaseEnv.SUPABASE_URL
        
        // プレースホルダーがそのまま残っている場合は無視
        if url != "SUPABASE_URL_PLACEHOLDER" && !url.isEmpty {
            print("✅ Loaded SUPABASE_URL from Settings/Environment.swift: \(url.prefix(30))...")
            return url
        }
        
        // 環境変数から読み込む（フォールバック、Xcode Scheme設定用）
        if let envUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envUrl.isEmpty {
            print("✅ Loaded SUPABASE_URL from environment: \(envUrl.prefix(30))...")
            return envUrl
        }
        
        // 設定が見つからない場合はnilを返す（アプリはオフラインで動作可能）
        print("❌ SUPABASE_URL not found. App will work in offline mode.")
        return nil
    }
    
    /// Supabase Anon Key
    /// Settings/Environment.swiftから読み込み（ビルド時に環境変数から注入される）
    static var supabaseAnonKey: String? {
        // Settings/Environment.swiftから読み込む
        let key = SupabaseEnv.SUPABASE_ANON_KEY
        
        // プレースホルダーがそのまま残っている場合は無視
        if key != "SUPABASE_ANON_KEY_PLACEHOLDER" && !key.isEmpty {
            print("✅ Loaded SUPABASE_ANON_KEY from Settings/Environment.swift")
            return key
        }
        
        // 環境変数から読み込む（フォールバック、Xcode Scheme設定用）
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
            print("✅ Loaded SUPABASE_ANON_KEY from environment")
            return envKey
        }
        
        // 設定が見つからない場合はnilを返す（アプリはオフラインで動作可能）
        print("❌ SUPABASE_ANON_KEY not found. App will work in offline mode.")
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

