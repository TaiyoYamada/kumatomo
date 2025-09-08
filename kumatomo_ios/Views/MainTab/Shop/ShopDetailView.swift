import SwiftUI
import MapKit

struct ShopDetailView: View {
    let shop: Shop
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShopDetailViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 店舗画像（最適化された遅延読み込み）
                    AsyncImage(url: URL(string: shop.imageUrl ?? "")) { imagePhase in
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
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // 店舗名とジャンル
                        VStack(alignment: .leading, spacing: 8) {
                            Text(shop.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if let genre = shop.genre {
                                Text(genre)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.1))
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
                                    .foregroundColor(.pink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.pink.opacity(0.1))
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
                                    await viewModel.loadPosts(for: shop.id)
                                }
                            }
                        )
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
            .task {
                await viewModel.loadPosts(for: shop.id)
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
        guard let latitude = shop.latitude,
              let longitude = shop.longitude else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = shop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
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
                .foregroundColor(.pink)
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

#Preview {
    ShopDetailView(
        shop: Shop(
            id: 1,
            name: "サンプルカフェ",
            description: "美味しいコーヒーと手作りスイーツが楽しめる、落ち着いた雰囲気のカフェです。Wi-Fi完備で作業にも最適です。",
            address: "東京都渋谷区神南1-1-1",
            phone: "03-1234-5678",
            businessHours: "平日 8:00-20:00\n土日祝 9:00-21:00",
            genre: "カフェ",
            latitude: 35.6762,
            longitude: 139.6503,
            imageUrl: "https://example.com/cafe.jpg"
        )
    )
}