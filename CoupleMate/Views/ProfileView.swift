//
//  ProfileView 2.swift
//  CoupleMate
//
//  Created by 山田大陽 on 2025/04/28.
//


import SwiftUI
import PhotosUI

struct ProfileView: View {
//    @StateObject var viewModel = AuthViewModel()
    @StateObject var viewModel: ProfileViewModel
    @State private var showEditProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                
                profileDetails
                
                editButton
            }
            .padding()
        }
        .navigationTitle("プロフィール")
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView(viewModel: viewModel)
            }
        }
        .alert("エラー", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") {}
        } message: { errorMessage in
            Text(errorMessage)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private var profileHeader: some View {
        VStack {
            if let imageURL = viewModel.profile.profileImageURL {
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
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 7)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 7)
            }
            
            Text(viewModel.profile.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.profile.relationshipStatus)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 1)
        }
    }
    
    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 15) {
            detailSection(title: "自己紹介", content: viewModel.profile.bio)
            
            if let birthDate = viewModel.profile.birthDate {
                detailSection(title: "誕生日", content: formatDate(birthDate))
            }
            
            if !viewModel.profile.interests.isEmpty {
                VStack(alignment: .leading) {
                    Text("興味・関心事")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.profile.interests, id: \.self) { interest in
                            Text(interest)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            
            if let anniversary = viewModel.profile.anniversaryDate {
                detailSection(title: "記念日", content: formatDate(anniversary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }
    
    private func detailSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var editButton: some View {
        Button(action: {
            showEditProfile = true
        }) {
            HStack {
                Image(systemName: "pencil")
                Text("プロフィールを編集")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

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
