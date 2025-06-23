import SwiftUI

/**
 * MemoryGridItem - グリッド表示用のメモリーアイテムビュー
 * 
 * メモリーの写真をグリッドアイテムとして表示します。
 * 写真の読み込み中はプログレスインジケータを表示します。
 */
struct MemoryGridItem: View {
    let memory: Memory
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
            } else {
                // エラーまたは画像なしの場合
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .onAppear {
            // ビューが表示されたら画像を読み込む
            if let photoURL = memory.mainPhotoURL {
                print("📷 ロードする画像URL: \(photoURL)")
                imageLoader.loadImage(from: photoURL)

            } else {
                print("⚠️ 画像URLが存在しない")
            }

        }
        .onDisappear {
            // ビューが非表示になったら読み込みをキャンセル
            imageLoader.cancel()
        }
    }
}
