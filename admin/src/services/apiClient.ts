import axios, { AxiosInstance, AxiosResponse, AxiosError } from 'axios'
import type {
    ApiResponse,
    PaginatedResponse,
    ApiError,
    ShopListParams,
    FavoriteListParams,
    ShopProposalParams,
    ShopFormData
} from '@/types/api'
import type {
    Shop,
    Favorite,
    ShopProposal,
    FavoriteStats,
    FavoriteToggleResponse,
    FavoriteCheckResponse
} from '@/types/shop'

class ApiClient {
    private client: AxiosInstance

    constructor() {
        const baseURL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'

        this.client = axios.create({
            baseURL,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        })

        this.setupInterceptors()
    }

    private setupInterceptors(): void {
        // Request interceptor for auth token
        this.client.interceptors.request.use(
            (config) => {
                const token = localStorage.getItem('admin_token')
                if (token) {
                    config.headers.Authorization = `Bearer ${token}`
                }
                return config
            },
            (error) => {
                return Promise.reject(error)
            }
        )

        // Response interceptor for error handling
        this.client.interceptors.response.use(
            (response) => response,
            (error: AxiosError<ApiError>) => {
                if (error.response?.status === 401) {
                    localStorage.removeItem('admin_token')
                    // Could emit an event or redirect to login
                }
                return Promise.reject(error)
            }
        )
    }

    // Shop API methods
    async getShops(params?: ShopListParams): Promise<PaginatedResponse<Shop>> {
        const response: AxiosResponse<PaginatedResponse<Shop>> = await this.client.get('/shops', { params })
        return response.data
    }

    async getShop(id: number): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await this.client.get(`/shops/${id}`)
        return response.data
    }

    async searchShops(query: string, params?: Omit<ShopListParams, 'q'>): Promise<PaginatedResponse<Shop>> {
        const response: AxiosResponse<PaginatedResponse<Shop>> = await this.client.get('/shops/search', {
            params: { q: query, ...params }
        })
        return response.data
    }

    // Favorite API methods
    async getFavorites(params?: FavoriteListParams): Promise<PaginatedResponse<Favorite>> {
        const response: AxiosResponse<PaginatedResponse<Favorite>> = await this.client.get('/favorites', { params })
        return response.data
    }

    async toggleFavorite(shopId: number): Promise<FavoriteToggleResponse> {
        const response: AxiosResponse<FavoriteToggleResponse> = await this.client.post(`/favorites/toggle/${shopId}`)
        return response.data
    }

    async checkFavorite(shopId: number): Promise<FavoriteCheckResponse> {
        const response: AxiosResponse<FavoriteCheckResponse> = await this.client.get(`/favorites/check/${shopId}`)
        return response.data
    }

    async removeFavorite(favoriteId: number): Promise<ApiResponse<null>> {
        const response: AxiosResponse<ApiResponse<null>> = await this.client.delete(`/favorites/${favoriteId}`)
        return response.data
    }

    async getFavoriteStats(): Promise<FavoriteStats> {
        const response: AxiosResponse<FavoriteStats> = await this.client.get('/favorites/stats')
        return response.data
    }

    // Shop Proposal API methods
    async getShopProposals(params?: { page?: number; per_page?: number }): Promise<PaginatedResponse<ShopProposal>> {
        const response: AxiosResponse<PaginatedResponse<ShopProposal>> = await this.client.get('/shop-proposals', { params })
        return response.data
    }

    async createShopProposal(data: ShopProposalParams): Promise<ApiResponse<ShopProposal>> {
        const response: AxiosResponse<ApiResponse<ShopProposal>> = await this.client.post('/shop-proposals', data)
        return response.data
    }

    async getShopProposal(id: number): Promise<ApiResponse<ShopProposal>> {
        const response: AxiosResponse<ApiResponse<ShopProposal>> = await this.client.get(`/shop-proposals/${id}`)
        return response.data
    }

    // Admin Shop API methods
    async getAdminShops(params?: ShopListParams): Promise<PaginatedResponse<Shop>> {
        const response: AxiosResponse<PaginatedResponse<Shop>> = await this.client.get('/admin/shops', { params })
        return response.data
    }

    async createShop(data: ShopFormData): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await this.client.post('/admin/shops', data)
        return response.data
    }

    async updateShop(id: number, data: Partial<ShopFormData>): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await this.client.put(`/admin/shops/${id}`, data)
        return response.data
    }

    async deleteShop(id: number): Promise<ApiResponse<null>> {
        const response: AxiosResponse<ApiResponse<null>> = await this.client.delete(`/admin/shops/${id}`)
        return response.data
    }

    // Admin Shop Proposal methods
    async getAdminShopProposals(params?: { page?: number; per_page?: number }): Promise<PaginatedResponse<ShopProposal>> {
        const response: AxiosResponse<PaginatedResponse<ShopProposal>> = await this.client.get('/admin/shop-proposals', { params })
        return response.data
    }

    async approveShopProposal(id: number): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await this.client.post(`/admin/shop-proposals/${id}/approve`)
        return response.data
    }

    async rejectShopProposal(id: number, notes?: string): Promise<ApiResponse<null>> {
        const response: AxiosResponse<ApiResponse<null>> = await this.client.post(`/admin/shop-proposals/${id}/reject`, {
            admin_notes: notes
        })
        return response.data
    }

    // Generic error handler
    handleError(error: AxiosError<ApiError>): never {
        if (error.response?.data?.error) {
            throw new Error(error.response.data.error.message)
        } else if (error.message) {
            throw new Error(error.message)
        } else {
            throw new Error('An unexpected error occurred')
        }
    }
}

// Create and export a singleton instance
export const apiClient = new ApiClient()
export default apiClient