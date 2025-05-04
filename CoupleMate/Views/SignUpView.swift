import SwiftUI
import PhotosUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        VStack {
            // ヘッダー
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
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            
            // プロフィール画像選択
            VStack {
                PhotosPicker(selection: $viewModel.selectedImage) {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .foregroundColor(Color(.systemGray4))
                    }
                }
                .onChange(of: viewModel.selectedImage) { oldValue, newValue in
                    viewModel.loadProfileImage()
                }
                Text("プロフィール写真を選択")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.pink)
                    .padding(.top, 8)
            }
            .padding(.vertical)
            
            // 入力フォーム
            VStack(spacing: 20) {
                InputField(text: $viewModel.fullName,
                          title: "お名前",
                          placeholder: "フルネームを入力",
                          systemImage: "person")
                
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
                
                // 誕生日選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("誕生日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        DatePicker("", selection: $viewModel.birthDate,
                                   displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // エラーメッセージ
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
            }
            
            // 登録ボタン
            Button {
                Task { await viewModel.createUser() }
            } label: {
                HStack {
                    Text("登録する")
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
        }
        .navigationBarHidden(true)
    }
}
