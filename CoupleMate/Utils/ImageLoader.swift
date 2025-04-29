import Foundation
import SwiftUI
import Combine

/**
 * ImageLoader - 画像をURLから非同期で読み込むユーティリティクラス
 * 
 * URLから画像を読み込み、キャッシュする機能を提供します。
 * ObservableObjectに準拠しているため、SwiftUIのビューから観測可能です。
 */
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellable: AnyCancellable?
    private var cache: URLCache
    private var urlString: String?
    
    init(cache: URLCache = .shared) {
        self.cache = cache
    }
    
    /**
     * 指定されたURLから画像を読み込む
     * 
     * - Parameter urlString: 画像のURL文字列
     */
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            self.error = NSError(domain: "ImageLoader", code: 400, userInfo: [NSLocalizedDescriptionKey: "無効なURL形式です"])
            return
        }
        
        // 既に同じURLを読み込み中の場合はスキップ
        if self.urlString == urlString { return }
        
        self.urlString = urlString
        self.image = nil
        self.error = nil
        self.isLoading = true
        
        let request = URLRequest(url: url)
        
        // キャッシュをチェック
        if let cachedResponse = cache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            self.image = image
            self.isLoading = false
            return
        }
        
        // キャッシュになければダウンロード
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response) -> UIImage in
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode,
                      let image = UIImage(data: data) else {
                    throw NSError(domain: "ImageLoader", code: 500, userInfo: [NSLocalizedDescriptionKey: "画像データの変換に失敗しました"])
                }
                return image
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.error = error
                    print("画像の読み込みに失敗しました: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] image in
                guard let self = self else { return }
                
                self.image = image
            })
    }
    
    /**
     * 現在の読み込み処理をキャンセルする
     */
    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }
    
    /**
     * ローディング中や読み込みが完了した後のクリーンアップ
     */
    func cleanup() {
        cancel()
        image = nil
        error = nil
        urlString = nil
    }
}
