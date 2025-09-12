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
    @Published var connectionQuality: ConnectionQuality = .good
    @Published var lastConnectedAt: Date?
    @Published var connectionHistory: [ConnectionEvent] = []
    
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
        
        // Determine connection type
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
        
        // Update connection quality
        let newQuality = calculateConnectionQuality(path: path)
        
        // Record connection events
        if !wasConnected && isConnected {
            // Connection established
            connectionStartTime = Date()
            lastConnectedAt = Date()
            addConnectionEvent(.connected, type: newConnectionType, quality: newQuality)
        } else if wasConnected && !isConnected {
            // Connection lost
            let duration = connectionStartTime.map { Date().timeIntervalSince($0) }
            addConnectionEvent(.disconnected, type: previousType, quality: .unavailable, duration: duration)
            connectionStartTime = nil
        } else if isConnected {
            // Connection type or quality changed
            if previousType != newConnectionType {
                addConnectionEvent(.typeChanged, type: newConnectionType, quality: newQuality)
            } else if previousQuality != newQuality {
                addConnectionEvent(.qualityChanged, type: newConnectionType, quality: newQuality)
            }
        }
        
        connectionType = newConnectionType
        connectionQuality = newQuality
        
        // Log connection changes
        print("Network status changed: Connected=\(isConnected), Type=\(connectionType.displayName), Quality=\(connectionQuality.displayName), Expensive=\(isExpensive), Constrained=\(isConstrained)")
    }
    
    private func calculateConnectionQuality(path: NWPath) -> ConnectionQuality {
        if path.status != .satisfied {
            return .unavailable
        }
        
        // Base quality on connection type and constraints
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
        // Monitor connection quality changes over time
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performQualityCheck()
            }
            .store(in: &cancellables)
    }
    
    private func performQualityCheck() {
        guard isConnected else { return }
        
        // In a real implementation, this could perform network speed tests
        // or ping tests to determine actual connection quality
        
        // For now, we'll update quality based on current constraints
        let currentPath = monitor.currentPath
        let newQuality = calculateConnectionQuality(path: currentPath)
        
        if newQuality != connectionQuality {
            connectionQuality = newQuality
            addConnectionEvent(.qualityChanged, type: connectionType, quality: newQuality)
        }
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
