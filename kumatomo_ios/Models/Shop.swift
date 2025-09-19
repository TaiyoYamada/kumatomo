import Foundation
import CoreLocation

struct Shop: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var description: String?
    var address: String?
    var phone: String?
    var businessHours: String?
    var genre: ShopGenre?
    var latitude: Double?
    var longitude: Double?
    var imageUrl: String?
    var hasTryBenefit: Bool
    var stampCount: Int
    var isApproved: Bool
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, phone, genre, latitude, longitude
        case businessHours = "business_hours"
        case imageUrl = "image_url"
        case hasTryBenefit = "has_try_benefit"
        case stampCount = "stamp_count"
        case isApproved = "is_approved"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Shop {
    init(id: Int = 0, name: String, description: String? = nil, address: String? = nil, phone: String? = nil, businessHours: String? = nil, genre: ShopGenre? = nil, latitude: Double? = nil, longitude: Double? = nil, imageUrl: String? = nil, hasTryBenefit: Bool = false, stampCount: Int = 0, isApproved: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.phone = phone
        self.businessHours = businessHours
        self.genre = genre
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrl = imageUrl
        self.hasTryBenefit = hasTryBenefit
        self.stampCount = stampCount
        self.isApproved = isApproved
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Returns the coordinate of the shop if latitude and longitude are available
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    /// Calculates distance from user location to this shop using LocationManager
    func distanceFromUser(_ userLocation: CLLocation?) -> String? {
        guard let userLocation = userLocation,
              let coordinate = coordinate else { return nil }
        
        let shopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = userLocation.distance(from: shopLocation)
        
        return LocationManager.formatDistance(distance)
    }
    
    /// Calculates distance from current user location using LocationManager
    @MainActor
    var distanceFromCurrentUser: String? {
        return LocationManager.shared.distanceFromUser(to: self)
    }
}