import Foundation
import SwiftUI
import Combine

class ProfileEditViewModel: ObservableObject {
    @Published var name: String
    @Published var username: String
    @Published var email: String
    @Published var website: String
    @Published var bio: String
    @Published var profileImage: UIImage?
    @Published var profileImageURL: String?
    
    @Published var isProcessing = false

    
    private let originalProfile: User
    private let userAPIService = UserAPIService()
    private let imageManager = ProfileImageManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(profile: User) {
        self.originalProfile = profile
        self.name = profile.name
        self.username = "" // 必要なら profile.username を用意
        self.email = profile.email ?? ""
        self.website = profile.website ?? ""
        self.bio = profile.bio
        
    }
    
    func updateProfile(completion: @escaping (Bool, String) -> Void) {
        isProcessing = true
        
        var updatedUser = originalProfile
        updatedUser.name = name
        updatedUser.email = email
        updatedUser.website = website
        updatedUser.bio = bio
        
        if let image = profileImage {
            imageManager.uploadImage(image)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    if case .failure(let error) = result {
                        self?.isProcessing = false
                        completion(false, "画像アップロードに失敗しました: \(error.localizedDescription)")
                    }
                } receiveValue: { [weak self] url in
                    updatedUser.profileImageURL = url.absoluteString
                    self?.saveProfile(updatedUser, completion: completion)
                }
                .store(in: &cancellables)
        } else {
            saveProfile(updatedUser, completion: completion)
        }
    }
    
    private func saveProfile(_ user: User, completion: @escaping (Bool, String) -> Void) {
        userAPIService.saveProfile(user)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                self?.isProcessing = false
                if case .failure(let error) = completionResult {
                    completion(false, "プロフィール更新に失敗しました: \(error.localizedDescription)")
                }
            } receiveValue: { _ in
                completion(true, "プロフィールを更新しました")
            }
            .store(in: &cancellables)
    }
}
