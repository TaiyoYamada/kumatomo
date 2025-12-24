import SwiftUI

// MARK: - UserProfileHeaderView

/// 他ユーザー用のプロフィールヘッダー
/// MyProfileViewのModernProfileHeaderViewと同様のデザインで、編集ボタンの代わりにフォローボタンを表示
struct UserProfileHeaderView: View {
    let user: User
    let isFollowing: Bool
    let isFollowLoading: Bool
    let isCurrentUser: Bool
    let onFollowTapped: () -> Void

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                // カバー画像
                ZStack {
                    if let coverImageURL = user.coverImageURL, !coverImageURL.isEmpty,
                       let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                defaultCoverGradient
                                    .overlay(
                                        ProgressView()
                                            .tint(.white.opacity(0.8))
                                    )
                            case let .success(image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                defaultCoverGradient
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                            @unknown default:
                                defaultCoverGradient
                            }
                        }
                    } else {
                        defaultCoverGradient
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("カバー画像")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            )
                    }
                }
                .frame(height: min(150, UIScreen.main.bounds.height * 0.18))
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0.0),
                            .init(color: Color.black.opacity(0.1), location: 0.7),
                            .init(color: Color.black.opacity(0.3), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // プロフィール画像とフォローボタン
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top) {
                        // プロフィール画像
                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 90, height: 90)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                            if let imageURL = user.profileImageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                ProgressView()
                                                    .tint(.secondary)
                                            )
                                    case let .success(image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        defaultProfileImage
                                    @unknown default:
                                        defaultProfileImage
                                    }
                                }
                                .frame(width: 84, height: 84)
                                .clipShape(Circle())
                            } else {
                                defaultProfileImage
                                    .frame(width: 84, height: 84)
                            }
                        }
                        .offset(y: -45)

                        Spacer()
                    }

                    // フォローボタン（自分以外の場合のみ表示）
                    if !isCurrentUser {
                        FollowButton(
                            isFollowing: isFollowing,
                            isLoading: isFollowLoading,
                            onTap: onFollowTapped
                        )
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 230)
    }

    private var defaultCoverGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.7),
                Color.purple.opacity(0.7),
                Color.orange.opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var defaultProfileImage: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.secondary)
            )
    }
}
