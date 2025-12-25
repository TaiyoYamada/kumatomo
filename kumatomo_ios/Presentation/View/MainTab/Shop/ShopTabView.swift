import SwiftUI
import MapKit

// MARK: - ShopTabView

struct ShopTabView: View {
    @State private var viewModel = ShopViewModel()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @Environment(\.openSidebar) private var openSidebar

    var body: some View {
        ZStack(alignment: .top) {
            // Map Layer
            Map(position: $position, selection: $viewModel.selectedShop) {
                UserAnnotation()

                ForEach(viewModel.shops) { shop in
                    Annotation(shop.name, coordinate: shop.coordinate.clLocationCoordinate2D) {
                        ShopPinView(category: shop.category)
                            .onTapGesture {
                                viewModel.onPinTapped(shop)
                            }
                    }
                    .tag(shop)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                // マップが移動したら新しい地域を検索
                viewModel.onMapRegionChanged(center: context.region.center)
            }
            .onTapGesture {
                viewModel.onMapTapped()
            }

            // UI Layer (Top)
            VStack(spacing: 8) {
                ShopSearchBar(text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.onSearchQueryChanged($0) }
                ))
                .padding(.horizontal)
                .padding(.top, 8)

                CategoryFilterView(
                    selectedCategory: viewModel.selectedCategory,
                    onSelect: { viewModel.onCategorySelected($0) }
                )
            }
            .background(
                LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)
                    .frame(height: 150)
                    .ignoresSafeArea()
            )

            // 現在地ボタン（右下）
            CurrentLocationButton {
                moveToCurrentLocation()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 16)
            .padding(.bottom, viewModel.bottomSheetState != .hidden ? 220 : 32)

            // Bottom Sheet
            if viewModel.bottomSheetState != .hidden {
                ShopBottomSheet(
                    state: $viewModel.bottomSheetState,
                    shop: viewModel.selectedShop,
                    reviews: viewModel.selectedShopReviews,
                    isFetchingReviews: viewModel.isFetchingReviews
                )
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("お店")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.lightOrangeColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sidebarButton()
        .onAppear {
            viewModel.onAppear()
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    /// 現在地に移動して検索を実行
    private func moveToCurrentLocation() {
        LocationManager.shared.requestOneTimeLocation { result in
            switch result {
            case let .success(location):
                withAnimation {
                    position = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        latitudinalMeters: 1_500,
                        longitudinalMeters: 1_500
                    ))
                }
                // 現在地周辺を検索
                Task {
                    await viewModel.searchAtLocation(location.coordinate)
                }
            case let .failure(error):
                print("❌ 現在地取得失敗: \(error)")
            }
        }
    }
}

// MARK: - CurrentLocationButton

struct CurrentLocationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                Image(systemName: "location.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ShopPinView

struct ShopPinView: View {
    let category: ShopCategory?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(radius: 2, y: 1)

            Image(systemName: iconName(for: category))
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.orange)
        }
    }

    func iconName(for category: ShopCategory?) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bar: return "wineglass"
        case .convenienceStore: return "takeoutbag.and.cup.and.straw"
        case .superMarket: return "basket"
        case .hospital: return "cross.case"
        case .school: return "graduationcap"
        case .publicFacility: return "building.columns"
        case .gym: return "dumbbell"
        case .entertainment: return "figure.socialdance"
        case .other, .none: return "mappin"
        }
    }
}

// MARK: - ShopSearchBar

struct ShopSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("店名・ジャンルで検索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2, y: 1)
    }
}

// MARK: - CategoryFilterView

struct CategoryFilterView: View {
    let selectedCategory: ShopCategory?
    let onSelect: (ShopCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShopCategory.allCases) { category in
                    Button(action: { onSelect(category) }) {
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedCategory == category ? .bold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color.orange : Color(.systemBackground))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(16)
                            .shadow(radius: 1, y: 1)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
