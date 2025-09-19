import api from './api'
import type { Shop } from '@/types/shop'
import type { ApiResponse, PaginatedResponse, ShopFormData } from '@/types/api'
import type { AxiosResponse } from 'axios'

export interface ShopServiceParams {
    page?: number
    per_page?: number
    genre?: string
    search?: string
    sort_by?: string
    sort_order?: 'asc' | 'desc'
}

export interface ImageUploadResponse {
    url: string
    path: string
    message: string
}

export const shopService = {
    // Get all shops with pagination and filters
    async getShops(params: ShopServiceParams = {}): Promise<PaginatedResponse<Shop>> {
        const response: AxiosResponse<PaginatedResponse<Shop>> = await api.get('/admin/shops', { params })
        return response.data
    },

    // Get single shop by ID
    async getShop(id: number): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await api.get(`/admin/shops/${id}`)
        return response.data
    },

    // Create new shop
    async createShop(shopData: ShopFormData): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await api.post('/admin/shops', shopData)
        return response.data
    },

    // Update existing shop
    async updateShop(id: number, shopData: Partial<ShopFormData>): Promise<ApiResponse<Shop>> {
        const response: AxiosResponse<ApiResponse<Shop>> = await api.put(`/admin/shops/${id}`, shopData)
        return response.data
    },

    // Delete shop
    async deleteShop(id: number): Promise<ApiResponse<null>> {
        const response: AxiosResponse<ApiResponse<null>> = await api.delete(`/admin/shops/${id}`)
        return response.data
    },

    // Upload shop image
    async uploadImage(file: File): Promise<ImageUploadResponse> {
        const formData = new FormData()
        formData.append('image', file)

        const response: AxiosResponse<ImageUploadResponse> = await api.post('/admin/shops/upload-image', formData, {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
        })
        return response.data
    }
}