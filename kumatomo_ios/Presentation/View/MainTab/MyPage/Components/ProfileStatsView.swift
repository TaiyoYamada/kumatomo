import SwiftUI

// MARK: - ProfileStatsView

/// プロフィール統計情報ビュー
/// 投稿数、フォロー中、フォロワー数を表示
struct ProfileStatsView: View {
    let user: User
    var onFollowersTapped: (() -> Void)?
    var onFollowingTapped: (() -> Void)?

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
            Button(action: { onFollowingTapped?() }) {
                StatItemView(
                    count: user.followingCount ?? 0,
                    label: "フォロー中",
                    isClickable: false
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // フォロワー
            Button(action: { onFollowersTapped?() }) {
                StatItemView(
                    count: user.followersCount ?? 0,
                    label: "フォロワー",
                    isClickable: false
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
