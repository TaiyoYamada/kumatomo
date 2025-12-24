import SwiftUI

// MARK: - StatItemView

/// 個別の統計項目ビュー
/// 数値とラベルを表示（オプションでクリッカブル）
struct StatItemView: View {
    let count: Int
    let label: String
    let isClickable: Bool
    var labelColor: Color = .secondary

    private var formattedCount: String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }

    @ViewBuilder
    var body: some View {
        let content = HStack(spacing: 4) {
            Text(formattedCount)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(labelColor)
        }

        if isClickable {
            Button(action: {
                print("Navigate to \(label) list")
            }) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }
}
