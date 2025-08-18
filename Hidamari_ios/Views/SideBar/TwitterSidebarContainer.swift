import SwiftUI
import UIKit

struct TwitterSidebarContainer<Content: View>: View {
    @Binding var isPresented: Bool
    let user: User?
    let content: () -> Content
    
    @State private var dragOffsetX: CGFloat = 0
    @GestureState private var isDetectingLongPress = false
    
    private let sidebarWidth: CGFloat = 300
    private let overlayOpacity: Double = 0.35
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main content (no push) with dim overlay when sidebar is open
                content()
                    .offset(x: dragOffsetX)
                    .disabled(isPresented) // Prevent interactions when menu is open
                    .overlay(
                        Group {
                            if isPresented || dragOffsetX > 0 {
                                Color.black
                                    .opacity(overlayOpacity * Double((max(dragOffsetX, 0) / sidebarWidth).clamped(to: 0...1)))
                                    .ignoresSafeArea()
                                    .onTapGesture { closeSidebar() }
                                    .accessibilityIdentifier("sidebar_overlay")
                            }
                        }
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("overlay_content")
                
                // Sidebar panel
                TwitterSidebarPanel(user: user, onClose: closeSidebar)
                    .frame(width: sidebarWidth)
                    .offset(x: overlaySidebarOffsetX())
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 2, y: 0)
                    .accessibilityIdentifier("twitter_sidebar_panel")
            }
            .ignoresSafeArea(edges: .vertical)
            .gesture(edgePanGesture(in: geometry))
        }
    }
    
    private func overlaySidebarOffsetX() -> CGFloat {
        if isPresented { return 0 }
        // For overlay: panel starts hidden (-width) and follows positive drag
        if dragOffsetX > 0 { return -sidebarWidth + dragOffsetX }
        return -sidebarWidth
    }
    
    private func openSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = true
            dragOffsetX = sidebarWidth // サイドバーが開いた状態のオフセット
        }
    }
    
    private func closeSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            isPresented = false
            dragOffsetX = 0 // サイドバーが閉じた状態のオフセット
        }
    }
    
    private func edgePanGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                let startX = value.startLocation.x
                let translationX = value.translation.width

                if isPresented { // サイドバーが開いている場合
                    // 左にスライドして閉じる
                    dragOffsetX = sidebarWidth + min(0, translationX)
                } else { // サイドバーが閉じている場合
                    // 左端から右にスライドして開く
                    if startX < 24 && translationX > 0 {
                        dragOffsetX = min(translationX, sidebarWidth)
                    }
                }
            }
            .onEnded { value in
                let translationX = value.translation.width
                if isPresented { // サイドバーが開いている場合
                    if translationX < -sidebarWidth * 0.33 { // 左に大きくスライドしたら閉じる
                        closeSidebar()
                    } else { // それ以外は開いたまま
                        openSidebar()
                    }
                } else { // サイドバーが閉じている場合
                    if translationX > sidebarWidth * 0.33 { // 右に大きくスライドしたら開く
                        openSidebar()
                    } else { // それ以外は閉じたまま
                        closeSidebar()
                    }
                }
            }
    }
}

// MARK: - Sidebar Panel Content

private struct TwitterSidebarPanel: View {
    let user: User?
    let onClose: () -> Void

    @State private var showingShops = false
    @State private var showingBookmarks = false
    @State private var showingLikes = false
    @State private var showingCoupons = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Header
                Button(action: { /* Navigate to profile */ }) {
                    SidebarHeader(user: user)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("プロフィールを開く")
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Primary section
                        SectionHeader(title: "主要機能")
                        SidebarMenuItem(icon: "storefront.fill", title: "お店一覧", subtitle: "近くのお店を探す") {
                            showingShops = true; onClose()
                        }
                        Divider().padding(.leading, 56)
                        SidebarMenuItem(icon: "bookmark.fill", title: "ブックマーク", subtitle: "保存した投稿") {
                            showingBookmarks = true; onClose()
                        }
                        Divider().padding(.leading, 56)
                        SidebarMenuItem(icon: "heart.fill", title: "いいね", subtitle: "いいねした投稿") {
                            showingLikes = true; onClose()
                        }
                        Divider().padding(.leading, 56)
                        SidebarMenuItem(icon: "ticket.fill", title: "クーポン", subtitle: "利用可能なクーポン") {
                            showingCoupons = true; onClose()
                        }
                        
                        // Secondary section
                        SectionHeader(title: "補助機能")
                        SidebarLinkItem(icon: "bell.fill", title: "お知らせ", urlString: "https://www.notion.so/")
                        SidebarLinkItem(icon: "questionmark.circle.fill", title: "ヘルプ", urlString: "https://www.notion.so/")
                        SidebarLinkItem(icon: "envelope.fill", title: "お問い合わせ", urlString: "https://www.notion.so/")
                        SidebarMenuItem(icon: "gearshape.fill", title: "設定", subtitle: "アプリの設定") {
                            showingSettings = true; onClose()
                        }
                        SidebarMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "ログアウト", subtitle: "サインアウトします") {
                            Task { try? await AuthService.shared.signOut() }
                            onClose()
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        // Sheets
        .sheet(isPresented: $showingShops) { ShopListView() }
        .sheet(isPresented: $showingBookmarks) { BookmarkListView() }
        .sheet(isPresented: $showingLikes) { LikeListView() }
        .sheet(isPresented: $showingCoupons) { CouponsView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("twitter_sidebar_content")
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .accessibilityHidden(true)
    }
}

private struct SidebarLinkItem: View {
    let icon: String
    let title: String
    let urlString: String
    
    var body: some View {
        Button(action: { if let url = URL(string: urlString) { UIApplication.shared.open(url) } }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray.opacity(0.001))
        .accessibilityHint("")
    }
}

// Placeholder Coupons view
private struct CouponsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Image(systemName: "ticket.fill").font(.system(size: 64)).foregroundColor(.orange)
                Text("クーポン").font(.title2).fontWeight(.semibold)
                Text("利用可能なクーポンがここに表示されます").foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("クーポン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("閉じる") { dismiss() } } }
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}


