import SwiftUI

struct LikedPostsView: View {
    @EnvironmentObject private var userManager: CurrentUserManager
    @StateObject private var engagementViewModel = EngagementViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if engagementViewModel.isLoadingLikedPosts {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if engagementViewModel.likedPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("いいねした投稿がありません")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("投稿にいいねをすると、ここに表示されます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // TODO: Implement post list view when PostListView component is available
                    List(engagementViewModel.likedPosts, id: \.id) { post in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.user?.name ?? "Unknown User")
                                .font(.headline)
                            Text(post.content)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("いいねした投稿")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await engagementViewModel.refreshLikedPosts()
            }
            .task {
                await engagementViewModel.loadLikedPosts()
            }
        }
    }
}

#Preview {
    LikedPostsView()
        .environmentObject(CurrentUserManager.shared)
}