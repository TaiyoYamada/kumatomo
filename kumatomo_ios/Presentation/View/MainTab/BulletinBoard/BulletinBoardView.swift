import SwiftUI

struct BulletinBoardView: View {
    @Environment(BulletinBoardViewModel.self) private var viewModel
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showPostModal = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openSidebar) private var openSidebar
    @Environment(CurrentUserManager.self) private var userManager
    
    var body: some View {
//        NavigationStack { // AppRouterで管理するため削除
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
                            .environment(viewModel)
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
                // 初回登録後は出身地の市町村タブを優先表示
                let preferMunicipality = UserDefaults.standard.bool(forKey: "preferMunicipalityTabOnFirstOpen")
                if preferMunicipality, let muni = viewModel.selectedMunicipality, !muni.isEmpty {
                    viewModel.changeTab(.municipality)
                    UserDefaults.standard.set(false, forKey: "preferMunicipalityTabOnFirstOpen")
                }
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
                .environment(userManager)
            }
            
//        }
    }
    
    private func showToastMessage(_ message: String, type: ToastView.ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
    }
}
