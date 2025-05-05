import Foundation
import PhotosUI
import SwiftUI
import Combine

/// 認証関連のビジネスロジックを担う ViewModel
final class AuthViewModel: ObservableObject {
    // - 認証／ユーザー情報の状態管理
    
    // 認証状態（trueならログイン済み）
    @Published var isAuthenticated: Bool = false
    // API から取得したユーザーモデル
    @Published var currentUser: User?
    
    // - サインイン／サインアップ用フォーム
    
    @Published var email = ""                         // メールアドレス入力
    @Published var password = ""                      // パスワード入力
    @Published var name = ""                          // サインアップ時の氏名
    @Published var birthDate: Date =                  // サインアップ時の生年月日
        Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    
    // - プロフィール画像アップロード用
    
    @Published var profileImage: UIImage?             // アップロード対象 UIImage
    @Published var selectedImage: PhotosPickerItem?   // PhotosPicker からのアイテム
    
    // - UI フラグ
    
    @Published var errorMessage = ""                  // エラー表示用
    @Published var isLoading = false                  // ローディングインジケーター用
    
    // - サービス依存性
    
    private let authService = AuthService.shared       // 認証・ユーザー取得サービス
    private let storageService = StorageService.shared // 画像アップロードサービス
    
    private var cancellables = Set<AnyCancellable>()   // Combine の購読保持
    
    // - イニシャライザ
    
    init() {
        // 初期状態をサービスから取得
        self.isAuthenticated = authService.isAuthenticated
        self.currentUser = authService.currentUser
        
        // 購読を開始
        addSubscribers()
    }
    
    // - Combine 購読設定
    
    private func addSubscribers() {
        // 認証状態の変化を反映
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.isAuthenticated = isAuth
            }
            .store(in: &cancellables)
        
        // API から取得したユーザーモデルの変化を反映
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    // - サインイン処理
    
    // メール／パスワードでサインイン
    @MainActor
    func signIn() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signIn(withEmail: email, password: password)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    //  - サインアップ処理

    /// 新規ユーザーを作成
    @MainActor
    func createUser() async {
        isLoading = true
        errorMessage = ""
        
        do {
            // Auth サービスでユーザー作成
            try await authService.createUser(
                withEmail: email,
                password: password,
                name: name,
                birthDate: birthDate
            )
            
            // プロフィール画像が選択されていればアップロード
            if let image = profileImage {
                await uploadProfileImage(image)
            }
            
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    //  - サインアウト処理
    
    /// ログアウト
    @MainActor
    func signOut() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // - プロフィール画像アップロード
    
    /// UIImage を StorageService 経由でアップロードし、URL を AuthService に登録
    /// プロフィール画像をアップロードし、APIのユーザープロフィールも更新する
    @MainActor
    private func uploadProfileImage(_ image: UIImage) async {
        // 1. ユーザーが認証済みか確認
        guard isAuthenticated, let user = currentUser else { return }
        
        // 2. ローディング開始
        isLoading = true
        defer { isLoading = false }    // 処理後に必ずローディング停止
        
        do {
            // 3. StorageService で画像をアップロード → URL を取得

            guard let userId = user.id else {
                throw NSError(domain: "AuthViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ユーザーIDが取得できません"])
            }
            
            // IntのuserIdをStringに変換
            let userIdString = String(userId)
            
            let url = try await StorageService.shared.uploadImage(
                image,
                path: StoragePath.profile(uid: userIdString)
            )
            
            // 4. URL を文字列に変換して AuthService へ渡し、API上のプロフィールを更新
            let urlString = url.absoluteString
            try await authService.updateProfileImage(withImageUrl: urlString)
            
        } catch {
            // 5. エラー発生時はメッセージをセット
            errorMessage = error.localizedDescription
            print("DEBUG: 画像アップロード失敗 -> \(error.localizedDescription)")
        }
    }

    
    // - PhotosPicker から UIImage を取得
    
    /// PhotosPickerItem → UIImage 変換
    func loadProfileImage() {
        Task {
            guard let item = selectedImage else { return }
            do {
                let data = try await item.loadTransferable(type: Data.self)
                if let data,
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = uiImage
                    }
                }
            } catch {
                print("DEBUG: 画像読み込み失敗: \(error)")
            }
        }
    }
    
    // - フォームリセット
    
    /// すべての入力フォームを初期状態に戻す
    private func resetForm() {
        email = ""
        password = ""
        name = ""
        profileImage = nil
        selectedImage = nil
    }
}
