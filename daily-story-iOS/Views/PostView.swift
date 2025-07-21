import SwiftUI
import PhotosUI

struct PostView: View {
    @StateObject private var viewModel = PostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    ContentInputCard(
                        content: $viewModel.postContent,
                        characterCount: viewModel.postContent.count
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("新規投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PostButton(
                        isEnabled: canPost,
                        isLoading: viewModel.isLoading
                    ) {
                        handlePost()
                    }
                }
            }
        }
        .overlay {
            OverlayContent(viewModel: viewModel) {
                dismiss()
            }
        }
        .onChange(of: selectedItem) { newItem in
            handleImageSelection(newItem)
        }
    }
}

// MARK: - Computed Properties
private extension PostView {
    var canPost: Bool {
        !viewModel.postContent.isEmpty &&
        viewModel.postContent.count <= 200 &&
        !viewModel.isLoading
    }
}

// MARK: - Actions
private extension PostView {
    func handlePost() {
        Task {
            if let currentUser = AuthService.shared.currentUser {
                let success = await viewModel.postPost(
                    userId: currentUser.id,
                    
                    content: viewModel.postContent
                )
            } else {
                viewModel.errorMessage = "ユーザー情報が取得できません。再ログインしてください。"
            }
        }
    }
    
    func handleImageSelection(_ newItem: PhotosPickerItem?) {
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
// MARK: - Content Input Card
private struct ContentInputCard: View {
    @Binding var content: String
    let characterCount: Int
    
    private var isOverLimit: Bool {
        characterCount > 200
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
            
            
            TextEditor(text: $content)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.secondarySystemBackground))
                .frame(minHeight: 120)
                .cornerRadius(12)
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 1,
                    y: 1
                )
            
            CharacterCounter(
                count: characterCount,
                isOverLimit: isOverLimit
            )
        }
    }
}

// MARK: - Character Counter
private struct CharacterCounter: View {
    let count: Int
    let isOverLimit: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(count)/200")
                .font(.caption)
                .foregroundStyle(isOverLimit ? Color.red : Color.secondary)
                .animation(.easeInOut(duration: 0.3), value: isOverLimit)
        }
    }
}

// MARK: - Post Button
private struct PostButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button("投稿", action: action)
            .disabled(!isEnabled)
            .foregroundStyle(isEnabled ? Color.blue : Color.secondary)
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isEnabled)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Overlay Content
private struct OverlayContent: View {
    @ObservedObject var viewModel: PostViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                ErrorOverlay(
                    message: errorMessage,
                    onClose: {
                        viewModel.errorMessage = nil
                    }
                )
            }
            
            if viewModel.showSuccessModal {
                SuccessOverlay(onDismiss: onDismiss)
            }
            
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Error Overlay
private struct ErrorOverlay: View {
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.red)
                    
                    Text(message)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("閉じる") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: message)
    }
}

// MARK: - Success Overlay
private struct SuccessOverlay: View {
    let onDismiss: () -> Void
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.green)
                            .scaleEffect(checkmarkScale)
                    }
                    
                    VStack(spacing: 8) {
                        Text("投稿しました！")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("タイムラインに反映されます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30).delay(0.1)) {
                    checkmarkScale = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
    }
}

// MARK: - Loading Overlay
private struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text("投稿中...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: true)
    }
}
