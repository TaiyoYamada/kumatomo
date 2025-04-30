import Foundation
import Combine

struct UserProfile: Identifiable, Codable {
    var id: String
    var name: String
    var bio: String
    var birthDate: Date?
    var profileImageURL: URL?
    var interests: [String]
    var relationshipStatus: String
    var partnerID: String?
    var anniversaryDate: Date?
    
    init(id: String = UUID().uuidString,
         name: String = "",
         bio: String = "",
         birthDate: Date? = nil,
         profileImageURL: URL? = nil,
         interests: [String] = [],
         relationshipStatus: String = "Single",
         partnerID: String? = nil,
         anniversaryDate: Date? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.birthDate = birthDate
        self.profileImageURL = profileImageURL
        self.interests = interests
        self.relationshipStatus = relationshipStatus
        self.partnerID = partnerID
        self.anniversaryDate = anniversaryDate
    }
}
