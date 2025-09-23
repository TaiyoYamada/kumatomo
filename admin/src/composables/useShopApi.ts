import { ref, computed } from 'vue'
import { apiClient } from '@/services/apiClient'
import type {
    Shop,
    ShopProposal,
    FavoriteStats,
    ShopGenre
} from '@/types/shop'
import type {
    ShopListParams,
    FavoriteListParams,
    ShopProposalParams,
    ShopFormData,
    PaginatedResponse
} from '@/types/api'

export const useShopApi = () => {
    const loading = ref(false)
    const error = ref<string | null>(null)
    const shops = ref<Shop[]>([])
    const proposals = ref<ShopProposal[]>([])
    const pagination = ref({
        current_page: 1,
        last_page: 1,
        per_page: 20,
        total: 0,
        from: null as number | null,
        to: null as number | null,
        has_more_pages: false
    })

    // Computed properties
    const hasError = computed(() => error.value !== null)
    const isEmpty = computed(() => shops.value.length === 0)
    const hasMorePages = computed(() => pagination.value.has_more_pages)

    // Clear error
    const clearError = () => {
        error.value = null
    }

    // Shop operations
    const fetchShops = async (params?: ShopListParams): Promise<void> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.getShops(params)
            shops.value = response.data
            pagination.value = response.pagination
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to fetch shops'
            console.error('Failed to fetch shops:', err)
        } finally {
            loading.value = false
        }
    }

    const fetchShop = async (id: number): Promise<Shop | null> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.getShop(id)
            return response.data
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to fetch shop'
            console.error('Failed to fetch shop:', err)
            return null
        } finally {
            loading.value = false
        }
    }

    const searchShops = async (query: string, params?: Omit<ShopListParams, 'q'>): Promise<void> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.searchShops(query, params)
            shops.value = response.data
            pagination.value = response.pagination
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to search shops'
            console.error('Failed to search shops:', err)
        } finally {
            loading.value = false
        }
    }

    const createShop = async (shopData: ShopFormData): Promise<Shop | null> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.createShop(shopData)
            return response.data
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to create shop'
            console.error('Failed to create shop:', err)
            return null
        } finally {
            loading.value = false
        }
    }

    const updateShop = async (id: number, shopData: Partial<ShopFormData>): Promise<Shop | null> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.updateShop(id, shopData)
            return response.data
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to update shop'
            console.error('Failed to update shop:', err)
            return null
        } finally {
            loading.value = false
        }
    }

    const deleteShop = async (id: number): Promise<boolean> => {
        loading.value = true
        error.value = null

        try {
            await apiClient.deleteShop(id)
            return true
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to delete shop'
            console.error('Failed to delete shop:', err)
            return false
        } finally {
            loading.value = false
        }
    }

    // Proposal operations
    const fetchProposals = async (params?: { page?: number; per_page?: number }): Promise<void> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.getAdminShopProposals(params)
            proposals.value = response.data
            pagination.value = response.pagination
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to fetch proposals'
            console.error('Failed to fetch proposals:', err)
        } finally {
            loading.value = false
        }
    }

    const createProposal = async (proposalData: ShopProposalParams): Promise<ShopProposal | null> => {
        loading.value = true
        error.value = null

        try {
            const response = await apiClient.createShopProposal(proposalData)
            return response.data
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to create proposal'
            console.error('Failed to create proposal:', err)
            return null
        } finally {
            loading.value = false
        }
    }

    const approveProposal = async (id: number): Promise<Shop | null> => {
        error.value = null

        try {
            const response = await apiClient.approveShopProposal(id)
            // Remove from proposals list
            proposals.value = proposals.value.filter(p => p.id !== id)
            return response.data
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to approve proposal'
            console.error('Failed to approve proposal:', err)
            return null
        }
    }

    const rejectProposal = async (id: number, notes?: string): Promise<boolean> => {
        error.value = null

        try {
            await apiClient.rejectShopProposal(id, notes)
            // Remove from proposals list
            proposals.value = proposals.value.filter(p => p.id !== id)
            return true
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to reject proposal'
            console.error('Failed to reject proposal:', err)
            return false
        }
    }

    // Favorite operations
    const toggleFavorite = async (shopId: number): Promise<boolean | null> => {
        error.value = null

        try {
            const response = await apiClient.toggleFavorite(shopId)
            return response.favorited
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to toggle favorite'
            console.error('Failed to toggle favorite:', err)
            return null
        }
    }

    const checkFavorite = async (shopId: number): Promise<boolean> => {
        try {
            const response = await apiClient.checkFavorite(shopId)
            return response.favorited
        } catch (err) {
            console.error('Failed to check favorite:', err)
            return false
        }
    }

    const getFavoriteStats = async (): Promise<FavoriteStats | null> => {
        loading.value = true
        error.value = null

        try {
            return await apiClient.getFavoriteStats()
        } catch (err) {
            error.value = err instanceof Error ? err.message : 'Failed to get favorite stats'
            console.error('Failed to get favorite stats:', err)
            return null
        } finally {
            loading.value = false
        }
    }

    return {
        // State
        loading,
        error,
        shops,
        proposals,
        pagination,

        // Computed
        hasError,
        isEmpty,
        hasMorePages,

        // Methods
        clearError,
        fetchShops,
        fetchShop,
        searchShops,
        createShop,
        updateShop,
        deleteShop,
        fetchProposals,
        createProposal,
        approveProposal,
        rejectProposal,
        toggleFavorite,
        checkFavorite,
        getFavoriteStats
    }
}