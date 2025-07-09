import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var showSuccessAlert = false
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(profile: user))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // カバー画像編集セクション
                    CoverImageEditSection(
                        selectedCoverItem: $selectedCoverItem,
                        viewModel: viewModel
                    )
                    
                    // プロフィール画像編集セクション
                    ProfileImageEditSection(
                        selectedProfileItem: $selectedProfileItem,
                        viewModel: viewModel
                    )
                    
                    // フォーム
                    VStack(spacing: 24) {
                        // 基本情報
                        VStack(alignment: .leading, spacing: 16) {
                            CustomTextField(
                                title: "名前",
                                text: $viewModel.name,
                                placeholder: "名前を入力"
                            )
                            
                            CustomTextField(
                                title: "自己紹介",
                                text: $viewModel.bio,
                                placeholder: "自己紹介を入力してください",
                                isMultiline: true
                            )
                            
                            CustomTextField(
                                title: "場所",
                                text: $viewModel.location,
                                placeholder: "場所を入力"
                            )
                            
                            CustomTextField(
                                title: "ウェブサイト",
                                text: $viewModel.website,
                                placeholder: "https://example.com"
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        
                        // 生年月日セクション
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("生年月日")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            DatePicker(
                                "生年月日",
                                selection: .constant(Date()),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("この情報は公開されません。年齢に基づいてよりよいコンテンツを表示するために使用されます。")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                    }
                    
                    // エラーメッセージ
                    if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.callout)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            // 選択された画像をviewModelにセット
                            await viewModel.updateProfile()
                            if viewModel.showSuccessMessage {
                                showSuccessAlert = true
                            }
                        }
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("保存完了"),
                    message: Text("プロフィールを更新しました"),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
            .onChange(of: selectedProfileItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.profileImage = uiImage
                        }
                    }
                }
            }
            .onChange(of: selectedCoverItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.coverImage = uiImage
                        }
                    }
                }
            }
//            .overlay {
//                if viewModel.isProcessing {
//                    Color.black.opacity(0.3)
//                        .ignoresSafeArea()
//                        .overlay(
//                            ProgressView()
//                                .scaleEffect(1.5)
//                                .tint(.white)
//                        )
//                }
//            }
        }
    }
}

// カスタムテキストフィールド
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .padding(8)
                        .cornerRadius(8)
                    
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    }
                }
            } else {
                TextField(placeholder, text: $text)
                    .padding()
//                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
        }
    }
}

// カバー画像編集セクション
struct CoverImageEditSection: View {
    @Binding var selectedCoverItem: PhotosPickerItem?
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // カバー画像
            if let coverImage = viewModel.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
            } else if let ProfileImageURL = viewModel.profile.ProfileImageURL, !ProfileImageURL.isEmpty {
                AsyncImage(url: URL(string: ProfileImageURL)) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.5)
                            .frame(height: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                    case .failure:
                        Color.gray.opacity(0.5)
                            .frame(height: 150)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        Color.gray.opacity(0.5)
                            .frame(height: 150)
                    }
                }
            } else {
                Color.gray.opacity(0.5)
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                    )
            }
            
            // 編集ボタン
            PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                Text("編集")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
//                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(8)
        }
    }
}

// プロフィール画像編集セクション
struct ProfileImageEditSection: View {
    @Binding var selectedProfileItem: PhotosPickerItem?
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // プロフィール画像
            ZStack {
                if let profileImage = viewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                } else if let profileImageURL = viewModel.profile.ProfileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 80, height: 80)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        case .failure:
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 80, height: 80)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }
            }
            .offset(y: -40)
            .padding(.bottom, -40)
            
            // 編集ボタン
            PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                    )
            }
            .offset(x: -10, y: -45)
        }
        .padding(.leading, 16)
    }
}
