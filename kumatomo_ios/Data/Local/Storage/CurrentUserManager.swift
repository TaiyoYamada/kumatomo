import Foundation
import SwiftUI
import Combine
import Observation

// MARK: - CurrentUserManager

@MainActor
@Observable
class CurrentUserManager {
    static let shared = CurrentUserManager()

    var currentUser: User?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // 初期ロード
        loadCurrentUser()
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
        currentUser = AuthService.shared.currentUser
    }

    func updateUser(_ user: User) {
        currentUser = user
    }

    func clearUser() {
        currentUser = nil
    }
}

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
        username = nil
        self.profileImageURL = nil
        location = nil
        postCount = nil
        followingCount = nil
        followersCount = nil
        hasCompletedSetup = nil
        isVerified = nil
        joinedDate = nil
    }
}
