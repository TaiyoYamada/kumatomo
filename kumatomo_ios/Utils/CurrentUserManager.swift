import Foundation
import SwiftUI

@MainActor
class CurrentUserManager: ObservableObject {
    static let shared = CurrentUserManager()
    
    @Published var currentUser: User?
    
    private init() {
        loadCurrentUser()
    }
    
    func loadCurrentUser() {
        // AuthServiceから現在のユーザー情報を取得
        if let authUser = AuthService.shared.currentUser {
            currentUser = User(
                id: authUser.id,
                email: authUser.email,
                name: authUser.name,
                bio: authUser.bio,
                profileImageURL: authUser.profileImageURL,
                coverImageURL: authUser.coverImageURL,
                birthday: authUser.birthday,
                createdAt: authUser.createdAt
            )
        }
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
        self.profileIconImageURL = nil
        self.city = nil
        self.location = nil
        self.postCount = nil
        self.website = nil
        self.followingCount = nil
        self.followersCount = nil
        self.hasCompletedSetup = nil
        self.isVerified = nil
        self.joinedDate = nil
    }
}