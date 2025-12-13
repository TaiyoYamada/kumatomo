import SwiftUI
import PhotosUI

// MARK: - SheetDestination

enum SheetDestination: Identifiable {
    case postDetail(Int) // 投稿詳細モーダル
    case profileEdit(User, onProfileUpdated: (() -> Void)? = nil) // プロフィール編集モーダル
    case municipalityPicker(selected: String?, onSelect: (String) -> Void) // 市区町村選択モーダル
    case postEdit(viewModel: PostViewModel) // 投稿編集モーダル
    case profileImageEdit(selectedItem: Binding<PhotosPickerItem?>, onDelete: () -> Void) // プロフィールアイコン画像編集モーダル
    case coverImageEdit(selectedItem: Binding<PhotosPickerItem?>, onDelete: () -> Void) // プロフィール背景画像編集モーダル

    var id: String {
        switch self {
        case let .postDetail(postId):
            return "postDetail_\(postId)"
        case let .profileEdit(user, _):
            return "profileEdit_\(user.id)"
        case .municipalityPicker:
            return "municipalityPicker"
        case let .postEdit(viewModel):
            return "postEdit"
        case .profileImageEdit:
            return "profileImageEdit"
        case .coverImageEdit:
            return "coverImageEdit"
        }
    }
}

extension View {
    func withSheetRouter(sheet: Binding<SheetDestination?>) -> some View {
        self.sheet(item: sheet) { destination in
            switch destination {
            case let .postDetail(postId):
                PostDetailView(postId: postId)
                    .environment(CurrentUserManager.shared)
            case let .profileEdit(user, onProfileUpdated):
                ModernProfileEditView(user: user, onProfileUpdated: onProfileUpdated)
            case let .municipalityPicker(selected, onSelect):
                MunicipalityPickerView(selectedMunicipality: selected, onSelection: { value in
                    onSelect(value)
                })
            case let .postEdit(viewModel):
                PostEditView(viewModel: viewModel)
            case let .profileImageEdit(selectedItem, onDelete):
                ImageEditSheet(
                    imageType: .profile,
                    selectedItem: selectedItem,
                    onDelete: onDelete
                )
            case let .coverImageEdit(selectedItem, onDelete):
                ImageEditSheet(
                    imageType: .cover,
                    selectedItem: selectedItem,
                    onDelete: onDelete
                )
            }
        }
    }
}
