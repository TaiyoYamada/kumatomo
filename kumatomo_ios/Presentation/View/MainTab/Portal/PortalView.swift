import SwiftUI


struct PortalView: View {
    // MARK: - Environment Properties
    @Environment(\.openSidebar) private var openSidebar
    @EnvironmentObject private var userManager: CurrentUserManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - State Properties
    @State private var showingNetworkAlert = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
                LazyVStack(spacing: 24) {
                    VStack(spacing: 0) {
                        PortalAdvertisingSlideshow()
                    }
                    .padding(.top, 8)
                    
                    VStack(spacing: 10) {
                        // Section header
                        HStack {
                            Text("サービス一覧")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        // Cards grid component
                        PortalCardGrid(cards: samplePortalCards)
                    }
                    
                    VStack {
                        HStack {
                            Text("おすすめのお店")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        RecommendedShopCarouselView(shops: sampleShops)
                    }
                }
                .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ポータル")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ProfileIconButton(
                    user: userManager.currentUser,
                    action: { openSidebar() }
                )
            }
            
            // MARK: - Network Status Indicator
            // Shows network connectivity status in toolbar
            ToolbarItem(placement: .navigationBarTrailing) {
                if !networkMonitor.isConnected {
                    Button {
                        showingNetworkAlert = true
                    } label: {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("ネットワーク接続", isPresented: $showingNetworkAlert) {
            Button("OK") { }
        } message: {
            Text(networkMonitor.getNetworkStatusMessage())
        }
        .safeAreaInset(edge: .bottom) {
            // MARK: - Network Status Banner (safe area)
            // Insert banner in safe area so content isn't obscured
            if !networkMonitor.isConnected {
                networkStatusBanner
            } else {
                // Maintain a small, consistent bottom inset for spacing
                Color.clear.frame(height: 8)
            }
        }
    }
    
    // MARK: - Network Status Banner
    
    private var networkStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("オフライン")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("インターネット接続を確認してください")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button("設定") {
                // Open system settings for network configuration
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}
