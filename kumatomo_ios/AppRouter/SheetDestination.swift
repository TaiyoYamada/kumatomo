import SwiftUI

// MARK: - モーダル表示用のDestination enum
// 統合済み: 全てのシート・モーダル表示はこのenumで管理
enum SheetDestination: Identifiable {
	case postDetail(Post)                                                           // 投稿詳細モーダル
	case shopDetail(Shop)                                                          // お店詳細モーダル
	case shopPicker(selectedShop: Binding<Shop?>)                                  // // 投稿プレビューモーダル
	case profileEdit(User, onProfileUpdated: (() -> Void)? = nil)              // プロフィール編集モーダル
	case municipalityPicker(selected: String?, onSelect: (String) -> Void)         // 市区町村選択モーダル
	case postEdit(viewModel: PostViewModel)                                        // 投稿編集モーダル
	case profileImageEdit(onPhotoSelection: () -> Void, onDelete: () -> Void)      // プロフィール画像編集モーダル
	case coverImageEdit(onPhotoSelection: () -> Void, onDelete: () -> Void)        // カバー画像編集モーダル

	var id: String {
		switch self {
		case .postDetail(let post):
			return "postDetail_\(post.id)"
		case .shopDetail(let shop):
			return "shopDetail_\(shop.id)"
		case .shopPicker:
			return "shopPicker"
		case .profileEdit(let user, _):
			return "profileEdit_\(user.id)"
		case .municipalityPicker:
			return "municipalityPicker"
		case .postEdit(let viewModel):
			// Avoid touching MainActor-isolated properties here
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
			case .postDetail(let post):
				PostDetailView(post: post)
			case .shopDetail(let shop):
				ShopDetailView(shop: shop)
			case .shopPicker(let selectedShop):
				ShopPickerView(selectedShop: selectedShop)
			case .profileEdit(let user, let onProfileUpdated):
				ModernProfileEditView(user: user, onProfileUpdated: onProfileUpdated)
			case .municipalityPicker(let selected, let onSelect):
				MunicipalityPickerView(selectedMunicipality: selected, onSelection: { value in
					onSelect(value)
				})
			case .postEdit(let viewModel):
				PostEditView(viewModel: viewModel)
			case .profileImageEdit(let onPhotoSelection, let onDelete):
				ImageEditSheet(
					imageType: .profile,
					onPhotoSelection: onPhotoSelection,
					onDelete: onDelete
				)
			case .coverImageEdit(let onPhotoSelection, let onDelete):
				ImageEditSheet(
					imageType: .cover,
					onPhotoSelection: onPhotoSelection,
					onDelete: onDelete
				)
			}
		}
	}
}


