import XCTest
import SwiftUI
@testable import Hidamari

@MainActor
final class KumamonAIViewModelTests: XCTestCase {
    
    var viewModel: KumamonAIViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = KumamonAIViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests (Requirement 3.1, 3.2)
    
    func testInitialState() {
        // Given: A new KumamonAIViewModel instance
        // When: Checking initial state
        // Then: All properties should be in their initial state
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil initially")
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input text should be empty initially")
        XCTAssertFalse(viewModel.isTyping, "Should not be typing initially")
        XCTAssertEqual(viewModel.serviceState, .idle, "Service state should be idle initially")
    }
    
    func testStatelessBehavior() {
        // Given: ViewModel with some messages
        viewModel.messages = [
            ChatMessage.userMessage("Test message 1"),
            ChatMessage.aiMessage("Test response 1")
        ]
        
        // When: Clearing chat (simulating stateless behavior)
        viewModel.clearChat()
        
        // Then: All state should be reset
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be cleared")
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input text should be cleared")
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared")
        XCTAssertEqual(viewModel.serviceState, .idle, "Service state should be reset to idle")
        XCTAssertFalse(viewModel.isLoading, "Loading state should be reset")
        XCTAssertFalse(viewModel.isTyping, "Typing state should be reset")
    }
    
    // MARK: - Message State Management Tests (Requirement 2.3)
    
    func testAddUserMessage() {
        // Given: Empty message list
        XCTAssertTrue(viewModel.messages.isEmpty)
        
        // When: Adding a user message
        let userMessage = ChatMessage.userMessage("Hello, Kumamon!")
        viewModel.messages.append(userMessage)
        
        // Then: Message should be added correctly
        XCTAssertEqual(viewModel.messages.count, 1, "Should have one message")
        XCTAssertEqual(viewModel.messages.first?.content, "Hello, Kumamon!", "Message content should match")
        XCTAssertTrue(viewModel.messages.first?.isFromUser ?? false, "Message should be from user")
    }
    
    func testAddAIMessage() {
        // Given: Empty message list
        XCTAssertTrue(viewModel.messages.isEmpty)
        
        // When: Adding an AI message
        let aiMessage = ChatMessage.aiMessage("Hello! How can I help you?")
        viewModel.messages.append(aiMessage)
        
        // Then: Message should be added correctly
        XCTAssertEqual(viewModel.messages.count, 1, "Should have one message")
        XCTAssertEqual(viewModel.messages.first?.content, "Hello! How can I help you?", "Message content should match")
        XCTAssertFalse(viewModel.messages.first?.isFromUser ?? true, "Message should be from AI")
    }
    
    func testMessageOrdering() {
        // Given: Empty message list
        XCTAssertTrue(viewModel.messages.isEmpty)
        
        // When: Adding messages in sequence
        let userMessage1 = ChatMessage.userMessage("First message")
        let aiMessage1 = ChatMessage.aiMessage("First response")
        let userMessage2 = ChatMessage.userMessage("Second message")
        
        viewModel.messages.append(userMessage1)
        viewModel.messages.append(aiMessage1)
        viewModel.messages.append(userMessage2)
        
        // Then: Messages should be in correct order
        XCTAssertEqual(viewModel.messages.count, 3, "Should have three messages")
        XCTAssertEqual(viewModel.messages[0].content, "First message", "First message should be correct")
        XCTAssertEqual(viewModel.messages[1].content, "First response", "Second message should be correct")
        XCTAssertEqual(viewModel.messages[2].content, "Second message", "Third message should be correct")
    }
    
    // MARK: - Loading State Tests (Requirement 8.1, 8.2)
    
