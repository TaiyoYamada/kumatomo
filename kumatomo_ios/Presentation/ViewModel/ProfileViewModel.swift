import SwiftUI
import Foundation
import UIKit
import Combine
import PhotosUI
import Resolver

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
    @Published var isLoadingMore: Bool = false
    @Published var hasMorePosts: Bool = true

    // 編集用プロパティ
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var bio: String = ""
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
    
    // MARK: - Enhanced Image State Properties
    @Published var hasUnsavedProfileImage: Bool = false
    @Published var hasUnsavedCoverImage: Bool = false
    @Published var selectedProfileItem: PhotosPickerItem?
    @Published var selectedCoverItem: PhotosPickerItem?
    
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
    
    // MARK: - Computed Properties
    var canSaveProfile: Bool {
        return isFormValid && hasUnsavedChanges && !isProcessing && !isValidatingUsername && !isOffline
    }
    
    @Injected var userAPIService: UserAPIService
    @Injected var postAPIService: PostAPIService
    private let imageManager = ProfileImageManager()
    private let imageUploadService = ImageUploadService() // 追加: 画像アップロードサービス
    private let errorHandler = ProfileErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentPage: Int = 1
    private let postsPerPage: Int = 20
    
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
            coverImageURL: nil,
            bio: "",
            location: "",
            birthday: "",
            postCount: 0,
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
    
    // ユーザーのストーリーを読み込む（初回/リフレッシュ）
    func loadUserPosts(userID: Int) {
        isLoading = true
        currentPage = 1
        hasMorePosts = true

        Task {
            do {
                let fetched = try await postAPIService.fetchUserPosts(userId: userID, page: currentPage, limit: postsPerPage)
                await MainActor.run {
                    self.posts = fetched
                    self.isLoading = false
                    self.hasMorePosts = fetched.count >= self.postsPerPage
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoading = false
                }
            }
        }
    }

    // 追加読み込み（無限スクロール）
    func loadMoreUserPosts(userID: Int) {
        guard !isLoadingMore && hasMorePosts else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1

        Task {
            do {
                let fetched = try await postAPIService.fetchUserPosts(userId: userID, page: nextPage, limit: postsPerPage)
                await MainActor.run {
                    self.posts.append(contentsOf: fetched)
                    self.currentPage = nextPage
                    self.hasMorePosts = fetched.count >= self.postsPerPage
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                    self.isLoadingMore = false
                }
            }
        }
    }
    
    // MARK: - Enhanced Form Validation System (Task 3.4)
    
    private func setupFormValidation() {
        setupFieldValidation()
        setupUsernameAvailabilityValidation()
        setupFormStateTracking()
        setupValidationResultTracking()
    }
    
    
    private func setupFieldValidation() {
        // Real-time validation for email with enhanced feedback
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateEmailField(email)
            }
            .store(in: &cancellables)
        
        // Real-time validation for name with enhanced feedback
        $name
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] name in
                self?.validateNameField(name)
            }
            .store(in: &cancellables)
        
        // Real-time validation for bio with character count
        $bio
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] bio in
                self?.validateBioField(bio)
            }
            .store(in: &cancellables)
        
        
        // Real-time validation for location
        $location
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.validateLocationField(location)
            }
            .store(in: &cancellables)
        
        // Real-time validation for birthday with age validation
        $birthday
            .sink { [weak self] birthday in
                self?.validateBirthdayField(birthday)
            }
            .store(in: &cancellables)
    }
    
    private func setupUsernameAvailabilityValidation() {
        $username
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] username in
                self?.validateUsernameWithAvailability(username)
            }
            .store(in: &cancellables)
    }
    
    private func setupFormStateTracking() {
        Publishers.CombineLatest4($email, $name, $username, $bio)
            .combineLatest(Publishers.CombineLatest($location, $birthday))
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.checkForUnsavedChanges()
            }
            .store(in: &cancellables)
    }
    
    private func setupValidationResultTracking() {
        Publishers.CombineLatest4($emailValidation, $nameValidation, $usernameValidation, $bioValidation)
            .combineLatest(Publishers.CombineLatest($locationValidation, $birthdayValidation))
            .combineLatest($isUsernameAvailable, $isValidatingUsername)
            .sink { [weak self] _ in
                self?.updateFormValidityState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Enhanced Field Validation Methods
    
    private func validateEmailField(_ email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            emailValidation = .valid // Email can be empty initially
        } else {
            emailValidation = ProfileFormValidation.validateEmail(trimmedEmail)
        }
        
        updateFormValidityState()
        logValidationResult(field: "email", result: emailValidation)
    }
    
    private func validateNameField(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        nameValidation = ProfileFormValidation.validateName(trimmedName)
        updateFormValidityState()
        logValidationResult(field: "name", result: nameValidation)
    }
    
    private func validateBioField(_ bio: String) {
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        bioValidation = ProfileFormValidation.validateBio(trimmedBio)
        
        // Add character count information
        let characterCount = bio.count
        let maxCharacters = 500
        
        if characterCount > Int(Double(maxCharacters) * 0.8) { // Warn at 80% capacity
            print("📝 Bio character count: \(characterCount)/\(maxCharacters)")
        }
        
        updateFormValidityState()
        logValidationResult(field: "bio", result: bioValidation)
    }
    
    private func validateLocationField(_ location: String) {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        locationValidation = ProfileFormValidation.validateLocation(trimmedLocation)
        updateFormValidityState()
        logValidationResult(field: "location", result: locationValidation)
    }
    
    private func validateBirthdayField(_ birthday: Date) {
        birthdayValidation = ProfileFormValidation.validateBirthday(birthday)
        
        // Add age calculation for feedback
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        if let age = ageComponents.year {
            print("🎂 Calculated age: \(age)")
        }
        
        updateFormValidityState()
        logValidationResult(field: "birthday", result: birthdayValidation)
    }
    

    private func logValidationResult(field: String, result: ValidationResult) {
        switch result {
        case .valid:
            print("✅ \(field) validation: valid")
        case .invalid(let message):
            print("❌ \(field) validation: \(message)")
        }
    }
    
    // MARK: - Enhanced Username Validation with Debounced API Calls
    
    private func validateUsernameWithAvailability(_ username: String) {
        // Cancel previous validation work
        usernameValidationWorkItem?.cancel()
        
        // First, validate username format
        let formatValidation = ProfileFormValidation.validateUsername(username)
        usernameValidation = formatValidation
        
        // Reset availability state when format is invalid
        if !formatValidation.isValid {
            isUsernameAvailable = nil
            usernameCheckMessage = nil
            updateFormValidityState()
            logValidationResult(field: "username", result: formatValidation)
            return
        }
        
        // If username hasn't changed from original, mark as available
        if username == profile.username {
            isUsernameAvailable = true
            usernameCheckMessage = "現在のユーザーネームです"
            updateFormValidityState()
            print("✅ Username unchanged from original")
            return
        }
        
        // Create debounced work item for availability checking
        let workItem = DispatchWorkItem { [weak self] in
            self?.performUsernameAvailabilityCheck(username)
        }
        
        usernameValidationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + usernameValidationDelay, execute: workItem)
        
        print("⏳ Username availability check scheduled for: \(username)")
    }
    
    private func performUsernameAvailabilityCheck(_ username: String) {
        isValidatingUsername = true
        usernameCheckMessage = "確認中..."
        
        print("🔍 Checking username availability: \(username)")
        
        userAPIService.checkUsernameAvailability(username)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isValidatingUsername = false
                if case .failure(let error) = completion {
                    self?.handleUsernameCheckError(error)
                }
                self?.updateFormValidityState()
            } receiveValue: { [weak self] isAvailable in
                self?.handleUsernameAvailabilityResult(username: username, isAvailable: isAvailable)
            }
            .store(in: &cancellables)
    }
    
    private func handleUsernameAvailabilityResult(username: String, isAvailable: Bool) {
        isUsernameAvailable = isAvailable
        usernameCheckMessage = isAvailable ? "利用可能です" : "既に使用されています"
        
        if !isAvailable {
            usernameValidation = .invalid(message: "このユーザーネームは既に使用されています")
        }
        
        updateFormValidityState()
        
        let status = isAvailable ? "✅ available" : "❌ unavailable"
        print("🔍 Username '\(username)' is \(status)")
    }
    

    private func handleUsernameCheckError(_ error: Error) {
        isUsernameAvailable = nil
        usernameCheckMessage = "確認に失敗しました"
        
        print("❌ Username availability check failed: \(error.localizedDescription)")
        
        // Don't mark form as invalid due to network errors
        // User can still proceed if format validation passes
    }
    
    // MARK: - Enhanced Form State Management
    
    private func updateFormValidityState() {
        let fieldValidationsValid = emailValidation.isValid &&
                                    nameValidation.isValid &&
                                    usernameValidation.isValid &&
                                    bioValidation.isValid &&
                                    locationValidation.isValid &&
                                    birthdayValidation.isValid
        
        let usernameAvailabilityValid = isUsernameAvailable ?? false
        let notValidatingUsername = !isValidatingUsername
        
        let previousFormValid = isFormValid
        isFormValid = fieldValidationsValid && usernameAvailabilityValid && notValidatingUsername
        
        // Log form validity changes
        if previousFormValid != isFormValid {
            print("📋 Form validity changed: \(isFormValid ? "valid" : "invalid")")
            if !isFormValid {
                logFormValidationIssues()
            }
        }
    }
    
    private func logFormValidationIssues() {
        var issues: [String] = []
        
        if !emailValidation.isValid, let error = emailValidation.errorMessage {
            issues.append("Email: \(error)")
        }
        if !nameValidation.isValid, let error = nameValidation.errorMessage {
            issues.append("Name: \(error)")
        }
        if !usernameValidation.isValid, let error = usernameValidation.errorMessage {
            issues.append("Username: \(error)")
        }
        if !bioValidation.isValid, let error = bioValidation.errorMessage {
            issues.append("Bio: \(error)")
        }
        if !locationValidation.isValid, let error = locationValidation.errorMessage {
            issues.append("Location: \(error)")
        }
        if !birthdayValidation.isValid, let error = birthdayValidation.errorMessage {
            issues.append("Birthday: \(error)")
        }
        if let isAvailable = isUsernameAvailable, !isAvailable {
            issues.append("Username: not available")
        }
        if isValidatingUsername {
            issues.append("Username: still validating")
        }
        
        if !issues.isEmpty {
            print("❌ Form validation issues: \(issues.joined(separator: ", "))")
        }
    }
    

    func getValidationSummary() -> ValidationSummary {
        return ValidationSummary(
            emailValidation: emailValidation,
            nameValidation: nameValidation,
            usernameValidation: usernameValidation,
            bioValidation: bioValidation,
            locationValidation: locationValidation,
            birthdayValidation: birthdayValidation,
            isUsernameAvailable: isUsernameAvailable,
            isValidatingUsername: isValidatingUsername,
            isFormValid: isFormValid,
            hasUnsavedChanges: hasUnsavedChanges
        )
    }
    
    func validateAllFields() {
        print("🔍 Performing comprehensive form validation...")
        
        validateEmailField(email)
        validateNameField(name)
        validateBioField(bio)
        
        validateLocationField(location)
        validateBirthdayField(birthday)
        
        // Validate username format and check availability if needed
        let formatValidation = ProfileFormValidation.validateUsername(username)
        usernameValidation = formatValidation
        
        if formatValidation.isValid && username != profile.username && !username.isEmpty {
            performUsernameAvailabilityCheck(username)
        }
        
        updateFormValidityState()
        
        let summary = getValidationSummary()
        print("📋 Validation summary: \(summary.isFormValid ? "✅ Valid" : "❌ Invalid")")
    }
    
    
    private func checkForUnsavedChanges() {
        enhancedCheckForUnsavedChanges()
    }

    private func updateFormFields(with profile: User) {
        email = profile.email ?? ""
        name = profile.name ?? ""
        username = profile.username ?? ""
        bio = profile.bio ?? ""
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
    
    // MARK: - Profile Creation Logic
    
    @MainActor
    func createProfile() async -> Bool {
        // Check network connectivity first
        guard canPerformNetworkOperation() else {
            return false
        }
        
        // Validate form before creating
        guard isFormValid else {
            let validationErrors = getValidationErrors()
            validationErrorMessages = validationErrors
            showValidationErrors = true
            handleError(ProfileError.validationFailed(validationErrors), context: "profile_creation")
            return false
        }
        
        isProcessing = true
        clearAllErrors()
        
        do {
            // Create new user profile with form data
            var newProfile = User(
                id: 0, // Will be assigned by server
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                profileImageURL: nil,
                coverImageURL: nil,
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                birthday: nil,
                postCount: 0,
                followingCount: 0,
                followersCount: 0,
                hasCompletedSetup: false,
                createdAt: nil,
                isVerified: false,
                joinedDate: nil
            )
            
            // Format birthday
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            newProfile.birthday = formatter.string(from: birthday)
            
            // Upload profile image if selected
            if let image = profileImage {
                print("📤 プロフィール画像アップロード開始（作成時）")
                if let imageUrl = await uploadProfileImageWithProgress(image) {
                    newProfile.profileImageURL = imageUrl
                    print("✅ プロフィール画像アップロード成功（作成時）: \(imageUrl)")
                } else {
                    print("❌ プロフィール画像アップロード失敗（作成時）")
                    isProcessing = false
                    return false
                }
            }
            
            // Upload cover image if selected
            if let image = coverImage {
                print("📤 カバー画像アップロード開始（作成時）")
                if let imageUrl = await uploadCoverImageWithProgress(image) {
                    newProfile.coverImageURL = imageUrl
                    print("✅ カバー画像アップロード成功（作成時）: \(imageUrl)")
                } else {
                    print("❌ カバー画像アップロード失敗（作成時）")
                    isProcessing = false
                    return false
                }
            }
            
            // Create profile via API
            print("📤 プロフィール作成開始")
            let createdProfile = try await createProfileAsync(newProfile)
            
            // Success - update local state
            self.profile = createdProfile
            
            // Clear form state
            self.profileImage = nil
            self.coverImage = nil
            self.hasUnsavedChanges = false
            
            // Reset retry attempts on success
            resetRetryAttempts()
            
            isProcessing = false
            showSuccessMessage("プロフィールが正常に作成されました")
            print("✅ プロフィール作成完了")
            
            return true
            
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
                return await retryCreateProfile()
            } else {
                handleError(error, context: "profile_creation")
                print("❌ プロフィール作成エラー: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// Async wrapper for profile creation API call
    private func createProfileAsync(_ user: User) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            userAPIService.createProfile(user)
                .receive(on: DispatchQueue.main)
                .sink { completionResult in
                    switch completionResult {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        break
                    }
                } receiveValue: { createdUser in
                    continuation.resume(returning: createdUser)
                }
                .store(in: &cancellables)
        }
    }
    
    /// Retry profile creation with exponential backoff
    private func retryCreateProfile() async -> Bool {
        retryAttempts += 1
        return await createProfile()
    }
    
    /// Validates profile creation form with real-time feedback
    func validateProfileCreationForm() -> Bool {
        validateAllFields()
        
        // Additional validation for profile creation
        let requiredFieldsValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                    !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if !requiredFieldsValid {
            let missingFields = getMissingRequiredFields()
            validationErrorMessages = missingFields
            showValidationErrors = true
            return false
        }
        
        return isFormValid
    }
    
    /// Gets list of missing required fields for profile creation
    func getMissingRequiredFields() -> [String] {
        var missingFields: [String] = []
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("メールアドレスは必須です")
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("名前は必須です")
        }
        
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("ユーザーネームは必須です")
        }
        
        return missingFields
    }
    
    /// Resets the form for new profile creation
    func resetForProfileCreation() {
        // Clear all form fields
        email = ""
        name = ""
        username = ""
        bio = ""
        location = ""
        birthday = Date()
        profileImage = nil
        coverImage = nil
        
        // Reset image state
        hasUnsavedProfileImage = false
        hasUnsavedCoverImage = false
        selectedProfileItem = nil
        selectedCoverItem = nil
        
        // Reset validation states
        emailValidation = .valid
        nameValidation = .valid
        usernameValidation = .valid
        bioValidation = .valid
        locationValidation = .valid
        birthdayValidation = .valid
        
        // Reset username availability state
        isUsernameAvailable = nil
        isValidatingUsername = false
        usernameCheckMessage = nil
        
        // Reset form state
        hasUnsavedChanges = false
        isFormValid = false
        
        // Clear all errors
        clearAllErrors()
        
        print("📝 プロフィール作成フォームをリセットしました")
    }
    
    /// Checks if profile creation is allowed (all validations pass)
    var canCreateProfile: Bool {
        return isFormValid &&
                !isProcessing &&
                !isValidatingUsername &&
                !isOffline &&
                !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                (isUsernameAvailable ?? false)
    }
    
    // MARK: - Profile Deletion Logic (Task 3.3)
    
    /// State properties for profile deletion
    @Published var showDeleteConfirmation = false
    @Published var isDeletingProfile = false
    @Published var deleteConfirmationText = ""
    @Published var isDeleteConfirmationValid = false
    
    /// Initiates profile deletion with confirmation dialog
    func initiateProfileDeletion() {
        guard canPerformNetworkOperation() else {
            return
        }
        
        guard profile.canBeDeleted() else {
            handleError(ProfileError.serverError(statusCode: 403, message: "このプロフィールは削除できません"), context: "profile_deletion")
            return
        }
        
        showDeleteConfirmation = true
        deleteConfirmationText = ""
        isDeleteConfirmationValid = false
        
        print("⚠️ プロフィール削除の確認ダイアログを表示")
    }
    
    /// Validates delete confirmation input
    func validateDeleteConfirmation(_ input: String) {
        let expectedText = "削除"
        isDeleteConfirmationValid = input.trimmingCharacters(in: .whitespacesAndNewlines) == expectedText
        deleteConfirmationText = input
    }
    
    /// Confirms and executes profile deletion
    @MainActor
    func confirmProfileDeletion() async -> Bool {
        guard isDeleteConfirmationValid else {
            handleError(ProfileError.validationFailed(["削除確認テキストが正しくありません"]), context: "profile_deletion")
            return false
        }
        
        guard canPerformNetworkOperation() else {
            return false
        }
        
        isDeletingProfile = true
        showDeleteConfirmation = false
        clearAllErrors()
        
        do {
            print("🗑️ プロフィール削除開始")
            let success = try await deleteProfileAsync(String(profile.id))
            
            if success {
                // Clear all local data
                await cleanupAfterDeletion()
                
                // Reset retry attempts on success
                resetRetryAttempts()
                
                isDeletingProfile = false
                showSuccessMessage("プロフィールが正常に削除されました")
                print("✅ プロフィール削除完了")
                
                return true
            } else {
                isDeletingProfile = false
                handleError(ProfileError.serverError(statusCode: 500, message: "プロフィールの削除に失敗しました"), context: "profile_deletion")
                return false
            }
            
        } catch {
            isDeletingProfile = false
            
            // Handle specific error scenarios
            let profileError = convertToProfileError(error)
            
            // Check if we should retry automatically
            if shouldRetryOperation(for: profileError) {
                print("🔄 自動リトライを実行します (試行回数: \(retryAttempts + 1)/\(maxRetryAttempts))")
                
                // Wait before retry
                try? await Task.sleep(nanoseconds: UInt64(profileError.retryDelay * 1_000_000_000))
                
                // Retry the operation
                return await retryDeleteProfile()
            } else {
                handleError(error, context: "profile_deletion")
                print("❌ プロフィール削除エラー: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// Async wrapper for profile deletion API call
    private func deleteProfileAsync(_ userID: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            userAPIService.deleteProfile(userID: userID)
                .receive(on: DispatchQueue.main)
                .sink { completionResult in
                    switch completionResult {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        break
                    }
                } receiveValue: { success in
                    continuation.resume(returning: success)
                }
                .store(in: &cancellables)
        }
    }
    
    /// Retry profile deletion with exponential backoff
    private func retryDeleteProfile() async -> Bool {
        retryAttempts += 1
        return await confirmProfileDeletion()
    }
    
    /// Cleans up local state after successful profile deletion
    @MainActor
    private func cleanupAfterDeletion() {
        // Clear profile data
        profile = User(
            id: 0,
            email: "",
            name: "",
            username: "",
            profileImageURL: nil,
            coverImageURL: nil,
            bio: "",
            location: "",
            birthday: "",
            postCount: 0,
            followingCount: 0,
            followersCount: 0,
            hasCompletedSetup: false,
            createdAt: nil,
            isVerified: false,
            joinedDate: ""
        )
        
        // Clear form fields
        resetForProfileCreation()
        
        // Clear posts
        posts.removeAll()
        
        // Clear image state
        hasUnsavedProfileImage = false
        hasUnsavedCoverImage = false
        selectedProfileItem = nil
        selectedCoverItem = nil
        
        // Clear any cached data
        ProfileCache.shared.removeUser(id: String(profile.id))
        
        // Clear authentication state (this would typically be handled by AuthService)
        // AuthTokenManager.shared.clearToken()
        
        print("🧹 プロフィール削除後のクリーンアップ完了")
    }
    
    /// Cancels profile deletion process
    func cancelProfileDeletion() {
        showDeleteConfirmation = false
        deleteConfirmationText = ""
        isDeleteConfirmationValid = false
        isDeletingProfile = false
        
        print("❌ プロフィール削除をキャンセルしました")
    }
    
    /// Checks if profile deletion is allowed
    var canDeleteProfile: Bool {
        return !isProcessing &&
                !isDeletingProfile &&
                !isOffline &&
                profile.id > 0 &&
                profile.canBeDeleted()
    }
    
    /// Gets deletion warning message based on profile data
    func getDeletionWarningMessage() -> String {
        let postCount = profile.postCount ?? 0
        let followersCount = profile.followersCount ?? 0
        
        var warnings: [String] = []
        
        if postCount > 0 {
            warnings.append("\(postCount)件の投稿")
        }
        
        if followersCount > 0 {
            warnings.append("\(followersCount)人のフォロワー")
        }
        
        if warnings.isEmpty {
            return "プロフィールを削除すると、すべてのデータが完全に削除されます。この操作は取り消すことができません。"
        } else {
            let dataList = warnings.joined(separator: "、")
            return "プロフィールを削除すると、\(dataList)を含むすべてのデータが完全に削除されます。この操作は取り消すことができません。"
        }
    }
    
    /// Shows deletion confirmation with appropriate warning
    func showDeletionConfirmationDialog() {
        let warningMessage = getDeletionWarningMessage()
        
        // This would typically trigger a UI alert with the warning message
        // For now, we'll just log it and show the confirmation
        print("⚠️ 削除警告: \(warningMessage)")
        
        initiateProfileDeletion()
    }

    // MARK: - Enhanced Profile Update Logic (Task 3.2)
    
    /// Enhanced profile update with optimistic UI updates and rollback on failure
    @MainActor
    func updateProfile() async -> Bool {
        // Check if there are unsaved changes
        guard hasUnsavedChanges else {
            showSuccessMessage("変更がありません")
            return true
        }
        
        // Check network connectivity first
        guard canPerformNetworkOperation() else {
            return false
        }
        
        // Validate form before saving
        guard isFormValid else {
            let validationErrors = getValidationErrors()
            validationErrorMessages = validationErrors
            showValidationErrors = true
            handleError(ProfileError.validationFailed(validationErrors), context: "profile_update")
            return false
        }
        
        // Store original profile for rollback
        let originalProfile = profile
        let originalFormState = captureCurrentFormState()
        
        isProcessing = true
        clearAllErrors()
        
        do {
            var updatedProfile = profile
            updatedProfile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedProfile.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 誕生日の保存
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            updatedProfile.birthday = formatter.string(from: birthday)
            
            // Optimistic UI update - update profile immediately
            self.profile = updatedProfile
            
            // プロフィール画像があれば先にアップロード
            if let image = profileImage {
                print("📤 プロフィール画像アップロード開始")
                if let imageUrl = await uploadProfileImageWithProgress(image) {
                    updatedProfile.profileImageURL = imageUrl
                    self.profile.profileImageURL = imageUrl // Update optimistically
                    print("✅ プロフィール画像アップロード成功: \(imageUrl)")
                } else {
                    print("❌ プロフィール画像アップロード失敗")
                    // Rollback optimistic update
                    await rollbackProfileUpdate(originalProfile, originalFormState)
                    return false
                }
            }
            
            // カバー画像があれば先にアップロード
            if let image = coverImage {
                print("📤 カバー画像アップロード開始")
                if let imageUrl = await uploadCoverImageWithProgress(image) {
                    updatedProfile.coverImageURL = imageUrl
                    self.profile.coverImageURL = imageUrl // Update optimistically
                    print("✅ カバー画像アップロード成功: \(imageUrl)")
                } else {
                    print("❌ カバー画像アップロード失敗")
                    // Rollback optimistic update
                    await rollbackProfileUpdate(originalProfile, originalFormState)
                    return false
                }
            }
            
            // プロフィール情報を更新
            print("📤 プロフィール更新開始")
            var savedProfile = try await updateProfileAsync(updatedProfile)
            
            // 画像が更新された場合、URLにユニークなタイムスタンプを追加してキャッシュを無効化する
            if hasUnsavedProfileImage {
                savedProfile.profileImageURL = self.bustCache(for: savedProfile.profileImageURL)
            }
            if hasUnsavedCoverImage {
                savedProfile.coverImageURL = self.bustCache(for: savedProfile.coverImageURL)
            }
            
            // 成功したらプロフィール情報を最終更新
            self.profile = savedProfile
            
            self.hasUnsavedChanges = false
            
            // Reset retry attempts on success
            resetRetryAttempts()
            
            isProcessing = false
            showSuccessMessage("プロフィールが正常に更新されました")
            print("✅ プロフィール更新完了")
            
            return true
            
        } catch {
            // Rollback optimistic update on failure
            await rollbackProfileUpdate(originalProfile, originalFormState)
            
            // Handle specific error scenarios
            let profileError = convertToProfileError(error)
            
            // Check if we should retry automatically
            if shouldRetryOperation(for: profileError) {
                print("🔄 自動リトライを実行します (試行回数: \(retryAttempts + 1)/\(maxRetryAttempts))")
                
                // Wait before retry
                try? await Task.sleep(nanoseconds: UInt64(profileError.retryDelay * 1_000_000_000))
                
                // Retry the operation
                return await retryUpdateProfile()
            } else {
                handleError(error, context: "profile_update")
                print("❌ プロフィール更新エラー: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// URL文字列にキャッシュ無効化のためのタイムスタンプを追加する
    private func bustCache(for urlString: String?) -> String? {
        guard var urlString = urlString, !urlString.isEmpty else { return nil }
        
        // 既存のクエリパラメータを削除して、新しいタイムスタンプだけを追加する
        if let url = URL(string: urlString), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.query = nil
            urlString = components.url?.absoluteString ?? urlString
        }
        
        let timestamp = Date().timeIntervalSince1970
        if urlString.contains("?") {
            return "\(urlString)&t=\(timestamp)"
        } else {
            return "\(urlString)?t=\(timestamp)"
        }
    }
    
    /// Captures current form state for rollback purposes
    private func captureCurrentFormState() -> FormState {
        return FormState(
            email: email,
            name: name,
            username: username,
            bio: bio,
            location: location,
            birthday: birthday,
            profileImage: profileImage,
            coverImage: coverImage,
            hasUnsavedChanges: hasUnsavedChanges,
            hasUnsavedProfileImage: hasUnsavedProfileImage,
            hasUnsavedCoverImage: hasUnsavedCoverImage,
            selectedProfileItem: selectedProfileItem,
            selectedCoverItem: selectedCoverItem
        )
    }
    
    /// Rolls back profile and form state on update failure
    @MainActor
    private func rollbackProfileUpdate(_ originalProfile: User, _ originalFormState: FormState) {
        print("🔄 プロフィール更新をロールバックしています...")
        
        // Restore original profile
        self.profile = originalProfile
        
        // Restore original form state
        self.email = originalFormState.email
        self.name = originalFormState.name
        self.username = originalFormState.username
        self.bio = originalFormState.bio
        self.location = originalFormState.location
        self.birthday = originalFormState.birthday
        self.profileImage = originalFormState.profileImage
        self.coverImage = originalFormState.coverImage
        self.hasUnsavedChanges = originalFormState.hasUnsavedChanges
        self.hasUnsavedProfileImage = originalFormState.hasUnsavedProfileImage
        self.hasUnsavedCoverImage = originalFormState.hasUnsavedCoverImage
        self.selectedProfileItem = originalFormState.selectedProfileItem
        self.selectedCoverItem = originalFormState.selectedCoverItem
        
        isProcessing = false
        
        print("✅ プロフィール更新のロールバック完了")
    }
    
    /// Retry profile update with exponential backoff
    private func retryUpdateProfile() async -> Bool {
        retryAttempts += 1
        return await updateProfile()
    }
    
    /// Shows confirmation dialog for unsaved changes
    func showUnsavedChangesConfirmation(onDiscard: @escaping () -> Void, onSave: @escaping () -> Void) {
        guard hasUnsavedChanges else {
            onDiscard()
            return
        }
        
        // This would typically trigger a UI alert
        // For now, we'll just call the appropriate callback
        // In a real implementation, this would show an alert with options
        print("⚠️ 未保存の変更があります")
    }
    
    /// Discards unsaved changes and reverts to original profile data
    func discardUnsavedChanges() {
        updateFormFields(with: profile)
        profileImage = nil
        coverImage = nil
        hasUnsavedProfileImage = false
        hasUnsavedCoverImage = false
        selectedProfileItem = nil
        selectedCoverItem = nil
        hasUnsavedChanges = false
        clearAllErrors()
        print("🗑️ 未保存の変更を破棄しました")
    }
    
    /// Checks if specific fields have been modified
    func hasFieldChanged(_ field: ProfileField) -> Bool {
        switch field {
        case .email:
            return email.trimmingCharacters(in: .whitespacesAndNewlines) != (profile.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        case .name:
            return name.trimmingCharacters(in: .whitespacesAndNewlines) != (profile.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        case .username:
            return username.trimmingCharacters(in: .whitespacesAndNewlines) != (profile.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        case .bio:
            return bio.trimmingCharacters(in: .whitespacesAndNewlines) != (profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        case .location:
            return location.trimmingCharacters(in: .whitespacesAndNewlines) != (profile.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        case .birthday:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let currentBirthdayString = formatter.string(from: birthday)
            return currentBirthdayString != (profile.birthday ?? "")
        case .profileImage:
            return hasUnsavedProfileImage
        case .coverImage:
            return hasUnsavedCoverImage
        }
    }
    
    /// Gets list of changed fields for display purposes
    func getChangedFields() -> [ProfileField] {
        return ProfileField.allCases.filter { hasFieldChanged($0) }
    }
    
    /// Enhanced unsaved changes tracking with field-level granularity
    private func enhancedCheckForUnsavedChanges() {
        let changedFields = getChangedFields()
        hasUnsavedChanges = !changedFields.isEmpty
        
        if hasUnsavedChanges {
            print("📝 変更されたフィールド: \(changedFields.map { $0.displayName }.joined(separator: ", "))")
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
        guard let item = item else {
            selectedProfileItem = nil
            return
        }
        
        selectedProfileItem = item
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.updateProfileImage(image)
                    }
                }
            } catch {
                await MainActor.run {
                    self.selectedProfileItem = nil
                    self.handleError(ProfileError.imageUploadFailed(error))
                }
            }
        }
    }
    
    /// Handles cover image selection from PhotosPicker
    func handleCoverImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else {
            selectedCoverItem = nil
            return
        }
        
        selectedCoverItem = item
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.updateCoverImage(image)
                    }
                }
            } catch {
                await MainActor.run {
                    self.selectedCoverItem = nil
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
    
    // MARK: - Enhanced Separate Image Handling Methods
    
    /// Updates profile image with local preview and state tracking
    func updateProfileImage(_ image: UIImage) {
        profileImage = image
        hasUnsavedProfileImage = true
        checkForUnsavedChanges()
        print("📸 プロフィール画像を更新しました")
    }
    
    /// Updates cover image with local preview and state tracking
    func updateCoverImage(_ image: UIImage) {
        coverImage = image
        hasUnsavedCoverImage = true
        checkForUnsavedChanges()
        print("🖼️ カバー画像を更新しました")
    }
    
    /// Deletes profile image and resets to default state
    func deleteProfileImage() {
        profileImage = nil
        hasUnsavedProfileImage = true
        selectedProfileItem = nil
        checkForUnsavedChanges()
        print("🗑️ プロフィール画像を削除しました")
    }
    
    /// Deletes cover image and resets to default state
    func deleteCoverImage() {
        coverImage = nil
        hasUnsavedCoverImage = true
        selectedCoverItem = nil
        checkForUnsavedChanges()
        print("🗑️ カバー画像を削除しました")
    }
    
    /// Saves all images (profile and cover) in a batch operation
    @MainActor
    func saveAllImages() async -> Bool {
        guard hasUnsavedProfileImage || hasUnsavedCoverImage else {
            print("💾 保存する画像の変更がありません")
            return true
        }
        
        // Check network connectivity first
        guard canPerformNetworkOperation() else {
            return false
        }
        
        var profileImageUrl: String? = nil
        var coverImageUrl: String? = nil
        var uploadSuccess = true
        
        clearAllErrors()
        
        do {
            // Upload profile image if changed
            if hasUnsavedProfileImage {
                if let image = profileImage {
                    print("📤 プロフィール画像の一括アップロード開始")
                    profileImageUrl = await uploadProfileImageWithProgress(image)
                    if profileImageUrl == nil {
                        print("❌ プロフィール画像のアップロードに失敗しました")
                        uploadSuccess = false
                    } else {
                        print("✅ プロフィール画像のアップロード成功: \(profileImageUrl!)")
                    }
                } else {
                    // Image was deleted, we'll handle this in the profile update
                    print("🗑️ プロフィール画像が削除されました")
                }
            }
            
            // Upload cover image if changed
            if hasUnsavedCoverImage && uploadSuccess {
                if let image = coverImage {
                    print("📤 カバー画像の一括アップロード開始")
                    coverImageUrl = await uploadCoverImageWithProgress(image)
                    if coverImageUrl == nil {
                        print("❌ カバー画像のアップロードに失敗しました")
                        uploadSuccess = false
                    } else {
                        print("✅ カバー画像のアップロード成功: \(coverImageUrl!)")
                    }
                } else {
                    // Image was deleted, we'll handle this in the profile update
                    print("🗑️ カバー画像が削除されました")
                }
            }
            
            if uploadSuccess {
                // Update profile with new image URLs
                var updatedProfile = profile
                
                if hasUnsavedProfileImage {
                    updatedProfile.profileImageURL = profileImageUrl
                }
                
                if hasUnsavedCoverImage {
                    updatedProfile.coverImageURL = coverImageUrl
                }
                
                // Save profile with updated image URLs
                print("📤 画像URL付きプロフィール更新開始")
                let savedProfile = try await updateProfileAsync(updatedProfile)
                
                // Success - update local state
                self.profile = savedProfile
                
                // Clear unsaved image state
                hasUnsavedProfileImage = false
                hasUnsavedCoverImage = false
                selectedProfileItem = nil
                selectedCoverItem = nil
                
                checkForUnsavedChanges()
                
                print("✅ 全画像の一括保存完了")
                showSuccessMessage("画像が正常に保存されました")
                
                return true
            } else {
                handleError(ProfileError.imageUploadFailed(NSError(domain: "BatchImageUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: "画像のアップロードに失敗しました"])), context: "batch_image_save")
                return false
            }
            
        } catch {
            handleError(error, context: "batch_image_save")
            print("❌ 画像の一括保存エラー: \(error.localizedDescription)")
            return false
        }
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
        case "profile_creation":
            _ = await createProfile()
        case "profile_update":
            _ = await updateProfile()
        case "profile_deletion":
            _ = await confirmProfileDeletion()
        case "profile_load":
            let userId = AuthService.shared.currentUser?.id ?? 0
            loadProfile(userID: userId)
        case "username_check":
            if !username.isEmpty {
                performUsernameAvailabilityCheck(username)
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

// MARK: - Supporting Types for Enhanced Profile Update

/// Represents form state for rollback purposes
struct FormState {
    let email: String
    let name: String
    let username: String
    let bio: String
    let location: String
    let birthday: Date
    let profileImage: UIImage?
    let coverImage: UIImage?
    let hasUnsavedChanges: Bool
    let hasUnsavedProfileImage: Bool
    let hasUnsavedCoverImage: Bool
    let selectedProfileItem: PhotosPickerItem?
    let selectedCoverItem: PhotosPickerItem?
}

/// Enum representing profile fields for change tracking
enum ProfileField: CaseIterable {
    case email
    case name
    case username
    case bio
    case location
    case birthday
    case profileImage
    case coverImage
    
    var displayName: String {
        switch self {
        case .email:
            return "メールアドレス"
        case .name:
            return "名前"
        case .username:
            return "ユーザーネーム"
        case .bio:
            return "自己紹介"

        case .location:
            return "出身地"
        case .birthday:
            return "誕生日"
        case .profileImage:
            return "プロフィール画像"
        case .coverImage:
            return "カバー画像"
        }
    }
}

/// Comprehensive validation summary for form state
struct ValidationSummary {
    let emailValidation: ValidationResult
    let nameValidation: ValidationResult
    let usernameValidation: ValidationResult
    let bioValidation: ValidationResult
    let locationValidation: ValidationResult
    let birthdayValidation: ValidationResult
    let isUsernameAvailable: Bool?
    let isValidatingUsername: Bool
    let isFormValid: Bool
    let hasUnsavedChanges: Bool
    
    /// Gets all validation errors as a list
    var allErrors: [String] {
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
    
    /// Gets count of valid fields
    var validFieldCount: Int {
        var count = 0
        if emailValidation.isValid { count += 1 }
        if nameValidation.isValid { count += 1 }
        if usernameValidation.isValid { count += 1 }
        if bioValidation.isValid { count += 1 }
        if locationValidation.isValid { count += 1 }
        if birthdayValidation.isValid { count += 1 }
        return count
    }
    
    /// Total number of fields being validated
    var totalFieldCount: Int { return 7 }
    
    /// Validation completion percentage
    var completionPercentage: Double {
        return Double(validFieldCount) / Double(totalFieldCount)
    }
}
