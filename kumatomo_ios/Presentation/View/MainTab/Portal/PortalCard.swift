import SwiftUI

// MARK: - PortalCardGrid

struct PortalCardGrid: View {
    let cards: [PortalCardData]
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(cards) { card in
                    PortalCardView(cardData: card)
                        .frame(width: 85) // 少し幅を調整
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - PortalCardView

struct PortalCardView: View {
    let cardData: PortalCardData

    @State private var isPressed = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        Button(action: handleCardTap) {
            VStack(spacing: 8) {
                // Circular Icon container
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    Image(systemName: cardData.iconName)
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(.accentColor)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isPressed)

                // Title
                Text(cardData.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 32, alignment: .top) // テキストエリアの高さを固定して揃える
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!networkMonitor.isConnected && !isValidURL)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .alert("エラー", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleCardTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        PortalErrorHandler.shared.openURL(cardData.externalURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: break
                case let .failure(error):
                    showError(error.userFriendlyMessage)
                    PortalErrorHandler.shared.logError(error, "Portal card '\(cardData.title)' error")
                }
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    private var isValidURL: Bool {
        (try? PortalErrorHandler.shared.validateURL(cardData.externalURL)) != nil
    }
}
