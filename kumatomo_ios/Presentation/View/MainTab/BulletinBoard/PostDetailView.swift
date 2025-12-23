import SwiftUI
import UIKit

// MARK: - PostDetailView

struct PostDetailView: View {
    let postId: Int

    @State private var viewModel = PostDetailViewModel()
    @State private var commentViewModel = CommentViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(AppRouter.self) private var appRouter

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

            if viewModel.isLoading, viewModel.post == nil {
                PostDetailLoadingView()
            } else if let post = viewModel.post {
                ScrollViewReader { _ in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            PostContentSection(
                                post: post,
                                onProfileTap: {
                                    if let userId = post.userId {
                                        appRouter.navigate(to: .userProfile(userId: userId))
                                    }
                                }
                            )

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

                            CommentsSection(
                                comments: viewModel.comments,
                                isLoading: viewModel.isLoadingComments,
                                onRefresh: {
                                    Task {
                                        await viewModel.refreshComments()
                                    }
                                },
                                onUserTap: { userId in
                                    appRouter.navigate(to: .userProfile(userId: userId))
                                },
                                onImageTap: { imageUrl in
                                    print("Image tapped: \(imageUrl)")
                                }
                            )

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
                PostDetailErrorView(
                    error: errorMessage,
                    onRetry: {
                        Task {
                            await loadAllData()
                        }
                    }
                )
            }

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
        .onReceive(NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
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
        }
        .sheet(isPresented: $showShareSheet) {
            if let post = viewModel.post {
                ShareSheet(items: [createShareText(for: post)])
            }
        }
        .confirmationDialog("投稿を削除", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                print("Delete post: \(postId)")
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この投稿を削除しますか？この操作は取り消せません。")
        }
        .confirmationDialog("投稿を報告", isPresented: $showReportSheet) {
            Button("不適切なコンテンツ") {
                print("Report post as inappropriate: \(postId)")
            }
            Button("スパム") {
                print("Report post as spam: \(postId)")
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この投稿を報告する理由を選択してください")
        }
    }

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

#Preview {
    PostDetailView(postId: 1)
        .environment(CurrentUserManager.shared)
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
