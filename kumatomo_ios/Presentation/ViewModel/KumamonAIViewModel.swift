import Foundation
import SwiftUI
import Combine
import Resolver
import Observation

@MainActor
@Observable
final class KumamonAIViewModel {

    var messages: [ChatMessage] = []

    var isLoading: Bool = false

    var errorMessage: String?

    var isTyping: Bool = false

    var serviceState: AIServiceState = .idle

    var isServiceAvailable: Bool = true


    @ObservationIgnored @Injected var aiService: KumamonAIService
    private var cancellables = Set<AnyCancellable>()
    private var inputDebounceTask: Task<Void, Never>?


    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading &&
        !isTyping &&
        isServiceAvailable
    }

    var sanitizedInputText: String {
        aiService.sanitizeMessage(inputText)
    }


    var isInputValid: Bool {
        aiService.isValidMessage(inputText)
    }


    init() {
        setupSubscribers()
        checkServiceAvailability()
    }


    private func setupSubscribers() {
    }

    var inputText: String = "" {
        didSet {
            inputDebounceTask?.cancel()
            let current = inputText
            inputDebounceTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    self?.validateInput(current)
                }
            }
        }
    }
    private func validateInput(_ text: String) {
        if aiService.isValidMessage(text) && errorMessage != nil {
            errorMessage = nil
        }
    }


    func sendMessage(_ message: String? = nil) async {
        print("[KumamonAIViewModel] sendMessage invoked. input length=\(inputText.count)")
        let messageToSend = message ?? inputText
        let sanitizedMessage = aiService.sanitizeMessage(messageToSend)

        guard aiService.isValidMessage(sanitizedMessage) else {
            errorMessage = "有効なメッセージを入力してください"
            return
        }

        guard !isLoading && !isTyping else {
            return
        }

        errorMessage = nil

        let userMessage = ChatMessage.userMessage(sanitizedMessage)
        messages.append(userMessage)

        inputText = ""

        isLoading = true
        isTyping = true
        serviceState = .loading

        do {
            print("[KumamonAIViewModel] calling service.sendMessage")
            let response = try await aiService.sendMessage(sanitizedMessage)
            print("[KumamonAIViewModel] got response")

            let aiMessage = ChatMessage.aiMessage(response.message)
            messages.append(aiMessage)

            serviceState = .success

            print("✅ AI応答成功: \(response.message)")

        } catch let error as KumamonAIError {
            if !APIConfig.shared.isConfigured || ( { if case .aiServiceUnavailable = error { return true } else { return false } }() ) {
                let mockResponse = generateMockResponse(for: sanitizedMessage)
                let aiMessage = ChatMessage.aiMessage(mockResponse)
                messages.append(aiMessage)
                serviceState = .success
                print("🔧 モック応答を使用: \(mockResponse)")
            } else {
                await handleKumamonAIError(error)
            }
        } catch {
            print("[KumamonAIViewModel] sendMessage error -> \(error)")
            await handleGenericError(error)
        }

        isLoading = false
        isTyping = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if case .success = self.serviceState {
                self.serviceState = .idle
            }
        }
    }

    func clearChat() {
        messages.removeAll()
        inputText = ""
        errorMessage = nil
        serviceState = .idle
        isLoading = false
        isTyping = false

        print("🧹 チャット履歴をクリアしました")
    }

    func retryLastMessage() async {
        guard let lastUserMessage = messages.last(where: { $0.isFromUser }) else {
            errorMessage = "再送信するメッセージがありません"
            return
        }

        if let lastUserIndex = messages.lastIndex(where: { $0.isFromUser }) {
            messages = Array(messages.prefix(through: lastUserIndex))
        }

        await sendMessage(lastUserMessage.content)
    }

    func checkServiceAvailability() {
        print("[KumamonAIViewModel] checkServiceAvailability start")
        Task {
            let available = await aiService.checkServiceAvailability()
            await MainActor.run {
                self.isServiceAvailable = available
                print("[KumamonAIViewModel] checkServiceAvailability result=\(available)")
                if !available {
                    if APIConfig.shared.isConfigured {
                        self.errorMessage = "AIサービスが利用できません"
                        self.serviceState = .error(.aiServiceUnavailable)
                    } else {
                        self.isServiceAvailable = true
                        print("🔧 AI APIが未設定のため、モック応答を使用します")
                    }
                }
            }
        }
    }

    func refreshServiceAvailability() async {
        print("[KumamonAIViewModel] refreshServiceAvailability start")
        checkServiceAvailability()
    }


    private func handleKumamonAIError(_ error: KumamonAIError) async {
        errorMessage = error.errorDescription
        serviceState = .error(error)

        switch error {
        case .aiServiceUnavailable:
            isServiceAvailable = false
        case .unauthorized:
            break
        case .rateLimitExceeded:
            break
        default:
            break
        }

        print("🚨 KumamonAIError: \(error.errorDescription ?? "Unknown error")")

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

    func clearError() {
        errorMessage = nil
        if case .error = serviceState {
            serviceState = .idle
        }
    }


    var messageCount: Int {
        messages.count
    }

    var userMessageCount: Int {
        messages.filter { $0.isFromUser }.count
    }

    var aiMessageCount: Int {
        messages.filter { !$0.isFromUser }.count
    }

    var hasMessages: Bool {
        !messages.isEmpty
    }

    var lastMessage: ChatMessage? {
        messages.last
    }

    var conversationSummary: String {
        let userCount = userMessageCount
        let aiCount = aiMessageCount
        return "会話: ユーザー \(userCount)件, AI \(aiCount)件, 合計 \(messageCount)件"
    }


    private func generateMockResponse(for message: String) -> String {
        let mockResponses = [
            "こんにちは！くまモンだモン！何でも聞いてくださいモン！",
            "熊本のことなら何でも知ってるモン！お手伝いするモン！",
            "それは面白い質問だモン！熊本には素晴らしい場所がたくさんあるモン！",
            "くまモンがお答えするモン！熊本城や阿蘇山はとても有名だモン！",
            "熊本の美味しい食べ物といえば、馬刺しや熊本ラーメンがおすすめだモン！",
            "水前寺成趣園や阿蘇ファームランドも素敵な場所だモン！",
            "熊本の方言で「だっこん」は「とても」という意味だモン！",
            "くまモンは熊本県のPRキャラクターだモン！みんなに愛されて嬉しいモン！"
        ]

        // メッセージの内容に基づいて適切な応答を選択
        let lowercaseMessage = message.lowercased()

        if lowercaseMessage.contains("こんにちは") || lowercaseMessage.contains("はじめまして") {
            return mockResponses[0]
        } else if lowercaseMessage.contains("熊本") || lowercaseMessage.contains("観光") {
            return mockResponses[2]
        } else if lowercaseMessage.contains("食べ物") || lowercaseMessage.contains("グルメ") {
            return mockResponses[4]
        } else if lowercaseMessage.contains("場所") || lowercaseMessage.contains("スポット") {
            return mockResponses[5]
        } else {
            return mockResponses.randomElement() ?? mockResponses[1]
        }
    }
}


extension KumamonAIViewModel {

    func removeMessage(withId messageId: UUID) {
        messages.removeAll { $0.id == messageId }
    }

    func getMessages(fromUser isFromUser: Bool) -> [ChatMessage] {
        messages.filter { $0.isFromUser == isFromUser }
    }

    func getRecentMessages(count: Int) -> [ChatMessage] {
        Array(messages.suffix(count))
    }
}


extension KumamonAIViewModel {

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

    var inputCharacterCount: Int {
        inputText.count
    }

    var remainingCharacterCount: Int {
        max(0, 2000 - inputCharacterCount)
    }

    var isApproachingLimit: Bool {
        inputCharacterCount > 1800
    }
}