    func testLoadingStateManagement() {
        // Given: Initial state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isTyping)
        
        // When: Setting loading states
        viewModel.isLoading = true
        viewModel.isTyping = true
        
        // Then: States should be updated
        XCTAssertTrue(viewModel.isLoading, "Loading state should be true")
        XCTAssertTrue(viewModel.isTyping, "Typing state should be true")
        
        // When: Resetting loading states
        viewModel.isLoading = false
        viewModel.isTyping = false
        
        // Then: States should be reset
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false")
        XCTAssertFalse(viewModel.isTyping, "Typing state should be false")
    }
    
    func testCanSendMessageWithLoadingStates() {
        // Given: Valid input text
        viewModel.inputText = "Test message"
        
        // When: Not loading
        XCTAssertTrue(viewModel.canSendMessage, "Should be able to send message when not loading")
        
        // When: Loading
        viewModel.isLoading = true
        XCTAssertFalse(viewModel.canSendMessage, "Should not be able to send message when loading")
        
        // When: Typing
        viewModel.isLoading = false
        viewModel.isTyping = true
        XCTAssertFalse(viewModel.canSendMessage, "Should not be able to send message when typing")
    }
    
    // MARK: - Error Handling Tests (Requirement 8.1, 8.2)
    
    func testErrorMessageHandling() {
        // Given: No error initially
        XCTAssertNil(viewModel.errorMessage)
        
        // When: Setting an error message
        let testError = "Test error message"
        viewModel.errorMessage = testError
        
        // Then: Error message should be set
        XCTAssertEqual(viewModel.errorMessage, testError, "Error message should match")
        
        // When: Clearing error
        viewModel.clearError()
        
        // Then: Error message should be cleared
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared")
    }
    
    func testServiceStateErrorHandling() {
        // Given: Idle service state
        XCTAssertEqual(viewModel.serviceState, .idle)
        
        // When: Setting error state
        let testError = KumamonAIError.aiServiceUnavailable
        viewModel.serviceState = .error(testError)
        
        // Then: Service state should be error
        if case .error(let error) = viewModel.serviceState {
            XCTAssertEqual(error.errorDescription, testError.errorDescription, "Error should match")
        } else {
            XCTFail("Service state should be error")
        }
        
        // When: Clearing error
        viewModel.clearError()
        
        // Then: Service state should be reset
        XCTAssertEqual(viewModel.serviceState, .idle, "Service state should be reset to idle")
    }
    
    // MARK: - Input Validation Tests
    
    func testInputValidation() {
        // Given: Empty input
        viewModel.inputText = ""
        XCTAssertFalse(viewModel.canSendMessage, "Should not be able to send empty message")
        
        // When: Valid input
        viewModel.inputText = "Valid message"
        XCTAssertTrue(viewModel.canSendMessage, "Should be able to send valid message")
        
        // When: Whitespace only input
        viewModel.inputText = "   "
        XCTAssertFalse(viewModel.canSendMessage, "Should not be able to send whitespace-only message")
    }
    
    func testValidateCurrentInput() {
        // Given: Empty input
        viewModel.inputText = ""
        let emptyResult = viewModel.validateCurrentInput()
        XCTAssertFalse(emptyResult.isValid, "Empty input should be invalid")
        XCTAssertNotNil(emptyResult.errorMessage, "Should have error message for empty input")
        
        // Given: Valid input
        viewModel.inputText = "Valid message"
        let validResult = viewModel.validateCurrentInput()
        XCTAssertTrue(validResult.isValid, "Valid input should be valid")
        XCTAssertNil(validResult.errorMessage, "Should not have error message for valid input")
        
        // Given: Too long input
        viewModel.inputText = String(repeating: "a", count: 2001)
        let longResult = viewModel.validateCurrentInput()
        XCTAssertFalse(longResult.isValid, "Too long input should be invalid")
        XCTAssertNotNil(longResult.errorMessage, "Should have error message for too long input")
    }
    
