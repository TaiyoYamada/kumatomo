import SwiftUI
import UIKit

// MARK: - SidebarPanel

struct SidebarPanel: View {
    let user: User?
    let onClose: () -> Void

    let allItems = SidebarMenuItemType.allCases
    @Environment(AppRouter.self) private var appRouter

    var body: some View {

        GeometryReader { _ in
            VStack(spacing: 0) {
                Spacer().frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)

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
                            if item == .logout {
                                // ログアウトは特別処理
                                SidebarMenuItemView(icon: item.icon, title: item.title, subtitle: item.subtitle) {
                                    handleLogout()
                                }
                            } else {
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
            .background(Color(UIColor.systemBackground))
        }
    }

    private func routerDestination(for item: SidebarMenuItemType) -> RouterDestination {
        switch item {
        case .bookmarks:
            return .bookmarkedPosts
        case .likes:
            return .likedPosts
        case .settings:
            return .settings
        default:
            return .settings
        }
    }

    private func navigate(using item: SidebarMenuItemType) {
        let router = appRouter
        router.selectedTab = .portal
        router.popToRoot()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            switch item {
            case .bookmarks:
                router.navigate(to: .bookmarkedPosts, on: .portal)
            case .likes:
                router.navigate(to: .likedPosts, on: .portal)
            case .settings:
                router.navigate(to: .settings, on: .portal)
            case .help:
                if let urlString = item.externalURL, let url = URL(string: urlString) {
                    router.navigate(to: .webView(url: url, title: "ヘルプ"), on: .portal)
                }
            case .contact:
                if let urlString = item.externalURL, let url = URL(string: urlString) {
                    router.navigate(to: .webView(url: url, title: "お問い合わせ"), on: .portal)
                }
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

// MARK: - SidebarHeader

struct SidebarHeader: View {
    let user: User?

    var body: some View {
        HStack(spacing: 12) {
            if let user {
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

// MARK: - SidebarMenuItemContent

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

                if let subtitle {
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

// MARK: - SidebarMenuItemView

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

                    if let subtitle {
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
