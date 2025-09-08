import SwiftUI
import Foundation
import UIKit
import Combine
import PhotosUI

@MainActor
class ProfileViewModel: ObservableObject {
    // 表示用プロパティ
    @Published var profile: User
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var selectedImage: UIImage?
    @Published var isImageUploading = false
    @Published var showSuccessMessage = false
    @Published var posts: [Post] = []

    // 編集用プロパティ
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var website: String = ""
    @Published var location: String = ""
    @Published var birthday: Date = Date()
    @Published var profileImage: UIImage?
    @Published var coverImage: UIImage?
    @Published var isProcessing = false
    
    // MARK: - Form Validation Properties
    @Published var emailValidation: ValidationResult = .valid
    @Published var nameValidation: ValidationResult = .valid
    @Published var usernameValidation: ValidationResult = .valid
    @Published var bioValidation: ValidationResult = .valid
    @Published var websiteValidation: ValidationResult = .valid
    @Published var locationValidation: ValidationResult = .valid
    @Published var birthdayValidation: ValidationResult = .valid
    
    // MARK: - Username Availability Properties
    @Published var isUsernameAvailable: Bool? = nil
    @Published var isValidatingUsername = false
    @Published var usernameCheckMessage: String? = nil
    
    // MARK: - Image Upload Properties
    @Published var profileImageUploadProgress: Double = 0.0
    @Published var coverImageUploadProgress: Double = 0.0
    @Published var isProfileImageUploading = false
    @Published var isCoverImageUploading = false
    @Published var profileImageUploadError: ProfileError?
    @Published var coverImageUploadError: ProfileError?
    
    // MARK: - Enhanced Error Handling Properties
    @Published var networkStatus: NetworkMonitor.ConnectionType = .unknown
    @Published var isOffline = false
    @Published var showNetworkError = false
    @Published var showValidationErrors = false
    @Published var validationErrorMessages: [String] = []
    @Published var showSuccessAlert = false
    @Published var successMessage = ""
    @Published var retryAttempts = 0
    @Published var maxRetryAttempts = 3
    @Published var isRetrying = false
    
    // MARK: - Form State Properties
    @Published var hasUnsavedChanges = false
    @Published var isFormValid = false
    
    private let userAPIService = UserAPIService()
    private let postAPIService = PostAPIService()
    private let imageManager = ProfileImageManager()
    private let imageUploadService = ImageUploadService() // 追加: 画像アップロードサービス
    private let errorHandler = ProfileErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Upload Cancellation
    private var profileImageUploadTask: Task<String?, Never>?
    private var coverImageUploadTask: Task<String?, Never>?
    
    // MARK: - Debounced Username Validation
    private var usernameValidationWorkItem: DispatchWorkItem?
    private let usernameValidationDelay: TimeInterval = 0.8
    
    init(userID: Int) {
        self.profile = User(
            id: userID,
            email: "",
            name: "",
            username: "",
            profileImageURL: nil,
            profileIconImageURL: nil,
            coverImageURL: nil,
            bio: "",
            city: "",
            location: "",
            birthday: "",
            postCount: 0,
            website: "",
            followingCount: 0,
            followersCount: 0,
            hasCompletedSetup: false,
            createdAt: nil,
            isVerified: false,
            joinedDate: ""
        )
        loadProfile(userID: userID)
        loadUserPosts(userID: userID)
    }
    
    // プロフィール編集用の初期化処理を追加
    init(profile: User) {
        self.profile = profile
        self.email = profile.email ?? ""
        self.name = profile.name ?? ""
        self.username = profile.username ?? ""
        self.bio = profile.bio ?? ""
        self.website = profile.website ?? ""
        self.location = profile.location ?? ""
        
        // 誕生日の初期化
        if let birthdayString = profile.birthday, !birthdayString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.birthday = formatter.date(from: birthdayString) ?? Date()
        }
        
        // ユーザーストーリーを読み込む
        loadUserPosts(userID: profile.id)
        
        // Set up real-time form validation
        setupFormValidation()
        
