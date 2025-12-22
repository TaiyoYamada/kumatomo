import SwiftUI

// MARK: - ChangePasswordView

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                SecureField("現在のパスワード", text: $currentPassword)
                    .textContentType(.password)
                    .autocapitalization(.none)
            } header: {
                Text("現在のパスワード")
            }

            Section {
                SecureField("新しいパスワード", text: $newPassword)
                    .textContentType(.newPassword)
                    .autocapitalization(.none)

                SecureField("新しいパスワード（確認）", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .autocapitalization(.none)
            } header: {
                Text("新しいパスワード")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("パスワードは8文字以上で設定してください。")
                    if !passwordsMatch, !confirmPassword.isEmpty {
                        Text("パスワードが一致しません")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption)
            }

            Section {
                Button {
                    Task {
                        await changePassword()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("パスワードを変更")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .navigationTitle("パスワード変更")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("完了", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("パスワードが変更されました。")
        }
    }

    // MARK: - Private

    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
            newPassword.count >= 8 &&
            passwordsMatch
    }

    private func changePassword() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: API連携を実装
        // 実際のAPI呼び出しはバックエンド実装後に追加
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 仮の遅延
            showSuccessAlert = true
        } catch {
            errorMessage = "パスワードの変更に失敗しました"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
}
