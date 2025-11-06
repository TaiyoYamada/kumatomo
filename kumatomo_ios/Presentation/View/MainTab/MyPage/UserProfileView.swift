import SwiftUI

struct UserProfileView: View {
    let userId: Int
    @Environment(CurrentUserManager.self) private var userManager
    @State private var user: User?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let user = user {
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())

                                VStack(spacing: 4) {
                                    Text(user.name ?? "name")
                                        .font(.title2)
                                        .fontWeight(.semibold)

                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding()

                            Divider()

                            Text("ユーザーの投稿")
                                .font(.headline)
                                .padding()

                            Text("投稿一覧は開発中です")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("エラーが発生しました")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("再試行") {
                            loadUserProfile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                loadUserProfile()
            }
        }
    }

    private func loadUserProfile() {
        isLoading = true
        errorMessage = nil

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                if userId > 0 {
                    user = User(
                        id: userId,
                        name: "ユーザー \(userId)",
                        username: "user\(userId)",
                        profileImageURL: nil,
                        coverImageURL: nil,
                        bio: "これはサンプルのプロフィールです。",
                        createdAt: Date(),
                    )
                } else {
                    errorMessage = "ユーザーが見つかりません"
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    UserProfileView(userId: 1)
        .environment(CurrentUserManager.shared)
}
