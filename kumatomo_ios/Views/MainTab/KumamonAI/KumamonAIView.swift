import SwiftUI

struct KumamonAIView: View {
    @StateObject private var viewModel = KumamonAIViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages Area
                chatMessagesView
                
                // Input Area
                messageInputView
            }
            .navigationTitle("くまモンAI")
            .navigationBarTitleDisplayMode(.inline)
            .sidebarButton()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
        }
        .onAppear {
            viewModel.checkServiceAvailability()
        }
    }
    
    // MARK: - Chat Messages View
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    
                    // Typing indicator
                    if viewModel.isTyping {
                        TypingIndicatorView()
                            .id("typing")
                    }
                    
                    // Bottom spacer for proper scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if viewModel.isTyping {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isTyping) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if viewModel.isTyping {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input View
    
    private var messageInputView: some View {
        VStack(spacing: 8) {
            // Error message
            if let errorMessage = viewModel.errorMessage {
                ErrorMessageView(
                    message: errorMessage,
                    onRetry: {
                        Task {
                            await viewModel.retryLastMessage()
                        }
                    },
                    onDismiss: {
                        viewModel.clearError()
                    }
                )
            }
            
            // Service unavailable warning
            if !viewModel.isServiceAvailable {
                ServiceUnavailableView {
                    Task {
                        await viewModel.refreshServiceAvailability()
                    }
                }
            }
            
            // Input field and send button
            HStack(alignment: .bottom, spacing: 12) {
                // Text input
                VStack(alignment: .leading, spacing: 4) {
                    TextField("メッセージを入力...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isInputFocused)
                        .lineLimit(1...6)
                        .onSubmit {
                            if viewModel.canSendMessage {
                                sendMessage()
                            }
                        }
                    
                    // Character count
                    if viewModel.inputCharacterCount > 0 {
                        HStack {
                            Spacer()
                            Text("\(viewModel.inputCharacterCount)/2000")
                                .font(.caption2)
                                .foregroundColor(viewModel.isApproachingLimit ? .orange : .secondary)
                        }
                    }
                }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.canSendMessage ? .orange : .gray)
                }
                .disabled(!viewModel.canSendMessage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
//        .overlay(
//            Rectangle()
//                .frame(height: 0.5)
//                .foregroundColor(Color(.separator)),
//            alignment: .top
//        )
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("くまモンAI")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("何でも聞いてください！\nくまモンがお答えします。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Clear Button
    
    private var clearButton: some View {
        Button("クリア") {
            viewModel.clearChat()
        }
        .disabled(viewModel.messages.isEmpty)
        .accessibilityLabel("チャットクリア")
        .accessibilityHint("すべてのメッセージを削除します")
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        isInputFocused = false
        Task {
            await viewModel.sendMessage()
        }
    }
    

}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                userMessageBubble
            } else {
                aiMessageBubble
                Spacer(minLength: 60)
            }
        }
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel("あなたのメッセージ: \(message.content)")
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
                .accessibilityLabel("送信時刻: \(formatTime(message.timestamp))")
        }
    }
    
    private var aiMessageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // Kumamon avatar
                Image(systemName: "bear.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .accessibilityLabel("くまモンの返答: \(message.content)")
            }
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 32)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: 8) {
                // Kumamon avatar
                Image(systemName: "bear.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animationPhase
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            Spacer(minLength: 60)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button("再試行", action: onRetry)
                .font(.caption)
                .foregroundColor(.orange)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.orange.opacity(0.3)),
            alignment: .top
        )
    }
}

// MARK: - Service Unavailable View

struct ServiceUnavailableView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.red)
            
            Text("AIサービスが利用できません")
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("再接続", action: onRefresh)
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.red.opacity(0.3)),
            alignment: .top
        )
    }
}
