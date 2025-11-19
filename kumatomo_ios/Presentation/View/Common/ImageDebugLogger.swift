import Foundation

#if DEBUG
enum ImageDebugLogger {
    static func logImage(_ urlString: String?, context: String) {
        let raw = urlString ?? "<nil>"
        let normalized = ImageURLNormalizer.normalize(urlString)
        print("🧩 [ImageDebug] context=\(context) raw=\(raw)")
        print("🧩 [ImageDebug] context=\(context) normalized=\(normalized?.absoluteString ?? "<nil>")")

        guard let url = normalized else {
            print("🧩 [ImageDebug] context=\(context) normalized URL is nil")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 6

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("🧩 [ImageDebug] context=\(context) HEAD error=\(error.localizedDescription)")
                var getReq = URLRequest(url: url)
                getReq.httpMethod = "GET"
                getReq.timeoutInterval = 6
                let getTask = URLSession.shared.dataTask(with: getReq) { data, response, error in
                    if let http = response as? HTTPURLResponse {
                        print("🧩 [ImageDebug] context=\(context) GET status=\(http.statusCode) contentType=\(http.value(forHTTPHeaderField: "Content-Type") ?? "?") bytes=\(data?.count ?? 0)")
                    }
                    if let error = error {
                        print("🧩 [ImageDebug] context=\(context) GET error=\(error.localizedDescription)")
                    }
                }
                getTask.resume()
                return
            }
            if let http = response as? HTTPURLResponse {
                print("🧩 [ImageDebug] context=\(context) HEAD status=\(http.statusCode) contentType=\(http.value(forHTTPHeaderField: "Content-Type") ?? "?")")
            } else {
                print("🧩 [ImageDebug] context=\(context) HEAD no HTTPURLResponse")
            }
        }
        task.resume()
    }
}
#endif

