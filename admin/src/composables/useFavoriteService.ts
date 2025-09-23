import { ref, computed } from 'vue'
import { favoriteService, type FavoriteQueryParams, type FavoriteStatsResponse } from '@/services/favoriteService'
import type { Favorite, FavoriteToggleResponse } from '@/types/shop'

export const useFavoriteService = () => {
    // Reactive state
    const favorites = ref<Favorite[]>([])
    const favoriteStats = ref<FavoriteStatsResponse | null>(null)
    const loading = ref(false)
    const error = ref<string | null>(null)
    const currentPage = ref(1)
    const totalPages = ref(1)
    const totalFavorites = ref(0)

    // Computed properties
    const isEmpty = computed(() => favorites.value.length === 0)
    const hasError = computed(() => error.value !== null)
    const isLoading = computed(() => loading.value)

    // Methods
    const clearError = (): void => {
        error.value = null
    }

    const setLoading = (isLoading: boolean): void => {
        loading.value = isLoading
    }

    const setError = (errorMessage: string): void => {
        error.value = errorMessage
    }

    /**
     * Load favorites with pagination
     */
    const loadFavorites = async (params: FavoriteQueryParams = {}): Promise<void> => {
        try {
            setLoading(true)
            clearError()

            const response = await favoriteService.getFavorites(params)

            favorites.value = response.data
            currentPage.value = response.meta.current_page
            totalPages.value = response.meta.last_page
            totalFavorites.value = response.meta.total

            console.log(`✅ Loaded ${response.data.length} favorites`)
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'お気に入りの読み込みに失敗しました'
            setError(errorMessage)
            console.error('Failed to load favorites:', err)
        } finally {
            setLoading(false)
        }
    }

    /**
     * Toggle favorite status for a shop
     */
    const toggleFavorite = async (shopId: number): Promise<FavoriteToggleResponse | null> => {
        try {
            clearError()

            const response = await favoriteService.toggleFavorite(shopId)

            // Update local state based on the response
            if (response.favorited) {
                console.log(`✅ Shop ${shopId} added to favorites`)
            } else {
                // Remove from local favorites list
                favorites.value = favorites.value.filter(fav => fav.shop_id !== shopId)
                console.log(`✅ Shop ${shopId} removed from favorites`)
            }

            return response
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'お気に入りの更新に失敗しました'
            setError(errorMessage)
            console.error('Failed to toggle favorite:', err)
            return null
        }
    }

    /**
     * Check if a shop is favorited
     */
    const checkFavoriteStatus = async (shopId: number): Promise<boolean> => {
        try {
            clearError()

            const response = await favoriteService.checkFavoriteStatus(shopId)
            return response.favorited
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'お気に入り状態の確認に失敗しました'
            setError(errorMessage)
            console.error('Failed to check favorite status:', err)
            return false
        }
    }

    /**
     * Remove a specific favorite
     */
    const removeFavorite = async (favoriteId: number): Promise<boolean> => {
        try {
            clearError()

            await favoriteService.removeFavorite(favoriteId)

            // Remove from local state
            favorites.value = favorites.value.filter(fav => fav.id !== favoriteId)
            totalFavorites.value = Math.max(0, totalFavorites.value - 1)

            console.log(`✅ Favorite ${favoriteId} removed`)
            return true
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'お気に入りの削除に失敗しました'
            setError(errorMessage)
            console.error('Failed to remove favorite:', err)
            return false
        }
    }

    /**
     * Load favorite statistics
     */
    const loadFavoriteStats = async (): Promise<void> => {
        try {
            clearError()

            const stats = await favoriteService.getFavoriteStats()
            favoriteStats.value = stats

            console.log(`✅ Loaded favorite statistics: ${stats.total_favorites} total`)
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : '統計情報の読み込みに失敗しました'
            setError(errorMessage)
            console.error('Failed to load favorite statistics:', err)
        }
    }

    /**
     * Refresh favorites (reload current page)
     */
    const refreshFavorites = async (): Promise<void> => {
        await loadFavorites({ page: currentPage.value })
    }

    /**
     * Load next page of favorites
     */
    const loadNextPage = async (): Promise<void> => {
        if (currentPage.value < totalPages.value) {
            await loadFavorites({ page: currentPage.value + 1 })
        }
    }

    /**
     * Load previous page of favorites
     */
    const loadPreviousPage = async (): Promise<void> => {
        if (currentPage.value > 1) {
            await loadFavorites({ page: currentPage.value - 1 })
        }
    }

    /**
     * Load specific page of favorites
     */
    const loadPage = async (page: number): Promise<void> => {
        if (page >= 1 && page <= totalPages.value) {
            await loadFavorites({ page })
        }
    }

    /**
     * Clear all favorites from local state
     */
    const clearFavorites = (): void => {
        favorites.value = []
        favoriteStats.value = null
        currentPage.value = 1
        totalPages.value = 1
        totalFavorites.value = 0
        clearError()
    }

    /**
     * Get favorite by shop ID
     */
    const getFavoriteByShopId = (shopId: number): Favorite | undefined => {
        return favorites.value.find(fav => fav.shop_id === shopId)
    }

    /**
     * Check if shop is in local favorites
     */
    const isShopFavorited = (shopId: number): boolean => {
        return favorites.value.some(fav => fav.shop_id === shopId)
    }

    return {
        // State
        favorites: computed(() => favorites.value),
        favoriteStats: computed(() => favoriteStats.value),
        loading: isLoading,
        error: computed(() => error.value),
        currentPage: computed(() => currentPage.value),
        totalPages: computed(() => totalPages.value),
        totalFavorites: computed(() => totalFavorites.value),
        isEmpty,
        hasError,

        // Methods
        loadFavorites,
        toggleFavorite,
        checkFavoriteStatus,
        removeFavorite,
        loadFavoriteStats,
        refreshFavorites,
        loadNextPage,
        loadPreviousPage,
        loadPage,
        clearFavorites,
        clearError,
        getFavoriteByShopId,
        isShopFavorited
    }
}