import Foundation

struct Shop: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var description: String?
    var address: String?
    var phone: String?
    var businessHours: String?
    var genre: String?
    var latitude: Double?
    var longitude: Double?
    var imageUrl: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, phone, genre, latitude, longitude
        case businessHours = "business_hours"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Shop {
    init(id: Int = 0, name: String, description: String? = nil, address: String? = nil, phone: String? = nil, businessHours: String? = nil, genre: String? = nil, latitude: Double? = nil, longitude: Double? = nil, imageUrl: String? = nil) {
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
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}