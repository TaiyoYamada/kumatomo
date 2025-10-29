import Foundation
import SwiftUI
import Combine

@MainActor
class CurrentUserManager: ObservableObject {
    static let shared = CurrentUserManager()
    
    @Published var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 初期ロード
        loadCurrentUser()
        // AuthService の変更を監視して即時反映
        AuthService.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
        AuthService.shared.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthed in
                if !isAuthed { self?.currentUser = nil }
            }
            .store(in: &cancellables)
    }
    
    func loadCurrentUser() {
        // AuthServiceから現在のユーザー情報をスナップショット
        currentUser = AuthService.shared.currentUser
    }
    
    func updateUser(_ user: User) {
        currentUser = user
    }
    
    func clearUser() {
        currentUser = nil
    }
}

// MARK: - User Extension for easier initialization

extension User {
    init(
        id: Int,
        email: String?,
        name: String?,
        bio: String? = nil,
        profileImageURL: String? = nil,
        coverImageURL: String? = nil,
        birthday: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.coverImageURL = coverImageURL
        self.birthday = birthday
        self.createdAt = createdAt
        
        // デフォルト値を設定
        self.username = nil
        self.profileImageURL = nil
        self.location = nil
        self.postCount = nil        
        self.followingCount = nil
        self.followersCount = nil
        self.hasCompletedSetup = nil
        self.isVerified = nil
        self.joinedDate = nil
    }
}
