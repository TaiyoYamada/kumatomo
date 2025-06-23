import SwiftUI
import PhotosUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    
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
        }
        .padding(.top, 20)
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Components
    
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
        VStack(spacing: 20) {
            InputField(text: $viewModel.email,
                      title: "メールアドレス",
                      placeholder: "your@email.com",
                      systemImage: "envelope")
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureInputField(text: $viewModel.password,
                            title: "パスワード",
                            placeholder: "パスワードを入力 (6文字以上)",
                            systemImage: "lock")
        }
        .padding(.horizontal)
    }
    
    private var errorMessage: some View {
        Group {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
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
            Task { await viewModel.createUser() }
        } label: {
            HStack {
                Text("登録する")
                    .fontWeight(.semibold)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.leading, 4)
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pink)
                    .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 3)
            )
            .foregroundColor(.white)
        }
        .padding(.horizontal)
        .disabled(viewModel.isLoading)
    }
}
