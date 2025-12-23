import OSLog

/// os.Logger ベースのアプリケーションLogger
final class AppLogger: @unchecked Sendable {
    private let logger: Logger
    let category: LogCategory

    // MARK: - Initializer

    init(category: LogCategory) {
        self.category = category
        let subsystem = Bundle.main.bundleIdentifier ?? "com.kumatomo"
        logger = Logger(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Static Instances (カテゴリ別アクセス)

    static let network = AppLogger(category: .network)
    static let auth = AppLogger(category: .auth)
    static let debug = AppLogger(category: .debug)
    static let ui = AppLogger(category: .ui)
    static let cache = AppLogger(category: .cache)

    // MARK: - Log Methods

    /// デバッグログ（DEBUGビルドのみ出力）
    func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        let msg = message()
        logger.debug("\(msg)")
        #endif
    }

    /// 情報ログ
    func info(_ message: String) {
        logger.info("\(message)")
    }

    /// 通知ログ
    func notice(_ message: String) {
        logger.notice("\(message)")
    }

    /// 警告ログ
    func warning(_ message: String) {
        logger.warning("\(message)")
    }

    /// エラーログ
    func error(_ message: String) {
        logger.error("\(message)")
    }

    /// 致命的エラーログ
    func fault(_ message: String) {
        logger.fault("\(message)")
    }

    // MARK: - Network Logging

    /// APIリクエストのログ
    func logRequest(method: String, url: String, body: [String: Any]? = nil) {
        #if DEBUG
        var log = "📡 \(method) \(url)"
        if let body {
            log += " | body: \(body)"
        }
        logger.debug("\(log)")
        #endif
    }

    /// APIレスポンスのログ
    func logResponse(statusCode: Int, url: String, body: String? = nil) {
        #if DEBUG
        var log = "📡 [\(statusCode)] \(url)"
        if let body {
            let truncated = String(body.prefix(500))
            log += " | response: \(truncated)"
        }
        logger.debug("\(log)")
        #endif
    }

    /// エラーログ（コンテキスト付き）
    func logError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? "\(error)" : "[\(context)] \(error)"
        logger.error("🚨 \(message)")
    }
}
