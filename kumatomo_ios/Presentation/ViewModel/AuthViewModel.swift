import Foundation
import PhotosUI
import SwiftUI
import Combine
import Resolver
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var isAuthenticated: Bool = false
    var currentUser: User?
    var accounts: [User] = []
    var selectedAccount: User?
    
    var hasCompletedSetup: Bool? = nil
    var email = ""
    var password = ""
    var name = ""
    var bio = ""
    var birthDate: Date =
        Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    var location = ""
    var birthday = Date()
    var profileImage: UIImage?
    var selectedImage: PhotosPickerItem?
    
    var errorMessage:String? = ""
    var isLoading = false
    
    // - サービス依存性
    
    @ObservationIgnored @Injected var authRepository: AuthRepository       // 認証・ユーザー取得
    @ObservationIgnored @Injected var imageUploader: ImageUploadRepository // 画像アップロード
    // Optional: UseCases wrappers
    @ObservationIgnored @Injected var signInUseCase: SignInUseCase
    @ObservationIgnored @Injected var signOutUseCase: SignOutUseCase
    @ObservationIgnored @Injected var createUserUseCase: CreateUserUseCase
    @ObservationIgnored @Injected var updateUserUseCase: UpdateUserUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初期状態をサービスから取得
        self.isAuthenticated = authRepository.isAuthenticated
        self.currentUser = authRepository.currentUser
        
        if let currentUser = currentUser {
            self.hasCompletedSetup = currentUser.hasCompletedSetup
        } else {
            self.hasCompletedSetup = nil
        }
        
        addSubscribers()
    }
    
    
    private func addSubscribers() {
        // 認証状態の変化を監視
        authRepository.isAuthenticatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.isAuthenticated = isAuth
            }
            .store(in: &cancellables)
            
        // ユーザー情報の変化を監視
        authRepository.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                self.currentUser = user
                
                // ユーザー情報が更新されたらhasCompletedSetupも更新
                if let user = user {
                    print("DEBUG: ユーザー情報更新 - hasCompletedSetup: \(user.hasCompletedSetup ?? false)")
                    self.hasCompletedSetup = user.hasCompletedSetup
                } else {
                    self.hasCompletedSetup = nil
                }
            }
            .store(in: &cancellables)
    }
    

    @MainActor
    func signIn() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await signInUseCase.execute(email: email, password: password)
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
            // Auth サービスでユーザー作成（サーバー側で自動的にランダムなusernameが生成される）
            try await createUserUseCase.execute(email: email, password: password)
            
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
            try await signOutUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // - プロフィール画像アップロード
    
//    // プロフィール画像をアップロードし、APIのユーザープロフィールも更新する
//    @MainActor
//    private func uploadProfileImage(_ image: UIImage) async {
//        guard isAuthenticated, let user = currentUser, let userId = user.id else {
//            errorMessage = "ユーザーIDが取得できません。再ログインしてください。"
//            return
//        }
//
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            let userIdString = String(userId)
//            let url = try await StorageService.shared.uploadImage(
//                image,
//                path: StoragePath.profile(uid: userIdString)
//            )
//
//            let urlString = url.absoluteString
//            try await authService.updateProfileImage(withImageUrl: urlString)
//        } catch {
//            errorMessage = error.localizedDescription
//            print("DEBUG: 画像アップロード失敗 -> \(error.localizedDescription)")
//        }
//    }

    
    private func handleSubmit() {
        guard isFormValid else { return }
        isLoading = true
        
        Task {
            do {
                // プロフィール画像がある場合はアップロード
                var profileImageURL: String? = nil
                if let image = profileImage {
                    profileImageURL = try await uploadProfileImage(image)
                }
                
                
                // 初期設定完了を記録
                self.hasCompletedSetup = true
                
                
                // ユーザー情報を更新
                try await updateUserUseCase.execute(
                    name: name,
                    profileImageURL: profileImageURL,
                    bio: bio,
                    location: location,
                    birthday: birthDate,
                    hasCompletedSetup: true
                )
            
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "プロフィール情報の更新に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
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
    
    /// すべての入力フォームを初期状態に戻す
    private func resetForm() {
        email = ""
        password = ""
        name = ""
        profileImage = nil
        selectedImage = nil
    }
    
    // 初期設定を保存
    func saveInitialSetup() async -> Bool {
        isLoading = true
        errorMessage = ""
        
        // バリデーション
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "名前を入力してください"
            isLoading = false
            return false
        }
        
        do {
            // 画像がある場合はアップロード
            var profileImageURL: String? = nil
            if let image = profileImage {
                profileImageURL = try await uploadProfileImage(image)
            }
            
            // プロフィール情報を更新
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let birthdayString = dateFormatter.string(from: birthDate)
            
            
            try await updateUserUseCase.execute(
                name: name,
                profileImageURL: profileImageURL,
                bio: bio,
                location: location,
                birthday: birthDate,
                hasCompletedSetup: true
            )

            
            isLoading = false
            return true
        } catch {
            errorMessage = "プロフィールの保存に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // プロフィール画像のアップロード
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.imageConversionFailed
        }
        return try await imageUploader.uploadImage(data, endpoint: "/upload-image")
    }
}
