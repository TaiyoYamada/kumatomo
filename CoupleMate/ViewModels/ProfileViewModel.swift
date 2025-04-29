//
//  ProfileViewModel.swift
//  CoupleMate
//
//  Created by 山田大陽 on 2025/04/28.
//
import Foundation
import UIKit
import Combine

class ProfileViewModel: ObservableObject {
    // 表示用の公開プロパティ
    @Published var profile: UserProfile
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedImage: UIImage?
    @Published var isImageUploading = false
    @Published var showSuccessMessage = false
    
    // 編集用フォームのプロパティ
    @Published var name: String = ""
    @Published var bio: String = ""
    @Published var birthDate: Date?
    @Published var interests: [String] = []
    @Published var relationshipStatus: String = ""
    @Published var anniversaryDate: Date?
    
    private let profileService = ProfileService()
    private let imageManager = ProfileImageManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(userID: String = UUID().uuidString) {
        self.profile = UserProfile(id: userID)
        loadProfile(userID: userID)
    }
    
    func loadProfile(userID: String) {
        isLoading = true
        profileService.fetchProfile(userID: userID)
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
    
    private func updateFormFields(with profile: UserProfile) {
        name = profile.name
        bio = profile.bio
        birthDate = profile.birthDate
        interests = profile.interests
        relationshipStatus = profile.relationshipStatus
        anniversaryDate = profile.anniversaryDate
    }
    
    func saveProfile() {
        isLoading = true
        
        // フォームの内容をプロフィールに反映
        var updatedProfile = profile
        updatedProfile.name = name
        updatedProfile.bio = bio
        updatedProfile.birthDate = birthDate
        updatedProfile.interests = interests
        updatedProfile.relationshipStatus = relationshipStatus
        updatedProfile.anniversaryDate = anniversaryDate
        
        // 選択された画像がある場合はアップロード
        if let image = selectedImage {
            uploadProfileImage(image) { [weak self] result in
                switch result {
                case .success(let url):
                    updatedProfile.profileImageURL = url
                    self?.saveProfileData(updatedProfile)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        } else {
            saveProfileData(updatedProfile)
        }
    }
    
    private func saveProfileData(_ updatedProfile: UserProfile) {
        profileService.saveProfile(updatedProfile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.profile = updatedProfile
                    self?.showSuccessMessage = true
                }
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
    
    // 興味・関心事を追加するメソッド
    func addInterest(_ interest: String) {
        if !interest.isEmpty && !interests.contains(interest) {
            interests.append(interest)
        }
    }
    
    // 興味・関心事を削除するメソッド
    func removeInterest(at index: Int) {
        if interests.indices.contains(index) {
            interests.remove(at: index)
        }
    }
}
