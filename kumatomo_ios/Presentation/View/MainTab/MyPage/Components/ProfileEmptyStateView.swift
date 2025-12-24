import SwiftUI

// MARK: - ProfileEmptyStateView

/// 投稿がない場合の空状態ビュー
/// プロフィール画面固有の空状態メッセージを表示
struct ProfileEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            // アイコン
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }

            // メッセージ
            VStack(spacing: 8) {
                Text("まだ投稿がありません")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("あなたの最初の投稿を共有して、\nフォロワーとつながりましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 80)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}
