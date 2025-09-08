import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
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
    }
    
    private init() {
        startMonitoring()
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
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
        
        // Log connection changes
        print("Network status changed: Connected=\(isConnected), Type=\(connectionType.displayName), Expensive=\(isExpensive), Constrained=\(isConstrained)")
    }
    
    // MARK: - Public Methods
    
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

// MARK: - Network Error Handling

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
        
        // Exponential backoff with jitter
        let delay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
        let jitter = Double.random(in: 0...1)
        
        return delay + jitter
    }
}