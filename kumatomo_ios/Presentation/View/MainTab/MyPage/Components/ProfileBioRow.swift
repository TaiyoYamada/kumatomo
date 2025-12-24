import SwiftUI

// MARK: - ProfileBioRow

/// プロフィール編集用の自己紹介入力行
struct ProfileBioRow: View {
    @Binding var text: String
    let validation: ValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("自己紹介")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(text.count)/300")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            HStack {
                                VStack {
                                    Text("自己紹介を入力してください")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 16)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )

            if !validation.isValid, let errorMessage = validation.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}
