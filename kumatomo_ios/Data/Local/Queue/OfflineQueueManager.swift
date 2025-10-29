import Foundation
import Combine
import UIKit

// MARK: - Offline Queue Manager for Profile Operations

@MainActor
class OfflineQueueManager: ObservableObject {
    static let shared = OfflineQueueManager()
    
    @Published var pendingOperations: [QueuedOperation] = []
    @Published var isProcessingQueue = false
    @Published var queueStatus: QueueStatus = .idle
    
    private let networkMonitor = NetworkMonitor.shared
    private let retryManager = RetryManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let maxQueueSize = 100
    private let persistenceKey = "OfflineQueue"
    
    private init() {
        loadPersistedQueue()
        setupNetworkMonitoring()
    }
    
    // MARK: - Queue Management
    
    /// Adds an operation to the offline queue
    func enqueueOperation(_ operation: QueuedOperation) {
        // Check if queue is full
        if pendingOperations.count >= maxQueueSize {
            print("⚠️ Offline queue is full, removing oldest operation")
            pendingOperations.removeFirst()
        }
        
        // Add operation to queue
        pendingOperations.append(operation)
        persistQueue()
        
        print("📝 Enqueued operation: \(operation.type.rawValue) - \(operation.id)")
        
        // Try to process immediately if online
        if networkMonitor.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Removes an operation from the queue
    func dequeueOperation(withId id: String) {
        pendingOperations.removeAll { $0.id == id }
        persistQueue()
    }
    
    /// Clears all pending operations
    func clearQueue() {
        pendingOperations.removeAll()
        persistQueue()
        queueStatus = .idle
    }
    
    /// Processes all pending operations when network becomes available
    func processQueue() async {
        guard networkMonitor.isConnected && !isProcessingQueue else {
            return
        }
        
        guard !pendingOperations.isEmpty else {
            queueStatus = .idle
            return
        }
        
        isProcessingQueue = true
        queueStatus = .processing
        
        print("🔄 Processing offline queue with \(pendingOperations.count) operations")
        
        var processedOperations: [String] = []
        var failedOperations: [QueuedOperation] = []
        
        for operation in pendingOperations {
            do {
                try await processOperation(operation)
                processedOperations.append(operation.id)
                print("✅ Successfully processed operation: \(operation.id)")
                
            } catch {
                print("❌ Failed to process operation \(operation.id): \(error)")
                
                // Update retry count and check if should retry
                var updatedOperation = operation
                updatedOperation.retryCount += 1
                updatedOperation.lastError = error
                updatedOperation.lastAttempt = Date()
                
                if updatedOperation.retryCount < updatedOperation.maxRetries {
                    failedOperations.append(updatedOperation)
                } else {
                    print("🚫 Operation \(operation.id) exceeded max retries, removing from queue")
                }
            }
        }
        
        // Update queue with failed operations that can be retried
        pendingOperations = failedOperations
        persistQueue()
        
        isProcessingQueue = false
        queueStatus = pendingOperations.isEmpty ? .idle : .waiting
        
        print("📊 Queue processing complete. Processed: \(processedOperations.count), Failed: \(failedOperations.count)")
    }
    
    // MARK: - Operation Processing
    
    private func processOperation(_ operation: QueuedOperation) async throws {
        switch operation.type {
        case .createProfile:
            try await processCreateProfile(operation)
        case .updateProfile:
            try await processUpdateProfile(operation)
        case .deleteProfile:
            try await processDeleteProfile(operation)
        case .uploadProfileImage:
            try await processUploadProfileImage(operation)
        case .uploadCoverImage:
            try await processUploadCoverImage(operation)
        }
    }
    
    private func processCreateProfile(_ operation: QueuedOperation) async throws {
        guard let userData = operation.data["user"] as? Data,
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            throw ProfileError.dataCorrupted
        }
        
        let userAPIService = UserAPIService()
        _ = try await userAPIService.createProfile(user)
    }
    
