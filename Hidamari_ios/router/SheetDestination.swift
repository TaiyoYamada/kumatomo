import SwiftUI
import UIKit

enum SheetDestination: Identifiable {
	case postDetail(Post)
	case shopDetail(Shop)
	case shopPicker(selectedShop: Binding<Shop?>)
	case postPreview(content: String, images: [UIImage], shop: Shop?, onPost: () -> Void)
	case profileEdit(User)
	case municipalityPicker(selected: String?, onSelect: (String) -> Void)
	case postEdit(viewModel: PostViewModel)

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


