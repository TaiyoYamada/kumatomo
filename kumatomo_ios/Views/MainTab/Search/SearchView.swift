import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var userManager: CurrentUserManager
    @State private var sheetDestination: SheetDestination?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            // 検索バー
            searchBar
            
            // フィルターセグメント
            filterSegment
            
            // コンテンツ
            if viewModel.isLoading {
                loadingView
            } else if viewModel.showingSearchHistory {
                searchHistoryView
            } else if viewModel.hasSearchResults {
                searchResultsView
            } else if !viewModel.searchText.isEmpty {
                noResultsView
            } else {
                emptyStateView
            }
            
            Spacer()
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
            .sidebarButton()
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .withAppRouter()
            .withSheetRouter(sheet: $sheetDestination)
        }
    }
    
    // 検索バー
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("投稿やお店を検索", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        viewModel.performSearch()
                    }
                    .onChange(of: viewModel.searchText) { _ in
                        viewModel.onSearchTextChanged()
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !viewModel.searchText.isEmpty {
                Button("検索") {
                    viewModel.performSearch()
                }
                .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // フィルターセグメント
    private var filterSegment: some View {
        Picker("フィルター", selection: $viewModel.selectedFilter) {
            ForEach(SearchFilterType.allCases, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onChange(of: viewModel.selectedFilter) { newFilter in
            viewModel.changeFilter(to: newFilter)
        }
    }
    
    // ローディング表示
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("検索中...")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }
    
    // 検索履歴表示
    private var searchHistoryView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !viewModel.searchHistory.isEmpty {
                    HStack {
                        Text("最近の検索")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("すべて削除") {
                            viewModel.clearSearchHistory()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    ForEach(Array(viewModel.searchHistory.enumerated()), id: \.element.id) { index, history in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                                .font(.caption)
                            
                            Text(history.query)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.removeSearchHistory(at: index)
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.searchFromHistory(history)
                        }
                        
                        if index < viewModel.searchHistory.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("検索履歴がありません")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // 検索結果表示
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let results = viewModel.searchResults {
                    // 投稿結果
                    if !results.posts.isEmpty && (viewModel.selectedFilter == .all || viewModel.selectedFilter == .posts) {
                        searchSectionHeader(title: "投稿", count: results.posts.count)
                        
                        ForEach(results.posts) { post in
                            PostSearchResultCard(post: post) {
                                sheetDestination = .postDetail(post.id)
                            }
                        }
                    }
                    
                    // お店結果
                    if !results.shops.isEmpty && (viewModel.selectedFilter == .all || viewModel.selectedFilter == .shops) {
                        searchSectionHeader(title: "お店", count: results.shops.count)
                        
                        ForEach(results.shops) { shop in
                            ShopSearchResultCard(shop: shop) {
                                sheetDestination = .shopDetail(shop)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // セクションヘッダー
    private func searchSectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("(\(count)件)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // 検索結果なし
    private var noResultsView: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("検索結果が見つかりませんでした")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 8)
            Text("別のキーワードで検索してみてください")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    // 空の状態
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("投稿やお店を検索")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 8)
            Text("キーワードを入力して検索してください")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    // 投稿検索結果カード
    struct PostSearchResultCard: View {
        let post: Post
        let onTap: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // ユーザー情報
                    if let user = post.user {
                        AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        
                        Text(user.name ?? "Unknown User")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // お店情報
                    if let shop = post.shop {
                        Text(shop.name)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // 投稿内容
                Text(post.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.primary)
                
                // 画像
                if let images = post.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(images.prefix(3)) { image in
                                AsyncImage(url: URL(string: image.imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            if images.count > 3 {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("+\(images.count - 3)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                
                // 投稿日時
                if let createdAt = post.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
    }
    
    // お店検索結果カード
    struct ShopSearchResultCard: View {
        let shop: Shop
        let onTap: () -> Void
        
        var body: some View {
            HStack(spacing: 12) {
                // お店画像
                AsyncImage(url: URL(string: shop.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    // お店名
                    Text(shop.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // ジャンル
                    if let genre = shop.genre {
                        Text(genre)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // 住所
                    if let address = shop.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
    }
}


// 検索フィルタータイプ
enum SearchFilterType: String, CaseIterable {
    case all = "all"
    case posts = "posts"
    case shops = "shops"
    
    var displayName: String {
        switch self {
        case .all:
            return "すべて"
        case .posts:
            return "投稿"
        case .shops:
            return "お店"
        }
    }
}
