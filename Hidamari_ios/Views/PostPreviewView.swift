import SwiftUI

struct PostPreviewView: View {
    let content: String
    let images: [UIImage]
    let shop: Shop?
    let onPost: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview Header
                    PostPreviewHeader()
                    
                    // Post Content Preview
                    PostPreviewContent(
                        content: content,
                        images: images,
                        shop: shop
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("投稿プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("投稿する") {
                        onPost()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
        }
    }
}

// MARK: - Post Preview Header
private struct PostPreviewHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("投稿プレビュー")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
            
            Text("実際の投稿はこのように表示されます")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Post Preview Content
private struct PostPreviewContent: View {
    let content: String
    let images: [UIImage]
    let shop: Shop?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Info (Mock)
            PostPreviewUserInfo()
            
            // Post Content
            if !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Images
            if !images.isEmpty {
                PostPreviewImageGallery(images: images)
            }
            
            // Shop Info
            if let shop = shop {
                PostPreviewShopInfo(shop: shop)
            }
            
            // Post Actions (Mock)
            PostPreviewActions()
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.05),
            radius: 4,
            y: 2
        )
    }
}

// MARK: - Post Preview User Info
private struct PostPreviewUserInfo: View {
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image Placeholder
            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("あなた")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("今")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Post Preview Image Gallery
private struct PostPreviewImageGallery: View {
    let images: [UIImage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if images.count == 1 {
                PostPreviewSingleImage(image: images[0])
            } else {
                PostPreviewMultipleImages(images: images)
            }
        }
    }
}

// MARK: - Post Preview Single Image
private struct PostPreviewSingleImage: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(12)
    }
}

// MARK: - Post Preview Multiple Images
private struct PostPreviewMultipleImages: View {
    let images: [UIImage]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }
}

// MARK: - Post Preview Shop Info
private struct PostPreviewShopInfo: View {
    let shop: Shop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                Text("投稿先のお店")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
            }
            
            HStack(spacing: 12) {
                // Shop Image or Placeholder
                AsyncImage(url: URL(string: shop.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .overlay {
                            Image(systemName: "storefront")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 40, height: 40)
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(shop.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let address = shop.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

// MARK: - Post Preview Actions
private struct PostPreviewActions: View {
    var body: some View {
        HStack(spacing: 24) {
            PostPreviewActionButton(
                icon: "heart",
                text: "いいね",
                count: 0
            )
            
            PostPreviewActionButton(
                icon: "message",
                text: "コメント",
                count: 0
            )
            
            PostPreviewActionButton(
                icon: "square.and.arrow.up",
                text: "シェア",
                count: nil
            )
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Post Preview Action Button
private struct PostPreviewActionButton: View {
    let icon: String
    let text: String
    let count: Int?
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let count = count {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PostPreviewView(
        content: "美味しいコーヒーを飲みました！雰囲気も良くて、また来たいと思います。",
        images: [],
        shop: Shop(
            id: 1,
            name: "カフェ・ド・パリ",
            address: "東京都渋谷区渋谷1-1-1",
            genre: "カフェ"
        ),
        onPost: {}
    )
}