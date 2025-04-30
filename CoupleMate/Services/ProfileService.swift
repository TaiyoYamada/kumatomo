import Foundation
import Combine
import FirebaseFirestore

class ProfileService {
    private let store = Firestore.firestore()
    private let collection = "users"

    // プロフィールを保存
    func saveProfile(_ profile: UserProfile) -> AnyPublisher<Bool, Error> {
        let docRef = store.collection(collection).document(profile.id)
        return Future<Bool, Error> { promise in
            do {
                try docRef.setData(from: profile) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(true))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    // プロフィールを取得（ダミー値 fallback 付き）
    func fetchProfile(userID: String) -> AnyPublisher<UserProfile, Error> {
        let docRef = store.collection(collection).document(userID)

        return Future<UserProfile, Error> { promise in
            docRef.getDocument { snapshot, error in
                if let error = error {
                    // エラーが起きたらモックを返す（デバッグ時や初期起動時など）
                    print("⚠️ Firestore error: \(error.localizedDescription)")
                    promise(.success(Self.mockProfile(id: userID)))
                    return
                }

                if let snapshot = snapshot, snapshot.exists {
                    do {
                        let profile = try snapshot.data(as: UserProfile.self)
                        promise(.success(profile))
                    } catch {
                        print("⚠️ デコード失敗: \(error)")
                        promise(.success(Self.mockProfile(id: userID)))
                    }
                } else {
                    // ドキュメントが存在しないときもダミーで返す
                    print("⚠️ ドキュメントなし、モックを返します")
                    promise(.success(Self.mockProfile(id: userID)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    //  ダミープロファイルを返すユーティリティ
    private static func mockProfile(id: String) -> UserProfile {
        return UserProfile(
            id: id,
            name: "ニックネーム",
            bio: "よろしくお願いします",
            birthDate: Calendar.current.date(from: DateComponents(year: 2000, month: 4, day: 1)),
            interests: ["映画鑑賞", "料理", "旅行"],
            relationshipStatus: "In a relationship",
            anniversaryDate: Calendar.current.date(from: DateComponents(year: 2020, month: 6, day: 10))
        )
    }
}
