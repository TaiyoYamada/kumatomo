import SwiftUI
import Observation

struct PortalView: View {
    @Environment(\.openSidebar) private var openSidebar
    @Environment(CurrentUserManager.self) private var userManager
    @Environment(NetworkMonitor.self) private var networkMonitor

    @State private var viewModel = PortalViewModel()
    @State private var showingNetworkAlert = false
    @State private var showingAllAnnouncements = false
    @State private var selectedAnnouncement: Announcement?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Slideshow Section
                VStack(spacing: 0) {
                    PortalAdvertisingSlideshow()
                }
                .padding(.top, 8)

                // Services Section
                VStack(spacing: 16) {
                    HStack {
                        Text("サービス一覧")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    PortalCardGrid(cards: samplePortalCards)
                }

                // Announcements Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("運営からのお知らせ")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Spacer()

                        if !viewModel.recentAnnouncements.isEmpty {
                            Button {
                                showingAllAnnouncements = true
                            } label: {
                                Text("すべて見る")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if viewModel.recentAnnouncements.isEmpty {
                        // Empty State
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("お知らせはありません")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    } else {
                        // Announcement List (Summary)
                        VStack(spacing: 0) {
                            ForEach(viewModel.recentAnnouncements) { announcement in
                                NavigationLink(value: announcement) {
                                    PortalAnnouncementRow(announcement: announcement)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if announcement.id != viewModel.recentAnnouncements.last?.id {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("portal_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                ProfileIconButton(
                    user: userManager.currentUser,
                    action: { openSidebar() }
                )
            }

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
            Button("OK") {}
        } message: {
            Text(networkMonitor.getNetworkStatusMessage())
        }
        .safeAreaInset(edge: .bottom) {
            if !networkMonitor.isConnected {
                networkStatusBanner
            } else {
                Color.clear.frame(height: 8)
            }
        }
        .navigationDestination(isPresented: $showingAllAnnouncements) {
            AnnouncementListView(announcements: viewModel.announcements)
        }
        .navigationDestination(for: Announcement.self) { announcement in
            AnnouncementDetailView(announcement: announcement)
        }
        .task {
            await viewModel.loadAnnouncements()
        }
    }

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
