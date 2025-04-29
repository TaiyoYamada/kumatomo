//
//  EditProfileView.swift
//  CoupleMate
//
//  Created by 山田大陽 on 2025/04/30.
//
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var newInterest = ""
    
    var body: some View {
        Form {
            Section(header: Text("プロフィール画像")) {
                profileImageSection
            }
            
            Section(header: Text("基本情報")) {
                TextField("名前", text: $viewModel.name)
                
                TextField("自己紹介", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(4...6)
                
                DatePicker("誕生日", selection: Binding(
                    get: { viewModel.birthDate ?? Date() },
                    set: { viewModel.birthDate = $0 }
                ), displayedComponents: .date)
            }
            
            Section(header: Text("興味・関心事")) {
                interestsSection
            }
            
            Section(header: Text("恋愛情報")) {
                Picker("ステータス", selection: $viewModel.relationshipStatus) {
                    Text("Single").tag("Single")
                    Text("In a relationship").tag("In a relationship")
                    Text("Engaged").tag("Engaged")
                    Text("Married").tag("Married")
                }
                
                DatePicker("記念日", selection: Binding(
                    get: { viewModel.anniversaryDate ?? Date() },
                    set: { viewModel.anniversaryDate = $0 }
                ), displayedComponents: .date)
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
                .disabled(viewModel.name.isEmpty)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
        .overlay {
            if viewModel.isImageUploading {
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
        }
        .alert("プロフィールを更新しました", isPresented: $viewModel.showSuccessMessage) {
            Button("OK") {}
        }
    }
    
    private var profileImageSection: some View {
        HStack {
            Spacer()
            
            VStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let imageURL = viewModel.profile.profileImageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }
                
                Button("画像を変更") {
                    showImagePicker = true
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    private var interestsSection: some View {
        VStack {
            HStack {
                TextField("新しい興味・関心事", text: $newInterest)
                
                Button(action: {
                    viewModel.addInterest(newInterest)
                    newInterest = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newInterest.isEmpty)
            }
            
            if !viewModel.interests.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(viewModel.interests.enumerated()), id: \.element) { index, interest in
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
                }
            }
        }
    }
}

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
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
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
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        self?.parent.selectedImage = image
                    }
                }
            }
        }
    }
}
