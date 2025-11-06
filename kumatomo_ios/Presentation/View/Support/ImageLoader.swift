import Foundation
import SwiftUI
import Combine

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

    func loadImage(from url: URL) {
        if self.urlString == url.absoluteString { return }

        self.urlString = url.absoluteString
        self.image = nil
        self.error = nil
        self.isLoading = true

        let request = URLRequest(url: url)

        // キャッシュがあれば使う
        if let cachedResponse = cache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            self.image = image
            self.isLoading = false
            return
        }

        // なければダウンロード
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
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                    print("画像の読み込みに失敗しました: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] image in
                self?.image = image
            })
    }

    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }

    func cleanup() {
        cancel()
        image = nil
        error = nil
        urlString = nil
    }
}
