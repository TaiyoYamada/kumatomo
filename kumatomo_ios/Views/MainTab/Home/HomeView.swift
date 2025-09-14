import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: BulletinBoardViewModel
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showPostModal = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openSidebar) private var openSidebar
    @EnvironmentObject private var userManager: CurrentUserManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    TabNavigationHeader(
                        activeTab: viewModel.activeTab,
                        selectedMunicipality: viewModel.selectedMunicipality,
                        onTabChange: viewModel.changeTab,
                        onMunicipalityChange: viewModel.changeMunicipality
                    )
                    
                    ZStack {
                        // Main content
                        if viewModel.isLoading && viewModel.posts.isEmpty {
                            SkeletonLoadingView()
                        } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                            if errorMessage.contains("ネットワーク") || errorMessage.contains("接続") {
                                NetworkErrorView {
                                    viewModel.refreshPosts()
                                }
                            } else {
                                ErrorStateView(error: errorMessage) {
                                    viewModel.refreshPosts()
                                }
                            }
                        } else {
                            PostTimeline(
                                posts: viewModel.posts,
                                loading: viewModel.isLoadingMore,
                                onRefresh: viewModel.refreshPosts,
                                onLoadMore: viewModel.loadMorePosts
                            )
                            .environmentObject(viewModel)
                        }
                    }
                }
                
                // Toast notification
                VStack {
                    ToastView(
                        message: toastMessage,
                        type: toastType,
                        isShowing: $showToast
                    )
                    
                    Spacer()
                }
                .zIndex(1)
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            showPostModal = true
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .zIndex(2)
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.inline)
            .sidebarButton()
            .onAppear {
                viewModel.loadInitialPosts()
            }
            .onChange(of: viewModel.errorMessage) { errorMessage in
                if let error = errorMessage {
                    showToastMessage(error, type: .error)
                }
            }
            .fullScreenCover(isPresented: $showPostModal) {
                PostView(onPostSuccess: {
                    // Refresh the bulletin board feed after successful posting
                    viewModel.refreshPosts()
                })
                .environmentObject(userManager)
            }
            .withAppRouter()
        }
    }
    
    private func showToastMessage(_ message: String, type: ToastView.ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
    }
}
