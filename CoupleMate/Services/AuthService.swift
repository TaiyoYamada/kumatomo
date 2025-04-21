import Foundation
import Firebase
import FirebaseAuth

class AuthService: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    static let shared = AuthService()
    
    init() {
        self.userSession = Auth.auth().currentUser
        Task { await fetchCurrentUser() }
    }
    
    @MainActor
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchCurrentUser()
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
                id: result.user.uid,
                email: email,
                fullName: fullName,
                birthDate: birthDate,
                profileImageURL: nil,
                createdAt: Date(),
                partnerId: nil,
                relationshipStartDate: nil
            )
            
            try await Firestore.firestore().collection("users").document(user.id).setData(user.toDictionary())
            self.currentUser = user
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
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func fetchCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard let data = snapshot.data() else { return }
            
            self.currentUser = User(dictionary: data)
        } catch {
            print("DEBUG: Failed to fetch current user: \(error.localizedDescription)")
        }
    }
    
    func updateProfileImage(withImageUrl url: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await Firestore.firestore().collection("users").document(uid).updateData([
                "profileImageURL": url
            ])
            
            self.currentUser?.profileImageURL = url
        } catch {
            throw error
        }
    }
}
