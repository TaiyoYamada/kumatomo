import SwiftUI
import MapKit
import CoreLocation

struct ShopMapView: UIViewRepresentable {
    let shops: [Shop]
    let userLocation: CLLocation?
    let selectedShop: Shop?
    let onShopSelected: (Shop) -> Void
    let onPinTapped: (Shop) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // Configure map appearance
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        
        // Register custom annotation view
        mapView.register(ShopAnnotationView.self, forAnnotationViewWithReuseIdentifier: ShopAnnotationView.identifier)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateAnnotations(mapView)
        centerMapIfNeeded(mapView)
        highlightSelectedShop(mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private Methods
    
    private func updateAnnotations(_ mapView: MKMapView) {
        // Remove existing annotations (except user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        let newAnnotations = shops.compactMap { shop -> ShopAnnotation? in
            guard let latitude = shop.latitude,
                  let longitude = shop.longitude else { return nil }
            
            return ShopAnnotation(
                shop: shop,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        }
        
        mapView.addAnnotations(newAnnotations)
    }
    
    private func centerMapIfNeeded(_ mapView: MKMapView) {
        if let userLocation = userLocation {
            // Center on user location with appropriate zoom level
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 2000, // 2km radius
                longitudinalMeters: 2000
            )
            mapView.setRegion(region, animated: true)
        } else if !shops.isEmpty {
            // Center on shops if no user location
            let coordinates = shops.compactMap { shop -> CLLocationCoordinate2D? in
                guard let lat = shop.latitude, let lng = shop.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            
            if !coordinates.isEmpty {
                let region = calculateRegionForCoordinates(coordinates)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    private func highlightSelectedShop(_ mapView: MKMapView) {
        // Update annotation views to reflect selection state
        for annotation in mapView.annotations {
            if let shopAnnotation = annotation as? ShopAnnotation,
               let annotationView = mapView.view(for: annotation) as? ShopAnnotationView {
                annotationView.updateSelection(isSelected: shopAnnotation.shop.id == selectedShop?.id)
            }
        }
        
        // Center on selected shop if needed
        if let selectedShop = selectedShop,
           let coordinate = selectedShop.coordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func calculateRegionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.2, // Add 20% padding
            longitudeDelta: max(maxLng - minLng, 0.01) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Coordinator
extension ShopMapView {
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ShopMapView
        
        init(_ parent: ShopMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            guard let shopAnnotation = annotation as? ShopAnnotation else {
                return nil
            }
            
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: ShopAnnotationView.identifier,
                for: annotation
            ) as! ShopAnnotationView
            
            annotationView.configure(with: shopAnnotation.shop)
            annotationView.updateSelection(isSelected: shopAnnotation.shop.id == parent.selectedShop?.id)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let shopAnnotation = view.annotation as? ShopAnnotation else { return }
            
            // Update selection state
            if let annotationView = view as? ShopAnnotationView {
                annotationView.updateSelection(isSelected: true)
            }
            
            // Notify parent of selection
            parent.onShopSelected(shopAnnotation.shop)
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let annotationView = view as? ShopAnnotationView {
                annotationView.updateSelection(isSelected: false)
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let shopAnnotation = view.annotation as? ShopAnnotation else { return }
            parent.onPinTapped(shopAnnotation.shop)
        }
    }
}

// MARK: - Shop Annotation
class ShopAnnotation: NSObject, MKAnnotation {
    let shop: Shop
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return shop.name
    }
    
    var subtitle: String? {
        var components: [String] = []
        
        if let genre = shop.genre {
            components.append(genre.displayName)
        }
        
        if shop.hasTryBenefit {
            components.append("Try特典あり")
        }
        
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }
    
    init(shop: Shop, coordinate: CLLocationCoordinate2D) {
        self.shop = shop
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - Custom Annotation View
class ShopAnnotationView: MKAnnotationView {
    static let identifier = "ShopAnnotationView"
    
    private let pinSize: CGFloat = 40
    private let imageSize: CGFloat = 32
    
    private var shop: Shop?
    private var isSelectedState = false
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var pinBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = pinSize / 2
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.3
        return view
    }()
    
    private lazy var shopImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageSize / 2
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.systemGray5
        return imageView
    }()
    
    private lazy var genreIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 3
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        return view
    }()
    
    private lazy var tryBenefitBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemOrange
        view.layer.cornerRadius = 6
        view.isHidden = true
        
        let label = UILabel()
        label.text = "特典"
        label.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.widthAnchor.constraint(equalToConstant: 24),
            view.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        return view
    }()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        frame = CGRect(x: 0, y: 0, width: pinSize, height: pinSize + 8) // Extra height for badge
        centerOffset = CGPoint(x: 0, y: -frame.height / 2)
        
        // Enable callout
        canShowCallout = true
        
        // Add detail disclosure button
        let detailButton = UIButton(type: .detailDisclosure)
        detailButton.tintColor = UIColor.systemOrange
        rightCalloutAccessoryView = detailButton
        
        // Setup view hierarchy
        addSubview(containerView)
        containerView.addSubview(pinBackgroundView)
        containerView.addSubview(shopImageView)
        containerView.addSubview(genreIndicatorView)
        containerView.addSubview(tryBenefitBadge)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Pin background
            pinBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            pinBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pinBackgroundView.widthAnchor.constraint(equalToConstant: pinSize),
            pinBackgroundView.heightAnchor.constraint(equalToConstant: pinSize),
            
            // Shop image
            shopImageView.centerXAnchor.constraint(equalTo: pinBackgroundView.centerXAnchor),
            shopImageView.centerYAnchor.constraint(equalTo: pinBackgroundView.centerYAnchor),
            shopImageView.widthAnchor.constraint(equalToConstant: imageSize),
            shopImageView.heightAnchor.constraint(equalToConstant: imageSize),
            
            // Genre indicator
            genreIndicatorView.trailingAnchor.constraint(equalTo: pinBackgroundView.trailingAnchor, constant: -2),
            genreIndicatorView.bottomAnchor.constraint(equalTo: pinBackgroundView.bottomAnchor, constant: -2),
            genreIndicatorView.widthAnchor.constraint(equalToConstant: 6),
            genreIndicatorView.heightAnchor.constraint(equalToConstant: 6),
            
            // Try benefit badge
            tryBenefitBadge.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            tryBenefitBadge.topAnchor.constraint(equalTo: pinBackgroundView.bottomAnchor, constant: 2)
        ])
    }
    
    func configure(with shop: Shop) {
        self.shop = shop
        
        // Set genre color
        if let genre = shop.genre {
            pinBackgroundView.backgroundColor = UIColor(genre.color)
            genreIndicatorView.backgroundColor = UIColor(genre.color)
        } else {
            pinBackgroundView.backgroundColor = UIColor.systemGray
            genreIndicatorView.backgroundColor = UIColor.systemGray
        }
        
        // Load shop image
        loadShopImage(from: shop.imageUrl)
        
        // Show/hide try benefit badge
        tryBenefitBadge.isHidden = !shop.hasTryBenefit
        
        // Set accessibility
        accessibilityLabel = shop.name
        accessibilityHint = "店舗の詳細を表示するにはダブルタップしてください"
        accessibilityTraits = .button
    }
    
    func updateSelection(isSelected: Bool) {
        isSelectedState = isSelected
        
        UIView.animate(withDuration: 0.2) {
            if isSelected {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.pinBackgroundView.layer.shadowOpacity = 0.5
                self.pinBackgroundView.layer.shadowRadius = 6
            } else {
                self.transform = .identity
                self.pinBackgroundView.layer.shadowOpacity = 0.3
                self.pinBackgroundView.layer.shadowRadius = 4
            }
        }
    }
    
    private func loadShopImage(from urlString: String?) {
        // Reset image
        shopImageView.image = UIImage(systemName: "storefront")
        shopImageView.tintColor = .white
        
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return
        }
        
        // Simple image loading (in production, use a proper image loading library)
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                self?.shopImageView.image = image
                self?.shopImageView.tintColor = nil
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        shop = nil
        isSelectedState = false
        transform = .identity
        shopImageView.image = nil
        tryBenefitBadge.isHidden = true
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
                genre: .cafe,
                latitude: 35.6762,
                longitude: 139.6503,
                hasTryBenefit: true
            ),
            Shop(
                id: 2,
                name: "イタリアンレストラン",
                description: "本格的なイタリア料理",
                address: "東京都新宿区",
                genre: .restaurant,
                latitude: 35.6896,
                longitude: 139.6917,
                hasTryBenefit: false
            )
        ],
        userLocation: CLLocation(latitude: 35.6762, longitude: 139.6503),
        selectedShop: nil,
        onShopSelected: { _ in },
        onPinTapped: { _ in }
    )
}