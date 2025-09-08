import SwiftUI

/**
 * PortalView - Main Portal Screen (ポータル画面)
 * 
 * This view serves as the central hub for the portal tab, providing users with:
 * - Promotional content via an advertising slideshow
 * - Quick access to external link collection
 * - Grid of actionable service cards
 * 
 * Layout Structure:
 * 1. Advertising Slideshow (top section)
 * 2. Link Collection Button (middle section)
 * 3. Service Cards Grid (bottom section - 3x2 layout)
 * 
 * Navigation:
 * - Uses NavigationStack for consistent navigation behavior
 * - Integrates with existing sidebar functionality
 * - Maintains consistent toolbar styling with other screens
 * 
 * Requirements Fulfilled: 4.1, 4.2, 4.3, 4.4, 4.5
 */
struct PortalView: View {
    // MARK: - Environment Properties
    @Environment(\.openSidebar) private var openSidebar
    @EnvironmentObject private var userManager: CurrentUserManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - State Properties
    @State private var showingNetworkAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // MARK: - Advertising Slideshow Section
                    // Displays rotating promotional content at the top of the screen
                    // Requirements: 1.1, 1.2, 1.3, 1.4, 1.5
                    VStack(spacing: 0) {
                        PortalAdvertisingSlideshow()
                    }
                    .padding(.top, 8)
                    
                    // MARK: - Portal Cards Grid Section
                    // 3x2 grid of actionable service cards
                    // Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
                    VStack(spacing: 16) {
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
                    .padding(.top, 8)
                    
                    // Bottom spacing for better scroll experience
                    Spacer(minLength: 20)
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
            .overlay(alignment: .bottom) {
                // MARK: - Network Status Banner
                // Shows persistent network status banner when offline
                if !networkMonitor.isConnected {
                    networkStatusBanner
                }
            }
        }
    }
    
    // MARK: - Network Status Banner
    
    /**
     * Persistent network status banner shown at bottom when offline
     * Provides clear feedback about connectivity issues
     */
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

// MARK: - Preview

#Preview {
    PortalView()
        .environmentObject(CurrentUserManager.shared)
        .environment(\.openSidebar, {})
}
