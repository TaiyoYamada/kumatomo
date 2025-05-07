//import SwiftUI
//
///**
// * MemoriesView - メモリー一覧画面
// * 
// * メモリー（デート記録）をグリッド形式で表示するメイン画面です。
// * インスタグラムのような3列グリッドでメモリーの写真を表示します。
// * 新規メモリー追加や詳細画面への遷移も可能です。
// */
//struct MemoriesView: View {
//    // MARK: - プロパティ
//    
//    @StateObject private var viewModel = MemoriesViewModel()
//    @State private var showAddMemorySheet = false
//    @State private var isRefreshing = false
//    @State private var gridColumns: Int = 3
//    
//    // グリッドアイテムの計算
//    private var gridLayout: [GridItem] {
//        Array(repeating: GridItem(.flexible(), spacing: 2), count: gridColumns)
//    }
//    
//    // MARK: - ボディ
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // メインコンテンツ
//                contentView
//                
//                // オーバーレイ
//                if viewModel.isLoading {
//                    loadingOverlay
//                }
//            }
//            .navigationBarTitle("思い出", displayMode: .inline)
//            .navigationBarItems(trailing: addButton)
//            .sheet(isPresented: $showAddMemorySheet) {
//                MemoryEditView(isNewMemory: true)
//                    .environmentObject(viewModel)
//            }
//            .onAppear {
//                viewModel.loadMemories()
//            }
//        }
//    }
//    
//    // MARK: - コンポーネント
//    
//    /// メインコンテンツビュー
//    private var contentView: some View {
//        Group {
//            if viewModel.memories.isEmpty {
//                emptyStateView
//            } else {
//                memoriesGridView
//            }
//        }
//    }
//    
//    /// メモリーグリッドビュー
//    private var memoriesGridView: some View {
//        ScrollView {
//            LazyVGrid(columns: gridLayout, spacing: 2) {
//                ForEach(viewModel.memories) { memory in
//                    NavigationLink(destination: MemoryDetailView(memory: memory)
//                        .environmentObject(viewModel)) {
//                        MemoryGridItem(memory: memory)
//                            .aspectRatio(1, contentMode: .fill)
//                            .clipped()
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//            .padding(.horizontal, 0)
//            .refreshable {
//                await refreshData()
//            }
//        }
//    }
//    
//    /// 空の状態ビュー
//    private var emptyStateView: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "heart.fill")
//                .font(.system(size: 80))
//                .foregroundColor(.gray.opacity(0.5))
//            
//            Text("まだ思い出がありません")
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundColor(.gray)
//            
//            Text("右上の「+」ボタンから\n最初の思い出を記録しましょう！")
//                .multilineTextAlignment(.center)
//                .foregroundColor(.gray)
//            
//            Button(action: {
//                showAddMemorySheet = true
//            }) {
//                Text("思い出を追加")
//                    .fontWeight(.semibold)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//            .padding(.top, 10)
//        }
//        .padding()
//    }
//    
//    /// 読み込み中オーバーレイ
//    private var loadingOverlay: some View {
//        Color.black.opacity(0.3)
//            .edgesIgnoringSafeArea(.all)
//            .overlay(
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle())
//                    .scaleEffect(1.5)
//            )
//    }
//    
//    /// 追加ボタン
//    private var addButton: some View {
//        Button(action: {
//            showAddMemorySheet = true
//        }) {
//            Image(systemName: "plus")
//                .font(.system(size: 20))
//        }
//    }
//    
//    // MARK: - メソッド
//    
//    /// データをリフレッシュする（Pull-to-refresh用）
//    private func refreshData() async {
//        isRefreshing = true
//        
//        // 非同期でデータをロード
//        await withCheckedContinuation { continuation in
//            viewModel.loadMemories()
//            
//            // 実際のデータロードは別スレッドで実行されるため、
//            // 少し遅延させてリフレッシュ状態を解除
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                isRefreshing = false
//                continuation.resume()
//            }
//        }
//    }
//}
