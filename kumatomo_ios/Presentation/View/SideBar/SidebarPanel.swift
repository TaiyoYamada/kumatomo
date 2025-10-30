import SwiftUI
import UIKit

// MARK: - Sidebar Panel
struct SidebarPanel: View {
    let user: User?
    let onClose: () -> Void
    
    let allItems = SidebarMenuItemType.allCases
    @Environment(AppRouter.self) private var appRouter
    
    var body: some View {
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer().frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                
                // Header - プロフィールタブへ遷移（確実に遷移するためプログラマティックに切替）
                Button(action: {
                    appRouter.selectedTab = .profile
                    onClose()
                }) {
                    SidebarHeader(user: user)
                }
                .buttonStyle(PlainButtonStyle())
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(allItems.enumerated()), id: \.offset) { index, item in
                            if item.isExternalLink {
                                SidebarLinkItem(icon: item.icon, title: item.title, urlString: item.externalURL ?? "")
                            } else if item == .logout {
                                // ログアウトは特別処理
                                SidebarMenuItemView(icon: item.icon, title: item.title, subtitle: item.subtitle) {
                                    handleLogout()
                                }
                            } else {
                                // 確実に遷移するため、AppRouterを使ってプログラマティックに遷移
                                Button(action: {
                                    navigate(using: item)
                                    onClose()
                                }) {
                                    SidebarMenuItemContent(icon: item.icon, title: item.title, subtitle: item.subtitle)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if index < allItems.count - 1 {
                                Divider().padding(.leading, 56)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 8)
                }
            }
//            .padding(.top, geometry.safeAreaInsets.top)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // 各メニュー項目に対応するRouterDestinationを返す（未使用だが将来拡張用に残す）
    private func routerDestination(for item: SidebarMenuItemType) -> RouterDestination {
        switch item {
        case .bookmarks:
            return .bookmarkedPosts
        case .likes:
            return .likedPosts
        case .coupons:
            return .coupons
        case .settings:
            return .settings
        case .kumamonAI:
            return .kumamonAI
        default:
            return .settings
        }
    }

    // Sidebarメニューの遷移ロジック（AppRouterで確実に遷移）
    private func navigate(using item: SidebarMenuItemType) {
        // Ensure navigation happens on the active tab stack after switching tabs
        let router = appRouter
        print("[Sidebar] navigate item=\(item)")
        router.selectedTab = .portal
        print("[Sidebar] selectedTab -> portal")
        router.popToRoot()
        
        // Slight delay to avoid race with sidebar dismissal & tab switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            print("[Sidebar] perform navigation for item=\(item)")
            switch item {
            case .bookmarks:
                router.navigateToBookmarkedPosts(on: .portal)
            case .likes:
                router.navigateToLikedPosts(on: .portal)
            case .favoriteShops:
                router.navigate(to: .favoritesList, on: .portal)
            case .coupons:
                router.navigate(to: .coupons, on: .portal)
            case .settings:
                router.navigateToSettings(on: .portal)
            case .kumamonAI:
                router.navigate(to: .kumamonAI, on: .portal)
            default:
                break
            }
        }
    }
    
    private func handleLogout() {
        Task {
            try? await AuthService.shared.signOut()
        }
        onClose()
    }
}

// MARK: - Sidebar Header
struct SidebarHeader: View {
    let user: User?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let user = user {
                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user?.name ?? "名前")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(user?.username ?? "@guest")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top)
        .padding(.bottom, 20)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Sidebar Menu Item Content（NavigationLink用）
struct SidebarMenuItemContent: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.001))
    }
}

// MARK: - Sidebar Menu Item View（ログアウト用）
struct SidebarMenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray.opacity(0.001))
    }
}

// MARK: - Sidebar Link Item
struct SidebarLinkItem: View {
    let icon: String
    let title: String
    let urlString: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
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
    }
}
