import Foundation

/// ログカテゴリ定義
enum LogCategory: String, CaseIterable, Sendable {
    /// API通信
    case network
    /// 認証・セッション
    case auth
    /// デバッグ全般
    case debug
    /// UI関連
    case ui
    /// キャッシュ
    case cache
}
