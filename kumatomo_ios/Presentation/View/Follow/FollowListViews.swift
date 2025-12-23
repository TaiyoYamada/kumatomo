import SwiftUI

// MARK: - FollowersListView

/// フォロワー一覧表示View
struct FollowersListView: View {
    let userId: Int
    let userName: String?
    @State private var viewModel = FollowViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingFollowers, viewModel.followers.isEmpty {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.followers.isEmpty {
                    ErrorStateView(error: error) {
                        Task {
                            await viewModel.fetchFollowers(userId: userId)
                        }
                    }
                } else if viewModel.followers.isEmpty {
                    FollowEmptyStateView(type: .followers)
                } else {
                    followersList
                }
            }
            .navigationTitle("\(userName ?? "ユーザー")のフォロワー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchFollowers(userId: userId)
        }
    }

    private var followersList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.followers) { user in
                    FollowUserRow(
                        user: user,
                        isLoading: viewModel.isFollowActionInProgress,
                        onFollowTap: {
                            Task {
                                let newState = await viewModel.toggleFollow(
                                    userId: user.id,
                                    isCurrentlyFollowing: user.isFollowing ?? false
                                )
                                viewModel.updateFollowStatus(userId: user.id, isFollowing: newState)
                            }
                        }
                    )
                    Divider()
                        .padding(.leading, 68)
                }

                if viewModel.hasMoreFollowers {
                    ProgressView()
                        .padding()
                        .onAppear {
                            Task {
                                await viewModel.loadMoreFollowers(userId: userId)
                            }
                        }
                }
            }
        }
    }
}

// MARK: - FollowingListView

/// フォロー中ユーザー一覧表示View
struct FollowingListView: View {
    let userId: Int
    let userName: String?
    @State private var viewModel = FollowViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingFollowing, viewModel.following.isEmpty {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.following.isEmpty {
                    ErrorStateView(error: error) {
                        Task {
                            await viewModel.fetchFollowing(userId: userId)
                        }
                    }
                } else if viewModel.following.isEmpty {
                    FollowEmptyStateView(type: .following)
                } else {
                    followingList
                }
            }
            .navigationTitle("\(userName ?? "ユーザー")のフォロー中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchFollowing(userId: userId)
        }
    }

    private var followingList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.following) { user in
                    FollowUserRow(
                        user: user,
                        isLoading: viewModel.isFollowActionInProgress,
                        onFollowTap: {
                            Task {
                                let newState = await viewModel.toggleFollow(
                                    userId: user.id,
                                    isCurrentlyFollowing: user.isFollowing ?? false
                                )
                                viewModel.updateFollowStatus(userId: user.id, isFollowing: newState)
                            }
                        }
                    )
                    Divider()
                        .padding(.leading, 68)
                }

                if viewModel.hasMoreFollowing {
                    ProgressView()
                        .padding()
                        .onAppear {
                            Task {
                                await viewModel.loadMoreFollowing(userId: userId)
                            }
                        }
                }
            }
        }
    }
}

// MARK: - FollowUserRow

/// フォローユーザー行コンポーネント
struct FollowUserRow: View {
    let user: FollowUser
    let isLoading: Bool
    let onFollowTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray4))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? "名前未設定")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let username = user.username {
                    Text("@\(username)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Follow Button
            CompactFollowButton(
                isFollowing: user.isFollowing ?? false,
                isLoading: isLoading,
                isMe: user.isMe ?? false,
                onTap: onFollowTap
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - FollowEmptyStateView

/// フォロー空状態View
struct FollowEmptyStateView: View {
    enum EmptyType {
        case followers
        case following
    }

    let type: EmptyType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type == .followers ? "person.2" : "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text(type == .followers ? "まだフォロワーがいません" : "まだ誰もフォローしていません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(type == .followers
                ? "投稿を続けてフォロワーを増やしましょう"
                : "気になるユーザーをフォローしてみましょう")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
