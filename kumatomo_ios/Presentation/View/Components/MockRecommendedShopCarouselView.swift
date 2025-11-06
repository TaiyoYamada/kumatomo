import SwiftUI

struct ShopData: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let imageName: String
}

struct RecommendedShopCarouselView: View {
    let shops: [ShopData]

    private let cardWidth: CGFloat = 280
    private let spacing: CGFloat = 16
    private let rowHeight: CGFloat = 320
    private let horizontalPadding: CGFloat = 16

    // 中央から開始し、ユーザー操作のみで無限に流せるようにする
    private let loopSpan: Int = 500
    private var loopRange: ClosedRange<Int> { (-loopSpan)...loopSpan }
    private var centerIndex: Int { 0 }

    var body: some View {
        if shops.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(loopRange, id: \.self) { i in
                            let shop = shops[safe: positiveMod(i, shops.count)]
                            if let shop {
                                MockShopCardView(shop: shop)
                                    .frame(width: cardWidth)
                                    .id(i)
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .frame(height: rowHeight)
                .onAppear {
                    // 初期表示は中央の要素の先頭を左端に合わせる（均一な見た目）
                    DispatchQueue.main.async {
                        proxy.scrollTo(centerIndex, anchor: .leading)
                    }
                }
            }
        }
    }

    private func positiveMod(_ a: Int, _ m: Int) -> Int {
        guard m > 0 else { return 0 }
        let r = a % m
        return r < 0 ? r + m : r
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .frame(height: rowHeight)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "cart")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("おすすめのお店がありません")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, horizontalPadding)
    }
}

struct MockShopCardView: View {
    let shop: ShopData

    var body: some View {
        VStack(spacing: 0) {
            // 画像領域（アセット差し替え前提のプレースホルダ）
            ZStack {
                if let uiImage = UIImage(named: shop.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 170)
                        .clipped()
                        .cornerRadius(16)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 170)
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }

            // テキスト領域
            VStack(alignment: .leading, spacing: 8) {
                Text(shop.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(shop.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.vertical, 8)
    }
}

// サンプルデータ
let sampleShops: [ShopData] = [
    ShopData(name: "くまもとドーナツ", location: "熊本市中央区", imageName: "donatu"),
    ShopData(name: "さばのみそにや", location: "熊本市中央区", imageName: "saba"),
    ShopData(name: "あまい", location: "阿蘇市", imageName: "sweet"),
    ShopData(name: "中華のみせ", location: "熊本市中央区", imageName: "tyuka"),
    ShopData(name: "和食店", location: "天草市", imageName: "washoku")
]

// 安全添字アクセス
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
