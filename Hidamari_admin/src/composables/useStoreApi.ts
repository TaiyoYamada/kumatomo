import { ref, computed } from 'vue'
import api from '../services/api.js'
import type {
    Store,
    StoreListResponse,
    StoreApiResponse,
    StoreCreateRequest,
    StoreUpdateRequest,
    StoreQueryParams,
    ApiError
} from '../types/store'

export function useStoreApi() {
    const stores = ref<Store[]>([])
    const currentStore = ref<Store | null>(null)
    const loading = ref(false)
    const error = ref<string>('')
    const pagination = ref({
        current_page: 1,
        last_page: 1,
        per_page: 10,
        total: 0,
        from: 0,
        to: 0
    })

    // Computed properties
    const hasStores = computed(() => stores.value.length > 0)
    const isLoading = computed(() => loading.value)
    const hasError = computed(() => !!error.value)

    // Clear error state
    const clearError = () => {
        error.value = ''
    }

    // Get all stores with pagination and filters
    const getStores = async (params: StoreQueryParams = {}) => {
        try {
            loading.value = true
            clearError()

            // Map to API endpoint parameters (using existing /admin/shops endpoint)
            const apiParams = {
                page: params.page || 1,
                per_page: params.per_page || 10,
                ...(params.search && { search: params.search }),
                ...(params.genre && { genre: params.genre }),
                ...(params.city && { city: params.city }),
                ...(params.has_try_benefit !== undefined && { has_try_benefit: params.has_try_benefit }),
                ...(params.sort_by && { sort_by: params.sort_by }),
                ...(params.sort_desc !== undefined && { sort_desc: params.sort_desc })
            }

            const response = await api.get<StoreListResponse>('/admin/shops', { params: apiParams })

            stores.value = response.data.data
            pagination.value = response.data.meta

            return response.data
        } catch (err: any) {
            const errorMessage = err.response?.data?.message || 'ストアの取得に失敗しました'
            error.value = errorMessage
            throw new Error(errorMessage)
        } finally {
            loading.value = false
        }
    }

    // Get single store by ID
    const getStore = async (id: number) => {
        try {
            loading.value = true
            clearError()

            const response = await api.get<StoreApiResponse>(`/admin/shops/${id}`)
            currentStore.value = response.data.data

            return response.data.data
        } catch (err: any) {
            const errorMessage = err.response?.data?.message || 'ストアの取得に失敗しました'
            error.value = errorMessage
            throw new Error(errorMessage)
        } finally {
            loading.value = false
        }
    }

    // Create new store
    const createStore = async (storeData: StoreCreateRequest) => {
        try {
            loading.value = true
            clearError()

            const response = await api.post<StoreApiResponse>('/admin/shops', storeData)
            const newStore = response.data.data

            // Add to local stores array
            stores.value.unshift(newStore)

            return newStore
        } catch (err: any) {
            const errorMessage = err.response?.data?.message || 'ストアの作成に失敗しました'
            error.value = errorMessage

            // Handle validation errors
            if (err.response?.data?.errors) {
                const validationErrors = err.response.data.errors
                throw { message: errorMessage, errors: validationErrors }
            }

            throw new Error(errorMessage)
        } finally {
            loading.value = false
        }
    }

    // Update existing store
    const updateStore = async (id: number, storeData: Partial<StoreCreateRequest>) => {
        try {
            loading.value = true
            clearError()

            const response = await api.put<StoreApiResponse>(`/admin/shops/${id}`, storeData)
            const updatedStore = response.data.data

            // Update in local stores array
            const index = stores.value.findIndex(store => store.id === id)
            if (index !== -1) {
                stores.value[index] = updatedStore
            }

            // Update current store if it's the same
            if (currentStore.value?.id === id) {
                currentStore.value = updatedStore
            }

            return updatedStore
        } catch (err: any) {
            const errorMessage = err.response?.data?.message || 'ストアの更新に失敗しました'
            error.value = errorMessage

            // Handle validation errors
            if (err.response?.data?.errors) {
                const validationErrors = err.response.data.errors
                throw { message: errorMessage, errors: validationErrors }
            }

            throw new Error(errorMessage)
        } finally {
            loading.value = false
        }
    }

    // Delete store
    const deleteStore = async (id: number) => {
        try {
            loading.value = true
            clearError()

            await api.delete(`/admin/shops/${id}`)

            // Remove from local stores array
            stores.value = stores.value.filter(store => store.id !== id)

            // Clear current store if it's the deleted one
            if (currentStore.value?.id === id) {
                currentStore.value = null
            }

            return true
        } catch (err: any) {
            const errorMessage = err.response?.data?.message || 'ストアの削除に失敗しました'
            error.value = errorMessage
            throw new Error(errorMessage)
        } finally {
            loading.value = false
        }
    }

    // Utility functions
    const refreshStores = async (params?: StoreQueryParams) => {
        return await getStores(params)
    }

    const resetState = () => {
        stores.value = []
        currentStore.value = null
        loading.value = false
        error.value = ''
        pagination.value = {
            current_page: 1,
            last_page: 1,
            per_page: 10,
            total: 0,
            from: 0,
            to: 0
        }
    }

    // Helper function to extract city from address
    const extractCityFromAddress = (address: string | null): string => {
        if (!address) return ''

        // Simple extraction logic - can be enhanced based on Japanese address format
        const parts = address.split(/[都道府県市区町村]/)
        if (parts.length > 1) {
            return parts[0] + (address.includes('都') ? '都' :
                address.includes('道') ? '道' :
                    address.includes('府') ? '府' : '県')
        }
        return ''
    }

    // Helper function to determine Try benefit availability
    const hasTryBenefit = (store: Store): boolean => {
        // This would be based on actual business logic
        // For now, return a placeholder based on genre
        const benefitGenres = ['レストラン', 'カフェ', '居酒屋']
        return benefitGenres.includes(store.genre || '')
    }

    // Helper function to determine store status
    const getStoreStatus = (store: Store): 'active' | 'inactive' => {
        // This would be based on actual business logic
        // For now, assume all stores are active
        return 'active'
    }

    // Enhance stores with computed fields
    const enhanceStore = (store: Store): Store => {
        return {
            ...store,
            city: extractCityFromAddress(store.address),
            has_try_benefit: hasTryBenefit(store),
            status: getStoreStatus(store)
        }
    }

    const enhanceStores = (storeList: Store[]): Store[] => {
        return storeList.map(enhanceStore)
    }

    return {
        // State
        stores: computed(() => enhanceStores(stores.value)),
        currentStore: computed(() => currentStore.value ? enhanceStore(currentStore.value) : null),
        loading: computed(() => loading.value),
        error: computed(() => error.value),
        pagination: computed(() => pagination.value),

        // Computed
        hasStores,
        isLoading,
        hasError,

        // Actions
        getStores,
        getStore,
        createStore,
        updateStore,
        deleteStore,
        refreshStores,
        resetState,
        clearError,

        // Utilities
        enhanceStore,
        enhanceStores
    }
}