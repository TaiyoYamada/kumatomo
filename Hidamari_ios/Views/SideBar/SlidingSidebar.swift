//import SwiftUI
//
//struct SlidingSidebar: View {
//    @Binding var isPresented: Bool
//    let user: User?
//    
//    @Environment(\.dismiss) private var dismiss
//    @State private var showingBookmarks = false
//    @State private var showingLikes = false
//    @State private var showingSettings = false
//    @State private var showingShops = false
//    
//    var body: some View {
//        ZStack {
//            // Background overlay
//            if isPresented {
//                Color.black.opacity(0.3)
//                    .ignoresSafeArea()
//                    .onTapGesture {
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            isPresented = false
//                        }
//                    }
//            }
//            
//            // Sidebar content
//            HStack(spacing: 0) {
//                if isPresented {
//                    VStack(spacing: 0) {
//                        // Header with user profile
//                        SidebarHeader(user: user)
//                        
//                        // Menu items
//                        ScrollView {
//                            VStack(spacing: 0) {
//                                // お店
//                                SidebarMenuItem(
//                                    icon: "storefront.fill",
//                                    title: "お店",
//                                    subtitle: "近くのお店を探す"
//                                ) {
//                                    showingShops = true
//                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                        isPresented = false
//                                    }
//                                }
//                                
//                                Divider()
//                                    .padding(.horizontal, 16)
//                                
//                                // ブックマーク
//                                SidebarMenuItem(
//                                    icon: "bookmark.fill",
//                                    title: "ブックマーク",
//                                    subtitle: "保存した投稿"
//                                ) {
//                                    showingBookmarks = true
//                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                        isPresented = false
//                                    }
//                                }
//                                
//                                Divider()
//                                    .padding(.horizontal, 16)
//                                
//                                // いいね
//                                SidebarMenuItem(
//                                    icon: "heart.fill",
//                                    title: "いいね",
//                                    subtitle: "いいねした投稿"
//                                ) {
//                                    showingLikes = true
//                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                        isPresented = false
//                                    }
//                                }
//                                
//                                Divider()
//                                    .padding(.horizontal, 16)
//                                
//                                // 設定
//                                SidebarMenuItem(
//                                    icon: "gearshape.fill",
//                                    title: "設定",
//                                    subtitle: "アプリの設定"
//                                ) {
//                                    showingSettings = true
//                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                        isPresented = false
//                                    }
//                                }
//                                
//                                Spacer(minLength: 50)
//                            }
//                        }
//                        
//                        Spacer()
//                    }
//                    .frame(width: 280)
//                    .background(Color(.systemBackground))
//                    .shadow(color: .black.opacity(0.2), radius: 10, x: 2, y: 0)
//                    .transition(.move(edge: .leading))
//                }
//                
//                Spacer()
//            }
//        }
//        .sheet(isPresented: $showingShops) {
//            ShopListView()
//        }
//        .sheet(isPresented: $showingBookmarks) {
//            BookmarkListView()
//        }
//        .sheet(isPresented: $showingLikes) {
//            LikeListView()
//        }
//        .sheet(isPresented: $showingSettings) {
//            SettingsView()
//        }
//    }
//}
