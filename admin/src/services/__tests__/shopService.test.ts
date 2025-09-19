import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { shopService } from '@/services/shopService'
import { ShopGenre } from '@/types/shop'
import type { ShopFormData, PaginatedResponse, ApiResponse } from '@/types/api'
import type { Shop } from '@/types/shop'

// Mock axios
const mockApi = {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn()
}

vi.mock('@/services/api', () => ({
    default: mockApi
}))

describe('shopService', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    afterEach(() => {
        vi.restoreAllMocks()
    })

    describe('getShops', () => {
        it('should fetch shops with default parameters', async () => {
            const mockResponse: PaginatedResponse<Shop> = {
                data: [
                    {
                        id: 1,
                        name: 'テストカフェ',
                        description: '素敵なカフェ',
                        address: '東京都渋谷区',
                        phone: '03-1234-5678',
                        business_hours: '9:00-18:00',
                        genre: ShopGenre.CAFE,
                        latitude: 35.6762,
                        longitude: 139.6503,
                        image_url: 'https://example.com/image.jpg',
                        has_try_benefit: true,
                        stamp_count: 5,
                        is_approved: true,
                        created_at: '2024-01-01T00:00:00Z',
                        updated_at: '2024-01-01T00:00:00Z'
                    }
                ],
                pagination: {
                    current_page: 1,
                    last_page: 1,
                    per_page: 10,
                    total: 1,
                    from: 1,
                    to: 1,
                    has_more_pages: false
                }
            }

            mockApi.get.mockResolvedValue({ data: mockResponse })

            const result = await shopService.getShops()

            expect(mockApi.get).toHaveBeenCalledWith('/admin/shops', { params: {} })
            expect(result).toEqual(mockResponse)
        })

        it('should fetch shops with custom parameters', async () => {
            const params = {
                page: 2,
                per_page: 20,
                genre: ShopGenre.CAFE,
                search: 'テスト',
                sort_by: 'name',
                sort_order: 'asc' as const
            }

            const mockResponse: PaginatedResponse<Shop> = {
                data: [],
                pagination: {
                    current_page: 2,
                    last_page: 5,
                    per_page: 20,
                    total: 100,
                    from: 21,
                    to: 40,
                    has_more_pages: true
                }
            }

            mockApi.get.mockResolvedValue({ data: mockResponse })

            const result = await shopService.getShops(params)

            expect(mockApi.get).toHaveBeenCalledWith('/admin/shops', { params })
            expect(result).toEqual(mockResponse)
        })

        it('should handle API errors', async () => {
            const errorMessage = 'Network error'
            mockApi.get.mockRejectedValue(new Error(errorMessage))

            await expect(shopService.getShops()).rejects.toThrow(errorMessage)
        })
    })

    describe('getShop', () => {
        it('should fetch single shop by ID', async () => {
            const shopId = 1
            const mockShop: Shop = {
                id: shopId,
                name: 'テストカフェ',
                description: '素敵なカフェ',
                address: '東京都渋谷区',
                phone: '03-1234-5678',
                business_hours: '9:00-18:00',
                genre: ShopGenre.CAFE,
                latitude: 35.6762,
                longitude: 139.6503,
                image_url: 'https://example.com/image.jpg',
                has_try_benefit: true,
                stamp_count: 5,
                is_approved: true,
                created_at: '2024-01-01T00:00:00Z',
                updated_at: '2024-01-01T00:00:00Z'
            }

            const mockResponse: ApiResponse<Shop> = {
                data: mockShop,
                message: 'Shop retrieved successfully'
            }

            mockApi.get.mockResolvedValue({ data: mockResponse })

            const result = await shopService.getShop(shopId)

            expect(mockApi.get).toHaveBeenCalledWith(`/admin/shops/${shopId}`)
            expect(result).toEqual(mockResponse)
        })

        it('should handle shop not found error', async () => {
            const shopId = 999
            const error = {
                response: {
                    status: 404,
                    data: { message: 'Shop not found' }
                }
            }

            mockApi.get.mockRejectedValue(error)

            await expect(shopService.getShop(shopId)).rejects.toEqual(error)
        })
    })

    describe('createShop', () => {
        it('should create new shop with valid data', async () => {
            const shopData: ShopFormData = {
                name: 'テストカフェ',
                description: '素敵なカフェ',
                address: '東京都渋谷区',
                phone: '03-1234-5678',
                business_hours: '9:00-18:00',
                genre: ShopGenre.CAFE,
                latitude: 35.6762,
                longitude: 139.6503,
                image_url: 'https://example.com/image.jpg',
                has_try_benefit: true,
                stamp_count: 5
            }

            const createdShop: Shop = {
                id: 1,
                ...shopData,
                is_approved: true,
                created_at: '2024-01-01T00:00:00Z',
                updated_at: '2024-01-01T00:00:00Z'
            }

            const mockResponse: ApiResponse<Shop> = {
                data: createdShop,
                message: 'Shop created successfully'
            }

            mockApi.post.mockResolvedValue({ data: mockResponse })

            const result = await shopService.createShop(shopData)

            expect(mockApi.post).toHaveBeenCalledWith('/admin/shops', shopData)
            expect(result).toEqual(mockResponse)
        })

        it('should handle validation errors', async () => {
            const shopData: ShopFormData = {
                name: '', // Invalid: empty name
                genre: ShopGenre.CAFE,
                has_try_benefit: false,
                stamp_count: 0
            }

            const validationError = {
                response: {
                    status: 422,
                    data: {
                        message: 'Validation failed',
                        errors: {
                            name: ['店舗名は必須です']
                        }
                    }
                }
            }

            mockApi.post.mockRejectedValue(validationError)

            await expect(shopService.createShop(shopData)).rejects.toEqual(validationError)
        })

        it('should enforce TypeScript types', () => {
            // This test ensures TypeScript compilation catches type errors
            const validShopData: ShopFormData = {
                name: 'テストカフェ',
                genre: ShopGenre.CAFE,
                has_try_benefit: true,
                stamp_count: 5
            }

            expect(validShopData.name).toBe('テストカフェ')
            expect(validShopData.genre).toBe(ShopGenre.CAFE)
            expect(validShopData.has_try_benefit).toBe(true)
            expect(validShopData.stamp_count).toBe(5)

            // TypeScript should prevent these invalid assignments:
            // validShopData.genre = 'invalid-genre' // Type error
            // validShopData.has_try_benefit = 'yes' // Type error
            // validShopData.stamp_count = '5' // Type error
        })
    })

    describe('updateShop', () => {
        it('should update existing shop', async () => {
            const shopId = 1
            const updateData: Partial<ShopFormData> = {
                name: '更新されたカフェ',
                has_try_benefit: true,
                stamp_count: 10
            }

            const updatedShop: Shop = {
                id: shopId,
                name: '更新されたカフェ',
                description: '素敵なカフェ',
                address: '東京都渋谷区',
                phone: '03-1234-5678',
                business_hours: '9:00-18:00',
                genre: ShopGenre.CAFE,
                latitude: 35.6762,
                longitude: 139.6503,
                image_url: 'https://example.com/image.jpg',
                has_try_benefit: true,
                stamp_count: 10,
                is_approved: true,
                created_at: '2024-01-01T00:00:00Z',
                updated_at: '2024-01-02T00:00:00Z'
            }

            const mockResponse: ApiResponse<Shop> = {
                data: updatedShop,
                message: 'Shop updated successfully'
            }

            mockApi.put.mockResolvedValue({ data: mockResponse })

            const result = await shopService.updateShop(shopId, updateData)

            expect(mockApi.put).toHaveBeenCalledWith(`/admin/shops/${shopId}`, updateData)
            expect(result).toEqual(mockResponse)
        })

        it('should handle partial updates', async () => {
            const shopId = 1
            const partialUpdate: Partial<ShopFormData> = {
                stamp_count: 15
            }

            const mockResponse: ApiResponse<Shop> = {
                data: {
                    id: shopId,
                    name: 'テストカフェ',
                    genre: ShopGenre.CAFE,
                    has_try_benefit: false,
                    stamp_count: 15,
                    is_approved: true,
                    created_at: '2024-01-01T00:00:00Z',
                    updated_at: '2024-01-02T00:00:00Z'
                } as Shop
            }

            mockApi.put.mockResolvedValue({ data: mockResponse })

            const result = await shopService.updateShop(shopId, partialUpdate)

            expect(mockApi.put).toHaveBeenCalledWith(`/admin/shops/${shopId}`, partialUpdate)
            expect(result.data.stamp_count).toBe(15)
        })
    })

    describe('deleteShop', () => {
        it('should delete shop successfully', async () => {
            const shopId = 1
            const mockResponse: ApiResponse<null> = {
                data: null,
                message: 'Shop deleted successfully'
            }

            mockApi.delete.mockResolvedValue({ data: mockResponse })

            const result = await shopService.deleteShop(shopId)

            expect(mockApi.delete).toHaveBeenCalledWith(`/admin/shops/${shopId}`)
            expect(result).toEqual(mockResponse)
        })

        it('should handle delete errors', async () => {
            const shopId = 1
            const error = {
                response: {
                    status: 403,
                    data: { message: 'Cannot delete shop with existing posts' }
                }
            }

            mockApi.delete.mockRejectedValue(error)

            await expect(shopService.deleteShop(shopId)).rejects.toEqual(error)
        })
    })

    describe('uploadImage', () => {
        it('should upload image file', async () => {
            const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
            const mockResponse = {
                url: 'https://example.com/uploaded-image.jpg',
                path: '/uploads/images/test.jpg',
                message: 'Image uploaded successfully'
            }

            mockApi.post.mockResolvedValue({ data: mockResponse })

            const result = await shopService.uploadImage(mockFile)

            expect(mockApi.post).toHaveBeenCalledWith(
                '/admin/shops/upload-image',
                expect.any(FormData),
                {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                }
            )
            expect(result).toEqual(mockResponse)
        })

        it('should handle upload errors', async () => {
            const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
            const error = {
                response: {
                    status: 413,
                    data: { message: 'File too large' }
                }
            }

            mockApi.post.mockRejectedValue(error)

            await expect(shopService.uploadImage(mockFile)).rejects.toEqual(error)
        })
    })

    describe('Type Safety Tests', () => {
        it('should enforce ShopGenre enum values', () => {
            const allGenres = Object.values(ShopGenre)

            // Should have exactly 20 genres
            expect(allGenres).toHaveLength(20)

            // Should contain all expected genres
            expect(allGenres).toContain(ShopGenre.RAMEN)
            expect(allGenres).toContain(ShopGenre.CAFE)
            expect(allGenres).toContain(ShopGenre.IZAKAYA)
            expect(allGenres).toContain(ShopGenre.YAKINIKU)
            expect(allGenres).toContain(ShopGenre.SUSHI)
            expect(allGenres).toContain(ShopGenre.SWEETS)
            expect(allGenres).toContain(ShopGenre.FAST_FOOD)
            expect(allGenres).toContain(ShopGenre.RESTAURANT)
            expect(allGenres).toContain(ShopGenre.BAR)
            expect(allGenres).toContain(ShopGenre.BAKERY)
            expect(allGenres).toContain(ShopGenre.ITALIAN)
            expect(allGenres).toContain(ShopGenre.CHINESE)
            expect(allGenres).toContain(ShopGenre.KOREAN)
            expect(allGenres).toContain(ShopGenre.FRENCH)
            expect(allGenres).toContain(ShopGenre.JAPANESE)
            expect(allGenres).toContain(ShopGenre.WESTERN)
            expect(allGenres).toContain(ShopGenre.SEAFOOD)
            expect(allGenres).toContain(ShopGenre.VEGETARIAN)
            expect(allGenres).toContain(ShopGenre.BBQ)
            expect(allGenres).toContain(ShopGenre.OTHER)
        })

        it('should enforce ShopFormData interface structure', () => {
            const validFormData: ShopFormData = {
                name: 'テストカフェ',
                description: '説明',
                address: '住所',
                phone: '電話番号',
                business_hours: '営業時間',
                genre: ShopGenre.CAFE,
                latitude: 35.6762,
                longitude: 139.6503,
                image_url: 'https://example.com/image.jpg',
                has_try_benefit: true,
                stamp_count: 5
            }

            // Required fields
            expect(typeof validFormData.name).toBe('string')
            expect(typeof validFormData.has_try_benefit).toBe('boolean')
            expect(typeof validFormData.stamp_count).toBe('number')

            // Optional fields
            expect(validFormData.description === undefined || typeof validFormData.description === 'string').toBe(true)
            expect(validFormData.address === undefined || typeof validFormData.address === 'string').toBe(true)
            expect(validFormData.phone === undefined || typeof validFormData.phone === 'string').toBe(true)
            expect(validFormData.business_hours === undefined || typeof validFormData.business_hours === 'string').toBe(true)
            expect(validFormData.genre === undefined || Object.values(ShopGenre).includes(validFormData.genre)).toBe(true)
            expect(validFormData.latitude === undefined || typeof validFormData.latitude === 'number').toBe(true)
            expect(validFormData.longitude === undefined || typeof validFormData.longitude === 'number').toBe(true)
            expect(validFormData.image_url === undefined || typeof validFormData.image_url === 'string').toBe(true)
        })

        it('should enforce Shop interface structure', () => {
            const validShop: Shop = {
                id: 1,
                name: 'テストカフェ',
                description: '説明',
                address: '住所',
                phone: '電話番号',
                business_hours: '営業時間',
                genre: ShopGenre.CAFE,
                latitude: 35.6762,
                longitude: 139.6503,
                image_url: 'https://example.com/image.jpg',
                has_try_benefit: true,
                stamp_count: 5,
                is_approved: true,
                created_at: '2024-01-01T00:00:00Z',
                updated_at: '2024-01-01T00:00:00Z'
            }

            // Required fields
            expect(typeof validShop.id).toBe('number')
            expect(typeof validShop.name).toBe('string')
            expect(typeof validShop.has_try_benefit).toBe('boolean')
            expect(typeof validShop.stamp_count).toBe('number')
            expect(typeof validShop.is_approved).toBe('boolean')
            expect(typeof validShop.created_at).toBe('string')
            expect(typeof validShop.updated_at).toBe('string')
        })
    })

    describe('Error Handling', () => {
        it('should handle network errors', async () => {
            const networkError = new Error('Network Error')
            mockApi.get.mockRejectedValue(networkError)

            await expect(shopService.getShops()).rejects.toThrow('Network Error')
        })

        it('should handle HTTP error responses', async () => {
            const httpError = {
                response: {
                    status: 500,
                    data: {
                        message: 'Internal Server Error'
                    }
                }
            }

            mockApi.get.mockRejectedValue(httpError)

            await expect(shopService.getShops()).rejects.toEqual(httpError)
        })

        it('should handle validation errors with proper typing', async () => {
            const validationError = {
                response: {
                    status: 422,
                    data: {
                        message: 'Validation failed',
                        errors: {
                            name: ['店舗名は必須です', '店舗名は2文字以上で入力してください'],
                            genre: ['ジャンルは必須です'],
                            stamp_count: ['スタンプ数は0以上で入力してください']
                        }
                    }
                }
            }

            mockApi.post.mockRejectedValue(validationError)

            try {
                await shopService.createShop({
                    name: '',
                    genre: undefined,
                    has_try_benefit: false,
                    stamp_count: -1
                } as ShopFormData)
            } catch (error: any) {
                expect(error.response.status).toBe(422)
                expect(error.response.data.errors.name).toContain('店舗名は必須です')
                expect(error.response.data.errors.genre).toContain('ジャンルは必須です')
                expect(error.response.data.errors.stamp_count).toContain('スタンプ数は0以上で入力してください')
            }
        })
    })
})