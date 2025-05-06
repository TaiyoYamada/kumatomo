import Foundation
import UIKit


struct MemoriesResponse: Decodable {
    let data: [Memory]
}


class MemoryAPIService {
    static let shared = MemoryAPIService()
    private let baseURL = URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://10.33.2.4:8000/api")!


    func fetchMemories(completion: @escaping ([Memory]?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("memories")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                return completion(nil, error)
            }

            guard let data = data else {
                let noDataError = NSError(domain: "MemoryAPIService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "データが返ってきませんでした"
                ])
                return completion(nil, noDataError)
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 受信データ: \(jsonString)")
            }

            do {
                let decoded = try JSONDecoder().decode(MemoriesResponse.self, from: data)
                completion(decoded.data, nil)
            } catch {
                print("❌ デコード失敗: \(error)")
                completion(nil, error)
            }
        }.resume()
    }




    func createMemory(_ memory: MemoryRequest, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/memories") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONEncoder().encode(memory)

        // ⬇️ デバッグログ追加
        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
//            print("🚀 送信データ: \(json)")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            // ⬇️ レスポンス確認用ログ
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📦 レスポンス: \(responseString)")
            }
            if let error = error {
                print("❌ エラー: \(error)")
            }
            completion(error)
        }.resume()
    }



    func updateMemory(_ memory: Memory, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/memories/\(memory.id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONEncoder().encode(memory)

        URLSession.shared.dataTask(with: request) { _, _, error in
            completion(error)
        }.resume()
    }

    func deleteMemory(id: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/memories/\(id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { _, _, error in
            completion(error)
        }.resume()
    }
}
