import SwiftUI
import Observation
import PhotosUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showInitialSetup = false
    @State private var navigatetoInitialSetup = false

    var body: some View {
        VStack(spacing: 30) {
            // ヘッダー
            header

            // 入力フォーム
            inputForm

            // エラーメッセージ
            errorMessage

            // 登録ボタン
            signUpButton

            Spacer()

            NavigationLink(
                destination: InitialSetupView(),
                isActive: $navigatetoInitialSetup,
                label: {
                    EmptyView()
                }
            )
        }
        .padding(.top, 20)
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
        .onChange(of: showInitialSetup) { newValue in
            if newValue {
                navigatetoInitialSetup = true
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("アカウント作成")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            // バランスを取るための透明ボタン
            Color.clear
                .frame(width: 22, height: 22) // 左側のボタンと同じサイズ
        }
        .padding(.horizontal)
    }

    private var inputForm: some View {
        @Bindable var auth = authViewModel
        return VStack(spacing: 20) {
            InputField(
                text: $auth.email,
                title: "メールアドレス",
                placeholder: "your@email.com",
                systemImage: "envelope"
            )
            .autocapitalization(.none)
            .keyboardType(.emailAddress)

            SecureInputField(
                text: $auth.password,
                title: "パスワード",
                placeholder: "パスワードを入力 (6文字以上)",
                systemImage: "lock"
            )

            SecureInputField(
                text: $auth.passwordConfirmation,
                title: "パスワード確認",
                placeholder: "パスワードを再入力",
                systemImage: "lock.fill"
            )
        }
        .padding(.horizontal)
    }

    private var errorMessage: some View {
        Group {
            if let errorMessage = authViewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 4)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            } else {
                Color.clear.frame(height: 20) // エラーがない場合のスペース確保
            }
        }
    }

    private var signUpButton: some View {
        Button {
            Task { await authViewModel.createUser() }
            showInitialSetup = true
        } label: {
            HStack {
                Text("登録する")
                    .fontWeight(.semibold)

                if authViewModel.isLoading {
                    ProgressView()
                        .padding(.leading, 4)
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange)
                    .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
            )
            .foregroundColor(.white)
        }

        .padding(.horizontal)
        .disabled(authViewModel.isLoading)
    }
}
