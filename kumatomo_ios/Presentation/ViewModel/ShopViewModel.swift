import SwiftUI
import CoreLocation
import Observation
import Combine

@MainActor
@Observable
final class ShopViewModel {
    // MARK: - Properties

    var shops: [Shop] = []
    var selectedShop: Shop?
    var selectedCategory: ShopCategory?
    var searchQuery: String = ""
    var bottomSheetState: BottomSheetState = .hidden
    var userLocation: CLLocationCoordinate2D?
    var errorMessage: String?
    var isSearching: Bool = false

    // Reviews
    var selectedShopReviews: [Comment] = []
    var isFetchingReviews: Bool = false

    // Dependencies
    private let searchShopsUseCase: SearchShopsUseCaseProtocol
    private let locationManager: LocationManager
    private let shopReviewService: ShopReviewAPIService

    // Internal State
    private var hasPerformedInitialSearch: Bool = false
    private var lastSearchedLocation: CLLocationCoordinate2D?
    private var debounceTask: Task<Void, Never>?

    // デバウンス時間（秒）
    private let debounceInterval: TimeInterval = 1.0
    // 最小移動距離（メートル）
    private let minimumMovementDistance: Double = 300.0
    // 最大保持件数
    private let maxShopsCount: Int = 300

    enum BottomSheetState {
        case hidden
        case collapsed
        case expanded
    }

    // MARK: - Initializer

    init(
        searchShopsUseCase: SearchShopsUseCaseProtocol = SearchShopsUseCase(placeRepository: PlaceRepositoryImpl()),
        locationManager: LocationManager = .shared,
        shopReviewService: ShopReviewAPIService = .shared
    ) {
        self.searchShopsUseCase = searchShopsUseCase
        self.locationManager = locationManager
        self.shopReviewService = shopReviewService

        setupLocationUpdates()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func onAppear() {
        locationManager.requestLocationPermission()
    }

    func onSearchQueryChanged(_ query: String) {
        searchQuery = query
        // Debounce logic could be added here or in View
        performSearch(isUserInitiated: true)
    }

    func onCategorySelected(_ category: ShopCategory) {
        if selectedCategory == category {
            selectedCategory = nil // Toggle off
        } else {
            selectedCategory = category
        }
        performSearch(isUserInitiated: true)
    }

    func onPinTapped(_ shop: Shop) {
        selectedShop = shop
        bottomSheetState = .collapsed

        // Reset and fetch reviews
        selectedShopReviews = []
        isFetchingReviews = true

        Task {
            do {
                let reviews = try await shopReviewService.fetchReviews(placeId: shop.id)
                self.selectedShopReviews = reviews
            } catch {
                print("Failed to fetch reviews: \(error)") // Silent fail or show in UI
            }
            self.isFetchingReviews = false
        }
    }

    func onMapTapped() {
        if bottomSheetState != .hidden {
            bottomSheetState = .hidden
            selectedShop = nil
        }
    }

    /// マップの中心座標が変更された時に呼ばれる
    func onMapRegionChanged(center: CLLocationCoordinate2D) {
        // 前回のデバウンスタスクをキャンセル
        debounceTask?.cancel()

        // 新しいデバウンスタスクを開始
        debounceTask = Task {
            do {
                try await Task.sleep(for: .seconds(debounceInterval))
            } catch {
                // キャンセルされた場合は何もしない
                return
            }

            // 最小移動距離チェック
            if let lastLocation = lastSearchedLocation {
                let distance = self.distance(from: lastLocation, to: center)
                if distance < minimumMovementDistance {
                    print("📍 移動距離が小さいため検索をスキップ: \(Int(distance))m")
                    return
                }
            }

            print("🗺️ マップ移動検出: 新しい地域を検索")
            await executeSearch(location: center)
        }
    }

    // MARK: - Private Methods

    private func setupLocationUpdates() {
        // Initial check
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager
            .authorizationStatus == .authorizedAlways {
            performSearch()
        }

        NotificationCenter.default
            .addObserver(
                forName: .LocationAuthorizationChanged,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self else { return }
                if let status = notification.userInfo?["status"] as? CLAuthorizationStatus,
                   status == .authorizedWhenInUse || status == .authorizedAlways {
                    print("✅ Location Authorized: Performing Search")
                    performSearch()
                }
            }

        NotificationCenter.default.addObserver(forName: .LocationUpdated, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            // Only search if we haven't yet, or if explicitly requested (handled elsewhere)
            if !hasPerformedInitialSearch {
                print("✅ Location Updated: Performing Initial Search")
                performSearch()
            }
        }
    }

    func performSearch(isUserInitiated: Bool = false) {
        print("🔍 performSearch called (UserInit: \(isUserInitiated))")
        guard let location = locationManager.userLocation?.coordinate else {
            print("⏳ User location not available, requesting one-time location")
            locationManager.requestOneTimeLocation { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(loc):
                    print("📍 One-time location received: \(loc.coordinate)")
                    Task { await self.executeSearch(location: loc.coordinate) }
                case let .failure(error):
                    print("❌ Location request failed: \(error)")
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        Task { await executeSearch(location: location) }
    }

    private func executeSearch(location: CLLocationCoordinate2D) async {
        if isSearching { return }
        isSearching = true

        do {
            print("🚀 Executing search with query: \(searchQuery), category: \(selectedCategory?.displayName ?? "All")")
            let results = try await searchShopsUseCase.execute(
                query: searchQuery.isEmpty ? nil : searchQuery,
                category: selectedCategory,
                location: location
            )
            // 累積表示: 重複を除外して新しいお店を追加
            let newShops = results.filter { newShop in
                !shops.contains { $0.id == newShop.id }
            }
            shops.append(contentsOf: newShops)

            // 最大件数を超えたら古いものから削除
            if shops.count > maxShopsCount {
                shops = Array(shops.suffix(maxShopsCount))
            }

            errorMessage = nil
            hasPerformedInitialSearch = true
            lastSearchedLocation = location
            print("✅ Search completed: +\(newShops.count) new shops, total \(shops.count) shops")
        } catch {
            print("❌ Search failed: \(error)")
            errorMessage = "検索に失敗しました: \(error.localizedDescription)"
            hasPerformedInitialSearch = true
        }

        isSearching = false
    }

    /// 2点間の距離を計算（メートル）
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}
