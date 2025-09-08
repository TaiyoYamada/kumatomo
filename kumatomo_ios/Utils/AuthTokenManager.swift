import Foundation
import Combine
import SwiftUI

// 認証トークンを管理するクラス
class AuthTokenManager {
    @AppStorage("auth_token") private var authToken: String?
    static let shared = AuthTokenManager()
    
    private let tokenKey = "auth_token"
    
    var token: String? {
        get {
            print("🔑 認証トークンを取得します")
            print("🔑 現在の認証トークン: \(UserDefaults.standard.string(forKey: tokenKey) ?? "nil")")
            return UserDefaults.standard.string(forKey: tokenKey)
            
        }
        set {
            print("🔑 認証トークンを設定します: \(newValue ?? "nil")")
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("🔑 認証トークンをクリアしました")
    }
    
    // リクエストにBearer認証トークンを追加
    func authorizedRequest(_ request: inout URLRequest) {
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

}
