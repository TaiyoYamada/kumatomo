import Foundation
import Combine
import FirebaseFirestore


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
