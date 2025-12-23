import Foundation
import Combine
import SwiftUI

/// 認証トークンを管理するクラス
class AuthTokenManager {
    @AppStorage("auth_token") private var authToken: String?
    static let shared = AuthTokenManager()

    private let tokenKey = "auth_token"
    private let logger = AppLogger.auth

    var token: String? {
        get {
            logger.debug("認証トークンを取得")
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            logger.debug("認証トークンを設定: \(newValue != nil ? "***" : "nil")")
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        logger.info("認証トークンをクリア")
    }

    func authorizedRequest(_ request: inout URLRequest) {
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }
}
