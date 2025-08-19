import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: BulletinBoardViewModel
    @StateObject private var userManager = CurrentUserManager.shared
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showingSidebar = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        NavigationStack {
            SidebarContainer(isPresented: $showingSidebar, user: userManager.currentUser) {
                NavigationView {
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
                                        .accessibilityLabel("投稿を読み込み中")
                                        .accessibilityIdentifier("bulletin_board_loading")
                                } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                                    if errorMessage.contains("ネットワーク") || errorMessage.contains("接続") {
                                        NetworkErrorView {
                                            viewModel.refreshPosts()
                                        }
                                        .accessibilityIdentifier("bulletin_board_network_error")
                                    } else {
                                        ErrorStateView(error: errorMessage) {
                                            viewModel.refreshPosts()
                                        }
                                        .accessibilityIdentifier("bulletin_board_error")
                                    }
                                } else {
                                    PostTimeline(
                                        posts: viewModel.posts,
                                        loading: viewModel.isLoadingMore,
                                        onRefresh: viewModel.refreshPosts,
                                        onLoadMore: viewModel.loadMorePosts
                                    )
                                    .environmentObject(viewModel)
                                    .accessibilityIdentifier("bulletin_board_timeline")
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
                        .accessibilityElement(children: .contain)
                    }
                    .navigationTitle("ホーム")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            ProfileIconButton(user: userManager.currentUser) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSidebar = true
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("bulletin_board_screen")
                }
            }
            .onAppear {
                viewModel.loadInitialPosts()
            }
            .onChange(of: viewModel.errorMessage) { errorMessage in
                if let error = errorMessage {
                    showToastMessage(error, type: .error)
                }
            }
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
