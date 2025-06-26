import SwiftUI

struct PostView: View {
    @StateObject private var viewModel = StoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var userId: Int = 1 // デフォルト値
    
    // フォントとカラー定数
    private let titleFont = Font.headline
    private let contentFont = Font.body
    private let primaryColor = Color.blue
    private let errorColor = Color.red
    private let regularColor = Color.gray
    private let cardBackground = Color.white
    private let backgroundColor = Color(UIColor.systemGray6)
    
    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Spacer()
                
                Text("新規投稿")
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    Task {
                        // 認証サービスから現在のユーザーIDを取得
                        if let currentUser = AuthService.shared.currentUser {
                            let success = await viewModel.postStory(userId: currentUser.id, content: viewModel.storyContent)
                            // 成功時はviewModelのshowSuccessModal状態変数を使用
                        } else {
                            viewModel.errorMessage = "ユーザー情報が取得できません。再ログインしてください。"
                        }
                    }
                }) {
                    Text("投稿")
                        .foregroundColor(viewModel.isContentValid() && !viewModel.isContentOverLimit() ? primaryColor : .gray)
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!viewModel.isContentValid() || viewModel.isContentOverLimit() || viewModel.isLoading)
            }
            .padding(.top, 10)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 1)
            
            // テキストエディタ部分
            ZStack(alignment: .topLeading) {
                backgroundColor.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 12) {
                    // エディター部分
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
                            .background(backgroundColor)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    
                    Spacer()
                    
                    // 文字数カウンター
                    HStack {
                        Spacer()
                        Text("\(viewModel.storyContent.count)/100")
                            .font(.subheadline)
                            .foregroundColor(viewModel.isContentOverLimit() ? errorColor : regularColor)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
                .padding(.top, 8)
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
        }
        .onAppear {
            // 画面表示時に現在のユーザーIDを取得
            if let currentUser = AuthService.shared.currentUser {
                userId = currentUser.id
            }
        }
    }
}

// プレビュー用
struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView()
    }
}
