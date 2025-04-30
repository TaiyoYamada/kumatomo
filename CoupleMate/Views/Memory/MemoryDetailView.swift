import SwiftUI

/**
 * MemoryDetailView - メモリー詳細表示画面
 * 
 * 選択されたメモリーの詳細情報を表示します。
 * 写真のカルーセル表示、タイトル、日付、場所、メモを含みます。
 * 編集機能へのアクセスも提供します。
 */
struct MemoryDetailView: View {
    // MARK: - プロパティ
    let memory: Memory
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MemoriesViewModel
    
    @State private var currentImageIndex: Int = 0
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    // MARK: - ボディ
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 写真カルーセル
                photoCarousel
                
                // メモリー詳細情報
                detailContent
            }
            .padding(.bottom, 24)
        }
        .navigationBarTitle(memory.title, displayMode: .inline)
        .navigationBarItems(trailing: editButton)
        .sheet(isPresented: $showEditSheet) {
            MemoryEditView(memory: memory, isNewMemory: false)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("この思い出を削除しますか？"),
                message: Text("この操作は取り消せません"),
                primaryButton: .destructive(Text("削除")) {
                    deleteMemory()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
    }
    
    // MARK: - コンポーネント
    
    /// 写真カルーセル
    private var photoCarousel: some View {
        Group {
            if memory.photos.isEmpty {
                // 写真がない場合のプレースホルダー
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    )
            } else {
                // 写真カルーセル
                TabView(selection: $currentImageIndex) {
                    ForEach(0..<memory.photos.count, id: \.self) { index in
                        AsyncImageView(urlString: memory.photos[index])
                            .scaledToFill()
                            .tag(index)
                    }
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
        }
    }
    
    /// 詳細コンテンツ
    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル
            if !memory.title.isEmpty {
                Text(memory.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
            }
            
            // 日付
            HStack {
                Image(systemName: "calendar")
                Text(formatDate(memory.date))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal)
            
            // 場所
            if !memory.location.isEmpty {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(memory.location)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
            
            // メモ
            if !memory.notes.isEmpty {
                Text(memory.notes)
                    .padding(.horizontal)
                    .padding(.top, 4)
            } else {
                Text("メモはありません")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            
            // 作成日・更新日
            VStack(alignment: .leading, spacing: 4) {
                Text("作成日: \(formatDateTime(memory.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("更新日: \(formatDateTime(memory.updatedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // 削除ボタン
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "trash")
                    Text("この思い出を削除")
                    Spacer()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 24)
            }
        }
    }
    
    /// 編集ボタン
    private var editButton: some View {
        Button(action: {
            showEditSheet = true
        }) {
            Text("編集")
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    /// 日付フォーマット（日付のみ）
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// 日付フォーマット（日付と時刻）
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// メモリー削除
    private func deleteMemory() {
        // メモリーIDで一致するインデックスを検索
        if let index = viewModel.memories.firstIndex(where: { $0.id == memory.id }) {
            viewModel.deleteMemory(at: IndexSet(integer: index))
            presentationMode.wrappedValue.dismiss()
        }
    }
}

/**
 * AsyncImageView - 非同期画像読み込みビュー
 * 
 * URLから画像を非同期で読み込み表示するためのビュー
 * 読み込み中・エラー時の表示も処理
 */
struct AsyncImageView: View {
    let urlString: String
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        ZStack {
            if let image = imageLoader.image {
                // 画像が読み込まれた場合
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if imageLoader.isLoading {
                // 読み込み中の場合
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else if imageLoader.error != nil {
                // エラーの場合
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            } else {
                // 初期状態
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .onAppear {
            imageLoader.loadImage(from: urlString)
        }
        .onDisappear {
            imageLoader.cancel()
        }
    }
}
