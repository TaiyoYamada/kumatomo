import SwiftUI
import PhotosUI

enum SheetDestination: Identifiable {
	case postDetail(Int)                                                           // 投稿詳細モーダル
	case profileEdit(User, onProfileUpdated: (() -> Void)? = nil)              // プロフィール編集モーダル
	case municipalityPicker(selected: String?, onSelect: (String) -> Void)         // 市区町村選択モーダル
	case postEdit(viewModel: PostViewModel)                                        // 投稿編集モーダル
    case profileImageEdit(selectedItem: Binding<PhotosPickerItem?>, onDelete: () -> Void)  // プロフィールアイコン画像編集モーダル
    case coverImageEdit(selectedItem: Binding<PhotosPickerItem?>, onDelete: () -> Void)   // プロフィール背景画像編集モーダル


	var id: String {
		switch self {
		case .postDetail(let postId):
			return "postDetail_\(postId)"
		case .profileEdit(let user, _):
			return "profileEdit_\(user.id)"
		case .municipalityPicker:
			return "municipalityPicker"
		case .postEdit(let viewModel):
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
			case .postDetail(let postId):
				PostDetailView(postId: postId)
					.environment(CurrentUserManager.shared)
			case .profileEdit(let user, let onProfileUpdated):
				ModernProfileEditView(user: user, onProfileUpdated: onProfileUpdated)
			case .municipalityPicker(let selected, let onSelect):
				MunicipalityPickerView(selectedMunicipality: selected, onSelection: { value in
					onSelect(value)
				})
			case .postEdit(let viewModel):
				PostEditView(viewModel: viewModel)
            case .profileImageEdit(let selectedItem, let onDelete):
                ImageEditSheet(
                    imageType: .profile,
                    selectedItem: selectedItem,
                    onDelete: onDelete
                )
            case .coverImageEdit(let selectedItem, let onDelete):
                ImageEditSheet(
                    imageType: .cover,
                    selectedItem: selectedItem,
                    onDelete: onDelete
                )
			}
		}
	}
}
