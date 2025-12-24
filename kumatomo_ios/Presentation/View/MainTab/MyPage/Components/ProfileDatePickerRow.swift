import SwiftUI

// MARK: - ProfileDatePickerRow

/// プロフィール編集用の日付選択行
struct ProfileDatePickerRow: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("この情報は公開されません。年齢に基づいてよりよいコンテンツを表示するために使用されます。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
