import Foundation
import SwiftUI
import Observation
import Resolver

@MainActor
@Observable
class ShopDetailViewModel {
    var posts: [Post] = []
    var isLoading = false
    var errorMessage: String?
    
    @ObservationIgnored @Injected var fetchShopPostsUseCase: FetchShopPostsUseCase
    
    func loadPosts(for shopId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            posts = try await fetchShopPostsUseCase.execute(shopId: shopId)
        } catch {
            errorMessage = error.localizedDescription
            print("🚨 お店の投稿取得に失敗: \(error)")
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
