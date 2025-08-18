import SwiftUI

struct SidebarMenu: View {
    @Binding var isPresented: Bool
    let user: User?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingBookmarks = false
    @State private var showingLikes = false
    @State private var showingSettings = false
    @State private var showingShops = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with user profile
                SidebarHeader(user: user)
                
                // Menu items
                ScrollView {
                    VStack(spacing: 0) {
                        // お店
                        SidebarMenuItem(
                            icon: "storefront.fill",
                            title: "お店",
                            subtitle: "近くのお店を探す"
                        ) {
                            showingShops = true
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                        
                        // ブックマーク
                        SidebarMenuItem(
                            icon: "bookmark.fill",
                            title: "ブックマーク",
                            subtitle: "保存した投稿"
                        ) {
                            showingBookmarks = true
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                        
                        // いいね
                        SidebarMenuItem(
                            icon: "heart.fill",
                            title: "いいね",
                            subtitle: "いいねした投稿"
                        ) {
                            showingLikes = true
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                        
                        // 設定
                        SidebarMenuItem(
                            icon: "gearshape.fill",
                            title: "設定",
                            subtitle: "アプリの設定"
                        ) {
                            showingSettings = true
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationTitle("メニュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        isPresented = false
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingShops) {
            ShopListView()
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarkListView()
        }
        .sheet(isPresented: $showingLikes) {
            LikeListView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SidebarHeader: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile image
            AsyncImage(url: URL(string: user?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            // User info
            VStack(spacing: 4) {
                Text(user?.name ?? "ユーザー")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let bio = user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct SidebarMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Color.gray.opacity(0.001) // Invisible background for tap area
        )
    }
}

// MARK: - Placeholder Views

struct BookmarkListView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("ブックマーク")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("保存した投稿がここに表示されます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("ブックマーク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LikeListView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                    .padding()
                
                Text("いいね")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("いいねした投稿がここに表示されます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("いいね")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("アカウント") {
                    SettingsRow(icon: "person.circle", title: "プロフィール編集", color: .blue)
                    SettingsRow(icon: "key", title: "パスワード変更", color: .orange)
                    SettingsRow(icon: "bell", title: "通知設定", color: .green)
                }
                
                Section("アプリ") {
                    SettingsRow(icon: "moon", title: "ダークモード", color: .purple)
                    SettingsRow(icon: "textformat.size", title: "文字サイズ", color: .blue)
                    SettingsRow(icon: "location", title: "位置情報", color: .red)
                }
                
                Section("サポート") {
                    SettingsRow(icon: "questionmark.circle", title: "ヘルプ", color: .gray)
                    SettingsRow(icon: "envelope", title: "お問い合わせ", color: .blue)
                    SettingsRow(icon: "star", title: "アプリを評価", color: .yellow)
                }
                
                Section("その他") {
                    SettingsRow(icon: "doc.text", title: "利用規約", color: .gray)
                    SettingsRow(icon: "hand.raised", title: "プライバシーポリシー", color: .gray)
                    SettingsRow(icon: "info.circle", title: "アプリについて", color: .blue)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SidebarMenu(
        isPresented: .constant(true),
        user: User(
            id: 1,
            email: "test@example.com",
            name: "テストユーザー",
            bio: "これはテストユーザーのプロフィールです。",
            profileImageURL: nil
        )
    )
}