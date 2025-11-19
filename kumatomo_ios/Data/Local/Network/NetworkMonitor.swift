import Foundation
import Network
import Combine
import Observation

@MainActor
@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected = true
    var connectionType: ConnectionType = .unknown
    var isExpensive = false
    var isConstrained = false
    var connectionQuality: ConnectionQuality = .good
    var lastConnectedAt: Date?
    var connectionHistory: [ConnectionEvent] = []

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var connectionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryEntries = 100

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown

        var displayName: String {
            switch self {
            case .wifi:
                return "Wi-Fi"
            case .cellular:
                return "モバイル通信"
            case .ethernet:
                return "有線接続"
            case .unknown:
                return "不明"
            }
        }

        var isReliable: Bool {
            switch self {
            case .wifi, .ethernet:
                return true
            case .cellular, .unknown:
                return false
            }
        }
    }

    enum ConnectionQuality {
        case excellent
        case good
        case poor
        case unavailable

        var displayName: String {
            switch self {
            case .excellent:
                return "優秀"
            case .good:
                return "良好"
            case .poor:
                return "不安定"
            case .unavailable:
                return "利用不可"
            }
        }

        var color: String {
            switch self {
            case .excellent:
                return "green"
            case .good:
                return "blue"
            case .poor:
                return "orange"
            case .unavailable:
                return "red"
            }
        }
    }

    struct ConnectionEvent {
        let id = UUID()
        let timestamp: Date
        let type: ConnectionEventType
        let connectionType: ConnectionType
        let quality: ConnectionQuality
        let duration: TimeInterval?

        enum ConnectionEventType {
            case connected
            case disconnected
            case qualityChanged
            case typeChanged
        }
    }

    private init() {
        startMonitoring()
        setupQualityMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    nonisolated private func stopMonitoring() {
        monitor.cancel()
    }

    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        let previousType = connectionType
        let previousQuality = connectionQuality

        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        let newConnectionType: ConnectionType
        if path.usesInterfaceType(.wifi) {
            newConnectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            newConnectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            newConnectionType = .ethernet
        } else {
            newConnectionType = .unknown
        }

        let newQuality = calculateConnectionQuality(path: path)

        if !wasConnected && isConnected {
            connectionStartTime = Date()
            lastConnectedAt = Date()
            addConnectionEvent(.connected, type: newConnectionType, quality: newQuality)
        } else if wasConnected && !isConnected {
            let duration = connectionStartTime.map { Date().timeIntervalSince($0) }
            addConnectionEvent(.disconnected, type: previousType, quality: .unavailable, duration: duration)
            connectionStartTime = nil
        } else if isConnected {
            if previousType != newConnectionType {
                addConnectionEvent(.typeChanged, type: newConnectionType, quality: newQuality)
            } else if previousQuality != newQuality {
                addConnectionEvent(.qualityChanged, type: newConnectionType, quality: newQuality)
            }
        }

        connectionType = newConnectionType
        connectionQuality = newQuality

        print("Network status changed: Connected=\(isConnected), Type=\(connectionType.displayName), Quality=\(connectionQuality.displayName), Expensive=\(isExpensive), Constrained=\(isConstrained)")

        NotificationCenter.default.post(
            name: .NetworkConnectivityChanged,
            object: self,
            userInfo: [
                "isConnected": isConnected,
                "connectionType": newConnectionType,
                "isExpensive": isExpensive,
                "isConstrained": isConstrained
            ]
        )
    }

    private func calculateConnectionQuality(path: NWPath) -> ConnectionQuality {
        if path.status != .satisfied {
            return .unavailable
        }

        var quality: ConnectionQuality

        switch connectionType {
        case .wifi, .ethernet:
            quality = isConstrained ? .good : .excellent
        case .cellular:
            quality = isExpensive || isConstrained ? .poor : .good
        case .unknown:
            quality = .poor
        }

        return quality
    }

    private func addConnectionEvent(
        _ eventType: ConnectionEvent.ConnectionEventType,
        type: ConnectionType,
        quality: ConnectionQuality,
        duration: TimeInterval? = nil
    ) {
        let event = ConnectionEvent(
            timestamp: Date(),
            type: eventType,
            connectionType: type,
            quality: quality,
            duration: duration
        )

        connectionHistory.insert(event, at: 0)

        if connectionHistory.count > maxHistoryEntries {
            connectionHistory = Array(connectionHistory.prefix(maxHistoryEntries))
        }
    }

    private func setupQualityMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performQualityCheck()
            }
            .store(in: &cancellables)
    }

    private func performQualityCheck() {
        guard isConnected else { return }


        let currentPath = monitor.currentPath
        let newQuality = calculateConnectionQuality(path: currentPath)

        if newQuality != connectionQuality {
            connectionQuality = newQuality
            addConnectionEvent(.qualityChanged, type: connectionType, quality: newQuality)
        }
    }


    func checkConnectivity() -> Bool {
        return isConnected
    }

    func getConnectionInfo() -> (isConnected: Bool, type: ConnectionType, isExpensive: Bool, isConstrained: Bool) {
        return (isConnected, connectionType, isExpensive, isConstrained)
    }

    func shouldShowOfflineMessage() -> Bool {
        return !isConnected
    }

    func shouldLimitDataUsage() -> Bool {
        return isExpensive || isConstrained
    }

    func getNetworkStatusMessage() -> String {
        if !isConnected {
            return "インターネット接続がありません"
        }

        var message = "\(connectionType.displayName)で接続中"

        if isExpensive {
            message += "（従量制課金）"
        }

        if isConstrained {
            message += "（制限あり）"
        }

        return message
    }
}

