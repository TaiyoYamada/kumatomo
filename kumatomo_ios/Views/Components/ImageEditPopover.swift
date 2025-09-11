import SwiftUI

struct ImageEditPopover: View {
    let imageType: ImageType
    let onPhotoSelection: () -> Void
    let onDelete: () -> Void
    @Binding var isPresented: Bool
    
    enum ImageType {
        case profile
        case cover
        
        var displayName: String {
            switch self {
            case .profile:
                return "プロフィール画像"
            case .cover:
                return "カバー画像"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo selection button
            Button(action: {
                onPhotoSelection()
                isPresented = false
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    
                    Text("写真から選択")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .padding(.horizontal, 16)
            
            // Delete button
            Button(action: {
                onDelete()
                isPresented = false
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 20)
                    
                    Text("削除")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(width: 200)
    }
}

// MARK: - Preview
struct ImageEditPopover_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Profile image popover preview
            ImageEditPopover(
                imageType: .profile,
                onPhotoSelection: {
                    print("Profile photo selection tapped")
                },
                onDelete: {
                    print("Profile delete tapped")
                },
                isPresented: .constant(true)
            )
            
            // Cover image popover preview
            ImageEditPopover(
                imageType: .cover,
                onPhotoSelection: {
                    print("Cover photo selection tapped")
                },
                onDelete: {
                    print("Cover delete tapped")
                },
                isPresented: .constant(true)
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}