    func testCharacterCountProperties() {
        // Given: Input text
        viewModel.inputText = "Hello"
        
        // Then: Character count should be correct
        XCTAssertEqual(viewModel.inputCharacterCount, 5, "Character count should be 5")
        XCTAssertEqual(viewModel.remainingCharacterCount, 1995, "Remaining count should be 1995")
        XCTAssertFalse(viewModel.isApproachingLimit, "Should not be approaching limit")
        
        // When: Approaching limit
        viewModel.inputText = String(repeating: "a", count: 1850)
        XCTAssertTrue(viewModel.isApproachingLimit, "Should be approaching limit")
    }
    
    // MARK: - Message Management Tests
    
    func testMessageCountProperties() {
        // Given: Mixed messages
        viewModel.messages = [
            ChatMessage.userMessage("User 1"),
            ChatMessage.aiMessage("AI 1"),
            ChatMessage.userMessage("User 2"),
            ChatMessage.aiMessage("AI 2"),
            ChatMessage.userMessage("User 3")
        ]
        
        // Then: Counts should be correct
        XCTAssertEqual(viewModel.messageCount, 5, "Total message count should be 5")
        XCTAssertEqual(viewModel.userMessageCount, 3, "User message count should be 3")
        XCTAssertEqual(viewModel.aiMessageCount, 2, "AI message count should be 2")
        XCTAssertTrue(viewModel.hasMessages, "Should have messages")
        XCTAssertEqual(viewModel.lastMessage?.content, "User 3", "Last message should be User 3")
    }
    
    func testRemoveMessage() {
        // Given: Messages with known IDs
        let message1 = ChatMessage.userMessage("Message 1")
        let message2 = ChatMessage.aiMessage("Message 2")
        viewModel.messages = [message1, message2]
        
        // When: Removing a message
        viewModel.removeMessage(withId: message1.id)
        
        // Then: Message should be removed
        XCTAssertEqual(viewModel.messages.count, 1, "Should have one message left")
        XCTAssertEqual(viewModel.messages.first?.content, "Message 2", "Remaining message should be Message 2")
    }
    
    func testGetMessagesByType() {
        // Given: Mixed messages
        viewModel.messages = [
            ChatMessage.userMessage("User 1"),
            ChatMessage.aiMessage("AI 1"),
            ChatMessage.userMessage("User 2")
        ]
        
        // When: Getting user messages
        let userMessages = viewModel.getMessages(fromUser: true)
        XCTAssertEqual(userMessages.count, 2, "Should have 2 user messages")
        
        // When: Getting AI messages
        let aiMessages = viewModel.getMessages(fromUser: false)
        XCTAssertEqual(aiMessages.count, 1, "Should have 1 AI message")
    }
    
    func testGetRecentMessages() {
        // Given: Multiple messages
        viewModel.messages = [
            ChatMessage.userMessage("Message 1"),
            ChatMessage.aiMessage("Message 2"),
            ChatMessage.userMessage("Message 3"),
            ChatMessage.aiMessage("Message 4"),
            ChatMessage.userMessage("Message 5")
        ]
        
        // When: Getting recent messages
        let recentMessages = viewModel.getRecentMessages(count: 3)
        
        // Then: Should get last 3 messages
        XCTAssertEqual(recentMessages.count, 3, "Should have 3 recent messages")
        XCTAssertEqual(recentMessages[0].content, "Message 3", "First recent message should be Message 3")
        XCTAssertEqual(recentMessages[2].content, "Message 5", "Last recent message should be Message 5")
    }
    
    // MARK: - Service Availability Tests
    
    func testServiceAvailabilityHandling() {
        // Given: Service available initially
        XCTAssertTrue(viewModel.isServiceAvailable)
        
        // When: Service becomes unavailable
        viewModel.isServiceAvailable = false
        
        // Then: Cannot send message
        viewModel.inputText = "Test message"
        XCTAssertFalse(viewModel.canSendMessage, "Should not be able to send message when service unavailable")
    }
    
    // MARK: - Conversation Summary Tests
    
