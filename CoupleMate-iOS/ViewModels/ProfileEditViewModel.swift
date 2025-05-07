import SwiftUI
import Combine

class ProfileEditViewModel: ObservableObject {
    // プロフィール情報
    let profile: Profile
    
    // 編集用フィールド
    @Published var name: String
    @Published var username: String
    @Published var email: String
    @Published var bio: String
    @Published var website: String
    @Published var profileImage: UIImage?
    
    // 処理状態
    @Published var isProcessing: Bool = false
    
    // APIサービス（既存のものを利用）
    private let apiService = ProfileAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(profile: Profile) {
        self.profile = profile
        
        // 初期値の設定
        self.name = profile.name
        self.username = profile.username
        self.email = profile.email ?? ""
        self.bio = profile.bio
        self.website = profile.website ?? ""
        
        // プロフィール画像がある場合はダウンロード
        loadProfileImage()
    }
    
    // プロフィール画像の読み込み
    private func loadProfileImage() {
        guard let urlString = profile.profileImageURL,
              let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.profileImage = image
            }
            .store(in: &cancellables)
    }
    
    // プロフィール更新処理
    func updateProfile(completion: @escaping (Bool, String) -> Void) {
        isProcessing = true
        
        // 更新するプロフィールデータの作成
        let updatedProfile = ProfileUpdateRequest(
            name: name,
            username: username,
            email: email,
            bio: bio,
            website: website
        )
        
        // プロフィール情報の更新
        apiService.updateProfile(updatedProfile)
            .flatMap { [weak self] _ -> AnyPublisher<Bool, Error> in
                // プロフィール画像がある場合はアップロード
                guard let self = self, let image = self.profileImage else {
                    return Just(true).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                return self.apiService.uploadProfileImage(image)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isProcessing = false
                    
                    switch result {
                    case .finished:
                        completion(true, "プロフィールが更新されました")
                    case .failure(let error):
                        completion(false, "エラーが発生しました: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

// プロフィール更新用リクエストモデル
struct ProfileUpdateRequest: Encodable {
    let name: String
    let username: String
    let email: String
    let bio: String
    let website: String
}
