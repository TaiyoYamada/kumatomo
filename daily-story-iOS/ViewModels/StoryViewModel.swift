import Foundation
import SwiftUI

class StoryViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var userStories: [Story] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var storyContent: String = ""
    @Published var showSuccessModal: Bool = false
    
    private let storyService = StoryAPIService.shared
    
    // 全ストーリーの取得
    func fetchAllStories() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let fetchedStories = try await storyService.fetchAllStories()
            
            await MainActor.run {
                self.stories = fetchedStories.sorted(by: { $0.createdAt > $1.createdAt })
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // エラーの詳細情報を取得して表示
                let detailedError = getDetailedErrorMessage(from: error)
                self.errorMessage = "ストーリーの取得に失敗しました: \(detailedError)"
                self.isLoading = false
                print("🚨 ストーリー取得エラー: \(detailedError)")
            }
        }
    }
    
    // ユーザーのストーリー取得
    func fetchUserStories(userId: Int) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let fetchedStories = try await storyService.fetchUserStories(userId: userId)
            
            await MainActor.run {
                self.userStories = fetchedStories.sorted(by: { $0.createdAt > $1.createdAt })
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // エラーの詳細情報を取得して表示
                let detailedError = getDetailedErrorMessage(from: error)
                self.errorMessage = "ストーリーの取得に失敗しました: \(detailedError)"
                self.isLoading = false
                print("🚨 ユーザーストーリー取得エラー: \(detailedError)")
            }
        }
    }
    
    // ストーリーの投稿
    func postStory(userId: Int, content: String) async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let newStory = try await storyService.postStory(userId: userId, content: content)
            
            await MainActor.run {
                self.stories.insert(newStory, at: 0)
                self.userStories.insert(newStory, at: 0)
                self.storyContent = ""
                self.isLoading = false
                self.showSuccessModal = true
            }
            return true
        } catch {
            await MainActor.run {
                // エラーの詳細情報を取得して表示
                let detailedError = getDetailedErrorMessage(from: error)
                self.errorMessage = "投稿に失敗しました: \(detailedError)"
                self.isLoading = false
                print("🚨 ストーリー投稿エラー: \(detailedError)")
            }
            return false
        }
    }
    
    // エラーメッセージの詳細化
    private func getDetailedErrorMessage(from error: Error) -> String {
        if let apiError = error as? StoryAPIError {
            switch apiError {
            case .networkError(let underlyingError):
                return "ネットワークエラー: \(underlyingError.localizedDescription)"
            case .invalidURL:
                return "無効なURL"
            case .invalidResponse:
                return "無効なレスポンス"
            case .serverError(let message):
                return "サーバーエラー: \(message)"
            case .decodingError(let decodingError):
                if let decodingErr = decodingError as? DecodingError {
                    switch decodingErr {
                    case .keyNotFound(let key, _):
                        return "キーが見つかりません: \(key.stringValue)"
                    case .typeMismatch(let type, _):
                        return "型の不一致: 期待される型 \(type)"
                    case .valueNotFound(_, _):
                        return "値が見つかりません"
                    case .dataCorrupted(let context):
                        return "データ破損: \(context.debugDescription)"
                    @unknown default:
                        return "不明なデコードエラー"
                    }
                }
                return "デコードエラー: \(decodingError)"
            }
        } else {
            return error.localizedDescription
        }
    }
    
    // 文字数チェック
    func isContentValid() -> Bool {
        return !storyContent.isEmpty && storyContent.count <= 100
    }
    
    // 文字数オーバー判定
    func isContentOverLimit() -> Bool {
        return storyContent.count > 100
    }
    
    // 残り文字数
    func remainingCharacters() -> Int {
        return 100 - storyContent.count
    }
}
