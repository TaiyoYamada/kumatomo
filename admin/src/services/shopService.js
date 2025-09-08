import api from './api.js'

export const shopService = {
    // Get all shops with pagination and filters
    async getShops(params = {}) {
        const response = await api.get('/admin/shops', { params })
        return response.data
    },

    // Get single shop by ID
    async getShop(id) {
        const response = await api.get(`/admin/shops/${id}`)
        return response.data
    },

    // Create new shop
    async createShop(shopData) {
        const response = await api.post('/admin/shops', shopData)
        return response.data
    },

    // Update existing shop
    async updateShop(id, shopData) {
        const response = await api.put(`/admin/shops/${id}`, shopData)
        return response.data
    },

    // Delete shop
    async deleteShop(id) {
        const response = await api.delete(`/admin/shops/${id}`)
        return response.data
    },

    // Upload shop image
    async uploadImage(file) {
        const formData = new FormData()
        formData.append('image', file)

        const response = await api.post('/admin/shops/upload-image', formData, {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
        })
        return response.data
    }
}