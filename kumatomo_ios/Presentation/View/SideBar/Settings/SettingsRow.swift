import SwiftUI

// MARK: - SettingsRow

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)

            Text(title)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        SettingsRow(icon: "envelope.fill", iconColor: .blue, title: "メールアドレス変更")
        SettingsRow(icon: "lock.fill", iconColor: .green, title: "パスワード変更")
        SettingsRow(icon: "trash.fill", iconColor: .red, title: "アカウント削除")
    }
}
