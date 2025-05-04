//
//  EditProfileView.swift
//  CoupleMate
//
//  Created by 山田大陽 on 2025/04/30.
//
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @State private var showImagePicker = false
    @State private var newInterest = ""
    
    // MARK: - Body
    var body: some View {
        Form {
            // Profile Image Section
            Section {
                profileImageSection
            } header: {
                Text("プロフィール画像")
            }
            
            // Basic Information Section
            Section {
                TextField("名前", text: $viewModel.fullName)
                
                TextField("自己紹介", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(4...6)
                
                DatePicker(
                    "誕生日",
                    selection: Binding(
                        get: { viewModel.birthDate ?? Date() },
                        set: { viewModel.birthDate = $0 }
                    ),
                    displayedComponents: .date
                )
            } header: {
                Text("基本情報")
            }
            
            // Interests Section
            Section {
                interestsSection
            } header: {
                Text("興味・関心事")
            }
            
            // Relationship Information Section
            Section {
                Picker("ステータス", selection: $viewModel.relationshipStatus) {
                    ForEach(relationshipOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                DatePicker(
                    "記念日",
                    selection: Binding(
                        get: { viewModel.relationshipStartDate ?? Date() },
                        set: { viewModel.relationshipStartDate = $0 }
                    ),
                    displayedComponents: .date
                )
            } header: {
                Text("恋愛情報")
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    viewModel.saveProfile()
                    dismiss()
                }
                .disabled(viewModel.fullName.isEmpty)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
        .overlay {
            if viewModel.isImageUploading {
                uploadingOverlay
            }
        }
        .alert("プロフィールを更新しました", isPresented: $viewModel.showSuccessMessage) {
            Button("OK") { }
        }
        .alert(viewModel.errorMessage ?? "エラーが発生しました", isPresented: $viewModel.showError) {
            Button("OK") { }
        }
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// List of relationship status options
    private let relationshipOptions = ["Single", "In a relationship", "Engaged", "Married"]
    
    /// Profile image section view
    private var profileImageSection: some View {
        HStack {
            Spacer()
            
            VStack {
                profileImage
                
                Button("画像を変更") {
                    showImagePicker = true
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    /// Profile image view based on available data
    private var profileImage: some View {
        Group {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else if let profileImageURLString = viewModel.profile.profileImageURL,
                      let profileImageURL = URL(string: profileImageURLString) {
                AsyncImage(url: profileImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        profileImagePlaceholder
                    case .empty:
                        profileImagePlaceholder
                    @unknown default:
                        profileImagePlaceholder
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                profileImagePlaceholder
            }
        }
    }
    
    /// Placeholder for when no profile image is available
    private var profileImagePlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 120, height: 120)
            .foregroundColor(.gray)
    }
    
    /// Interests section view
    private var interestsSection: some View {
        VStack(spacing: 12) {
            // Add new interest control
            HStack {
                TextField("新しい興味・関心事", text: $newInterest)
                
                Button(action: addInterest) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newInterest.isEmpty)
            }
            
            // Display existing interests
            if !viewModel.interests.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(viewModel.interests.enumerated()), id: \.element) { index, interest in
                        interestTag(interest: interest, index: index)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    /// Individual interest tag view
    private func interestTag(interest: String, index: Int) -> some View {
        HStack {
            Text(interest)
            Button(action: {
                viewModel.removeInterest(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
    
    /// Uploading overlay displayed during image upload
    private var uploadingOverlay: some View {
        VStack {
            ProgressView()
            Text("画像をアップロード中...")
                .padding(.top)
        }
        .frame(width: 200, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
    
    /// Loading overlay displayed during profile loading/saving
    private var loadingOverlay: some View {
        VStack {
            ProgressView()
            Text("読み込み中...")
                .padding(.top)
        }
        .frame(width: 200, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
    
    // MARK: - Methods
    
    /// Add a new interest to the list
    private func addInterest() {
        guard !newInterest.isEmpty else { return }
        viewModel.addInterest(newInterest)
        newInterest = ""
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let error = error {
                    print("Image loading error: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.parent.selectedImage = image
                    }
                }
            }
        }
    }
}
