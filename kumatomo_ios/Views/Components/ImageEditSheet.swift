import SwiftUI

struct ImageEditSheet: View {
    let imageType: ImageType
    let onPhotoSelection: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
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
        
        var icon: String {
            switch self {
            case .profile:
                return "person.crop.circle.fill"
            case .cover:
                return "photo.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text(imageType.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .onAppear {
                            print("🎭 ImageEditSheet appeared with type: \(imageType)")
                        }
                    
                    Spacer()
                    
                    Button("完了") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Action buttons
                VStack(spacing: 0) {
                    // Photo selection button
                    Button(action: {
                        onPhotoSelection()
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            
                            Text("写真から選択")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Divider
                    Divider()
                        .padding(.leading, 60)
                    
                    // Delete button
                    Button(action: {
                        onDelete()
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("削除")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
