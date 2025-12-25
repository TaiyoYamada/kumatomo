import SwiftUI

// MARK: - ModernProfileHeaderView

/// プロフィールヘッダービュー（自分のプロフィール用）
/// カバー画像、プロフィール画像、編集ボタンを表示
struct ModernProfileHeaderView: View {
    let user: User
    let scrollOffset: CGFloat
    let onEditTapped: () -> Void

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ZStack {
                    if let coverImageURL = user.coverImageURL, !coverImageURL.isEmpty,
                       let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.lightOrange.opacity(0.7),
                                        Color.purple.opacity(0.7),
                                        Color.lightOrange.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .overlay(
                                    ProgressView()
                                        .tint(.white.opacity(0.8))
                                )
                            case let .success(image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                // エラー時のデフォルトグラデーション
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.lightOrange.opacity(0.7),
                                        Color.purple.opacity(0.7),
                                        Color.lightOrange.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.7))
                                )
                            @unknown default:
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.lightOrange.opacity(0.7),
                                        Color.purple.opacity(0.7),
                                        Color.lightOrange.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    } else {
                        LinearGradient(
                            colors: [
                                Color(.systemGray5),
                                Color(.systemGray6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
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
                    // グラデーションオーバーレイ - より洗練された効果
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

                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top) {
                        // プロフィール画像 - より大きく、より目立つように
                        ZStack {
                            // 外側の白い境界線
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 90, height: 90)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                            // 内側のプロフィール画像
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
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 42))
                                                    .foregroundColor(.secondary)
                                            )
                                    @unknown default:
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 42))
                                                    .foregroundColor(.secondary)
                                            )
                                    }
                                }
                                .frame(width: 84, height: 84)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 42))
                                            .foregroundColor(.secondary)
                                    )
                                    .frame(width: 84, height: 84)
                            }
                        }
                        .offset(y: -45)

                        Spacer()
                    }

                    Button(action: {
                        onEditTapped()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                            Text("プロフィールを編集")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 230)
    }
}