    private func processUpdateProfile(_ operation: QueuedOperation) async throws {
        guard let userData = operation.data["user"] as? Data,
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            throw ProfileError.dataCorrupted
        }
        
        let userAPIService = UserAPIService()
        _ = try await userAPIService.updateProfile(user)
    }
    
    private func processDeleteProfile(_ operation: QueuedOperation) async throws {
        guard let userIDData = operation.data["userID"],
              let userID = String(data: userIDData, encoding: .utf8) else {
            throw ProfileError.dataCorrupted
        }
        
        let userAPIService = UserAPIService()
        _ = try await userAPIService.deleteProfile(userID: userID)
    }
    
    private func processUploadProfileImage(_ operation: QueuedOperation) async throws {
        guard let imageData = operation.data["imageData"] as? Data,
              let image = UIImage(data: imageData) else {
            throw ProfileError.dataCorrupted
        }
        
        let imageUploadService = ImageUploadService()
        _ = try await imageUploadService.uploadProfileImage(image)
    }
    
    private func processUploadCoverImage(_ operation: QueuedOperation) async throws {
        guard let imageData = operation.data["imageData"] as? Data,
              let image = UIImage(data: imageData) else {
            throw ProfileError.dataCorrupted
        }
        
        let imageUploadService = ImageUploadService()
        _ = try await imageUploadService.uploadCoverImage(image)
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    Task { @MainActor in
                        await self?.processQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    private func persistQueue() {
        do {
            let data = try JSONEncoder().encode(pendingOperations)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("❌ Failed to persist offline queue: \(error)")
        }
    }
    
    private func loadPersistedQueue() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return
        }
        
        do {
            pendingOperations = try JSONDecoder().decode([QueuedOperation].self, from: data)
            print("📂 Loaded \(pendingOperations.count) operations from persisted queue")
        } catch {
            print("❌ Failed to load persisted queue: \(error)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: persistenceKey)
        }
    }
    
    // MARK: - Convenience Methods
    
    func enqueueProfileCreation(_ user: User) {
        guard let userData = try? JSONEncoder().encode(user) else {
            print("❌ Failed to encode user data for offline queue")
            return
        }
        
        let operation = QueuedOperation(
            type: .createProfile,
            data: ["user": userData],
            priority: .high
        )
        
        enqueueOperation(operation)
    }
    
    func enqueueProfileUpdate(_ user: User) {
        guard let userData = try? JSONEncoder().encode(user) else {
            print("❌ Failed to encode user data for offline queue")
            return
        }
        
        let operation = QueuedOperation(
            type: .updateProfile,
            data: ["user": userData],
            priority: .medium
        )
        
        enqueueOperation(operation)
    }
    
    func enqueueProfileDeletion(userID: String) {
        let operation = QueuedOperation(
            type: .deleteProfile,
            data: ["userID": userID.data(using: .utf8)!],
            priority: .high
        )
        
        enqueueOperation(operation)
    }
    
    func enqueueProfileImageUpload(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data for offline queue")
            return
        }
        
        let operation = QueuedOperation(
            type: .uploadProfileImage,
            data: ["imageData": imageData],
            priority: .medium
        )
        
        enqueueOperation(operation)
    }
    
    func enqueueCoverImageUpload(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data for offline queue")
            return
        }
        
        let operation = QueuedOperation(
            type: .uploadCoverImage,
            data: ["imageData": imageData],
            priority: .low
        )
        
        enqueueOperation(operation)
    }
    
    // MARK: - Queue Statistics
    
    func getQueueStatistics() -> QueueStatistics {
        let operationsByType = Dictionary(grouping: pendingOperations) { $0.type }
        let operationsByPriority = Dictionary(grouping: pendingOperations) { $0.priority }
        
        let oldestOperation = pendingOperations.min { $0.createdAt < $1.createdAt }
        let newestOperation = pendingOperations.max { $0.createdAt < $1.createdAt }
        
        return QueueStatistics(
            totalOperations: pendingOperations.count,
            operationsByType: operationsByType.mapValues { $0.count },
            operationsByPriority: operationsByPriority.mapValues { $0.count },
            oldestOperationAge: oldestOperation?.createdAt.timeIntervalSinceNow.magnitude,
            newestOperationAge: newestOperation?.createdAt.timeIntervalSinceNow.magnitude,
            averageRetryCount: pendingOperations.isEmpty ? 0 : Double(pendingOperations.map { $0.retryCount }.reduce(0, +)) / Double(pendingOperations.count)
        )
    }
}