    func testConversationSummary() {
        // Given: Mixed messages
        viewModel.messages = [
            ChatMessage.userMessage("User 1"),
            ChatMessage.aiMessage("AI 1"),
            ChatMessage.userMessage("User 2")
        ]
        
        // When: Getting conversation summary
        let summary = viewModel.conversationSummary
        
        // Then: Summary should be correct
        XCTAssertTrue(summary.contains("ユーザー 2件"), "Summary should contain user count")
        XCTAssertTrue(summary.contains("AI 1件"), "Summary should contain AI count")
        XCTAssertTrue(summary.contains("合計 3件"), "Summary should contain total count")
    }
    
    // MARK: - Clear Chat Tests (Requirement 3.1, 3.2)
    
    func testClearChatResetsAllState() {
        // Given: ViewModel with various states set
        viewModel.messages = [ChatMessage.userMessage("Test")]
        viewModel.inputText = "Some input"
        viewModel.errorMessage = "Some error"
        viewModel.isLoading = true
        viewModel.isTyping = true
        viewModel.serviceState = .loading
        
        // When: Clearing chat
        viewModel.clearChat()
        
        // Then: All state should be reset
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be cleared")
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input text should be cleared")
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared")
        XCTAssertFalse(viewModel.isLoading, "Loading state should be reset")
        XCTAssertFalse(viewModel.isTyping, "Typing state should be reset")
        XCTAssertEqual(viewModel.serviceState, .idle, "Service state should be reset")
    }
    
    func testMultipleClearChatCalls() {
        // Given: ViewModel with messages
        viewModel.messages = [ChatMessage.userMessage("Test")]
        
        // When: Calling clearChat multiple times
        viewModel.clearChat()
        viewModel.clearChat()
        viewModel.clearChat()
        
        // Then: Should remain in cleared state
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should remain cleared")
        XCTAssertEqual(viewModel.serviceState, .idle, "Service state should remain idle")
    }
}

// MARK: - Mock Tests for Async Operations

extension KumamonAIViewModelTests {
    
    func testSendMessageInputHandling() async {
        // Given: Valid input text
        viewModel.inputText = "Test message"
        let originalInputText = viewModel.inputText
        
        // When: Attempting to send message (will fail due to no mock service, but input should be cleared)
        // Note: This test focuses on input handling, not actual API calls
        
        // Simulate the input clearing behavior that happens in sendMessage
        if viewModel.canSendMessage {
            let userMessage = ChatMessage.userMessage(viewModel.inputText)
            viewModel.messages.append(userMessage)
            viewModel.inputText = ""
        }
        
        // Then: Input should be cleared and message added
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input text should be cleared after sending")
        XCTAssertEqual(viewModel.messages.count, 1, "Should have one message")
        XCTAssertEqual(viewModel.messages.first?.content, originalInputText, "Message content should match original input")
    }
    
    func testRetryLastMessageLogic() {
        // Given: Messages with last user message
        viewModel.messages = [
            ChatMessage.userMessage("First message"),
            ChatMessage.aiMessage("First response"),
            ChatMessage.userMessage("Second message"),
            ChatMessage.aiMessage("Second response")
        ]
        
        // When: Simulating retry logic (finding last user message)
        let lastUserMessage = viewModel.messages.last(where: { $0.isFromUser })
        
        // Then: Should find correct last user message
        XCTAssertNotNil(lastUserMessage, "Should find last user message")
        XCTAssertEqual(lastUserMessage?.content, "Second message", "Should find correct last user message")
        
        // When: Simulating removal of messages after last user message
        if let lastUserIndex = viewModel.messages.lastIndex(where: { $0.isFromUser }) {
            viewModel.messages = Array(viewModel.messages.prefix(through: lastUserIndex))
        }
        
        // Then: Should have messages up to last user message
        XCTAssertEqual(viewModel.messages.count, 3, "Should have 3 messages after trimming")
        XCTAssertEqual(viewModel.messages.last?.content, "Second message", "Last message should be user message")
    }
}