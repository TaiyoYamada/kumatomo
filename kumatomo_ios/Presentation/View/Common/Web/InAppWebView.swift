import SwiftUI

// MARK: - InAppWebView

/// WebKitを使用したアプリ内Webビュー
struct InAppWebView: View {
    let url: URL
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var webViewNavigator = WebViewNavigator()

    var body: some View {
        VStack(spacing: 0) {
            // WebView
            WebViewRepresentable(
                url: url,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                navigator: webViewNavigator
            )

            // 下部ツールバー
            bottomToolbar
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.lightOrange, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 40) {
            Button {
                webViewNavigator.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
            }
            .disabled(!canGoBack)

            Button {
                webViewNavigator.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
            }
            .disabled(!canGoForward)

            Spacer()

            Button {
                webViewNavigator.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .medium))
            }

            Button {
                if let url = webViewNavigator.currentURL {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "safari")
                    .font(.system(size: 18, weight: .medium))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Divider(), alignment: .top
        )
    }
}

#Preview {
    NavigationStack {
        InAppWebView(
            url: URL(string: "https://www.notion.so/274db424e42280019ed4d3cbbcd9540d")!,
            title: "ヘルプ"
        )
    }
}
