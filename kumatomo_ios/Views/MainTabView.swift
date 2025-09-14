//
//  MainTabView.swift
//  kumatomo
//
//  Created by 山田大陽 on 2025/09/14.
//


import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var selection: TabSelection = .portal
    @StateObject private var bulletinBoardViewModel = BulletinBoardViewModel()
    @StateObject private var userManager = CurrentUserManager.shared
    @StateObject private var sidebarState = SidebarState()
    @StateObject private var appRouter = AppRouter.shared
    
    var body: some View {
        // 親のNavigationStackは不要になるため削除
        SidebarContainer(isPresented: $sidebarState.isPresented, user: userManager.currentUser) {
            VStack(spacing: 0) {
                NetworkStatusBanner()
                
                TabView(selection: $selection) {
                    // ホームタブ（掲示板機能を統合）
                    // 各タブに専用のNavigationStackを配置
                    NavigationStack {
                        HomeView()
                            .environmentObject(bulletinBoardViewModel)
                            .environmentObject(userManager)
                            .environmentObject(sidebarState)
                            .environment(\.openSidebar, sidebarState.open)
                            // ここでNavigationStackにタイトルを設定
                            .navigationTitle("ホーム")
                    }
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("ホーム")
                    }
                    .tag(TabSelection.home)
                    
                    // 検索タブ
                    // 各タブに専用のNavigationStackを配置
                    NavigationStack {
                        SearchView()
                            .environmentObject(userManager)
                            .environmentObject(sidebarState)
                            .environment(\.openSidebar, sidebarState.open)
                            .navigationTitle("検索")
                    }
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("検索")
                    }
                    .tag(TabSelection.search)
                    
                    // ポータルタブ
                    // 各タブに専用のNavigationStackを配置
                    NavigationStack {
                        PortalView()
                            .environmentObject(userManager)
                            .environmentObject(sidebarState)
                            .environment(\.openSidebar, sidebarState.open)
                            .navigationTitle("ポータル")
                    }
                    .tabItem {
                        Image(systemName: "rectangle.grid.2x2")
                        Text("ポータル")
                    }
                    .tag(TabSelection.portal)
                    
                    // くまモンAIタブ
                    // 各タブに専用のNavigationStackを配置
                    NavigationStack {
                        KumamonAIView()
                            .environmentObject(userManager)
                            .environmentObject(sidebarState)
                            .environment(\.openSidebar, sidebarState.open)
                            .navigationTitle("くまモンAI")
                    }
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("くまモンAI")
                    }
                    .tag(TabSelection.kumamonAI)
                    
                    // プロフィールタブ
                    // 各タブに専用のNavigationStackを配置
                    NavigationStack {
                        MyProfileView()
                            .environmentObject(userManager)
                            .environmentObject(sidebarState)
                            .environment(\.openSidebar, sidebarState.open)
                    }
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("プロフィール")
                    }
                    .tag(TabSelection.profile)
                }
                .accentColor(Color.primaryOrange)
            }
        }
        .withAppRouter()
        .errorOverlay()
        .onAppear {
            userManager.loadCurrentUser()
        }
        .onOpenURL { url in
            AppRouter.shared.handleDeepLink(url: url)
        }
    }
}
