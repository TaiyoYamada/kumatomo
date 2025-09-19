import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import axios from 'axios'
import type { Shop, ShopProposal, ShopGenre } from '@/types/shop'

// Mock axios
vi.mock('axios', () => ({
    default: {
        create: vi.fn(() => ({
            get: vi.fn(),
            post: vi.fn(),
            put: vi.fn(),
            delete: vi.fn(),
            interceptors: {
                request: { use: vi.fn() },
                response: { use: vi.fn() }
            }
        }))
    }
}))

const mockedAxios = vi.mocked(axios)

describe('ApiClient', () => {
    beforeEach(() => {
        vi.clearAllMocks()

        // Mock axios.create
        mockedAxios.create = vi.fn(() => ({
            get: vi.fn(),
            post: vi.fn(),
            put: vi.fn(),
            delete: vi.fn(),
            interceptors: {
                request: { use: vi.fn() },
                response: { use: vi.fn() }
            }
        })) as any
    })

    afterEach(() => {
        vi.restoreAllMocks()
    })

    describe('Shop API methods', () => {
        it('should fetch shops with parameters', async () => {
            const mockResponse = {
                data: {
                    data: [
                        {
                            id: 1,
                            name: 'Test Shop',
                            genre: 'ラーメン' as ShopGenre,
                            has_try_benefit: true,
                            stamp_count: 5,
                            is_approved: true
                        }
                    ],
                    pagination: {
                        current_page: 1,
                        last_page: 1,
                        per_page: 20,
                        total: 1,
                        from: 1,
                        to: 1,
                        has_more_pages: false
                    }
                }
            }

            const mockClient = {
                get: vi.fn().mockResolvedValue(mockResponse),
                post: vi.fn(),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)

            // Create new instance to use mocked client
            const testClient = new (apiClient.constructor as any)()

            const params = {
                genres: 'ラーメン,カフェ',
                lat: 35.6762,
                lng: 139.6503,
                radius: 5,
                per_page: 20
            }

            const result = await testClient.getShops(params)

            expect(mockClient.get).toHaveBeenCalledWith('/shops', { params })
            expect(result.data).toHaveLength(1)
            expect(result.data[0].name).toBe('Test Shop')
            expect(result.pagination.total).toBe(1)
        })

        it('should fetch single shop by id', async () => {
            const mockResponse = {
                data: {
                    data: {
                        id: 1,
                        name: 'Test Shop',
                        genre: 'ラーメン' as ShopGenre,
                        has_try_benefit: true,
                        stamp_count: 5,
                        is_approved: true
                    }
                }
            }

            const mockClient = {
                get: vi.fn().mockResolvedValue(mockResponse),
                post: vi.fn(),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.getShop(1)

            expect(mockClient.get).toHaveBeenCalledWith('/shops/1')
            expect(result.data.id).toBe(1)
            expect(result.data.name).toBe('Test Shop')
        })

        it('should search shops with query', async () => {
            const mockResponse = {
                data: {
                    data: [],
                    pagination: {
                        current_page: 1,
                        last_page: 1,
                        per_page: 20,
                        total: 0,
                        from: null,
                        to: null,
                        has_more_pages: false
                    }
                }
            }

            const mockClient = {
                get: vi.fn().mockResolvedValue(mockResponse),
                post: vi.fn(),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const query = 'ramen'
            const params = { per_page: 10 }

            await testClient.searchShops(query, params)

            expect(mockClient.get).toHaveBeenCalledWith('/shops/search', {
                params: { q: query, ...params }
            })
        })
    })

    describe('Favorite API methods', () => {
        it('should toggle favorite status', async () => {
            const mockResponse = {
                data: {
                    favorited: true,
                    message: 'Shop added to favorites'
                }
            }

            const mockClient = {
                get: vi.fn(),
                post: vi.fn().mockResolvedValue(mockResponse),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.toggleFavorite(1)

            expect(mockClient.post).toHaveBeenCalledWith('/favorites/toggle/1')
            expect(result.favorited).toBe(true)
            expect(result.message).toBe('Shop added to favorites')
        })

        it('should check favorite status', async () => {
            const mockResponse = {
                data: {
                    favorited: false
                }
            }

            const mockClient = {
                get: vi.fn().mockResolvedValue(mockResponse),
                post: vi.fn(),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.checkFavorite(1)

            expect(mockClient.get).toHaveBeenCalledWith('/favorites/check/1')
            expect(result.favorited).toBe(false)
        })

        it('should get favorite statistics', async () => {
            const mockResponse = {
                data: {
                    total_favorites: 5,
                    favorites_by_genre: {
                        'ラーメン': 2,
                        'カフェ': 3
                    }
                }
            }

            const mockClient = {
                get: vi.fn().mockResolvedValue(mockResponse),
                post: vi.fn(),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.getFavoriteStats()

            expect(mockClient.get).toHaveBeenCalledWith('/favorites/stats')
            expect(result.total_favorites).toBe(5)
            expect(result.favorites_by_genre['ラーメン']).toBe(2)
        })
    })

    describe('Admin Shop API methods', () => {
        it('should create shop', async () => {
            const shopData = {
                name: 'New Shop',
                genre: 'ラーメン' as ShopGenre,
                has_try_benefit: true,
                stamp_count: 0
            }

            const mockResponse = {
                data: {
                    data: {
                        id: 1,
                        ...shopData,
                        is_approved: true,
                        created_at: '2023-01-01T00:00:00Z',
                        updated_at: '2023-01-01T00:00:00Z'
                    }
                }
            }

            const mockClient = {
                get: vi.fn(),
                post: vi.fn().mockResolvedValue(mockResponse),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.createShop(shopData)

            expect(mockClient.post).toHaveBeenCalledWith('/admin/shops', shopData)
            expect(result.data.name).toBe('New Shop')
            expect(result.data.id).toBe(1)
        })

        it('should update shop', async () => {
            const updateData = {
                name: 'Updated Shop Name',
                stamp_count: 10
            }

            const mockResponse = {
                data: {
                    data: {
                        id: 1,
                        name: 'Updated Shop Name',
                        stamp_count: 10,
                        is_approved: true
                    }
                }
            }

            const mockClient = {
                get: vi.fn(),
                post: vi.fn(),
                put: vi.fn().mockResolvedValue(mockResponse),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.updateShop(1, updateData)

            expect(mockClient.put).toHaveBeenCalledWith('/admin/shops/1', updateData)
            expect(result.data.name).toBe('Updated Shop Name')
            expect(result.data.stamp_count).toBe(10)
        })

        it('should delete shop', async () => {
            const mockResponse = {
                data: {
                    data: null,
                    message: 'Shop deleted successfully'
                }
            }

            const mockClient = {
                get: vi.fn(),
                post: vi.fn(),
                put: vi.fn(),
                delete: vi.fn().mockResolvedValue(mockResponse),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.deleteShop(1)

            expect(mockClient.delete).toHaveBeenCalledWith('/admin/shops/1')
            expect(result.data).toBeNull()
        })
    })

    describe('Shop Proposal API methods', () => {
        it('should approve shop proposal', async () => {
            const mockResponse = {
                data: {
                    data: {
                        id: 1,
                        name: 'Approved Shop',
                        is_approved: true
                    }
                }
            }

            const mockClient = {
                get: vi.fn(),
                post: vi.fn().mockResolvedValue(mockResponse),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const result = await testClient.approveShopProposal(1)

            expect(mockClient.post).toHaveBeenCalledWith('/admin/shop-proposals/1/approve')
            expect(result.data.name).toBe('Approved Shop')
            expect(result.data.is_approved).toBe(true)
        })

        it('should reject shop proposal', async () => {
            const mockResponse = {
                data: {
                    data: null,
                    message: 'Proposal rejected'
                }
            }

            const mockClient = {
                get: vi.fn(),
                post: vi.fn().mockResolvedValue(mockResponse),
                put: vi.fn(),
                delete: vi.fn(),
                interceptors: {
                    request: { use: vi.fn() },
                    response: { use: vi.fn() }
                }
            }

            mockedAxios.create = vi.fn().mockReturnValue(mockClient)
            const testClient = new (apiClient.constructor as any)()

            const notes = 'Insufficient information'
            await testClient.rejectShopProposal(1, notes)

            expect(mockClient.post).toHaveBeenCalledWith('/admin/shop-proposals/1/reject', {
                admin_notes: notes
            })
        })
    })

    describe('Error handling', () => {
        it('should handle API errors gracefully', () => {
            const error = new Error('Network error')

            expect(() => {
                apiClient.handleError(error as any)
            }).toThrow('Network error')
        })

        it('should handle API response errors', () => {
            const error = {
                response: {
                    data: {
                        error: {
                            message: 'Validation failed'
                        }
                    }
                }
            }

            expect(() => {
                apiClient.handleError(error as any)
            }).toThrow('Validation failed')
        })
    })
})