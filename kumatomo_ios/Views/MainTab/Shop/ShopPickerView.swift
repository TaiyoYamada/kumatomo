import SwiftUI

struct ShopPickerView: View {
    @Binding var selectedShop: Shop?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ShopListViewModel
    @State private var searchText = ""
    
    init(selectedShop: Binding<Shop?>) {
        self._selectedShop = selectedShop
        self._viewModel = StateObject(wrappedValue: ShopListViewModel())
    }
    
    var filteredShops: [Shop] {
        if searchText.isEmpty {
            return viewModel.shops
        } else {
            return viewModel.shops.filter { shop in
                shop.name.localizedCaseInsensitiveContains(searchText) ||
                shop.address?.localizedCaseInsensitiveContains(searchText) == true ||
                shop.genre?.displayName.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                if viewModel.isLoading {
                    ShopLoadingView()
                } else if filteredShops.isEmpty {
                    ShopEmptyStateView(searchText: searchText)
                } else {
                    ShopPickerList(
                        shops: filteredShops,
                        selectedShop: $selectedShop,
                        onShopSelected: {
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("お店を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("クリア") {
                        selectedShop = nil
                        dismiss()
                    }
                    .disabled(selectedShop == nil)
                }
            }
        }
        .task {
            await viewModel.loadShops()
        }
        .overlay {
            if let errorMessage = viewModel.errorMessage {
                ShopPickerErrorOverlay(
                    message: errorMessage,
                    onRetry: {
                        Task {
                            await viewModel.loadShops()
                        }
                    },
                    onClose: {
                        viewModel.errorMessage = nil
                    }
                )
            }
        }
    }
}

// MARK: - Search Bar
private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("お店名、住所、ジャンルで検索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Shop Loading View
private struct ShopLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("お店を読み込み中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shop Empty State View
private struct ShopEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "storefront" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(searchText.isEmpty ? "お店が登録されていません" : "検索結果が見つかりません")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(searchText.isEmpty ? 
                 "管理者によってお店が登録されるまでお待ちください" : 
                 "別のキーワードで検索してみてください")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shop Picker List
private struct ShopPickerList: View {
    let shops: [Shop]
    @Binding var selectedShop: Shop?
    let onShopSelected: () -> Void
    
    var body: some View {
        List(shops) { shop in
            ShopPickerRow(
                shop: shop,
                isSelected: selectedShop?.id == shop.id,
                onTap: {
                    selectedShop = shop
                    onShopSelected()
                }
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Shop Picker Row
private struct ShopPickerRow: View {
    let shop: Shop
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                
                // Shop Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let address = shop.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if let genre = shop.genre {
                            Text(genre.displayName)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(12)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(
                color: .black.opacity(0.05),
                radius: 2,
                y: 1
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shop Picker Error Overlay
private struct ShopPickerErrorOverlay: View {
    let message: String
    let onRetry: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.red)
                    
                    Text("エラーが発生しました")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button("再試行") {
                            onClose()
                            onRetry()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("閉じる") {
                            onClose()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding(.horizontal, 40)
            }
    }
}
