import SwiftUI
import PhotosUI

// MARK: - ProfileImageEditRow

/// プロフィール・カバー画像編集行
struct ProfileImageEditRow: View {
    @Binding var selectedProfileItem: PhotosPickerItem?
    @Binding var selectedCoverItem: PhotosPickerItem?
    @Bindable var viewModel: ProfileViewModel
    @Binding var sheetDestination: SheetDestination?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    if let coverImage = viewModel.coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: min(120, UIScreen.main.bounds.height * 0.15))
                            .clipped()
                    } else if let coverImageURL = viewModel.profile.coverImageURL, !coverImageURL.isEmpty {
                        AsyncImage(url: URL(string: coverImageURL)) { phase in
                            switch phase {
                            case .empty:
                                defaultCoverImageGradient
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: min(120, UIScreen.main.bounds.height * 0.15))
                                    .clipped()
                            case .failure:
                                defaultCoverImageGradient
                            @unknown default:
                                defaultCoverImageGradient
                            }
                        }
                    } else {
                        defaultCoverImageGradient
                    }
                }
                .allowsHitTesting(false)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        Button(action: {
                            sheetDestination = .coverImageEdit(
                                selectedItem: $selectedCoverItem,
                                onDelete: {
                                    viewModel.deleteCoverImage()
                                }
                            )
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                Text("カバー画像")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(12)
                    }
                }
            }

            HStack {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 74, height: 74)
                                .clipShape(Circle())
                        } else if let profileImageURL = viewModel.profile.profileImageURL, !profileImageURL.isEmpty {
                            AsyncImage(url: URL(string: profileImageURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(.secondary)
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 74, height: 74)
                                        .clipShape(Circle())
                                case .failure:
                                    defaultProfileIcon
                                @unknown default:
                                    defaultProfileIcon
                                }
                            }
                        } else {
                            defaultProfileIcon
                        }
                    }
                    .allowsHitTesting(false)

                    Button(action: {
                        sheetDestination = .profileImageEdit(
                            selectedItem: $selectedProfileItem,
                            onDelete: {
                                viewModel.deleteProfileImage()
                            }
                        )
                    }) {

                        Circle()
                            .fill(Color.orange)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(x: 4, y: 4)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, -40)
            .padding(.bottom, 16)
        }
        .onChange(of: selectedProfileItem) { newItem in
            handleProfileImageSelection(newItem)
        }
        .onChange(of: selectedCoverItem) { newItem in
            handleCoverImageSelection(newItem)
        }
    }

    private var defaultCoverImageGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.6),
                Color.purple.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: min(120, UIScreen.main.bounds.height * 0.15))
    }

    private var defaultProfileIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 32))
            .foregroundColor(.secondary)
    }

    private func handleProfileImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else {
            return
        }

        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {

                    guard validateImageForProfile(uiImage, type: .profile) else {
                        await MainActor.run {
                            selectedProfileItem = nil
                        }
                        return
                    }

                    await MainActor.run {
                        viewModel.updateProfileImage(uiImage)
                        selectedProfileItem = nil
                    }
                }
            } catch {
                print("❌ Error loading profile image: \(error.localizedDescription)")
                await MainActor.run {
                    selectedProfileItem = nil
                }
            }
        }
    }

    private func handleCoverImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else {
            return
        }

        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {

                    guard validateImageForProfile(uiImage, type: .cover) else {
                        await MainActor.run {
                            selectedCoverItem = nil
                        }
                        return
                    }

                    await MainActor.run {
                        viewModel.updateCoverImage(uiImage)
                        selectedCoverItem = nil
                    }
                }
            } catch {
                print("❌ Error loading cover image: \(error.localizedDescription)")
                await MainActor.run {
                    selectedCoverItem = nil
                }
            }
        }
    }

    private func validateImageForProfile(_ image: UIImage, type: ImageEditSheet.ImageType) -> Bool {
        let maxDimension: CGFloat = type == .profile ? 1_024 : 2_048
        let imageSize = max(image.size.width, image.size.height)

        if imageSize > maxDimension {
            return true
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return false
        }

        let fileSizeMB = Double(imageData.count) / (1_024 * 1_024)
        let maxFileSizeMB = 10.0

        if fileSizeMB > maxFileSizeMB {
            return true
        }

        return true
    }
}