extension Notification.Name {
    static let NetworkConnectivityChanged = Notification.Name("NetworkConnectivityChanged")
}


extension NetworkMonitor {
    func isNetworkError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .timedOut:
                return true
            default:
                return false
            }
        }
        return false
    }

    func getNetworkErrorMessage(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "インターネット接続がありません"
            case .networkConnectionLost:
                return "ネットワーク接続が失われました"
            case .dataNotAllowed:
                return "データ通信が許可されていません"
            case .cannotConnectToHost:
                return "サーバーに接続できません"
            case .cannotFindHost:
                return "サーバーが見つかりません"
            case .dnsLookupFailed:
                return "DNS解決に失敗しました"
            case .timedOut:
                return "接続がタイムアウトしました"
            default:
                return "ネットワークエラーが発生しました"
            }
        }
        return "ネットワークエラーが発生しました"
    }

    func shouldRetryNetworkRequest(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .networkConnectionLost,
                 .cannotConnectToHost:
                return true
            case .notConnectedToInternet,
                 .dataNotAllowed:
                return false
            default:
                return false
            }
        }
        return false
    }

    func getRetryDelay(for error: Error, attempt: Int) -> TimeInterval {
        let baseDelay: TimeInterval = 2.0
        let maxDelay: TimeInterval = 30.0

        let delay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
        let jitter = Double.random(in: 0...1)

        return delay + jitter
    }


    func performNetworkDiagnostics() async -> NetworkDiagnostics {
        let startTime = Date()

        let connectivityResult = await testConnectivity()

        let dnsResult = await testDNSResolution()

        let serverResult = await testServerReachability()

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)

        return NetworkDiagnostics(
            isConnected: isConnected,
            connectionType: connectionType,
            connectionQuality: connectionQuality,
            isExpensive: isExpensive,
            isConstrained: isConstrained,
            connectivityTest: connectivityResult,
            dnsTest: dnsResult,
            serverTest: serverResult,
            totalDiagnosticTime: totalTime,
            timestamp: Date()
        )
    }

    private func testConnectivity() async -> DiagnosticResult {
        guard isConnected else {
            return DiagnosticResult(
                success: false,
                message: "デバイスがネットワークに接続されていません",
                responseTime: 0,
                error: "No network connection"
            )
        }

        let startTime = Date()

        do {
            let url = URL(string: "https://www.google.com")!
            let request = URLRequest(url: url, timeoutInterval: 5.0)
            let (_, response) = try await URLSession.shared.data(for: request)

            let responseTime = Date().timeIntervalSince(startTime)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                return DiagnosticResult(
                    success: true,
                    message: "インターネット接続は正常です",
                    responseTime: responseTime,
                    error: nil
                )
            } else {
                return DiagnosticResult(
                    success: false,
                    message: "インターネット接続に問題があります",
                    responseTime: responseTime,
                    error: "Invalid response"
                )
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            return DiagnosticResult(
                success: false,
                message: "インターネット接続テストに失敗しました",
                responseTime: responseTime,
                error: error.localizedDescription
            )
        }
    }

    private func testDNSResolution() async -> DiagnosticResult {
        let startTime = Date()

        do {
            let host = "api.example.com"
            let url = URL(string: "https://\(host)")!
            let request = URLRequest(url: url, timeoutInterval: 3.0)

            _ = try await URLSession.shared.data(for: request)

            let responseTime = Date().timeIntervalSince(startTime)
            return DiagnosticResult(
                success: true,
                message: "DNS解決は正常です",
                responseTime: responseTime,
                error: nil
            )
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            return DiagnosticResult(
                success: false,
                message: "DNS解決に失敗しました",
                responseTime: responseTime,
                error: error.localizedDescription
            )
        }
    }

    private func testServerReachability() async -> DiagnosticResult {
        let startTime = Date()

        do {
            let baseURL = APIConfig.shared.baseURLString
            let healthURL = URL(string: "\(baseURL)/health")!
            let request = URLRequest(url: healthURL, timeoutInterval: 10.0)

            let (_, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)

            if let httpResponse = response as? HTTPURLResponse,
               200...299 ~= httpResponse.statusCode {
                return DiagnosticResult(
                    success: true,
                    message: "APIサーバーは正常です",
                    responseTime: responseTime,
                    error: nil
                )
            } else {
                return DiagnosticResult(
                    success: false,
                    message: "APIサーバーに問題があります",
                    responseTime: responseTime,
                    error: "Server returned error status"
                )
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            return DiagnosticResult(
                success: false,
                message: "APIサーバーに接続できません",
                responseTime: responseTime,
                error: error.localizedDescription
            )
        }
    }
}


