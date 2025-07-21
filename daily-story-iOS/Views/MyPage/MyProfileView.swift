import SwiftUI

struct MyProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(userID: 0)
    @StateObject private var postviewModel = PostViewModel()
    @State private var showingNewPost = false
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // カバー画像とプロフィール
                    ProfileCoverView(user: viewModel.profile, showingEditProfile: $showingEditProfile)
                    
                    // プロフィール情報
                    ProfileInfoView(user: viewModel.profile)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    
                    // タブセクション
                    TabSectionView(selectedTab: $selectedTab)
                    
                    // 投稿グリッド
                    PostGridItemView(post: postviewModel.stories)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                // カスタムナビゲーションバー
                CustomNavigationBar(
                    profileName: viewModel.profile.name ?? "プロフィール",
                    showingNewPost: $showingNewPost
                )
            }
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView(user: viewModel.profile)
            }
            .overlay {
                if viewModel.isLoading {
                    Color.white.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        )
                }
            }
        }
        .onAppear {
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserStories(userID: userId)
        }
        .refreshable {
            let userId = AuthService.shared.currentUser?.id ?? 0
            viewModel.loadProfile(userID: userId)
            viewModel.loadUserStories(userID: userId)
        }
    }
}

// カスタムナビゲーションバー
struct CustomNavigationBar: View {
    let profileName: String
    @Binding var showingNewPost: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                // 戻る
            }) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profileName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    showingNewPost = true
                }) {
                    Image(systemName: "plus.app")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                
                Button(action: {
                    // メニュー
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
//        .background(
//            LinearGradient(
//                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
    }
}

// カバー画像とプロフィール
struct ProfileCoverView: View {
    let user: User
    @Binding var showingEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // カバー画像
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient( colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
            
            // プロフィール画像とアクションボタン
            ZStack(alignment: .topTrailing) {
                HStack {
                    // プロフィール画像
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 84, height: 84)
                        
                        if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .tint(.white)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .offset(y: -42)
                    
                    Spacer()
                }
                
                // アクションボタン
                Button(action: {
                    showingEditProfile = true
                }) {
                    Text("プロフィールを編集")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// プロフィール情報
struct ProfileInfoView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 名前とユーザーネーム
                Text(user.name ?? "名前")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            
            // バイオ
//            if let bio = user.bio, !bio.isEmpty {
//                Text(bio)
//                    .font(.body)
//                    .foregroundColor(.black)
//                    .lineLimit(nil)
//            }
            
//                if let website = user.website, !website.isEmpty {
//                    HStack(spacing: 4) {
//                        Image(systemName: "link")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                        Text(website)
//                            .font(.body)
//                            .foregroundColor(.blue)
//                    }
//                }
            
            
            // フォロワー情報
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("\(user.followingCount)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("フォロー中")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Text("\(user.followersCount)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("フォロワー")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// タブセクション
struct TabSectionView: View {
    @Binding var selectedTab: Int
    
    let tabs = ["投稿", "返信"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == index ? .black : .gray)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
}

// 投稿グリッド
struct PostGridItemView: View {
    @StateObject private var postviewModel = PostViewModel()
    let post: [Post]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(postviewModel.stories) { post in
                XPostCardView(post: post)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
    }
}

// X風投稿カード
struct XPostCardView: View {
    let post: Post
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // プロフィール画像
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // ユーザー名と時間
                HStack {
                    Text(post.user?.name ?? "Unknown")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text("@username")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Text("·")
                        .foregroundColor(.gray)
                    
                    Text("2時間")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                // 投稿内容
                Text(post.content)
                    .font(.body)
                    .foregroundColor(.black)
                    .lineLimit(nil)
                
                // 投稿画像
//                if let imageURL = post.imageURL, let url = URL(string: imageURL) {
//                    AsyncImage(url: url) { image in
//                        image
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                    } placeholder: {
//                        Rectangle()
//                            .fill(Color.gray.opacity(0.3))
//                            .frame(height: 200)
//                    }
//                    .frame(maxHeight: 300)
//                    .clipped()
//                    .cornerRadius(12)
//                }
                
                // アクションボタン
                HStack(spacing: 60) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .font(.system(size: 16))
                            Text("12")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 16))
                            Text("5")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.system(size: 16))
                            Text("24")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
