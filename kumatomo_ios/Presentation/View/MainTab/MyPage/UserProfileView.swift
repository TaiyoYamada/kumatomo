import SwiftUI
import Factory

// MARK: - UserProfileView

/// 他ユーザーのプロフィール表示View
struct UserProfileView: View {
    let userId: Int
    @Environment(CurrentUserManager.self) private var userManager
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var followViewModel = FollowViewModel()
    @State private var isFollowing = false
    @State private var showingFollowers = false
    @State private var showingFollowing = false

    private var isCurrentUser: Bool {
        userManager.currentUser?.id == userId
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let user {
                ScrollView {
                    VStack(spacing: 16) {
                        profileHeader(user: user)
                        statsSection(user: user)
                        Divider()
                        postsSection
                    }
                }
            } else if let errorMessage {
                errorView(message: errorMessage)
            }
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUserProfile()
        }
        .sheet(isPresented: $showingFollowers) {
            FollowersListView(userId: userId, userName: user?.name)
        }
        .sheet(isPresented: $showingFollowing) {
            FollowingListView(userId: userId, userName: user?.name)
        }
    }

    // MARK: - Profile Header

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            // User Info
            VStack(spacing: 4) {
                Text(user.name ?? "名前未設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let username = user.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Bio
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Follow Button (only show for other users)
            if !isCurrentUser {
                FollowButton(
                    isFollowing: isFollowing,
                    isLoading: followViewModel.isFollowActionInProgress
                ) {
                    Task {
                        isFollowing = await followViewModel.toggleFollow(
                            userId: userId,
                            isCurrentlyFollowing: isFollowing
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }

    // MARK: - Stats Section

    private func statsSection(user: User) -> some View {
        HStack(spacing: 40) {
            // Posts
            statItem(
                count: user.postCount ?? 0,
                label: "投稿"
            )

            // Followers
            Button {
                showingFollowers = true
            } label: {
                statItem(
                    count: user.followersCount ?? 0,
                    label: "フォロワー"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Following
            Button {
                showingFollowing = true
            } label: {
                statItem(
                    count: user.followingCount ?? 0,
                    label: "フォロー中"
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Posts Section

    private var postsSection: some View {
        VStack(spacing: 12) {
            Text("ユーザーの投稿")
                .font(.headline)
                .padding()

            Text("投稿一覧は開発中です")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("エラーが発生しました")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("再試行") {
                Task {
                    await loadUserProfile()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Load Profile

    private func loadUserProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            // Use the UserAPIService from DI container
            let service = Container.shared.userAPIService()
            let fetchedUser = try await service.fetchProfileAsync(userId: userId)
            await MainActor.run {
                user = fetchedUser
                // TODO: Check follow status from API
                isFollowing = false
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "ユーザー情報の取得に失敗しました"
                isLoading = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UserProfileView(userId: 1)
        .environment(CurrentUserManager.shared)
}
