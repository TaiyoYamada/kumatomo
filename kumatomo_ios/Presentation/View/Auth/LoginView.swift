import SwiftUI
import Observation

// MARK: - LoginView

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            VStack {
                // ロゴ画像
                Image("portal_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.vertical, 5)

                // 入力フォーム
                VStack(spacing: 24) {
                    InputField(
                        text: Bindable(authViewModel).email,
                        title: "メールアドレス",
                        placeholder: "your@email.com",
                        systemImage: "envelope"
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                    SecureInputField(
                        text: Bindable(authViewModel).password,
                        title: "パスワード",
                        placeholder: "パスワードを入力",
                        systemImage: "lock"
                    )
                }
                .padding(.horizontal)

                // エラーメッセージ
                if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }

                // ログインボタン
                Button {
                    Task { await authViewModel.signIn() }
                } label: {
                    HStack {
                        Text("ログイン")
                            .fontWeight(.semibold)

                        if authViewModel.isLoading {
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
                .padding(.top, 24)
                .disabled(authViewModel.isLoading)

                Spacer()

                // 新規登録リンク
                NavigationLink(value: RouterDestination.signUp) {
                    HStack {
                        Text("アカウントをお持ちでないですか？")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Text("新規登録")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.lightOrange)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: RouterDestination.self) { destination in
                DestinationViewBuilder.view(for: destination)
            }
        }
    }
}

// MARK: - InputField

struct InputField: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                TextField(placeholder, text: $text)
                    .font(.body)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - SecureInputField

struct SecureInputField: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                SecureField(placeholder, text: $text)
                    .font(.body)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
