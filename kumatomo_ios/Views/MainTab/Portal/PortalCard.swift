import SwiftUI

struct PortalCardGrid: View {
    // MARK: - Properties
    let cards: [PortalCardData]
    
    // MARK: - State
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - Grid Configuration
    // 3-column grid layout with flexible sizing and consistent spacing
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // MARK: - Body
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(cards) { card in
                PortalCardView(cardData: card)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.8, contentMode: .fill)
            }
        }
        .padding(.horizontal, 15)
    }
}

// MARK: - Portal Card View

struct PortalCardView: View {
    // MARK: - Properties
    let cardData: PortalCardData
    
    // MARK: - State
    @State private var isPressed = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var imageLoadError = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - Body
    var body: some View {
        Button(action: handleCardTap) {
//            if PortalErrorHandler.shared.validateImageAsset(cardData.imageName,) {
//
//            Image(cardData.imageName)
//                    .resizable()
//                    .cornerRadius(8)
//                    .shadow(radius: 5)
//                    .scaleEffect(isPressed ? 0.95 : 1.0)
//                    .animation(.easeInOut(duration: 0.1), value: isPressed)
//                    .overlay(alignment: .topTrailing) {
//                        if !networkMonitor.isConnected {
//                            Image(systemName: "wifi.slash")
//                                .font(.caption2)
//                                .foregroundColor(.red)
//                                .padding(4)
//                        }
//                    }
                
            VStack(spacing: 12) {      // ← spacingを少し広げる
                Image(systemName: cardData.iconName)
                    .font(.system(size: 32))                   // ← アイコンを大きめに
                    .foregroundColor(.accentColor)
                    .padding(16)                               // ← 余白を広めに
                    .background(
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                    )
                
                Text(cardData.title)
                    .font(.footnote)                           // ← コンパクトに
                    .fontWeight(.semibold)                     // ← 太字で見やすく
                    .multilineTextAlignment(.center)
                    .lineLimit(2)                              // ← タイトル長すぎても崩れない
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)   // ← 中央揃え

                
                
                
//            } else {
//                // Placeholder for missing image assets
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color.gray.opacity(0.1))
//                    .overlay {
//                        Image(systemName: "photo")
//                            .font(.title3)
//                            .foregroundColor(.gray)
//                    }
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                    )
//            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        )

        .buttonStyle(PlainButtonStyle())
        .disabled(!networkMonitor.isConnected && !isValidURL)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions & Helpers
    
    /// Handles card tap action and URL opening
    private func handleCardTap() {
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
