import SwiftUI
import Foundation
import UIKit
import Combine

class ProfileViewModel: ObservableObject {
    // 表示用プロパティ
    @Published var profile: User
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedImage: UIImage?
    @Published var isImageUploading = false
    @Published var showSuccessMessage = false

    // 編集用プロパティ
    @Published var name: String = ""
    @Published var bio: String = ""
    @Published var website: String = ""
    
    private let userAPIService = UserAPIService()
    private let imageManager = ProfileImageManager()
    private var cancellables = Set<AnyCancellable>()

    init(userID: String) {
        self.profile = User(
            id: nil,
            email: "",
            name: "",
            profileImageURL: nil,
            bio: "",
            website: nil,
            followingCount: 0,
            followersCount: 0,
            createdAt: nil
        )
        loadProfile(userID: userID)
    }
    
    

    func loadProfile(userID: String) {
        isLoading = true
        userAPIService.fetchProfile(userID: userID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] profile in
                self?.profile = profile
                self?.updateFormFields(with: profile)
            }
            .store(in: &cancellables)
    }

    private func updateFormFields(with profile: User) {
        name = profile.name ?? ""
        bio = profile.bio ?? ""
    }

    func saveProfile() {
        isLoading = true
        var updatedProfile = profile
        updatedProfile.name = name
        updatedProfile.bio = bio

        if let image = selectedImage {
            uploadProfileImage(image) { [weak self] result in
                switch result {
                case .success(let url):
                    updatedProfile.profileImageURL = url.absoluteString
                    self?.saveProfileData(updatedProfile)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        } else {
            saveProfileData(updatedProfile)
        }
    }

    private func saveProfileData(_ updatedProfile: User) {
        userAPIService.saveProfile(updatedProfile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] _ in
                self?.profile = updatedProfile
                self?.showSuccessMessage = true
            }
            .store(in: &cancellables)
    }
    
    

    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        isImageUploading = true

        imageManager.uploadImage(image)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isImageUploading = false
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            } receiveValue: { url in
                completion(.success(url))
            }
            .store(in: &cancellables)
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    // Reset form fields to the current profile values
    func resetFormFields() {
        name = profile.name ?? ""
        bio = profile.bio ?? ""
        website = profile.website ?? ""
    }

    // Validate input fields
    func validateInput() -> Bool {
        if name.isEmpty {
            errorMessage = "Name cannot be empty."
            showError = true
            return false
        }
        return true
    }

    // Save changes from EditPageView
    func saveChanges() {
        guard validateInput() else { return }
        saveProfile()
    }
}

// タグなどを整理するためのレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        let rows = computeRows(width: width, subviews: subviews)

        for row in rows {
            height += row.maxY - row.minY
        }

        height += spacing * CGFloat(max(0, rows.count - 1))

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        let rows = computeRows(width: width, subviews: subviews)

        var currentY = bounds.minY

        for row in rows {
            for (subview, x) in row.subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                let origin = CGPoint(x: x, y: currentY)
                subview.place(at: origin, proposal: ProposedViewSize(viewSize))
            }

            currentY += (row.maxY - row.minY) + spacing
        }
    }

    private func computeRows(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var currentX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > width && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                currentX = 0
            }

            currentRow.add(subview, at: currentX, size: size)
            currentX += size.width + spacing
        }

        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var subviews: [(subview: LayoutSubview, x: CGFloat)] = []
        var minY: CGFloat = 0
        var maxY: CGFloat = 0

        mutating func add(_ subview: LayoutSubview, at x: CGFloat, size: CGSize) {
            subviews.append((subview, x))
            minY = 0
            maxY = max(maxY, size.height)
        }
    }
}
