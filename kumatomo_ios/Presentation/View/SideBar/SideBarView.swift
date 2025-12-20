import SwiftUI

// MARK: - BookmarkListView

struct BookmarkListView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("ブックマーク")
                .font(.title2)
                .fontWeight(.semibold)

            Text("保存した投稿がここに表示されます")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("ブックマーク")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - LikeListView

struct LikeListView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("いいね")
                .font(.title2)
                .fontWeight(.semibold)

            Text("いいねした投稿がここに表示されます")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("いいね")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - CouponsView

struct CouponsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("クーポン")
                .font(.title2)
                .fontWeight(.semibold)

            Text("利用可能なクーポンがここに表示されます")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("クーポン")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("設定")
                .font(.title2)
                .fontWeight(.semibold)

            Text("アプリの設定がここに表示されます")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
    }
}
