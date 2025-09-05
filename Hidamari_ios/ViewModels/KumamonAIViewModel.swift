import Foundation
import SwiftUI
import Combine

@MainActor
final class KumamonAIViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of chat messages in the conversation
    @Published var messages: [ChatMessage] = []
    
    /// Current loading state of the AI service
    @Published var isLoading: Bool = false
    
    /// Current error message, if any
    @Published var errorMessage: String?
    
    /// Current input text from the user
    @Published var inputText: String = ""
    
    /// Whether the AI is currently typing (for UI animation)
    @Published var isTyping: Bool = false
    
    /// Current service state for detailed UI feedback
    @Published var serviceState: AIServiceState = .idle
    
    /// Whether the service is available
    @Published var isServiceAvailable: Bool = true
    
    // MARK: - Private Properties
    
    private let aiService = KumamonAIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Whether the user can send a message
    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !isLoading && 
        !isTyping &&
        isServiceAvailable
    }
    
    /// Sanitized input text for validation
    var sanitizedInputText: String {
        aiService.sanitizeMessage(inputText)
    }
    
    /// Whether the current input is valid
    var isInputValid: Bool {
        aiService.isValidMessage(inputText)
    }
    
    // MARK: - Initialization
    
    init() {
        setupSubscribers()
        checkServiceAvailability()
    }
    
    // MARK: - Private Setup Methods
    
    private func setupSubscribers() {
        // Monitor input text changes for validation
        $inputText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.validateInput(text)
            }
            .store(in: &cancellables)
    }
    
    private func validateInput(_ text: String) {
        // Clear error if input becomes valid
        if aiService.isValidMessage(text) && errorMessage != nil {
            errorMessage = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Send a message to Kumamon AI
    /// - Parameter message: The message to send (optional, uses inputText if nil)
    func sendMessage(_ message: String? = nil) async {
        let messageToSend = message ?? inputText
        let sanitizedMessage = aiService.sanitizeMessage(messageToSend)
        
        // Validate message
        guard aiService.isValidMessage(sanitizedMessage) else {
            errorMessage = "有効なメッセージを入力してください"
            return
        }
        
        // Check if already processing
        guard !isLoading && !isTyping else {
            return
        }
        
        // Clear previous error
        errorMessage = nil
        
        // Add user message to chat
        let userMessage = ChatMessage.userMessage(sanitizedMessage)
        messages.append(userMessage)
        
        // Clear input text
        inputText = ""
        
        // Set loading states
        isLoading = true
        isTyping = true
        serviceState = .loading
        
        do {
            // Send message to AI service
            let response = try await aiService.sendMessage(sanitizedMessage)
            
            // Add AI response to chat
            let aiMessage = ChatMessage.aiMessage(response.message)
            messages.append(aiMessage)
            
            // Update service state
            serviceState = .success
            
            print("✅ AI応答成功: \(response.message)")
            
        } catch let error as KumamonAIError {
            await handleKumamonAIError(error)
        } catch {
            await handleGenericError(error)
        }
        
        // Reset loading states
        isLoading = false
        isTyping = false
        
        // Reset service state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if case .success = self.serviceState {
                self.serviceState = .idle
            }
        }
    }
    
    /// Clear all chat messages (stateless behavior)
    func clearChat() {
        messages.removeAll()
        inputText = ""
        errorMessage = nil
        serviceState = .idle
        isLoading = false
        isTyping = false
        
        print("🧹 チャット履歴をクリアしました")
    }
    
    /// Retry the last failed message
    func retryLastMessage() async {
        // Find the last user message
        guard let lastUserMessage = messages.last(where: { $0.isFromUser }) else {
            errorMessage = "再送信するメッセージがありません"
            return
        }
        
        // Remove any AI messages after the last user message
        if let lastUserIndex = messages.lastIndex(where: { $0.isFromUser }) {
            messages = Array(messages.prefix(through: lastUserIndex))
        }
        
        // Resend the message
        await sendMessage(lastUserMessage.content)
    }
    
    /// Check if the AI service is available
    func checkServiceAvailability() {
        Task {
            let available = await aiService.checkServiceAvailability()
            await MainActor.run {
                self.isServiceAvailable = available
                if !available {
                    self.errorMessage = "AIサービスが利用できません"
                    self.serviceState = .error(.aiServiceUnavailable)
                }
            }
        }
    }
    
    /// Refresh the service availability
    func refreshServiceAvailability() async {
        checkServiceAvailability()
    }
    
    // MARK: - Error Handling
    
    private func handleKumamonAIError(_ error: KumamonAIError) async {
        errorMessage = error.errorDescription
        serviceState = .error(error)
        
        // Handle specific error types
        switch error {
        case .aiServiceUnavailable:
            isServiceAvailable = false
        case .unauthorized:
            // Could trigger re-authentication flow
            break
        case .rateLimitExceeded:
            // Could implement retry with backoff
            break
        default:
            break
        }
        
        print("🚨 KumamonAIError: \(error.errorDescription ?? "Unknown error")")
        
        // Log detailed error information
        if let failureReason = error.failureReason {
            print("🔍 Failure reason: \(failureReason)")
        }
        
        if let recoverySuggestion = error.recoverySuggestion {
            print("💡 Recovery suggestion: \(recoverySuggestion)")
        }
    }
    
    private func handleGenericError(_ error: Error) async {
        let errorMsg = "予期しないエラーが発生しました: \(error.localizedDescription)"
        errorMessage = errorMsg
        serviceState = .error(.unknownError(error))
        
        print("🚨 Generic error: \(error.localizedDescription)")
    }
    
    /// Clear the current error message
    func clearError() {
        errorMessage = nil
        if case .error = serviceState {
            serviceState = .idle
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get the count of messages in the conversation
    var messageCount: Int {
        messages.count
    }
    
    /// Get the count of user messages
    var userMessageCount: Int {
        messages.filter { $0.isFromUser }.count
    }
    
    /// Get the count of AI messages
    var aiMessageCount: Int {
        messages.filter { !$0.isFromUser }.count
    }
    
    /// Check if the conversation has any messages
    var hasMessages: Bool {
        !messages.isEmpty
    }
    
    /// Get the last message in the conversation
    var lastMessage: ChatMessage? {
        messages.last
    }
    
    /// Get a formatted conversation summary for debugging
    var conversationSummary: String {
        let userCount = userMessageCount
        let aiCount = aiMessageCount
        return "会話: ユーザー \(userCount)件, AI \(aiCount)件, 合計 \(messageCount)件"
    }
}

// MARK: - Message Management Extensions

extension KumamonAIViewModel {
    
    /// Remove a specific message from the conversation
    /// - Parameter messageId: The ID of the message to remove
    func removeMessage(withId messageId: UUID) {
        messages.removeAll { $0.id == messageId }
    }
    
    /// Get messages filtered by sender type
    /// - Parameter isFromUser: Whether to get user messages (true) or AI messages (false)
    /// - Returns: Array of filtered messages
    func getMessages(fromUser isFromUser: Bool) -> [ChatMessage] {
        messages.filter { $0.isFromUser == isFromUser }
    }
    
    /// Get the most recent messages up to a specified count
    /// - Parameter count: Maximum number of messages to return
    /// - Returns: Array of recent messages
    func getRecentMessages(count: Int) -> [ChatMessage] {
        Array(messages.suffix(count))
    }
}

// MARK: - Input Validation Extensions

extension KumamonAIViewModel {
    
    /// Validate the current input text and return validation result
    /// - Returns: Validation result with error message if invalid
    func validateCurrentInput() -> (isValid: Bool, errorMessage: String?) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return (false, "メッセージを入力してください")
        }
        
        if trimmed.count > 2000 {
            return (false, "メッセージが長すぎます（最大2000文字）")
        }
        
        if !aiService.isValidMessage(trimmed) {
            return (false, "無効な文字が含まれています")
        }
        
        return (true, nil)
    }
    
    /// Get the character count of the current input
    var inputCharacterCount: Int {
        inputText.count
    }
    
    /// Get the remaining character count for input
    var remainingCharacterCount: Int {
        max(0, 2000 - inputCharacterCount)
    }
    
    /// Whether the input is approaching the character limit
    var isApproachingLimit: Bool {
        inputCharacterCount > 1800
    }
}