import Foundation
import SwiftUI

class StoryViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var userStories: [Story] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var storyContent: String = ""
    
    private let storyService = StoryAPIService.shared
    
    // 全ストーリーの取得
    func fetchAllStories() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // 本番環境ではコメントアウトを外す
            // let fetchedStories = try await storyService.fetchAllStories()
            
            // 開発用モックデータ
            let fetchedStories = await storyService.getMockStories()
            
            await MainActor.run {
                self.stories = fetchedStories.sorted(by: { $0.createdAt > $1.createdAt })
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "ストーリーの取得に失敗しました: \(error.localizedDescription)"
                self.isLoading = false
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
            // 本番環境ではコメントアウトを外す
            // let fetchedStories = try await storyService.fetchUserStories(userId: userId)
            
            // 開発用モックデータ
            let allMockStories = await storyService.getMockStories()
            let userMockStories = allMockStories.filter { $0.userId == userId }
            
            await MainActor.run {
                self.userStories = userMockStories.sorted(by: { $0.createdAt > $1.createdAt })
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "ストーリーの取得に失敗しました: \(error.localizedDescription)"
                self.isLoading = false
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
            // 本番環境ではコメントアウトを外す
            // let newStory = try await storyService.postStory(userId: userId, content: content)
            
            // 開発用モックデータ
            let newStory = await storyService.postMockStory(userId: userId, content: content)
            
            await MainActor.run {
                self.stories.insert(newStory, at: 0)
                self.userStories.insert(newStory, at: 0)
                self.storyContent = ""
                self.isLoading = false
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "投稿に失敗しました: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
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