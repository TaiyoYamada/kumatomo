import SwiftUI

struct MyPageView: View {
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var memoriesViewModel = MemoriesViewModel()
    
    @State private var navigationPath = NavigationPath()
    @State private var showingProfileEdit = false

    class NavigationManager: ObservableObject {
         @Published var path = NavigationPath()
     }
    
    init() {
        let userID = String(AuthService.shared.currentUser?.id ?? 0)
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(userID: userID))
    }
    
    // グリッドのレイアウト設定
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // プロフィールヘッダーセクション
                profileHeaderSection
                
                // プロフィール詳細情報セクション
                profileDetailsSection
                
                // 編集ボタンとその他アクションボタン
                actionButtonsSection
                
                Divider().padding(.vertical, 10)
                
                // メモリー（投稿）グリッドセクション
                memoriesGridSection
            }
        }
        .navigationBarTitle("プロフィール", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                // 設定メニューを開く処理
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
        )
//        .onAppear {
//            profileViewModel.fetchUserProfile()
//            memoriesViewModel.fetchMemories()
//        }
    }
    
    // プロフィールヘッダーセクション
    private var profileHeaderSection: some View {
        HStack(spacing: 24) {
            // プロフィール画像
            if let urlString = profileViewModel.profile.profileImageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                    }
                }
            } else if profileViewModel.isLoading {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        ProgressView()
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            // 統計情報（投稿数、フォロワー、フォロー）
            HStack(spacing: 24) {
                VStack {
                    Text("\(memoriesViewModel.memories.count)")
                        .font(.headline)
                    Text("投稿")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(profileViewModel.profile.followersCount)")
                        .font(.headline)
                    Text("フォロワー")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(profileViewModel.profile.followingCount)")
                        .font(.headline)
                    Text("フォロー中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    
    // プロフィール詳細情報セクション
    private var profileDetailsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if profileViewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("読み込み中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                let user = profileViewModel.profile
                Text(user.name)
                    .font(.headline)
                
                Text(user.bio)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let website = user.website,
                   let url = URL(string: website) {
                    Link(destination: url) {
                        Text(website)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    
    // アクションボタンセクション
    private var actionButtonsSection: some View {
        HStack(spacing: 8) {
            // プロフィール編集ボタン - 更新：シートを表示するよう変更
            Button(action: {
                showingProfileEdit = true
            }) {
                Text("プロフィールを編集")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // その他アクションボタン
            Button(action: {
                // その他のアクション
            }) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    // メモリー（投稿）グリッドセクション
    private var memoriesGridSection: some View {
        Group {
            if memoriesViewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("投稿を読み込み中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if memoriesViewModel.memories.isEmpty {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                        .padding(.bottom)
                    Text("投稿はまだありません")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(memoriesViewModel.memories) { memory in
                        NavigationLink(destination: Text("詳細画面を表示: \(memory.id)")) {
                            memoryCell(memory)
                        }
                    }
                }
            }
        }
    }
    
    // 個別のメモリーセル
    private func memoryCell(_ memory: Memory) -> some View {
        GeometryReader { geo in
            AsyncImage(url: memory.mainPhotoURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
