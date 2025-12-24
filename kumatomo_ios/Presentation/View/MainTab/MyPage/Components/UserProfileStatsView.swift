import SwiftUI

// MARK: - UserProfileStatsView

/// 他ユーザー用の統計情報表示
/// タップでフォロワー・フォロー中一覧を表示
struct UserProfileStatsView: View {
    let user: User
    let onFollowersTapped: () -> Void
    let onFollowingTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 投稿数
            StatItemView(
                count: user.postCount ?? 0,
                label: "投稿",
                isClickable: false,
                labelColor: .primary
            )

            Spacer()

            // フォロー中
            Button {
                onFollowingTapped()
            } label: {
                StatItemView(
                    count: user.followingCount ?? 0,
                    label: "フォロー中",
                    isClickable: false
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // フォロワー
            Button {
                onFollowersTapped()
            } label: {
                StatItemView(
                    count: user.followersCount ?? 0,
                    label: "フォロワー",
                    isClickable: false
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
