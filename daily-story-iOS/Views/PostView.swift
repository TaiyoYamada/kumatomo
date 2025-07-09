import SwiftUI
import PhotosUI

struct PostView: View {
    @StateObject private var viewModel = StoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    
    // フォントとカラー定数
    private let titleFont = Font.headline
    private let contentFont = Font.body
    private let primaryColor = Color.blue
    private let errorColor = Color.red
    private let regularColor = Color.gray
    private let cardBackground = Color.white
    private let backgroundColor = Color(UIColor.systemGray6)
    private let tagBackgroundColor = Color.blue.opacity(0.1)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // タイトル入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タイトル")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("タイトルを入力（任意）", text: $viewModel.storyTitle)
                                .font(.title3)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.05), radius: 2)
                        }
                        .padding(.horizontal)
                        
                        // コンテンツ入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("内容")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.storyContent.isEmpty {
                                    Text("今日の出来事を100文字以内で共有しよう...")
                                        .foregroundColor(.gray)
                                        .font(contentFont)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 16)
                                }
                                
                                TextEditor(text: $viewModel.storyContent)
                                    .font(contentFont)
                                    .padding(.horizontal, 8)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white)
                                    .frame(minHeight: 150)
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.05), radius: 2)
                            }
                            
                            // 文字数カウンター
                            HStack {
                                Spacer()
                                Text("\(viewModel.storyContent.count)/100")
                                    .font(.caption)
                                    .foregroundColor(viewModel.storyContent.count > 100 ? errorColor : regularColor)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿") {
                        Task {
                            // 認証サービスから現在のユーザーIDを取得
                            if let currentUser = AuthService.shared.currentUser {
                                let success = await viewModel.postStory(
                                    userId: currentUser.id,
                                    title: viewModel.storyTitle,
                                    content: viewModel.storyContent
                                )
                            } else {
                                viewModel.errorMessage = "ユーザー情報が取得できません。再ログインしてください。"
                            }
                        }
                    }
                    .disabled(viewModel.storyContent.isEmpty || viewModel.storyContent.count > 100 || viewModel.isLoading)
                    .foregroundColor(!viewModel.storyContent.isEmpty && viewModel.storyContent.count <= 100 && !viewModel.isLoading ? primaryColor : .gray)
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.selectedImage = uiImage
                        }
                    }
                }
            }
        }
        .overlay {
            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text(errorMessage)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(10)
                                .padding()
                            
                            Button("閉じる") {
                                viewModel.errorMessage = nil
                            }
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        }
                    )
            }
            
            // 投稿成功時のモーダル（中央表示）
            if viewModel.showSuccessModal {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("投稿しました！")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            
                            Text("タイムラインに反映されます")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(30)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal, 40)
                    )
                    .onAppear {
                        // 3秒後に自動で閉じて前の画面に戻る
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.showSuccessModal = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                dismiss()
                            }
                        }
                    }
            }
            
            // ローディング表示
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    )
            }
        }
    }
}
