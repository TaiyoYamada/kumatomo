import SwiftUI

// MARK: - ExpandableBioView

/// 展開可能な自己紹介テキストビュー
/// - 3行を超える場合は「さらに表示」ボタンを表示
/// - タップで全文展開、「閉じる」で折りたたみ
struct ExpandableBioView: View {
    let bio: String

    @State private var isExpanded = false
    @State private var isTruncated = false

    /// 折りたたみ時の表示行数
    private let lineLimit = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 自己紹介テキスト
            Text(bio)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(2)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            checkTruncation(geometry: geometry)
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.25), value: isExpanded)

            // さらに表示 / 閉じるボタン
            if isTruncated || isExpanded {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "閉じる" : "さらに表示")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.lightOrange)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.lightOrange)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// テキストが切り詰められているかチェック
    private func checkTruncation(geometry: GeometryProxy) {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let lineHeight = font.lineHeight + 2 // lineSpacingを考慮

        // 3行分の高さを超えているかチェック
        let maxHeight = lineHeight * CGFloat(lineLimit)
        let textHeight = calculateTextHeight(for: bio, width: geometry.size.width, font: font)

        if textHeight > maxHeight, !isExpanded {
            isTruncated = true
        }
    }

    /// テキストの高さを計算
    private func calculateTextHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}

#if DEBUG
struct ExpandableBioView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 短いテキスト（展開不要）
            ExpandableBioView(bio: "短い自己紹介です。")
                .padding()
                .background(Color.gray.opacity(0.1))

            Divider()

            // 長いテキスト（展開必要）
            ExpandableBioView(
                bio: "これは長い自己紹介です。熊本県出身で、現在は東京でエンジニアとして働いています。趣味は読書と旅行で、特に温泉巡りが好きです。週末はよく阿蘇山や黒川温泉に行きます。地元の美味しいものを紹介するのが大好きで、馬刺しやからし蓮根、いきなり団子などがおすすめです。"
            )
            .padding()
            .background(Color.gray.opacity(0.1))
        }
        .padding()
    }
}
#endif