struct NetworkDiagnostics {
    let isConnected: Bool
    let connectionType: NetworkMonitor.ConnectionType
    let connectionQuality: NetworkMonitor.ConnectionQuality
    let isExpensive: Bool
    let isConstrained: Bool
    let connectivityTest: DiagnosticResult
    let dnsTest: DiagnosticResult
    let serverTest: DiagnosticResult
    let totalDiagnosticTime: TimeInterval
    let timestamp: Date

    var overallHealth: NetworkHealth {
        if !isConnected {
            return .offline
        }

        let allTestsPassed = connectivityTest.success && dnsTest.success && serverTest.success

        if allTestsPassed {
            return connectionQuality == .excellent ? .excellent : .good
        } else if connectivityTest.success {
            return .degraded
        } else {
            return .poor
        }
    }

    var recommendations: [String] {
        var suggestions: [String] = []

        if !isConnected {
            suggestions.append("ネットワーク接続を確認してください")
        }

        if isExpensive {
            suggestions.append("従量制課金接続を使用中です。データ使用量にご注意ください")
        }

        if isConstrained {
            suggestions.append("制限された接続を使用中です。一部機能が制限される場合があります")
        }

        if !connectivityTest.success {
            suggestions.append("インターネット接続に問題があります")
        }

        if !dnsTest.success {
            suggestions.append("DNS設定を確認してください")
        }

        if !serverTest.success {
            suggestions.append("APIサーバーが利用できません。しばらく時間をおいてから再試行してください")
        }

        return suggestions
    }
}

struct DiagnosticResult {
    let success: Bool
    let message: String
    let responseTime: TimeInterval
    let error: String?
}

enum NetworkHealth {
    case excellent
    case good
    case degraded
    case poor
    case offline

    var displayName: String {
        switch self {
        case .excellent:
            return "優秀"
        case .good:
            return "良好"
        case .degraded:
            return "低下"
        case .poor:
            return "不良"
        case .offline:
            return "オフライン"
        }
    }

    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .degraded:
            return "orange"
        case .poor:
            return "red"
        case .offline:
            return "gray"
        }
    }
}
