import SwiftUI

// MARK: - DeleteAccountView

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrentUserManager.self) private var userManager

    @State private var password = ""
    @State private var confirmText = ""
    @State private var isLoading = false
    @State private var showFinalConfirmation = false
    @State private var errorMessage: String?

    private let confirmationWord = "削除する"

    var body: some View {
        Form {
            // MARK: - 警告セクション

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        Text("注意")
                            .font(.headline)
                            .foregroundColor(.red)
                    }

                    Text("アカウントを削除すると、以下のデータがすべて削除されます：")
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 6) {
                        BulletPoint(text: "プロフィール情報")
                        BulletPoint(text: "投稿したすべての内容")
                        BulletPoint(text: "いいね・ブックマーク履歴")
                        BulletPoint(text: "フォロー・フォロワー情報")
                    }
                    .padding(.leading, 8)

                    Text("この操作は取り消せません。")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 8)
            }

            // MARK: - 確認入力セクション

            Section {
                SecureField("パスワード", text: $password)
                    .textContentType(.password)
                    .autocapitalization(.none)

                TextField("「\(confirmationWord)」と入力", text: $confirmText)
                    .autocapitalization(.none)
            } header: {
                Text("確認")
            } footer: {
                Text("本人確認のため、パスワードと「\(confirmationWord)」を入力してください。")
                    .font(.caption)
            }

            // MARK: - 削除ボタン

            Section {
                Button(role: .destructive) {
                    showFinalConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("アカウントを削除")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .navigationTitle("アカウント削除")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("最終確認", isPresented: $showFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("本当にアカウントを削除しますか？\nこの操作は取り消せません。")
        }
    }

    // MARK: - Private

    private var isFormValid: Bool {
        !password.isEmpty && confirmText == confirmationWord
    }

    private func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: API連携を実装
        // 実際のAPI呼び出しはバックエンド実装後に追加
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 仮の遅延
            // 成功したらログアウト処理
            try? await AuthService.shared.signOut()
        } catch {
            errorMessage = "アカウントの削除に失敗しました"
        }
    }
}

// MARK: - BulletPoint

private struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeleteAccountView()
            .environment(CurrentUserManager.shared)
    }
}
