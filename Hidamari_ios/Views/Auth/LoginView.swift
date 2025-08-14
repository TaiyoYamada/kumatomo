import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = AuthViewModel()
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hidamariへようこそ")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.vertical, 50)
                
                // 入力フォーム
                VStack(spacing: 24) {
                    InputField(text: $viewModel.email,
                              title: "メールアドレス",
                              placeholder: "your@email.com",
                              systemImage: "envelope")
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureInputField(text: $viewModel.password,
                                    title: "パスワード",
                                    placeholder: "パスワードを入力",
                                    systemImage: "lock")
                }
                .padding(.horizontal)
                .padding(.top)
                
                // エラーメッセージ
                if ((viewModel.errorMessage?.isEmpty) == nil) {
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
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                // 新規登録リンク
                NavigationLink(destination: SignUpView()) {
                    HStack {
                        Text("アカウントをお持ちでないですか？")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text("新規登録")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

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
                    .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

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
                    .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
