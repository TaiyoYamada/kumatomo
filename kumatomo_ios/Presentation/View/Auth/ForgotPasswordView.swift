import SwiftUI

// MARK: - ForgotPasswordView

/// パスワードリセットのメインビュー（フロー管理）
struct ForgotPasswordView: View {
    @State private var viewModel = PasswordResetViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.flowState {
            case .enterEmail:
                EnterEmailSection(viewModel: viewModel)
            case .enterCode:
                EnterCodeSection(viewModel: viewModel)
            case .enterNewPassword:
                EnterNewPasswordSection(viewModel: viewModel)
            case .completed:
                CompletedSection(onDismiss: { dismiss() })
            }
        }
        .navigationTitle("パスワードをリセット")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.flowState == .completed)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.lightOrange, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - EnterEmailSection

private struct EnterEmailSection: View {
    @Bindable var viewModel: PasswordResetViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 説明文
            VStack(spacing: 8) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.lightOrange)

                Text("登録済みのメールアドレスを入力してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            // メールアドレス入力
            VStack(alignment: .leading, spacing: 10) {
                Text("メールアドレス")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    TextField("", text: $viewModel.email)
                        .foregroundColor(.primary)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // エラーメッセージ
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // 成功メッセージ
            if let success = viewModel.successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            }

            // 送信ボタン
            Button {
                Task { await viewModel.sendResetCode() }
            } label: {
                HStack {
                    Text("認証コードを送信")
                        .fontWeight(.semibold)
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.leading, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.lightOrange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading)

            Spacer()
        }
    }
}

// MARK: - EnterCodeSection

private struct EnterCodeSection: View {
    @Bindable var viewModel: PasswordResetViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // 説明文
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.lightOrange)

                Text("メールに送信された6桁のコードを入力してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(viewModel.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)

            // OTPコード入力
            VStack(alignment: .leading, spacing: 10) {
                Text("認証コード")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    TextField("123456", text: $viewModel.code)
                        .foregroundColor(.primary)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.title2.monospaced())
                        .focused($isFocused)
                        .onChange(of: viewModel.code) { _, newValue in
                            // 6桁に制限
                            if newValue.count > 6 {
                                viewModel.code = String(newValue.prefix(6))
                            }
                        }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // エラーメッセージ
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // 確認ボタン
            Button {
                Task { await viewModel.verifyCode() }
            } label: {
                HStack {
                    Text("確認")
                        .fontWeight(.semibold)
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.leading, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.lightOrange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading)

            // 再送信リンク
            Button {
                Task { await viewModel.resendCode() }
            } label: {
                Text("コードを再送信")
                    .font(.footnote)
                    .foregroundColor(.lightOrange)
            }
            .disabled(viewModel.isLoading)

            Spacer()
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - EnterNewPasswordSection

private struct EnterNewPasswordSection: View {
    @Bindable var viewModel: PasswordResetViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 説明文
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.lightOrange)

                Text("新しいパスワードを設定してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            // 新しいパスワード
            VStack(alignment: .leading, spacing: 10) {
                Text("新しいパスワード")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    SecureField("6文字以上", text: $viewModel.newPassword)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // パスワード確認
            VStack(alignment: .leading, spacing: 10) {
                Text("パスワード確認")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    SecureField("もう一度入力", text: $viewModel.confirmPassword)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // エラーメッセージ
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // 設定ボタン
            Button {
                Task { await viewModel.resetPassword() }
            } label: {
                HStack {
                    Text("パスワードを変更")
                        .fontWeight(.semibold)
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.leading, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.lightOrange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading)

            Spacer()
        }
    }
}

// MARK: - CompletedSection

private struct CompletedSection: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("パスワードが変更されました")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("新しいパスワードでログインしてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("ログイン画面へ")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lightOrange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView()
}
