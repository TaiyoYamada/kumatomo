import Foundation
import FirebaseAuth
import PhotosUI
import SwiftUI
import Combine

/// 認証関連のビジネスロジックを担う ViewModel
final class AuthViewModel: ObservableObject {
    // MARK: - 認証／ユーザー情報の状態管理
    
    /// FirebaseAuth のログインセッション（nilなら未ログイン）
    @Published var userSession: FirebaseAuth.User?
    /// Firestore に保存している独自 User モデル
    @Published var currentUser: User?
    
    // MARK: - サインイン／サインアップ用フォーム
    
    @Published var email     = ""                        // メールアドレス入力
    @Published var password  = ""                        // パスワード入力
    @Published var fullName  = ""                        // サインアップ時の氏名
    @Published var birthDate: Date =                    // サインアップ時の生年月日
        Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    
    // MARK: - プロフィール画像アップロード用
    
    @Published var profileImage: UIImage?                // アップロード対象 UIImage
    @Published var selectedImage: PhotosPickerItem?      // PhotosPicker からのアイテム
    
    // MARK: - UI フラグ
    
    @Published var errorMessage = ""                     // エラー表示用
    @Published var isLoading    = false                  // ローディングインジケーター用
    
    // MARK: - サービス依存性
    
    private let authService    = AuthService.shared      // 認証・ユーザー取得サービス
    private let storageService = StorageService.shared   // 画像アップロードサービス
    
    private var cancellables = Set<AnyCancellable>()     // Combine の購読保持
    
    // MARK: - イニシャライザ
    
    init() {
        // 初期状態をサービスから取得
        self.userSession = authService.userSession
        self.currentUser = authService.currentUser
        
        // 購読を開始
        addSubscribers()
    }
    
    
    
    // MARK: - Combine 購読設定
    
    private func addSubscribers() {
        // 認証セッションの変化を反映
        authService.$userSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.userSession = session
            }
            .store(in: &cancellables)
        
        // Firestore 上の User モデルの変化を反映
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    // MARK: - サインイン処理
    
    /// メール／パスワードでサインイン
    @MainActor
    func signIn() async {
        isLoading    = true
        errorMessage = ""
        
        do {
            try await authService.signIn(withEmail: email, password: password)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - サインアップ処理
    
    /// 新規ユーザーを作成
    @MainActor
    func createUser() async {
        isLoading    = true
        errorMessage = ""
        
        do {
            // Auth サービスでユーザー作成
            try await authService.createUser(
                withEmail: email,
                password: password,
                fullName: fullName,
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
    
    // MARK: - サインアウト処理
    
    /// ログアウト
    @MainActor
    func signOut() {
        authService.signOut()
    }
    
    // MARK: - プロフィール画像アップロード
    
    /// UIImage を StorageService 経由でアップロードし、URL を AuthService に登録
    /// プロフィール画像をアップロードし、Firestore上のユーザープロフィールも更新する
    @MainActor
    private func uploadProfileImage(_ image: UIImage) async {
        // 1. ログイン中のユーザーIDを取得
        guard let uid = userSession?.uid else { return }
        
        // 2. ローディング開始
        isLoading = true
        defer { isLoading = false }    // 処理後に必ずローディング停止
        
        do {
            // 3. StorageService で画像をアップロード → URL を取得
            let url = try await StorageService.shared.uploadImage(
                image,
                path: StoragePath.profile(uid: uid)
            )
            
            // 4. URL を文字列に変換して AuthService へ渡し、Firestore上のプロフィールを更新
            let urlString = url.absoluteString
            try await authService.updateProfileImage(withImageUrl: urlString)
            
        } catch {
            // 5. エラー発生時はメッセージをセット
            errorMessage = error.localizedDescription
            print("DEBUG: 画像アップロード失敗 -> \(error.localizedDescription)")
        }
    }

    
    // MARK: - PhotosPicker から UIImage を取得
    
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
    
    // MARK: - フォームリセット
    
    /// すべての入力フォームを初期状態に戻す
    private func resetForm() {
        email        = ""
        password     = ""
        fullName     = ""
        profileImage = nil
        selectedImage = nil
    }
}


