import SwiftUI
import UIKit // Needed for UIRectCorner, UIBezierPath

// MARK: - ShopBottomSheet

struct ShopBottomSheet: View {
    @Binding var state: ShopViewModel.BottomSheetState
    let shop: Shop?
    let reviews: [Comment]
    let isFetchingReviews: Bool

    // Geometry logic for the sheet
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if let shop {
                    if state == .collapsed {
                        collapsedView(shop: shop)
                    } else {
                        expandedView(shop: shop)
                    }
                } else {
                    ProgressView()
                        .padding()
                }

                Spacer()
            }
            .frame(width: geometry.size.width, height: sheetHeight(in: geometry))
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 10, y: -2)
            .offset(y: offset) // For drag gesture
            .frame(maxHeight: .infinity, alignment: .bottom)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if state == .expanded, value.translation.height > 0 {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if state == .expanded, value.translation.height > 100 {
                            withAnimation {
                                state = .collapsed
                                offset = 0
                            }
                        } else if state == .collapsed, value.translation.height < -50 {
                            withAnimation {
                                state = .expanded
                                offset = 0
                            }
                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if state == .collapsed {
                    withAnimation {
                        state = .expanded
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func sheetHeight(in geometry: GeometryProxy) -> CGFloat {
        switch state {
        case .hidden: return 0
        case .collapsed: return 200 // Approx 25% depending on screen, fixed for stability
        case .expanded: return geometry.size.height * 0.9
        }
    }

    @ViewBuilder
    private func collapsedView(shop: Shop) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(shop.name)
                .font(.headline)

            HStack {
                Text(shop.category?.displayName ?? "その他")
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)

                if let rating = shop.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Spacer()

                if let isOpen = shop.isOpen {
                    Text(isOpen ? "営業中" : "営業時間外")
                        .font(.caption)
                        .foregroundColor(isOpen ? .green : .red)
                }
            }

            Text(shop.address)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal)
        .padding(.bottom, 32) // Safer area
    }

    @ViewBuilder
    private func expandedView(shop: Shop) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(shop.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack {
                    Text(shop.category?.displayName ?? "その他")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.orange)

                    if let rating = shop.rating {
                        HStack(spacing: 2) {
                            ForEach(0 ..< 5) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            Text(String(format: "%.1f", rating))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                }

                Divider()

                // Info
                VStack(alignment: .leading, spacing: 12) {
                    Label(shop.address, systemImage: "map")
                    if let isOpen = shop.isOpen {
                        Label(isOpen ? "営業中" : "営業時間外", systemImage: "clock")
                            .foregroundColor(isOpen ? .green : .red)
                    }
                }
                .font(.subheadline)

                Button(action: {
                    openGoogleMaps(shop: shop)
                }) {
                    Text("Google Mapsで開く")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Divider()

                // Reviews
                Text("kumatomoの口コミ")
                    .font(.headline)

                if isFetchingReviews {
                    ProgressView()
                        .padding()
                } else if reviews.isEmpty {
                    Text("まだ口コミはありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(reviews) { comment in
                        ShopReviewRow(comment: comment)
                        Divider()
                    }
                }
            }
            .padding()
        }
    }

    private func openGoogleMaps(shop: Shop) {
        let urlString = "https://www.google.com/maps/search/?api=1&query=\(shop.coordinate.latitude),\(shop.coordinate.longitude)&query_place_id=\(shop.id)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ShopReviewRow

struct ShopReviewRow: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill") // Placeholder avatar
                    .foregroundColor(.gray)

                VStack(alignment: .leading) {
                    Text(comment.user?.name ?? "ユーザー")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(comment.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(comment.content)
                .font(.body)
                .padding(.top, 4)

            // If image exists
            if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                } placeholder: {
                    Color.gray.opacity(0.1)
                        .frame(height: 150)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - RoundedCorner

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
