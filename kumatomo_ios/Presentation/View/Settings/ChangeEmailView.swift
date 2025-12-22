import SwiftUI

// MARK: - ChangeEmailView

struct ChangeEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentUserManager.self) private var userManager

    @State private var currentPassword = ""
    @State private var newEmail = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if let user = userManager.currentUser {
                    HStack {
                        Text("現在のメールアドレス")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(user.email ?? "未設定")
                            .foregroundColor(.primary)
                    }
                }
            } header: {
                Text("現在の情報")
            }

            Section {
                SecureField("現在のパスワード", text: $currentPassword)
                    .textContentType(.password)
                    .autocapitalization(.none)

                TextField("新しいメールアドレス", text: $newEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } header: {
                Text("変更内容")
            } footer: {
                Text("確認のため、現在のパスワードを入力してください。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button {
                    Task {
                        await changeEmail()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("メールアドレスを変更")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .navigationTitle("メールアドレス変更")
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
            Text("メールアドレスが変更されました。")
        }
    }

    // MARK: - Private

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
            !newEmail.isEmpty &&
            newEmail.contains("@")
    }

    private func changeEmail() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: API連携を実装
        // 実際のAPI呼び出しはバックエンド実装後に追加
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 仮の遅延
            showSuccessAlert = true
        } catch {
            errorMessage = "メールアドレスの変更に失敗しました"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChangeEmailView()
            .environment(CurrentUserManager.shared)
    }
}
