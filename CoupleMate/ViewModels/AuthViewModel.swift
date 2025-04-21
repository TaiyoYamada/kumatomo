import Foundation
import Firebase
import FirebaseAuth
import PhotosUI
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    
    @Published var profileImage: UIImage?
    @Published var selectedImage: PhotosPickerItem?
    
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let authService = AuthService.shared
    private let storageService = StorageService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.userSession = authService.userSession
        self.currentUser = authService.currentUser
        
        addSubscribers()
    }
    
    private func addSubscribers() {
        // 認証状態の変更を監視
        authService.$userSession.sink { [weak self] userSession in
            self?.userSession = userSession
        }.store(in: &cancellables)
        
        // ユーザー情報の変更を監視
        authService.$currentUser.sink { [weak self] currentUser in
            self?.currentUser = currentUser
        }.store(in: &cancellables)
    }
    
    @MainActor
    func signIn() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signIn(withEmail: email, password: password)
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func createUser() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.createUser(withEmail: email, password: password, fullName: fullName, birthDate: birthDate)
            
            if let profileImage = profileImage {
                await uploadProfileImage(profileImage)
            }
            
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() {
        authService.signOut()
    }
    
    @MainActor
    private func uploadProfileImage(_ image: UIImage) async {
        guard let uid = userSession?.uid else { return }
        
        do {
            let url = try await StorageService.shared.uploadImage(image, path: .profile(uid: uid))
            try await authService.updateProfileImage(withImageUrl: url)
        } catch {
            print("DEBUG: Failed to upload image with error \(error.localizedDescription)")
        }
    }
    
    func loadProfileImage() {
        Task {
            if let selectedImage = selectedImage {
                do {
                    let data = try await selectedImage.loadTransferable(type: Data.self)
                    if let data = data, let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.profileImage = uiImage
                        }
                    }
                } catch {
                    print("DEBUG: Failed to load image \(error)")
                }
            }
        }
    }
    
    private func resetForm() {
        email = ""
        password = ""
        fullName = ""
        profileImage = nil
        selectedImage = nil
    }
}
