import SwiftUI

// MARK: - ProfileTab

/// プロフィール画面のタブ種別
enum ProfileTab: Int, CaseIterable, Sendable {
    case posts = 0
    case photos = 1

    var title: String {
        switch self {
        case .posts:
            return "投稿"
        case .photos:
            return "写真"
        }
    }

    var icon: String {
        switch self {
        case .posts:
            return "square.grid.2x2"
        case .photos:
            return "photo.on.rectangle"
        }
    }
}

// MARK: - ProfileTabSelectorView

/// Facebook/Instagram風のプロフィールタブセレクタ
/// LazyVStackのpinnedViewsと組み合わせてスティッキーヘッダーとして使用
struct ProfileTabSelectorView: View {
    @Binding var selectedTab: ProfileTab
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    ProfileTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: tabNamespace,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)

            // 下部の区切り線
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.3))
                .frame(height: 1)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - ProfileTabButton

private struct ProfileTabButton: View {
    let tab: ProfileTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(tab.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                // アンダーラインインジケータ
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)

                    if isSelected {
                        Rectangle()
                            .fill(Color.lightOrange)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "tab_indicator", in: namespace)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack {
        ProfileTabSelectorView(selectedTab: .constant(.posts))
        Spacer()
    }
}
#endif
