import SwiftUI
import UIKit

// MARK: - モーダル表示用のDestination enum
// 統合済み: 全てのシート・モーダル表示はこのenumで管理
enum SheetDestination: Identifiable {
	case postDetail(Post)                                                           // 投稿詳細モーダル
	case shopDetail(Shop)                                                          // お店詳細モーダル
	case shopPicker(selectedShop: Binding<Shop?>)                                  // お店選択モーダル
	case postPreview(content: String, images: [UIImage], shop: Shop?, onPost: () -> Void)  // 投稿プレビューモーダル
	case profileEdit(User)                                                         // プロフィール編集モーダル
	case municipalityPicker(selected: String?, onSelect: (String) -> Void)         // 市区町村選択モーダル
	case postEdit(viewModel: PostViewModel)                                        // 投稿編集モーダル

	var id: String {
		switch self {
		case .postDetail(let post):
			return "postDetail_\(post.id)"
		case .shopDetail(let shop):
			return "shopDetail_\(shop.id)"
		case .shopPicker:
			return "shopPicker"
		case .postPreview:
			return "postPreview"
		case .profileEdit(let user):
			return "profileEdit_\(user.id)"
		case .municipalityPicker:
			return "municipalityPicker"
		case .postEdit(let viewModel):
			// Avoid touching MainActor-isolated properties here
			return "postEdit"
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
			case .postPreview(let content, let images, let shop, let onPost):
				PostPreviewView(content: content, images: images, shop: shop, onPost: onPost)
			case .profileEdit(let user):
				ModernProfileEditView(user: user)
			case .municipalityPicker(let selected, let onSelect):
				MunicipalityPickerView(selectedMunicipality: selected, onSelection: { value in
					onSelect(value)
				})
			case .postEdit(let viewModel):
				PostEditView(viewModel: viewModel)
			}
		}
	}
}


