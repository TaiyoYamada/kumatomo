import SwiftUI

struct ProfileEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: ProfileEditViewModel
    
    @State private var showImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: ProfileEditViewModel(profile: user))
    }


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // プロフィール画像セクション
                    profileImageSection
                    
                    // 入力フォームセクション
                    formSection
                }
                .padding(.horizontal)
            }
            .navigationBarTitle("プロフィール編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue),
                trailing: Button("完了") {
                    saveProfile()
                }
                .foregroundColor(.blue)
                .disabled(viewModel.isProcessing)
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("お知らせ"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $viewModel.profileImage)
            }
        }
    }
    
    // プロフィール画像セクション
    private var profileImageSection: some View {
        VStack(spacing: 12) {
            ProfileImageView(
                image: viewModel.profileImage,
                urlString: viewModel.profileImageURL
            )

                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 20)
            
            Button(action: {
                showImagePicker = true
            }) {
                Text("プロフィール写真を変更")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }
    
    // プレースホルダー画像
    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 90, height: 90)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 40))
            )
    }
    
    // フォームセクション
    private var formSection: some View {
        VStack(spacing: 0) {
            formField(title: "名前", text: $viewModel.name)
            formField(title: "メールアドレス", text: $viewModel.email, keyboardType: .emailAddress)
            formField(title: "ウェブサイト", text: $viewModel.website, keyboardType: .URL)
            
            Divider()
            
            // 自己紹介
            VStack(alignment: .leading, spacing: 6) {
                Text("自己紹介")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                    .padding(.top, 16)
                
                TextEditor(text: $viewModel.bio)
                    .font(.system(size: 16))
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.bottom, 20)
        }
    }
    
    // 入力フィールド共通レイアウト
    private func formField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.secondary)
                .font(.system(size: 14))
                .padding(.top, 16)
            
            TextField("", text: text)
                .font(.system(size: 16))
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress || keyboardType == .URL ? .none : .words)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            Divider()
        }
    }
    
    // プロフィール保存処理
    private func saveProfile() {
        viewModel.updateProfile { success, message in
            self.alertMessage = message
            self.showingAlert = true
            
            if success {
                // 更新成功時は一定の遅延後に画面を閉じる
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// 画像選択用のヘルパービュー
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
