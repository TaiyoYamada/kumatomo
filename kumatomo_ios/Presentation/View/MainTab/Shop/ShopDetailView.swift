import SwiftUI
import MapKit

struct ShopDetailView: View {
    let shopId: Int
    @State private var shop: Shop?
    @State private var isLoadingShop = false
    @State private var shopErrorMessage: String?
    @State private var viewModel = ShopDetailViewModel()
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let shop = shop {
                    // 店舗画像（最適化された遅延読み込み）
                    AsyncImage(url: ImageURLNormalizer.normalize(shop.imageUrl)) { imagePhase in
                        switch imagePhase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 250)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.secondary)
                                }
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 250)
                                .overlay {
                                    ProgressView()
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .onAppear {
                        #if DEBUG
                        ImageDebugLogger.logImage(shop.imageUrl, context: "ShopDetail:shopId=\(shop.id)")
                        #endif
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // 店舗名とジャンル
                        VStack(alignment: .leading, spacing: 8) {
                            Text(shop.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if let genre = shop.genre {
                                Text(genre.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // 説明
                        if let description = shop.description {
                            Text(description)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        
                        Divider()
                        
                        // 店舗情報
                        VStack(alignment: .leading, spacing: 12) {
                            Text("店舗情報")
                                .font(.system(size: 20, weight: .semibold))
                            
                            if let address = shop.address {
                                InfoRow(
                                    icon: "location",
                                    title: "住所",
                                    content: address
                                )
                            }
                            
                            if let phone = shop.phone {
                                InfoRow(
                                    icon: "phone",
                                    title: "電話番号",
                                    content: phone
                                )
                            }
                            
                            if let businessHours = shop.businessHours {
                                InfoRow(
                                    icon: "clock",
                                    title: "営業時間",
                                    content: businessHours
                                )
                            }
                        }
                        
                        // アクションボタン
                        VStack(spacing: 12) {
                            if let phone = shop.phone {
                                Button(action: {
                                    makePhoneCall(to: phone)
                                }) {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                        Text("電話をかける")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                }
                            }
                            
                            if shop.latitude != nil && shop.longitude != nil {
                                Button(action: openInMaps) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                        Text("マップで開く")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 投稿セクション
                        ShopPostsSection(
                            posts: viewModel.posts,
                            isLoading: viewModel.isLoading,
                            errorMessage: viewModel.errorMessage,
                            onRefresh: {
                                Task {
                                    await viewModel.loadPosts(for: shopId)
                                }
                            }
                        )
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    } else if isLoadingShop {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("店舗情報を読み込み中...")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let message = shopErrorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.primaryOrange)
                            Text(message)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Button("再試行") {
                                Task { await loadShop() }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.primaryOrange)
                            .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
//            .navigationTitle(shop?.name ?? "お店詳細")
//            .navigationBarTitleDisplayMode(.large)
            .task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await loadShop() }
                    group.addTask { await viewModel.loadPosts(for: shopId) }
                    await group.waitForAll()
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
    }
    
    private func makePhoneCall(to phoneNumber: String) {
        // 電話番号から不要な文字を除去
        let cleanedPhoneNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        if let url = URL(string: "tel:\(cleanedPhoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openInMaps() {
        guard let shop = shop,
              let latitude = shop.latitude,
              let longitude = shop.longitude else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = shop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    @MainActor
    private func loadShop() async {
        isLoadingShop = true
        shopErrorMessage = nil
        do {
            let fetched = try await ShopAPIService.shared.fetchShop(id: shopId)
            self.shop = fetched
        } catch {
            self.shopErrorMessage = error.localizedDescription
        }
        isLoadingShop = false
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.system(size: 16))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}
