//import SwiftUI
//
//struct PortalCardGrid: View {
//    // MARK: - Properties
//    let cards: [PortalCardData]
//    
//    // MARK: - State
//    @StateObject private var networkMonitor = NetworkMonitor.shared
//    
//    // MARK: - Grid Configuration
//    // 3-column grid layout with flexible sizing and consistent spacing
//    private let columns = [
//        GridItem(.flexible(), spacing: 12),
//        GridItem(.flexible(), spacing: 12),
//        GridItem(.flexible(), spacing: 12)
//    ]
//    
//    // MARK: - Bodya
//    var body: some View {
//        Group {
//            if cards.isEmpty {
//                // Handle empty card state
//                emptyStateView
//            } else {
//                LazyVGrid(columns: columns, spacing: 16) {
//                    ForEach(cards) { card in
//                        PortalCard(cardData: card)
//                            .frame(maxWidth: .infinity)
//                            .aspectRatio(0.8, contentMode: .fit)
//                    }
//                }
//                .padding(.horizontal, 16)
//            }
//        }
//    }
//    
//    // MARK: - Empty State View
//    
//    /**
//     * Empty state view when no cards are available
//     */
//    private var emptyStateView: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "square.grid.3x2")
//                .font(.system(size: 48))
//                .foregroundColor(.gray)
//            
//            Text("サービスカードがありません")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Text("カードデータを設定してください")
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//        .frame(height: 200)
//        .frame(maxWidth: .infinity)
//        .background(Color.gray.opacity(0.1))
//        .cornerRadius(12)
//        .padding(.horizontal, 16)
//    }
//}
//
