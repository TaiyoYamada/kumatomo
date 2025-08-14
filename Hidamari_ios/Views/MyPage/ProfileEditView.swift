import SwiftUI
import PhotosUI

struct ModernProfileEditView: View {
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
                    ModernCoverImageEditSection(
                        selectedCoverItem: $selectedCoverItem,
                        viewModel: viewModel
                    )
                    
                    // プロフィール画像編集セクション
                    ModernProfileImageEditSection(
                        selectedProfileItem: $selectedProfileItem,
                        viewModel: viewModel
                    )
                    
                    // フォーム
                    VStack(spacing: 24) {
                        // 基本情報
                        VStack(alignment: .leading, spacing: 20) {
                            ModernTextField(
                                title: "名前",
                                text: $viewModel.name,
                                placeholder: "名前を入力してください"
                            )
                            
                            ModernTextField(
                                title: "ユーザーネーム",
                                text: $viewModel.username,
                                placeholder: "ユーザーネームを入力してください"
                            )
                            
                            ModernTextField(
                                title: "自己紹介",
                                text: $viewModel.bio,
                                placeholder: "自己紹介を入力してください",
                                isMultiline: true
                            )
                            
                            ModernTextField(
                                title: "場所",
                                text: $viewModel.location,
                                placeholder: "場所を入力してください"
                            )
                            
                            ModernTextField(
                                title: "ウェブサイト",
                                text: $viewModel.website,
                                placeholder: "https://example.com"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // 生年月日セクション
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("生年月日")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            DatePicker(
                                "生年月日",
                                selection: $viewModel.birthday,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("この情報は公開されません。年齢に基づいてよりよいコンテンツを表示するために使用されます。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    
                    // エラーメッセージ
                    if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.callout)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await viewModel.updateProfile()
                            if viewModel.showSuccessMessage {
                                showSuccessAlert = true
                            }
                        }
                    }
                    .disabled(viewModel.isProcessing || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(viewModel.isProcessing || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .accentColor)
                    .fontWeight(.semibold)
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
            .overlay {
                if viewModel.isProcessing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                
                                Text("保存中...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        )
                }
            }
        }
    }
}

// モダンなテキストフィールド
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        .frame(minHeight: 120)
                    
                    TextEditor(text: $text)
                        .padding(16)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                    
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            } else {
                TextField(placeholder, text: $text)
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// モダンなカバー画像編集セクション
struct ModernCoverImageEditSection: View {
    @Binding var selectedCoverItem: PhotosPickerItem?
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ZStack {
            // カバー画像
            if let coverImage = viewModel.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
            } else if let coverImageURL = viewModel.profile.coverImageURL, !coverImageURL.isEmpty {
                AsyncImage(url: URL(string: coverImageURL)) { phase in
                    switch phase {
                    case .empty:
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                    case .failure:
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.7))
                        )
                    @unknown default:
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                    }
                }
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.6),
                        Color.purple.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 180)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("カバー画像を追加")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
            }
            
            // 編集ボタン
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                            Text("編集")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(16)
                }
            }
        }
    }
}

// モダンなプロフィール画像編集セクション
struct ModernProfileImageEditSection: View {
    @Binding var selectedProfileItem: PhotosPickerItem?
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // プロフィール画像
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                if let profileImage = viewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 94, height: 94)
                        .clipShape(Circle())
                } else if let profileImageURL = viewModel.profile.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.secondary)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 94, height: 94)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        @unknown default:
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
            }
            .offset(y: -50)
            .padding(.bottom, -50)
            
            // 編集ボタン
            PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .offset(x: -8, y: -55)
        }
        .padding(.leading, 20)
    }
}
