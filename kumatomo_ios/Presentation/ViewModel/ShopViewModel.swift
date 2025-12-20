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

    // Reviews
    var selectedShopReviews: [Comment] = []
    var isFetchingReviews: Bool = false

    // Dependencies
    private let searchShopsUseCase: SearchShopsUseCaseProtocol
    private let locationManager: LocationManager
    private let shopReviewService: ShopReviewAPIService

    // Internal State
    private var tasks: [Task<Void, Never>] = []
    private var hasPerformedInitialSearch: Bool = false

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
        if isFetchingReviews { return } // Simple guard, though reviews are separate.
        // Actually, we should guard against multiple simultaneous searches?

        do {
            print("🚀 Executing search with query: \(searchQuery), category: \(selectedCategory?.displayName ?? "All")")
            let results = try await searchShopsUseCase.execute(
                query: searchQuery.isEmpty ? nil : searchQuery,
                category: selectedCategory,
                location: location
            )
            shops = results
            errorMessage = nil
            hasPerformedInitialSearch = true
            print("✅ Search completed found \(results.count) shops")
        } catch {
            print("❌ Search failed: \(error)")
            errorMessage = "検索に失敗しました: \(error.localizedDescription)"
            hasPerformedInitialSearch = true // Even on failure, stop auto-loop
        }
    }
}
