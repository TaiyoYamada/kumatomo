import SwiftUI

// MARK: - ProfileFormRow

/// プロフィール編集用のテキスト入力フォーム行
struct ProfileFormRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let validation: ValidationResult
    var keyboardType: UIKeyboardType = .default
    var prefix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            HStack {
                if let prefix {
                    Text(prefix)
                        .foregroundColor(.secondary)
                        .font(.body)
                }

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if !validation.isValid, let errorMessage = validation.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}
