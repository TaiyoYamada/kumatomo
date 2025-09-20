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
    
    private enum AltCodingKeys: String, CodingKey {
        case imageUrlCamel = "imageUrl"
        case imageURLCaps = "imageURL"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""

        // Optionals
        description = try? container.decode(String.self, forKey: .description)
        address = try? container.decode(String.self, forKey: .address)
        phone = try? container.decode(String.self, forKey: .phone)
        businessHours = try? container.decode(String.self, forKey: .businessHours)

        // Genre as raw string -> enum
        if let genreString = try? container.decode(String.self, forKey: .genre) {
            genre = ShopGenre(rawValue: genreString)
        } else {
            genre = nil
        }

        // Flexible number decoding (string or number)
        func decodeDoubleFlexible(_ key: CodingKeys) -> Double? {
            if let d = try? container.decode(Double.self, forKey: key) { return d }
            if let s = try? container.decode(String.self, forKey: key) { return Double(s) }
            return nil
        }
        latitude = decodeDoubleFlexible(.latitude)
        longitude = decodeDoubleFlexible(.longitude)

        if let url = try? container.decode(String.self, forKey: .imageUrl) {
            imageUrl = url
        } else {
            // Fallback to camelCase variants for robustness
            let alt = try? decoder.container(keyedBy: AltCodingKeys.self)
            imageUrl = (try? alt?.decodeIfPresent(String.self, forKey: .imageUrlCamel))
                ?? (try? alt?.decodeIfPresent(String.self, forKey: .imageURLCaps))
        }

        // Defaults when missing
        if let b = try? container.decode(Bool.self, forKey: .hasTryBenefit) {
            hasTryBenefit = b
        } else if let i = try? container.decode(Int.self, forKey: .hasTryBenefit) {
            hasTryBenefit = (i != 0)
        } else if let s = try? container.decode(String.self, forKey: .hasTryBenefit) {
            hasTryBenefit = (s == "1" || s.lowercased() == "true")
        } else {
            hasTryBenefit = false
        }

        if let i = (try? container.decode(Int.self, forKey: .stampCount)) ?? (try? container.decode(String.self, forKey: .stampCount)).flatMap(Int.init) {
            stampCount = i
        } else {
            stampCount = 0
        }

        if let b = try? container.decode(Bool.self, forKey: .isApproved) {
            isApproved = b
        } else if let i = try? container.decode(Int.self, forKey: .isApproved) {
            isApproved = (i != 0)
        } else if let s = try? container.decode(String.self, forKey: .isApproved) {
            isApproved = (s == "1" || s.lowercased() == "true")
        } else {
            isApproved = true
        }

        // Dates (use decoder's strategy first; fallback to manual)
        if let d = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = d
        } else if let s = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = APIHelper.parseDate(s)
        } else {
            createdAt = nil
        }

        if let d = try? container.decode(Date.self, forKey: .updatedAt) {
            updatedAt = d
        } else if let s = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = APIHelper.parseDate(s)
        } else {
            updatedAt = nil
        }
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
