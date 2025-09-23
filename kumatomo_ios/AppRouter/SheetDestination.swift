import SwiftUI
import PhotosUI

// MARK: - モーダル表示用のDestination enum
// 統合済み: 全てのシート・モーダル表示はこのenumで管理
enum SheetDestination: Identifiable {
	case postDetail(Int)                                                           // 投稿詳細モーダル
	case shopPicker(selectedShop: Binding<Shop?>)                                  // // 投稿プレビューモーダル
	case profileEdit(User, onProfileUpdated: (() -> Void)? = nil)              // プロフィール編集モーダル
	case municipalityPicker(selected: String?, onSelect: (String) -> Void)         // 市区町村選択モーダル
	case postEdit(viewModel: PostViewModel)                                        // 投稿編集モーダル
    case profileImageEdit(selectedItem: Binding<PhotosPickerItem?>, onDelete: () -> Void)  // プロフィールアイコン画像編集モーダル
    case coverImageEdit(selectedItem: Binding<PhotosPickerItem?>, onDelete: () -> Void)   // プロフィール背景画像編集モーダル
    case shopProposal                                                              // 店舗提案フォーム
    case shopProposalStatus                                                        // 店舗提案状況
    

	var id: String {
		switch self {
		case .postDetail(let postId):
			return "postDetail_\(postId)"
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
		case .shopProposal:
			return "shopProposal"
		case .shopProposalStatus:
			return "shopProposalStatus"
		}
	}
}

extension View {
	func withSheetRouter(sheet: Binding<SheetDestination?>) -> some View {
		self.sheet(item: sheet) { destination in
			switch destination {
			case .postDetail(let postId):
				PostDetailView(postId: postId)
					.environmentObject(CurrentUserManager.shared)
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
            case .shopProposal:
                ShopProposalFormView()
            case .shopProposalStatus:
                ShopProposalStatusView()
			}
		}
	}
}


