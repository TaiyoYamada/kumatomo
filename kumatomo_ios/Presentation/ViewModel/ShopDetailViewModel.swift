import Foundation
import SwiftUI
import Resolver

@MainActor
class ShopDetailViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Injected var shopRepository: ShopRepository
    
    func loadPosts(for shopId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            posts = try await shopRepository.fetchShopPosts(shopId: shopId)
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
