import api from './api.js'
import type {
    Favorite,
    FavoriteToggleResponse,
    FavoriteListResponse,
    ApiResponse,
    ApiError
} from '@/types/shop'

export interface FavoriteServiceInterface {
    getFavorites(params?: FavoriteQueryParams): Promise<FavoriteListResponse>
    toggleFavorite(shopId: number): Promise<FavoriteToggleResponse>
    checkFavoriteStatus(shopId: number): Promise<{ favorited: boolean }>
    removeFavorite(favoriteId: number): Promise<ApiResponse<{ message: string }>>
    getFavoriteStats(): Promise<FavoriteStatsResponse>
}

export interface FavoriteQueryParams {
    page?: number
    per_page?: number
}

export interface FavoriteStatsResponse {
    total_favorites: number
    favorites_by_genre: Record<string, number>
}

class FavoriteService implements FavoriteServiceInterface {
    /**
     * Get user's favorite shops with pagination
     */
    async getFavorites(params: FavoriteQueryParams = {}): Promise<FavoriteListResponse> {
        try {
            const response = await api.get('/favorites', { params })
            return response.data
        } catch (error: any) {
            console.error('Failed to fetch favorites:', error)
            throw this.handleApiError(error)
        }
    }

    /**
     * Toggle favorite status for a shop
     */
    async toggleFavorite(shopId: number): Promise<FavoriteToggleResponse> {
        try {
            const response = await api.post(`/favorites/toggle/${shopId}`)
            return response.data
        } catch (error: any) {
            console.error(`Failed to toggle favorite for shop ${shopId}:`, error)
            throw this.handleApiError(error)
        }
    }

    /**
     * Check if a shop is favorited by the current user
     */
    async checkFavoriteStatus(shopId: number): Promise<{ favorited: boolean }> {
        try {
            const response = await api.get(`/favorites/check/${shopId}`)
            return response.data
        } catch (error: any) {
            console.error(`Failed to check favorite status for shop ${shopId}:`, error)
            throw this.handleApiError(error)
        }
    }

    /**
     * Remove a specific favorite
     */
    async removeFavorite(favoriteId: number): Promise<ApiResponse<{ message: string }>> {
        try {
            const response = await api.delete(`/favorites/${favoriteId}`)
            return response.data
        } catch (error: any) {
            console.error(`Failed to remove favorite ${favoriteId}:`, error)
            throw this.handleApiError(error)
        }
    }

    /**
     * Get favorite statistics for the current user
     */
    async getFavoriteStats(): Promise<FavoriteStatsResponse> {
        try {
            const response = await api.get('/favorites/stats')
            return response.data
        } catch (error: any) {
            console.error('Failed to fetch favorite statistics:', error)
            throw this.handleApiError(error)
        }
    }

    /**
     * Handle API errors and convert them to a consistent format
     */
    private handleApiError(error: any): Error {
        if (error.response?.data?.error) {
            const apiError = error.response.data.error as ApiError
            return new Error(apiError.message || 'An error occurred')
        }

        if (error.response?.status === 401) {
            return new Error('認証が必要です')
        }

        if (error.response?.status === 403) {
            return new Error('この操作を実行する権限がありません')
        }

        if (error.response?.status === 404) {
            return new Error('リソースが見つかりません')
        }

        if (error.response?.status >= 500) {
            return new Error('サーバーエラーが発生しました')
        }

        return new Error(error.message || 'ネットワークエラーが発生しました')
    }
}

// Export singleton instance
export const favoriteService = new FavoriteService()

// Export class for testing
export { FavoriteService }

// Export default
export default favoriteService