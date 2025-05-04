import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?

    static let shared = AuthService()
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.userSession = Auth.auth().currentUser
    }

    @MainActor
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            try await fetchCurrentUser(uid: result.user.uid)
        } catch {
            throw error
        }
    }

    @MainActor
    func createUser(withEmail email: String, password: String, fullName: String, birthDate: Date?) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user

            let user = User(
                id: nil,
                email: email,
                fullName: fullName,
                birthDate: birthDate,
                profileImageURL: nil,
                createdAt: Date(),
                partnerId: nil,
                pairId: nil,
                relationshipStartDate: nil,
                bio: "",
                interests: [],
                relationshipStatus: "Single"
            )

            print("📡 Laravelに送信: \(user)")

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                UserAPIService.shared.createUser(user)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: { success in
                        if success {
                            DispatchQueue.main.async {
                                self.currentUser = user
                                continuation.resume()
                            }
                        } else {
                            continuation.resume(throwing: URLError(.badServerResponse))
                        }
                    })
                    .store(in: &self.cancellables)
            }

        } catch {
            throw error
        }
    }

    @MainActor
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("⚠️ ログアウト失敗: \(error.localizedDescription)")
        }
    }

    @MainActor
    func fetchCurrentUser(uid: String) async throws {
        let url = URL(string: "http://localhost/api/users/\(uid)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        let user = try JSONDecoder().decode(User.self, from: data)
        self.currentUser = user
    }
    
    @MainActor
    func updateProfileImage(withImageUrl url: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var updatedUser = currentUser
        updatedUser?.profileImageURL = url

        guard let user = updatedUser else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UserAPIService.shared.saveProfile(user)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { success in
                    if success {
                        DispatchQueue.main.async {
                            self.currentUser = user
                            continuation.resume()
                        }
                    } else {
                        continuation.resume(throwing: URLError(.cannotWriteToFile))
                    }
                })
                .store(in: &self.cancellables)
        }

    }

}
