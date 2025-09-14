import SwiftUI
import UIKit

// MARK: - Sidebar Panel
struct SidebarPanel: View {
    let user: User?
    let onClose: () -> Void
    
    let allItems = SidebarMenuItemType.allCases
    
    var body: some View {
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer().frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                
                // Header - プロフィール画面への遷移
                NavigationLink(value: RouterDestination.myProfile) {
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
                                // NavigationLinkを使用した画面遷移
                                NavigationLink(value: routerDestination(for: item)) {
                                    SidebarMenuItemContent(icon: item.icon, title: item.title, subtitle: item.subtitle)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    onClose() // サイドバーを閉じる
                                })
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
    
    // 各メニュー項目に対応するRouterDestinationを返す
    private func routerDestination(for item: SidebarMenuItemType) -> RouterDestination {
        switch item {
        case .shops:
            return .shopList
        case .bookmarks:
            return .bookmarkedPosts
        case .likes:
            return .likedPosts
        case .coupons:
            return .coupons
        case .settings:
            return .settings
        default:
            return .settings
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
