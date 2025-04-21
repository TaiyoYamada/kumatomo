import Foundation
import Firebase

struct User: Codable {
    let id: String
    let email: String
    let fullName: String
    let birthDate: Date?
    var profileImageURL: String?
    let createdAt: Date
    var partnerId: String?
    var relationshipStartDate: Date?
    
    // Initialize with individual properties
    init(id: String, email: String, fullName: String, birthDate: Date?,
         profileImageURL: String?, createdAt: Date, partnerId: String?,
         relationshipStartDate: Date?) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.birthDate = birthDate
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.partnerId = partnerId
        self.relationshipStartDate = relationshipStartDate
    }
    
    // Initialize from a dictionary
    init?(dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let email = dictionary["email"] as? String,
            let fullName = dictionary["fullName"] as? String,
            let createdAtTimestamp = dictionary["createdAt"] as? Timestamp
        else { return nil }
        
        self.id = id
        self.email = email
        self.fullName = fullName
        
        if let birthDateTimestamp = dictionary["birthDate"] as? Timestamp {
            self.birthDate = birthDateTimestamp.dateValue()
        } else {
            self.birthDate = nil
        }
        
        self.profileImageURL = dictionary["profileImageURL"] as? String
        self.createdAt = createdAtTimestamp.dateValue()
        self.partnerId = dictionary["partnerId"] as? String
        
        if let startDateTimestamp = dictionary["relationshipStartDate"] as? Timestamp {
            self.relationshipStartDate = startDateTimestamp.dateValue()
        } else {
            self.relationshipStartDate = nil
        }
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "email": email,
            "fullName": fullName,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let birthDate = birthDate {
            dict["birthDate"] = Timestamp(date: birthDate)
        }
        
        if let profileImageURL = profileImageURL {
            dict["profileImageURL"] = profileImageURL
        }
        
        if let partnerId = partnerId {
            dict["partnerId"] = partnerId
        }
        
        if let relationshipStartDate = relationshipStartDate {
            dict["relationshipStartDate"] = Timestamp(date: relationshipStartDate)
        }
        
        return dict
    }
}
