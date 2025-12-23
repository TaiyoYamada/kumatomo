import Foundation
import WebKit
import Observation

// MARK: - WebViewNavigator

/// WebViewの操作を管理するクラス
@Observable
final class WebViewNavigator {
    var webView: WKWebView?
    var currentURL: URL?

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }
}
