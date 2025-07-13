import SwiftUI
import Foundation
import UIKit
import Combine
import PhotosUI

class ProfileViewModel: ObservableObject {
    // 表示用プロパティ
    @Published var profile: User
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedImage: UIImage?
    @Published var isImageUploading = false
    @Published var showSuccessMessage = false
    @Published var stories: [Story] = []

    // 編集用プロパティ
    @Published var name: String = ""
    @Published var bio: String = ""
    @Published var website: String = ""
    @Published var location: String = "" // 追加: 場所フィールド
    @Published var profileImage: UIImage? // 追加: プロフィール画像選択用
    @Published var coverImage: UIImage? // 追加: カバー画像選択用
    @Published var isProcessing = false // 追加: 処理中フラグ
    
    private let userAPIService = UserAPIService()
    private let storyAPIService = StoryAPIService()
    private let imageManager = ProfileImageManager()
    private let imageUploadService = ImageUploadService() // 追加: 画像アップロードサービス
    private var cancellables = Set<AnyCancellable>()
    
    init(userID: Int) {
        self.profile = User(
            id: userID,
            email: "",
            name: "",
            profileImageURL: nil,
            bio: "",
            city: "",
            birthday: "",
            postCount: 0,
            website: "",
            followingCount: 0,
            followersCount: 0,
            hasCompletedSetup: false,
            createdAt: nil
        )
        loadProfile(userID: userID)
        loadUserStories(userID: userID)
    }
    
    // プロフィール編集用の初期化処理を追加
    init(profile: User) {
        self.profile = profile
        self.name = profile.name ?? ""
        self.bio = profile.bio ?? ""
        self.website = profile.website ?? ""
//        self.location = profile.location ?? "" // 場所の初期化
        
        // ユーザーストーリーを読み込む
        loadUserStories(userID: profile.id)
    }
    
    // userIDをInt型に変更
    func loadProfile(userID: Int) {
        isLoading = true
        userAPIService.fetchProfile(userID: String(userID)) // String型に変換
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] profile in
                self?.profile = profile
                self?.updateFormFields(with: profile)
            }
            .store(in: &cancellables)
    }
    
    // ユーザーのストーリーを読み込むメソッドを追加
    func loadUserStories(userID: Int) {
        isLoading = true
        
        Task {
            do {
                let fetchedStories = try await storyAPIService.fetchUserStories(userId: userID)
                await MainActor.run {
                    self.stories = fetchedStories
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoading = false
                }
            }
        }
    }

    private func updateFormFields(with profile: User) {
        name = profile.name ?? ""
        bio = profile.bio ?? ""
        website = profile.website ?? ""
//        location = profile.location ?? "" // 場所も更新
    }

    func saveProfile() {
        isLoading = true
        var updatedProfile = profile
        updatedProfile.name = name
        updatedProfile.bio = bio
        updatedProfile.website = website
//        updatedProfile.location = location // 場所も保存

        if let image = selectedImage {
            uploadProfileImage(image) { [weak self] result in
                switch result {
                case .success(let url):
                    updatedProfile.profileImageURL = url.absoluteString
                    self?.saveProfileData(updatedProfile)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        } else {
            saveProfileData(updatedProfile)
        }
    }
    
    // ProfileEditViewModel相当の非同期プロフィール更新機能を追加
    @MainActor
    func updateProfile() async {
        isProcessing = true
        errorMessage = nil
        
        do {
            var updatedProfile = profile
            updatedProfile.name = name
            updatedProfile.bio = bio
            updatedProfile.website = website
//            updatedProfile.location = location
            
            // プロフィール画像があれば先にアップロード
            if let image = profileImage {
                do {
                    let imageUrl = try await imageUploadService.uploadImage(image)
                    updatedProfile.profileImageURL = imageUrl
                    print("✅ プロフィール画像アップロード成功: \(imageUrl)")
                } catch {
                    print("❌ プロフィール画像アップロード失敗: \(error.localizedDescription)")
                    isProcessing = false
                    errorMessage = "画像アップロードに失敗しました: \(error.localizedDescription)"
                    return
                }
            }
            
            // カバー画像があれば先にアップロード
            if let image = coverImage {
                do {
                    let imageUrl = try await imageUploadService.uploadImage(image)
                    updatedProfile.profileImageURL = imageUrl
                    print("✅ カバー画像アップロード成功: \(imageUrl)")
                } catch {
                    print("❌ カバー画像アップロード失敗: \(error.localizedDescription)")
                    isProcessing = false
                    errorMessage = "画像アップロードに失敗しました: \(error.localizedDescription)"
                    return
                }
            }
            
            // プロフィール情報を更新
            print("📤 プロフィール更新開始")
            try await saveProfileAsync(updatedProfile)
            
            // 成功したらプロフィール情報を更新
            self.profile = updatedProfile
            
            isProcessing = false
            showSuccessMessage = true
            print("✅ プロフィール更新完了")
        } catch {
            isProcessing = false
            errorMessage = "プロフィール更新に失敗しました: \(error.localizedDescription)"
            print("❌ プロフィール更新エラー: \(error.localizedDescription)")
        }
    }
    
    // 非同期でプロフィール保存するメソッドを追加
    private func saveProfileAsync(_ user: User) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            userAPIService.saveProfile(user)
                .receive(on: DispatchQueue.main)
                .sink { completionResult in
                    switch completionResult {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    continuation.resume(returning: ())
                }
                .store(in: &cancellables)
        }
    }

    private func saveProfileData(_ updatedProfile: User) {
        userAPIService.saveProfile(updatedProfile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] _ in
                self?.profile = updatedProfile
                self?.showSuccessMessage = true
            }
            .store(in: &cancellables)
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        isImageUploading = true

        imageManager.uploadImage(image)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isImageUploading = false
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            } receiveValue: { url in
                completion(.success(url))
            }
            .store(in: &cancellables)
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    // Reset form fields to the current profile values
    func resetFormFields() {
        name = profile.name ?? ""
        bio = profile.bio ?? ""
        website = profile.website ?? ""
//        location = profile.location ?? ""
        profileImage = nil
        coverImage = nil
    }
}

// タグなどを整理するためのレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        let rows = computeRows(width: width, subviews: subviews)

        for row in rows {
            height += row.maxY - row.minY
        }

        height += spacing * CGFloat(max(0, rows.count - 1))

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        let rows = computeRows(width: width, subviews: subviews)

        var currentY = bounds.minY

        for row in rows {
            for (subview, x) in row.subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                let origin = CGPoint(x: x, y: currentY)
                subview.place(at: origin, proposal: ProposedViewSize(viewSize))
            }

            currentY += (row.maxY - row.minY) + spacing
        }
    }

    private func computeRows(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var currentX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > width && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                currentX = 0
            }

            currentRow.add(subview, at: currentX, size: size)
            currentX += size.width + spacing
        }

        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var subviews: [(subview: LayoutSubview, x: CGFloat)] = []
        var minY: CGFloat = 0
        var maxY: CGFloat = 0

        mutating func add(_ subview: LayoutSubview, at x: CGFloat, size: CGSize) {
            subviews.append((subview, x))
            minY = 0
            maxY = max(maxY, size.height)
        }
    }
}
