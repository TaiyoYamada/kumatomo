import SwiftUI
import Observation

// MARK: - LoginView

struct LoginView: View {
    @State private var viewModel = AuthViewModel()
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            VStack {
                // ロゴ画像
                Image("portal_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.vertical, 20)

                // 入力フォーム
                VStack(spacing: 24) {
                    InputField(
                        text: $viewModel.email,
                        title: "メールアドレス",
                        placeholder: "your@email.com",
                        systemImage: "envelope"
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                    SecureInputField(
                        text: $viewModel.password,
                        title: "パスワード",
                        placeholder: "パスワードを入力",
                        systemImage: "lock"
                    )
                }
                .padding(.horizontal)
                .padding(.top)

                // エラーメッセージ
                if (viewModel.errorMessage?.isEmpty) == nil {
                    Text(viewModel.errorMessage ?? "")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }

                // ログインボタン
                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    HStack {
                        Text("ログイン")
                            .fontWeight(.semibold)

                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.leading, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lightOrangeColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .disabled(viewModel.isLoading)

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
                            .foregroundColor(.orange)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .font(.body)
            }
            .padding(.vertical, 4)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                SecureField(placeholder, text: $text)
                    .font(.body)
            }
            .padding(.vertical, 4)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
