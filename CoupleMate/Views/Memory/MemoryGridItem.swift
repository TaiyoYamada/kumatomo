//
//  MemoryGridItem.swift
//  CoupleMate
//
//  Created by 山田大陽 on 2025/04/30.
//


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
                imageLoader.loadImage(from: photoURL)
            }
        }
        .onDisappear {
            // ビューが非表示になったら読み込みをキャンセル
            imageLoader.cancel()
        }
    }
}

/**
 * MemoryGridItem_Previews - SwiftUIプレビュー用のプロバイダ
 */
struct MemoryGridItem_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用のサンプルデータ
        let sampleMemory = Memory(
            title: "サンプルデート",
            date: Date(),
            location: "東京",
            notes: "楽しかった！",
            photos: ["https://example.com/sample.jpg"]
        )
        
        return MemoryGridItem(memory: sampleMemory)
            .frame(width: 120, height: 120)
            .previewLayout(.sizeThatFits)
    }
}