// MARK: - Supporting Types

struct QueuedOperation: Codable, Identifiable {
    let id: String
    let type: OperationType
    let data: [String: Data]
    let priority: OperationPriority
    let createdAt: Date
    var retryCount: Int
    var maxRetries: Int
    var lastAttempt: Date?
    var lastError: Error?
    
    init(
        type: OperationType,
        data: [String: Data],
        priority: OperationPriority = .medium,
        maxRetries: Int = 3
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.data = data
        self.priority = priority
        self.createdAt = Date()
        self.retryCount = 0
        self.maxRetries = maxRetries
    }
    
    // Custom coding to handle Error type
    enum CodingKeys: String, CodingKey {
        case id, type, data, priority, createdAt, retryCount, maxRetries, lastAttempt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(OperationType.self, forKey: .type)
        data = try container.decode([String: Data].self, forKey: .data)
        priority = try container.decode(OperationPriority.self, forKey: .priority)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        maxRetries = try container.decode(Int.self, forKey: .maxRetries)
        lastAttempt = try container.decodeIfPresent(Date.self, forKey: .lastAttempt)
        lastError = nil // Cannot persist Error objects
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(data, forKey: .data)
        try container.encode(priority, forKey: .priority)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(maxRetries, forKey: .maxRetries)
        try container.encodeIfPresent(lastAttempt, forKey: .lastAttempt)
        // Skip lastError as it cannot be encoded
    }
}

enum OperationType: String, Codable, CaseIterable {
    case createProfile = "create_profile"
    case updateProfile = "update_profile"
    case deleteProfile = "delete_profile"
    case uploadProfileImage = "upload_profile_image"
    case uploadCoverImage = "upload_cover_image"
    
    var displayName: String {
        switch self {
        case .createProfile:
            return "プロフィール作成"
        case .updateProfile:
            return "プロフィール更新"
        case .deleteProfile:
            return "プロフィール削除"
        case .uploadProfileImage:
            return "プロフィール画像アップロード"
        case .uploadCoverImage:
            return "カバー画像アップロード"
        }
    }
}

enum OperationPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var sortOrder: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

enum QueueStatus: String, CaseIterable {
    case idle = "idle"
    case processing = "processing"
    case waiting = "waiting"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle:
            return "待機中"
        case .processing:
            return "処理中"
        case .waiting:
            return "接続待ち"
        case .error:
            return "エラー"
        }
    }
}

struct QueueStatistics {
    let totalOperations: Int
    let operationsByType: [OperationType: Int]
    let operationsByPriority: [OperationPriority: Int]
    let oldestOperationAge: TimeInterval?
    let newestOperationAge: TimeInterval?
    let averageRetryCount: Double
}

// MARK: - Extensions

extension OfflineQueueManager {
    /// Checks if a specific operation type is already queued
    func hasQueuedOperation(ofType type: OperationType) -> Bool {
        return pendingOperations.contains { $0.type == type }
    }
    
    /// Gets the count of operations for a specific type
    func getOperationCount(ofType type: OperationType) -> Int {
        return pendingOperations.filter { $0.type == type }.count
    }
    
    /// Removes all operations of a specific type
    func removeOperations(ofType type: OperationType) {
        pendingOperations.removeAll { $0.type == type }
        persistQueue()
    }
    
    /// Gets operations sorted by priority and creation date
    func getSortedOperations() -> [QueuedOperation] {
        return pendingOperations.sorted { lhs, rhs in
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder > rhs.priority.sortOrder
            }
            return lhs.createdAt < rhs.createdAt
        }
    }
}