        // Set up network monitoring
        setupNetworkMonitoring()
    }
    
    // userIDをInt型に変更
    func loadProfile(userID: Int) {
        isLoading = true
        userAPIService.fetchProfile(userID: String(userID)) // String型に変換
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
    
    // ユーザーのストーリーを読み込むメソッドを追加
    func loadUserPosts(userID: Int) {
        isLoading = true
        
        Task {
            do {
                let fetchedPosts = try await postAPIService.fetchUserPosts(userId: userID)
                await MainActor.run {
                    self.posts = fetchedPosts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Form Validation Setup
    private func setupFormValidation() {
        // Real-time validation for email
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.emailValidation = ProfileFormValidation.validateEmail(email)
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
        
        // Real-time validation for name
        $name
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] name in
                self?.nameValidation = ProfileFormValidation.validateName(name)
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
        
        // Real-time validation for username with availability checking
        $username
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] username in
                self?.validateUsernameWithAvailability(username)
            }
            .store(in: &cancellables)
        
        // Real-time validation for bio
        $bio
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] bio in
                self?.bioValidation = ProfileFormValidation.validateBio(bio)
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
        
        // Real-time validation for website
        $website
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] website in
                self?.websiteValidation = ProfileFormValidation.validateWebsite(website)
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
        
        // Real-time validation for location
        $location
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.locationValidation = ProfileFormValidation.validateLocation(location)
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
        
        // Real-time validation for birthday
        $birthday
            .sink { [weak self] birthday in
                self?.birthdayValidation = ProfileFormValidation.validateBirthday(birthday)
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
        
        // Track unsaved changes
        Publishers.CombineLatest4($email, $name, $username, $bio)
            .combineLatest(Publishers.CombineLatest3($website, $location, $birthday))
            .sink { [weak self] _, _ in
                self?.checkForUnsavedChanges()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Username Validation with Availability Checking
    private func validateUsernameWithAvailability(_ username: String) {
        // Cancel previous validation work
        usernameValidationWorkItem?.cancel()
        
        // First, validate username format
        let formatValidation = ProfileFormValidation.validateUsername(username)
        usernameValidation = formatValidation
        
        // If format is invalid, don't check availability
        guard formatValidation.isValid else {
            isUsernameAvailable = nil
            usernameCheckMessage = nil
            updateFormValidityState()
            return
        }
        
        // If username hasn't changed from original, mark as available
        if username == profile.username {
            isUsernameAvailable = true
            usernameCheckMessage = "現在のユーザーネームです"
            updateFormValidityState()
            return
        }
        
        // Create debounced work item for availability checking
        let workItem = DispatchWorkItem { [weak self] in
            self?.checkUsernameAvailability(username)
        }
        
        usernameValidationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + usernameValidationDelay, execute: workItem)
    }
    
    private func checkUsernameAvailability(_ username: String) {
        isValidatingUsername = true
        usernameCheckMessage = "確認中..."
        
        userAPIService.checkUsernameAvailability(username)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isValidatingUsername = false
                if case .failure(let error) = completion {
                    self?.isUsernameAvailable = nil
                    self?.usernameCheckMessage = "確認に失敗しました"
                    print("❌ ユーザーネーム確認エラー: \(error.localizedDescription)")
                }
                self?.updateFormValidityState()
            } receiveValue: { [weak self] isAvailable in
                self?.isUsernameAvailable = isAvailable
                self?.usernameCheckMessage = isAvailable ? "利用可能です" : "既に使用されています"
                if !isAvailable {
                    self?.usernameValidation = .invalid(message: "このユーザーネームは既に使用されています")
                }
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Form State Management
    private func updateFormValidityState() {
        let allValidationsValid = emailValidation.isValid &&
                                 nameValidation.isValid &&
                                 usernameValidation.isValid &&
                                 bioValidation.isValid &&
                                 websiteValidation.isValid &&
                                 locationValidation.isValid &&
                                 birthdayValidation.isValid
        
        let usernameAvailabilityValid = isUsernameAvailable ?? false
        
        isFormValid = allValidationsValid && usernameAvailabilityValid && !isValidatingUsername
    }
    
    private func checkForUnsavedChanges() {
        let currentEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let originalEmail = profile.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originalName = profile.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originalUsername = profile.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originalBio = profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originalWebsite = profile.website?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originalLocation = profile.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Check birthday changes
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentBirthdayString = formatter.string(from: birthday)
        let originalBirthdayString = profile.birthday ?? ""
        
        hasUnsavedChanges = currentEmail != originalEmail ||
                           currentName != originalName ||
                           currentUsername != originalUsername ||
                           currentBio != originalBio ||
                           currentWebsite != originalWebsite ||
                           currentLocation != originalLocation ||
                           currentBirthdayString != originalBirthdayString ||
                           profileImage != nil ||
                           coverImage != nil
    }

    private func updateFormFields(with profile: User) {
        email = profile.email ?? ""
        name = profile.name ?? ""
        username = profile.username ?? ""
        bio = profile.bio ?? ""
        website = profile.website ?? ""
        location = profile.location ?? ""
        
        // 誕生日の更新
        if let birthdayString = profile.birthday, !birthdayString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthday = formatter.date(from: birthdayString) ?? Date()
        }
    }

    func saveProfile() {
        isLoading = true
        var updatedProfile = profile
        updatedProfile.email = email
        updatedProfile.name = name
        updatedProfile.username = username
        updatedProfile.bio = bio
        updatedProfile.website = website
        updatedProfile.location = location
        
        // 誕生日の保存
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        updatedProfile.birthday = formatter.string(from: birthday)

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
    
    // MARK: - Enhanced Profile Save Functionality
    @MainActor
    func updateProfile() async {
        // Check network connectivity first
        guard canPerformNetworkOperation() else {
            return
        }
        
        // Validate form before saving
        guard isFormValid else {
            let validationErrors = getValidationErrors()
            validationErrorMessages = validationErrors
            showValidationErrors = true
            handleError(ProfileError.validationFailed(validationErrors), context: "profile_update")
            return
        }
        
        isProcessing = true
        clearAllErrors()
        
        do {
            var updatedProfile = profile
            updatedProfile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.website = website.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 誕生日の保存
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            updatedProfile.birthday = formatter.string(from: birthday)
            
            // プロフィール画像があれば先にアップロード
            if let image = profileImage {
                print("📤 プロフィール画像アップロード開始")
                if let imageUrl = await uploadProfileImageWithProgress(image) {
                    updatedProfile.profileImageURL = imageUrl
                    print("✅ プロフィール画像アップロード成功: \(imageUrl)")
                } else {
                    print("❌ プロフィール画像アップロード失敗")
                    isProcessing = false
                    return
                }
            }
            
            // カバー画像があれば先にアップロード
            if let image = coverImage {
                print("📤 カバー画像アップロード開始")
                if let imageUrl = await uploadCoverImageWithProgress(image) {
                    updatedProfile.coverImageURL = imageUrl
                    print("✅ カバー画像アップロード成功: \(imageUrl)")
                } else {
                    print("❌ カバー画像アップロード失敗")
                    isProcessing = false
                    return
                }
            }
            
            // プロフィール情報を更新
            print("📤 プロフィール更新開始")
            let savedProfile = try await updateProfileAsync(updatedProfile)
            
            // 成功したらプロフィール情報を更新
            self.profile = savedProfile
            
            // Clear selected images after successful upload
            self.profileImage = nil
            self.coverImage = nil
            self.hasUnsavedChanges = false
            
            // Reset retry attempts on success
            resetRetryAttempts()
            
            isProcessing = false
            showSuccessMessage("プロフィールが正常に更新されました")
            print("✅ プロフィール更新完了")
            
        } catch {
            isProcessing = false
            
            // Handle specific error scenarios
            let profileError = convertToProfileError(error)
            
            // Check if we should retry automatically
            if shouldRetryOperation(for: profileError) {
                print("🔄 自動リトライを実行します (試行回数: \(retryAttempts + 1)/\(maxRetryAttempts))")
                
                // Wait before retry
                try? await Task.sleep(nanoseconds: UInt64(profileError.retryDelay * 1_000_000_000))
                
                // Retry the operation
                await retryLastOperation(context: "profile_update")
            } else {
                handleError(error, context: "profile_update")
                print("❌ プロフィール更新エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// Gets all current validation errors
    private func getValidationErrors() -> [String] {
        var errors: [String] = []
        
        if !emailValidation.isValid, let error = emailValidation.errorMessage {
            errors.append(error)
        }
        if !nameValidation.isValid, let error = nameValidation.errorMessage {
            errors.append(error)
        }
        if !usernameValidation.isValid, let error = usernameValidation.errorMessage {
            errors.append(error)
        }
        if !bioValidation.isValid, let error = bioValidation.errorMessage {
            errors.append(error)
        }
        if !websiteValidation.isValid, let error = websiteValidation.errorMessage {
            errors.append(error)
        }
        if !locationValidation.isValid, let error = locationValidation.errorMessage {
            errors.append(error)
        }
        if !birthdayValidation.isValid, let error = birthdayValidation.errorMessage {
            errors.append(error)
        }
        
        if let isAvailable = isUsernameAvailable, !isAvailable {
            errors.append("ユーザーネームが利用できません")
        }
        
        return errors
    }
    
    // 非同期でプロフィール更新するメソッドを追加
    private func updateProfileAsync(_ user: User) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            userAPIService.updateProfile(user)
                .receive(on: DispatchQueue.main)
                .sink { completionResult in
                    switch completionResult {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        break
                    }
                } receiveValue: { updatedUser in
                    continuation.resume(returning: updatedUser)
                }
                .store(in: &cancellables)
        }
    }
    
    // 非同期でプロフィール保存するメソッドを追加（後方互換性のため保持）
    private func saveProfileAsync(_ user: User) async throws {
        _ = try await updateProfileAsync(user)
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
    
    // MARK: - Image Selection and Upload Handling
    
    /// Handles profile image selection from PhotosPicker
    func handleProfileImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                        self.checkForUnsavedChanges()
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleError(ProfileError.imageUploadFailed(error))
                }
            }
        }
    }
    
    /// Handles cover image selection from PhotosPicker
    func handleCoverImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.coverImage = image
                        self.checkForUnsavedChanges()
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleError(ProfileError.imageUploadFailed(error))
                }
            }
        }
    }
    
    /// Uploads profile image with progress tracking and error handling
    private func uploadProfileImageAsync(_ image: UIImage) async throws -> String {
        guard let url = await uploadProfileImageWithProgress(image) else {
            throw ProfileError.imageUploadFailed(NSError(domain: "ProfileImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: "プロフィール画像のアップロードに失敗しました"]))
        }
        return url
    }
    
    /// Uploads cover image with progress tracking and error handling
    private func uploadCoverImageAsync(_ image: UIImage) async throws -> String {
        guard let url = await uploadCoverImageWithProgress(image) else {
            throw ProfileError.imageUploadFailed(NSError(domain: "CoverImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: "カバー画像のアップロードに失敗しました"]))
        }
        return url
    }
    
    /// Enhanced profile image upload with progress tracking
    func uploadProfileImageWithProgress(_ image: UIImage) async -> String? {
        // Validate image before upload
        guard await validateImageForUpload(image) else {
            await handleError(ProfileError.unsupportedImageFormat, context: "profile_image_upload")
            return nil
        }
        
        isProfileImageUploading = true
        profileImageUploadProgress = 0.0
        profileImageUploadError = nil
        
        // Create upload task for cancellation support
        profileImageUploadTask = Task {
            do {
                // Simulate progress updates (in real implementation, this would come from the upload service)
                await updateUploadProgress(for: .profile, progress: 0.1)
                
                let url: String = try await withCheckedThrowingContinuation { continuation in
                    userAPIService.uploadProfileImage(image)
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] completion in
                            Task { @MainActor in
                                self?.isProfileImageUploading = false
                                if case .failure(let error) = completion {
                                    self?.profileImageUploadError = self?.convertToProfileError(error)
                                    continuation.resume(throwing: error)
                                }
                            }
                        } receiveValue: { url in
                            Task { @MainActor in
                                self.profileImageUploadProgress = 1.0
                            }
                            continuation.resume(returning: url)
                        }
                        .store(in: &cancellables)
                }
                
                await MainActor.run {
                    profileImageUploadProgress = 1.0
                    isProfileImageUploading = false
                }
                
                return url
            } catch {
                await MainActor.run {
                    isProfileImageUploading = false
                    profileImageUploadError = convertToProfileError(error)
                    handleError(error, context: "profile_image_upload")
                }
                return nil
            }
        }
        
        return await profileImageUploadTask?.value
    }
    
    /// Enhanced cover image upload with progress tracking
    func uploadCoverImageWithProgress(_ image: UIImage) async -> String? {
        // Validate image before upload
        guard await validateImageForUpload(image) else {
            await handleError(ProfileError.unsupportedImageFormat, context: "cover_image_upload")
            return nil
        }
        
        isCoverImageUploading = true
        coverImageUploadProgress = 0.0
        coverImageUploadError = nil
        
        // Create upload task for cancellation support
        coverImageUploadTask = Task {
            do {
                // Simulate progress updates
                await updateUploadProgress(for: .cover, progress: 0.1)
                
                let url: String = try await withCheckedThrowingContinuation { continuation in
                    userAPIService.uploadCoverImage(image)
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] completion in
                            Task { @MainActor in
                                self?.isCoverImageUploading = false
                                if case .failure(let error) = completion {
                                    self?.coverImageUploadError = self?.convertToProfileError(error)
                                    continuation.resume(throwing: error)
                                }
                            }
                        } receiveValue: { url in
                            Task { @MainActor in
                                self.coverImageUploadProgress = 1.0
                            }
                            continuation.resume(returning: url)
                        }
                        .store(in: &cancellables)
                }
                
                await MainActor.run {
                    coverImageUploadProgress = 1.0
                    isCoverImageUploading = false
                }
                
                return url
            } catch {
                await MainActor.run {
                    isCoverImageUploading = false
                    coverImageUploadError = convertToProfileError(error)
                    handleError(error, context: "cover_image_upload")
                }
                return nil
            }
        }
        
        return await coverImageUploadTask?.value
    }
    
    // MARK: - Upload Progress and Validation
    
    @MainActor
    private func updateUploadProgress(for imageType: ImageType, progress: Double) {
        switch imageType {
        case .profile:
            profileImageUploadProgress = progress
        case .cover:
            coverImageUploadProgress = progress
        }
    }
    
    private enum ImageType {
        case profile
        case cover
    }
    
    private func validateImageForUpload(_ image: UIImage) async -> Bool {
        // Check image size
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return false
        }
        
        let maxSizeInBytes = 10 * 1024 * 1024 // 10MB
        if imageData.count > maxSizeInBytes {
            await handleError(ProfileError.imageTooLarge(maxSize: 10))
            return false
        }
        
        // Check image dimensions
        let maxDimension: CGFloat = 2048
        if image.size.width > maxDimension || image.size.height > maxDimension {
            // Could implement automatic resizing here
            print("⚠️ Image dimensions exceed recommended size: \(image.size)")
        }
        
        return true
    }
    
    // MARK: - Upload Cancellation
    
    func cancelProfileImageUpload() {
        profileImageUploadTask?.cancel()
        profileImageUploadTask = nil
        isProfileImageUploading = false
        profileImageUploadProgress = 0.0
        profileImageUploadError = ProfileError.uploadCancelled
    }
    
    func cancelCoverImageUpload() {
        coverImageUploadTask?.cancel()
        coverImageUploadTask = nil
        isCoverImageUploading = false
        coverImageUploadProgress = 0.0
        coverImageUploadError = ProfileError.uploadCancelled
    }
    
    /// Removes selected profile image
    func removeProfileImage() {
        profileImage = nil
        checkForUnsavedChanges()
    }
    
    /// Removes selected cover image
    func removeCoverImage() {
        coverImage = nil
        checkForUnsavedChanges()
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

    // MARK: - Enhanced Error Handling
    private func handleError(_ error: Error, context: String = "") {
        let profileError = convertToProfileError(error)
        
        // Update error state
        errorMessage = profileError.errorDescription
        showError = true
        
        // Handle specific error types
        switch profileError {
        case .offlineError:
            isOffline = true
            showNetworkError = true
        case .validationFailed(let messages):
            validationErrorMessages = messages
            showValidationErrors = true
        case .networkError, .connectionTimeout, .slowConnection:
            showNetworkError = true
        default:
            break
        }
        
        // Use error handler for comprehensive handling
        errorHandler.handleError(profileError) { [weak self] in
            await self?.retryLastOperation(context: context)
        }
        
        print("❌ ProfileViewModel Error [\(context)]: \(profileError)")
    }
    
    private func convertToProfileError(_ error: Error) -> ProfileError {
        if let profileError = error as? ProfileError {
            return profileError
        }
        
        // Check network status
        if !networkMonitor.isConnected {
            return .offlineError
        }
        
        // Convert URL errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                return .offlineError
            case .timedOut:
                return .connectionTimeout
            case .networkConnectionLost:
                return .slowConnection
            default:
                return .networkError(urlError)
            }
        }
        
        // Convert image upload errors
        if let imageError = error as? ImageUploadError {
            switch imageError {
            case .imageConversionFailed:
                return .imageCompressionFailed
            case .fileSizeExceeded(_, let maxSize):
                return .imageTooLarge(maxSize: maxSize / (1024 * 1024)) // Convert to MB
            case .unsupportedImageFormat:
                return .unsupportedImageFormat
            case .uploadFailed(let reason):
                return .imageUploadFailed(NSError(domain: "ImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: reason]))
            default:
                return .imageUploadFailed(NSError(domain: "ImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: imageError.localizedDescription]))
            }
        }
        
        return .networkError(error)
    }
    
    private func retryLastOperation(context: String) async {
        isRetrying = true
        retryAttempts += 1
        
        defer {
            isRetrying = false
        }
        
        // Implement retry logic based on context
        switch context {
        case "profile_update":
            await updateProfile()
        case "profile_load":
            let userId = AuthService.shared.currentUser?.id ?? 0
            loadProfile(userID: userId)
        case "username_check":
            if !username.isEmpty {
                checkUsernameAvailability(username)
            }
        case "profile_image_upload":
            if let image = profileImage {
                _ = await uploadProfileImageWithProgress(image)
            }
        case "cover_image_upload":
            if let image = coverImage {
                _ = await uploadCoverImageWithProgress(image)
            }
        default:
            break
        }
    }
    
    /// Clears all error states
    func clearErrors() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Form Reset and Utility Methods
    
    /// Reset form fields to the current profile values
    func resetFormFields() {
        email = profile.email ?? ""
        name = profile.name ?? ""
        username = profile.username ?? ""
        bio = profile.bio ?? ""
        website = profile.website ?? ""
        location = profile.location ?? ""
        
        // 誕生日のリセット
        if let birthdayString = profile.birthday, !birthdayString.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthday = formatter.date(from: birthdayString) ?? Date()
        }
        
        profileImage = nil
        coverImage = nil
        
        // Reset validation states
        emailValidation = .valid
        nameValidation = .valid
        usernameValidation = .valid
        bioValidation = .valid
        websiteValidation = .valid
        locationValidation = .valid
        birthdayValidation = .valid
        
        // Reset username availability state
        isUsernameAvailable = nil
        isValidatingUsername = false
        usernameCheckMessage = nil
        
        // Reset form state
        hasUnsavedChanges = false
        isFormValid = false
        
        // Clear errors
        clearErrors()
    }
    
    /// Validates all form fields manually
    func validateAllFields() {
        emailValidation = ProfileFormValidation.validateEmail(email)
        nameValidation = ProfileFormValidation.validateName(name)
        usernameValidation = ProfileFormValidation.validateUsername(username)
        bioValidation = ProfileFormValidation.validateBio(bio)
        websiteValidation = ProfileFormValidation.validateWebsite(website)
        locationValidation = ProfileFormValidation.validateLocation(location)
        birthdayValidation = ProfileFormValidation.validateBirthday(birthday)
        
        // Check username availability if username is valid and different from current
        if usernameValidation.isValid && username != profile.username {
            checkUsernameAvailability(username)
        }
        
        updateFormValidityState()
    }
    
    /// Returns whether the profile can be saved
    var canSaveProfile: Bool {
        return isFormValid && !isProcessing && !isValidatingUsername && hasUnsavedChanges && !isOffline
    }
    
    // MARK: - Network Monitoring Setup
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if !isConnected {
                    self?.showNetworkError = true
                } else {
                    self?.showNetworkError = false
                    // Clear network-related errors when connection is restored
                    if self?.errorMessage?.contains("ネットワーク") == true || 
                       self?.errorMessage?.contains("インターネット") == true {
                        self?.clearErrors()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor connection type
        networkMonitor.$connectionType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionType in
                self?.networkStatus = connectionType
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Success Feedback
    
    func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccessAlert = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showSuccessAlert = false
        }
    }
    
    func clearSuccessMessage() {
        showSuccessAlert = false
        successMessage = ""
    }
    
    // MARK: - Enhanced Error State Management
    
    func clearAllErrors() {
        clearErrors()
        showNetworkError = false
        showValidationErrors = false
        validationErrorMessages.removeAll()
        profileImageUploadError = nil
        coverImageUploadError = nil
        retryAttempts = 0
        isRetrying = false
    }
    
    func clearValidationErrors() {
        showValidationErrors = false
        validationErrorMessages.removeAll()
    }
    
    func clearNetworkErrors() {
        showNetworkError = false
        if errorMessage?.contains("ネットワーク") == true || 
           errorMessage?.contains("インターネット") == true {
            clearErrors()
        }
    }
    
    // MARK: - Offline Handling
    
    func handleOfflineScenario() {
        if !networkMonitor.isConnected {
            handleError(ProfileError.offlineError)
        }
    }
    
    func canPerformNetworkOperation() -> Bool {
        guard networkMonitor.isConnected else {
            handleOfflineScenario()
            return false
        }
        return true
    }
    
    // MARK: - Retry Logic
    
    func shouldRetryOperation(for error: ProfileError) -> Bool {
        return error.shouldAutoRetry && retryAttempts < maxRetryAttempts
    }
    
    func resetRetryAttempts() {
        retryAttempts = 0
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
