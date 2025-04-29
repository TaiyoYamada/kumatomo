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

class ProfileService {
    func saveProfile(_ profile: UserProfile) -> AnyPublisher<Bool, Error> {
        // 実際のAPIリクエストやFirebaseなどとの連携コードをここに実装
        // この例ではモックとして即座に成功を返す
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fetchProfile(userID: String) -> AnyPublisher<UserProfile, Error> {
        // 実際にはAPIリクエストやFirebaseからプロフィールを取得
        // モックとしてサンプルデータを返す
        let profile = UserProfile(
            id: userID,
            name: "サンプルユーザー",
            bio: "よろしくお願いします",
            birthDate: Calendar.current.date(from: DateComponents(year: 1995, month: 5, day: 15)),
            interests: ["映画鑑賞", "料理", "旅行"],
            relationshipStatus: "In a relationship",
            anniversaryDate: Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 10))
        )
        
        return Just(profile)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
