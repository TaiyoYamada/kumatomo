import SwiftUI
import MapKit
import CoreLocation

struct ShopMapView: View {
    let shops: [Shop]
    let userLocation: CLLocation?
    let onShopSelected: (Shop) -> Void
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // Tokyo default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                ShopMapPin(
                    shop: annotation.shop,
                    onTap: { onShopSelected(annotation.shop) }
                )
            }
        }
        .onAppear {
            updateRegion()
        }
        .onChange(of: userLocation) { _ in
            updateRegion()
        }
    }
    
    private var mapAnnotations: [ShopMapAnnotation] {
        shops.compactMap { shop in
            guard let latitude = shop.latitude,
                  let longitude = shop.longitude else { return nil }
            
            return ShopMapAnnotation(
                shop: shop,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
    }
    
    private func updateRegion() {
        if let userLocation = userLocation {
            // ユーザーの現在地を中心にする
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        } else if !shops.isEmpty {
            // お店の位置を基に地域を設定
            let coordinates = shops.compactMap { shop -> CLLocationCoordinate2D? in
                guard let lat = shop.latitude, let lng = shop.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            if !coordinates.isEmpty {
                let center = calculateCenterCoordinate(coordinates: coordinates)
                region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
    
    private func calculateCenterCoordinate(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let totalLatitude = coordinates.reduce(0) { $0 + $1.latitude }
        let totalLongitude = coordinates.reduce(0) { $0 + $1.longitude }
        
        return CLLocationCoordinate2D(
            latitude: totalLatitude / Double(coordinates.count),
            longitude: totalLongitude / Double(coordinates.count)
        )
    }
}

// MARK: - Shop Map Annotation
struct ShopMapAnnotation: Identifiable {
    let id = UUID()
    let shop: Shop
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Shop Map Pin
struct ShopMapPin: View {
    let shop: Shop
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // ピンのアイコン
                ZStack {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "storefront")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                // お店名のラベル
                Text(shop.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ShopMapView(
        shops: [
            Shop(
                id: 1,
                name: "サンプルカフェ",
                description: "美味しいコーヒーが飲めるお店",
                address: "東京都渋谷区",
                genre: "カフェ",
                latitude: 35.6762,
                longitude: 139.6503
            ),
            Shop(
                id: 2,
                name: "イタリアンレストラン",
                description: "本格的なイタリア料理",
                address: "東京都新宿区",
                genre: "レストラン",
                latitude: 35.6896,
                longitude: 139.6917
            )
        ],
        userLocation: CLLocation(latitude: 35.6762, longitude: 139.6503),
        onShopSelected: { _ in }
    )
}