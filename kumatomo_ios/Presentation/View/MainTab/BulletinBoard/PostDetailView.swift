import SwiftUI
import UIKit

/// A comprehensive post detail view with engagement features, comments, and interaction capabilities
struct PostDetailView: View {
    let postId: Int
    
    @StateObject private var viewModel = PostDetailViewModel()
    @StateObject private var commentViewModel = CommentViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var userManager: CurrentUserManager
    
    // UI State
    @State private var showImagePicker = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var showReportSheet = false
    @FocusState private var isCommentFocused: Bool
    
    var body: some View {
        ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.post == nil {
                    // Loading state
                    PostDetailLoadingView()
                } else if let post = viewModel.post {
                    // Main content
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // Post content section
                                PostContentSection(
                                    post: post,
                                    onProfileTap: {
                                        // Navigate to user profile using AppRouter
                                        if let userId = post.userId {
                                            AppRouter.shared.navigateToUserProfile(userId: userId)
                                        }
                                    }
                                )
                                
                                // Engagement buttons section
                                EngagementSection(
                                    post: post,
                                    isTogglingLike: viewModel.isTogglingLike,
                                    isTogglingBookmark: viewModel.isTogglingBookmark,
                                    onLike: {
                                        Task {
                                            await viewModel.toggleLike()
                                        }
                                    },
                                    onBookmark: {
                                        Task {
                                            await viewModel.toggleBookmark()
                                        }
                                    },
                                    onComment: {
                                        isCommentFocused = true
                                    }
                                )
                                
                                Divider()
                                    .padding(.horizontal, 16)
                                
                                // Comments section
                                CommentsSection(
                                    comments: viewModel.comments,
                                    isLoading: viewModel.isLoadingComments,
                                    onRefresh: {
                                        Task {
                                            await viewModel.refreshComments()
                                        }
                                    },
                                    onUserTap: { userId in
                                        AppRouter.shared.navigateToUserProfile(userId: userId)
                                    },
                                    onImageTap: { imageUrl in
                                        // TODO: Implement image viewer
                                        print("Image tapped: \(imageUrl)")
                                    }
                                )
                                
                                // Bottom spacer so last comment isn't hidden by composer
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 100)
                            }
                        }
                        .refreshable {
                            await refreshAllData()
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state
                    PostDetailErrorView(
                        error: errorMessage,
                        onRetry: {
                            Task {
                                await loadAllData()
                            }
                        }
                    )
                }        
        
                // Success/Error messages overlay
                VStack {
                    if viewModel.showSuccessMessage {
                        ToastView(
                            message: viewModel.successMessage,
                            type: .success,
                            isShowing: .constant(true)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let errorMessage = viewModel.errorMessage, !viewModel.isLoading {
                        ToastView(
                            message: errorMessage,
                            type: .error,
                            isShowing: .constant(true)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            viewModel.errorMessage = nil
                        }
                    }
                    
                    Spacer()
                }
                .zIndex(1)
            }
            .navigationTitle("投稿詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("シェア", systemImage: "square.and.arrow.up")
                        }
                        
                        if viewModel.isCurrentUserPostOwner {
                            Button(role: .destructive, action: {
                                showDeleteAlert = true
                            }) {
                                Label("削除", systemImage: "trash")
                            }
                        } else {
                            Button(action: {
                                showReportSheet = true
                            }) {
                                Label("報告", systemImage: "exclamationmark.triangle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .onAppear {
                Task {
                    await loadAllData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                handleKeyboardShow(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                handleKeyboardHide()
            }
            .safeAreaInset(edge: .bottom) {
                CommentComposeSection(
                    viewModel: commentViewModel,
                    currentUser: userManager.currentUser,
                    isSubmitting: viewModel.isAddingComment,
                    onSubmit: {
                        Task {
                            let success = await commentViewModel.submitComment(postId: postId)
                            if success {
                                await viewModel.refreshComments()
                                isCommentFocused = false
                            }
                        }
                    },
                    onImagePicker: {
                        showImagePicker = true
                    }
                )
                .id("comment-compose")
                .focused($isCommentFocused)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $commentViewModel.selectedImage)
                    .appSheetStyle()
            }
            .sheet(isPresented: $showShareSheet) {
                if let post = viewModel.post {
                    ShareSheet(items: [createShareText(for: post)])
                        .appSheetStyle()
                }
            }
            .confirmationDialog("投稿を削除", isPresented: $showDeleteAlert) {
                Button("削除", role: .destructive) {
                    // TODO: Implement post deletion when delete functionality is available
                    print("Delete post: \(postId)")
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この投稿を削除しますか？この操作は取り消せません。")
            }
            .confirmationDialog("投稿を報告", isPresented: $showReportSheet) {
                Button("不適切なコンテンツ") {
                    // TODO: Implement report functionality
                    print("Report post as inappropriate: \(postId)")
                }
                Button("スパム") {
                    // TODO: Implement report functionality
                    print("Report post as spam: \(postId)")
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この投稿を報告する理由を選択してください")
            }
    }
    
    // MARK: - Private Methods
    
    private func loadAllData() async {
        await viewModel.loadPostDetail(postId: postId)
        await viewModel.loadComments(postId: postId)
    }
    
    private func refreshAllData() async {
        await viewModel.refreshPostDetail()
        await viewModel.refreshComments()
    }
    
    private func handleKeyboardShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = keyboardRect.height
            }
        }
    }
    
    private func handleKeyboardHide() {
        withAnimation(.easeInOut(duration: 0.3)) {
            keyboardHeight = 0
        }
    }
    
    private func createShareText(for post: Post) -> String {
        let userName = post.user?.name ?? "ユーザー"
        let content = post.content.prefix(100)
        return "\(userName)さんの投稿: \(content)..."
    }
}





// MARK: - Preview

#Preview {
    PostDetailView(postId: 1)
        .environmentObject(CurrentUserManager.shared)
}

// MARK: - Supporting Views

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
