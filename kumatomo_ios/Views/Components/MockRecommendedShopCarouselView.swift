import SwiftUI

// MARK: - Shop Data Model
struct ShopData: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let imageName: String
}

struct RecommendedShopCarouselView: View {
    // Data
    let shops: [ShopData]

    // Layout
    private let cardWidth: CGFloat = 280
    private let spacing: CGFloat = 16
    private let rowHeight: CGFloat = 320

    // Auto-scroll
    @State private var baseOffset: CGFloat = 0     // 純粋な自動スクロールの値
    @State private var dragOffset: CGFloat = 0     // ユーザー操作分（ジェスチャー中のみ）
    @State private var isDragging: Bool = false

    /// 1秒あたりに左へ進むポイント数（小さくするとゆっくり）
    var speed: CGFloat = 24

    /// 自動再開までの待機秒（ドラッグ終了後に間を置きたい場合）
    var resumeDelay: TimeInterval = 0.0

    // タイマーでなめらかに前進（60fps想定）
    private let ticker = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()
    @State private var lastTick = Date()
    @State private var resumeAt: Date? = nil

    private var unitWidth: CGFloat { cardWidth + spacing }
    private var loopWidth: CGFloat { unitWidth * CGFloat(max(shops.count, 1)) }

    // 実際に適用するオフセット（自動 + ドラッグ）を無限ループ範囲に正規化
    private var effectiveOffset: CGFloat {
        normalized(baseOffset + dragOffset, by: loopWidth)
    }

    var body: some View {
        ZStack { // クリップ用のコンテナ
            // 2周分並べてシームレスに見せる
            HStack(spacing: spacing) {
                ForEach(0..<2, id: \.self) { _ in
                    ForEach(shops) { shop in
                        ShopCardView(shop: shop)
                            .frame(width: cardWidth)
                    }
                }
            }
            .offset(x: effectiveOffset)
            .frame(height: rowHeight)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isDragging { isDragging = true }
                        // ユーザーの指の移動量をそのまま反映（ベース値は触らない）
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        // ドラッグ終了時にベースへ取り込み、ドラッグ分はリセット
                        baseOffset = normalized(baseOffset + value.translation.width, by: loopWidth)
                        dragOffset = 0
                        isDragging = false
                        // 自動再開の遅延指定
                        if resumeDelay > 0 {
                            resumeAt = Date().addingTimeInterval(resumeDelay)
                        } else {
                            resumeAt = nil
                        }
                        // タイマーステップの基準時刻を更新（ジャンプ防止）
                        lastTick = Date()
                    }
            )
        }
        .frame(height: rowHeight)
        .onReceive(ticker) { now in
            guard !shops.isEmpty else { return }

            let dt = now.timeIntervalSince(lastTick)
            lastTick = now

            // ドラッグ中は自動スクロール停止
            if isDragging { return }

            // 遅延再開が設定されている場合は、その時刻までは待つ
            if let resumeAt, now < resumeAt { return }

            // 左方向に進める（負方向）
            let step = speed * CGFloat(dt) // pt/sec * sec = pt
            baseOffset = normalized(baseOffset - step, by: loopWidth)
        }
    }

    /// - Returns: x を (-by, 0] の範囲に折りたたんだ値（無限ループ用）
    private func normalized(_ x: CGFloat, by by: CGFloat) -> CGFloat {
        guard by > 0 else { return 0 }
        var v = x.truncatingRemainder(dividingBy: by)
        if v > 0 { v -= by }  // 0 より大きければ左側レンジへ移す
        // これで常に -by .. 0 の範囲に収まる
        return v
    }
}

// MARK: - Shop Card View
struct ShopCardView: View {
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

let sampleShops: [ShopData] = [
    ShopData(name: "くまもとドーナツ", location: "熊本市中央区", imageName: "donatu"),
    ShopData(name: "さばのみそにや", location: "熊本市中央区", imageName: "saba"),
    ShopData(name: "あまい", location: "阿蘇市", imageName: "sweet"),
    ShopData(name: "中華のみせ", location: "熊本市中央区", imageName: "tyuka"),
    ShopData(name: "和食店", location: "天草市", imageName: "washoku")
]
