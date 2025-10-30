import SwiftUI

struct PortalCardGrid: View {
    // MARK: - Properties
    let cards: [PortalCardData]
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    
    // MARK: - Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(cards) { card in
                    PortalCardView(cardData: card)
                        .frame(width: 100, height: 120)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}


struct PortalCardView: View {
    // MARK: - Properties
    let cardData: PortalCardData
    
    @State private var isPressed = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var imageLoadError = false
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    // MARK: - Body
    var body: some View {
        Button(action: handleCardTap) {
                
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: cardData.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.accentColor)
                }

                Text(cardData.title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 12)
        }

        .buttonStyle(PlainButtonStyle())
        .disabled(!networkMonitor.isConnected && !isValidURL)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.08)) { isPressed = pressing }
        }, perform: {})
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions & Helpers
    
    /// Handles card tap action and URL opening
    private func handleCardTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        PortalErrorHandler.shared.openURL(cardData.externalURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // URL opened successfully - no action needed
                    break
                    
                case .failure(let error):
                    showError(error.userFriendlyMessage)
                    PortalErrorHandler.shared.logError(error, "Portal card '\(cardData.title)' error")
                }
            }
        }
    }
    
    /// Shows an error alert with the specified message
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    /// Validates if the card's URL is properly formatted
    private var isValidURL: Bool {
        do {
            _ = try PortalErrorHandler.shared.validateURL(cardData.externalURL)
            return true
        } catch {
            return false
        }
    }
}
