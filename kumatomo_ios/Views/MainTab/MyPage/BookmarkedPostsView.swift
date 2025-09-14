import SwiftUI

struct BookmarkedPostsView: View {
    @EnvironmentObject private var userManager: CurrentUserManager
    @StateObject private var engagementViewModel = EngagementViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if engagementViewModel.isLoadingBookmarkedPosts {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if engagementViewModel.bookmarkedPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("ブックマークした投稿がありません")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("投稿をブックマークすると、ここに表示されます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // TODO: Implement post list view when PostListView component is available
                    List(engagementViewModel.bookmarkedPosts, id: \.id) { post in
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
            .navigationTitle("ブックマークした投稿")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await engagementViewModel.refreshBookmarkedPosts()
            }
            .task {
                await engagementViewModel.loadBookmarkedPosts()
            }
        }
    }
}

#Preview {
    BookmarkedPostsView()
        .environmentObject(CurrentUserManager.shared)
}