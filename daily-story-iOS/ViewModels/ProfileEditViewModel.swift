import Foundation
import SwiftUI
import Combine

class ProfileEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var website: String = ""
    @Published var bio: String = ""
    @Published var profileImage: UIImage?
    @Published var profileImageURL: String?
    
    @Published var isProcessing = false

    
    private let originalProfile: User
    private let userAPIService = UserAPIService()
    private let imageManager = ProfileImageManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(profile: User) {
        self.originalProfile = profile
        self.name = profile.name ?? ""
        self.email = profile.email ?? ""
        self.website = profile.website ?? ""
        self.bio = profile.bio ?? ""
        
    }
    
    func updateProfile(completion: @escaping (Bool, String) -> Void) {
        print("🟡 updateProfile() が呼ばれた")
        isProcessing = true
        
        var updatedUser = originalProfile
        updatedUser.name = name
        updatedUser.email = email
        updatedUser.website = website
        updatedUser.bio = bio
        
        if let image = profileImage {
            print("🟡 画像があるのでアップロードを開始")
            imageManager.uploadImage(image)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    if case .failure(let error) = result {
                        print("❌ 画像アップロード失敗: \(error.localizedDescription)")
                        self?.isProcessing = false
                        completion(false, "画像アップロードに失敗しました: \(error.localizedDescription)")
                    }
                } receiveValue: { [weak self] url in
                    print("✅ 画像アップロード成功: \(url.absoluteString)")
                    updatedUser.profileImageURL = url.absoluteString
                    self?.saveProfile(updatedUser, completion: completion)
                }
                .store(in: &cancellables)
        } else {
            print("🟢 画像なし → 直接 saveProfile() を呼ぶ")
            saveProfile(updatedUser, completion: completion)
        }
    }
    
    private func saveProfile(_ user: User, completion: @escaping (Bool, String) -> Void) {
        print("📤 saveProfile() 開始 → ユーザーを送信:")
        print("📤 name: \(user.name), email: \(user.email), bio: \(user.bio), image: \(user.profileImageURL ?? "なし")")

        userAPIService.saveProfile(user)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                self?.isProcessing = false
                switch completionResult {
                case .failure(let error):
                    print("❌ saveProfile エラー: \(error.localizedDescription)")
                    completion(false, "プロフィール更新に失敗しました: \(error.localizedDescription)")
                case .finished:
                    print("✅ saveProfile 完了（sink完了）")
                }
            } receiveValue: { response in
                print("✅ APIレスポンス受信成功: \(response)")
                completion(true, "プロフィールを更新しました")
            }
            .store(in: &cancellables)
    }

}
