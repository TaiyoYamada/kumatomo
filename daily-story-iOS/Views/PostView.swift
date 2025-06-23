import SwiftUI
import PhotosUI
import Photos

struct PostView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var allImages: [UIImage] = []
    @State private var isMultipleSelection = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Spacer()
                
                Text("新規投稿")
                    .foregroundColor(.white)
                    .font(.system(size: 10, weight: .semibold))
                
                Spacer()
                
                Button("次へ") {
                    // Handle next action
                }
                .foregroundColor(.blue)
                .font(.system(size: 16, weight: .semibold))
            }
            .padding(.top, 10)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.black)
            
            // Image preview area
            if let firstImage = selectedImages.first {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: firstImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.width)
                        .background(Color.black)
                    
                    // Multi-image indicator
                    if selectedImages.count > 1 {
                        Text("\(selectedImages.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .padding(8)
                    }
                    
                    // Filter and edit controls
                    HStack {
                        Button(action: {
                            // Toggle filters
                        }) {
                            Image(systemName: "camera.filters")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Toggle edit
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(8)
                }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: UIScreen.main.bounds.width)
                    .overlay(Text("画像を選択してください").foregroundColor(.gray))
            }
            
            // Photo library section
            VStack(spacing: 0) {
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
                
                HStack {
                    Text("最近の...")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Button(action: {
                        toggleMultipleSelection()
                    }) {
                        Image(systemName: "square.on.square")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Photo grid
                let columns = [
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1)
                ]
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(0..<allImages.count, id: \.self) { index in
                            imageGridItem(index: index)
                        }
                    }
                }
                .frame(height: 300)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            loadAllPhotos()
        }
        .navigationBarHidden(true)
        .background(TabBarHider(isHidden: true))
    }
    
    // Grid item view to reduce complexity in the main body
    private func imageGridItem(index: Int) -> some View {
        let image = allImages[index]
        let isSelected = selectedImages.contains(image)
        let selectionIndex = selectedImages.firstIndex(of: image)
        
        return ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: (UIScreen.main.bounds.width - 3) / 4, height: (UIScreen.main.bounds.width - 3) / 4)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture {
                    handleImageSelection(index)
                }
            
            if isSelected, let selectionIndex = selectionIndex {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 22, height: 22)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                    
                    Text("\(selectionIndex + 1)")
                        .foregroundColor(.white)
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(4)
            }
        }
    }
    
    // Image selection handling
    private func handleImageSelection(_ index: Int) {
        let image = allImages[index]
        
        if selectedImages.contains(image) {
            selectedImages.removeAll { $0 == image }
        } else {
            // Check if we're at the limit
            if selectedImages.count >= 10 {
                return
            }
            
            // If not in multiple selection mode, replace current selection
            if !isMultipleSelection {
                selectedImages = [image]
            } else {
                selectedImages.append(image)
            }
        }
    }
    
    // Toggle multiple selection mode
    private func toggleMultipleSelection() {
        isMultipleSelection.toggle()
        
        // If turning off multiple selection, keep only first image
        if !isMultipleSelection && selectedImages.count > 1 {
            if let firstImage = selectedImages.first {
                selectedImages = [firstImage]
            }
        }
    }
    
    // Load photos from library
    private func loadAllPhotos() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else { return }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let imageManager = PHCachingImageManager()
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            
            let targetSize = CGSize(width: 500, height: 500)
            let photoLimit = 100 // Limit to prevent memory issues
            
            assets.enumerateObjects { asset, index, _ in
                if index < photoLimit {
                    imageManager.requestImage(
                        for: asset,
                        targetSize: targetSize,
                        contentMode: .aspectFill,
                        options: options
                    ) { image, _ in
                        if let image = image {
                            DispatchQueue.main.async {
                                self.allImages.append(image)
                                
                                // Select first image by default
                                if index == 0 && self.selectedImages.isEmpty {
                                    self.selectedImages = [image]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
