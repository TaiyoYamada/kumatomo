import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import { createRouter, createWebHistory } from 'vue-router'
import ShopForm from '@/pages/ShopForm.vue'
import { ShopGenre } from '@/types/shop'
import type { ShopFormData } from '@/types/api'

// Mock the shop service
const mockShopService = {
    getShop: vi.fn(),
    createShop: vi.fn(),
    updateShop: vi.fn()
}

vi.mock('@/services/shopService', () => ({
    shopService: mockShopService
}))

// Create test router
const router = createRouter({
    history: createWebHistory(),
    routes: [
        { path: '/', component: { template: '<div>Home</div>' } },
        { path: '/shops', component: { template: '<div>Shop List</div>' } },
        { path: '/shops/create', component: ShopForm },
        { path: '/shops/:id/edit', component: ShopForm, props: true }
    ]
})

// Create Vuetify instance
const vuetify = createVuetify()

describe('ShopForm', () => {
    let wrapper: any

    beforeEach(() => {
        vi.clearAllMocks()
    })

    const createWrapper = (props = {}) => {
        return mount(ShopForm, {
            props,
            global: {
                plugins: [vuetify, router]
            }
        })
    }

    describe('Form Validation', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should validate required shop name', async () => {
            const nameField = wrapper.find('[data-testid="shop-name"]')

            // Test empty name
            await nameField.setValue('')
            await nameField.trigger('blur')

            expect(wrapper.text()).toContain('お店名は必須です')
        })

        it('should validate shop name length', async () => {
            const nameField = wrapper.find('[data-testid="shop-name"]')

            // Test name too short
            await nameField.setValue('a')
            await nameField.trigger('blur')

            expect(wrapper.text()).toContain('お店名は2文字以上で入力してください')

            // Test name too long
            const longName = 'a'.repeat(101)
            await nameField.setValue(longName)
            await nameField.trigger('blur')

            expect(wrapper.text()).toContain('お店名は100文字以内で入力してください')
        })

        it('should validate genre selection', async () => {
            const genreField = wrapper.find('[data-testid="shop-genre"]')

            // Test empty genre
            await genreField.setValue('')
            await genreField.trigger('blur')

            expect(wrapper.text()).toContain('ジャンルは必須です')
        })

        it('should validate description length', async () => {
            const descriptionField = wrapper.find('[data-testid="shop-description"]')

            // Test description too long
            const longDescription = 'a'.repeat(1001)
            await descriptionField.setValue(longDescription)
            await descriptionField.trigger('blur')

            expect(wrapper.text()).toContain('説明は1000文字以内で入力してください')
        })

        it('should validate address length', async () => {
            const addressField = wrapper.find('[data-testid="shop-address"]')

            // Test address too long
            const longAddress = 'a'.repeat(256)
            await addressField.setValue(longAddress)
            await addressField.trigger('blur')

            expect(wrapper.text()).toContain('住所は255文字以内で入力してください')
        })

        it('should validate phone number format', async () => {
            const phoneField = wrapper.find('[data-testid="shop-phone"]')

            // Test invalid phone format
            await phoneField.setValue('invalid-phone')
            await phoneField.trigger('blur')

            expect(wrapper.text()).toContain('正しい電話番号形式で入力してください')

            // Test phone too long
            const longPhone = '1'.repeat(21)
            await phoneField.setValue(longPhone)
            await phoneField.trigger('blur')

            expect(wrapper.text()).toContain('電話番号は20文字以内で入力してください')
        })

        it('should validate latitude range', async () => {
            const latitudeField = wrapper.find('[data-testid="shop-latitude"]')

            // Test latitude out of range
            await latitudeField.setValue(-91)
            await latitudeField.trigger('blur')

            expect(wrapper.text()).toContain('緯度は-90から90の間で入力してください')

            await latitudeField.setValue(91)
            await latitudeField.trigger('blur')

            expect(wrapper.text()).toContain('緯度は-90から90の間で入力してください')
        })

        it('should validate longitude range', async () => {
            const longitudeField = wrapper.find('[data-testid="shop-longitude"]')

            // Test longitude out of range
            await longitudeField.setValue(-181)
            await longitudeField.trigger('blur')

            expect(wrapper.text()).toContain('経度は-180から180の間で入力してください')

            await longitudeField.setValue(181)
            await longitudeField.trigger('blur')

            expect(wrapper.text()).toContain('経度は-180から180の間で入力してください')
        })

        it('should validate stamp count', async () => {
            const stampCountField = wrapper.find('[data-testid="shop-stamp-count"]')

            // Test negative stamp count
            await stampCountField.setValue(-1)
            await stampCountField.trigger('blur')

            expect(wrapper.text()).toContain('スタンプ数は0以上で入力してください')

            // Test non-integer stamp count
            await stampCountField.setValue(1.5)
            await stampCountField.trigger('blur')

            expect(wrapper.text()).toContain('スタンプ数は整数で入力してください')
        })

        it('should validate image URL format', async () => {
            const imageUrlField = wrapper.find('[data-testid="shop-image-url"]')

            // Test invalid URL
            await imageUrlField.setValue('invalid-url')
            await imageUrlField.trigger('blur')

            expect(wrapper.text()).toContain('正しいURL形式で入力してください')
        })
    })

    describe('Form Submission', () => {
        it('should create new shop with valid data', async () => {
            wrapper = createWrapper()

            const mockShop = {
                id: 1,
                name: 'テストカフェ',
                genre: ShopGenre.CAFE,
                has_try_benefit: true,
                stamp_count: 5,
                is_approved: true
            }

            mockShopService.createShop.mockResolvedValue({ data: mockShop })

            // Fill form with valid data
            await wrapper.find('[data-testid="shop-name"]').setValue('テストカフェ')
            await wrapper.find('[data-testid="shop-genre"]').setValue(ShopGenre.CAFE)
            await wrapper.find('[data-testid="shop-description"]').setValue('素敵なカフェです')
            await wrapper.find('[data-testid="shop-address"]').setValue('東京都渋谷区')
            await wrapper.find('[data-testid="shop-phone"]').setValue('03-1234-5678')
            await wrapper.find('[data-testid="shop-business-hours"]').setValue('9:00-18:00')
            await wrapper.find('[data-testid="shop-latitude"]').setValue(35.6762)
            await wrapper.find('[data-testid="shop-longitude"]').setValue(139.6503)
            await wrapper.find('[data-testid="shop-has-try-benefit"]').setValue(true)
            await wrapper.find('[data-testid="shop-stamp-count"]').setValue(5)
            await wrapper.find('[data-testid="shop-image-url"]').setValue('https://example.com/image.jpg')

            // Submit form
            await wrapper.find('form').trigger('submit.prevent')

            expect(mockShopService.createShop).toHaveBeenCalledWith({
                name: 'テストカフェ',
                genre: ShopGenre.CAFE,
                description: '素敵なカフェです',
                address: '東京都渋谷区',
                phone: '03-1234-5678',
                business_hours: '9:00-18:00',
                latitude: 35.6762,
                longitude: 139.6503,
                has_try_benefit: true,
                stamp_count: 5,
                image_url: 'https://example.com/image.jpg'
            })
        })

        it('should update existing shop with valid data', async () => {
            const shopId = '1'
            wrapper = createWrapper({ id: shopId })

            const existingShop = {
                id: 1,
                name: '既存カフェ',
                genre: ShopGenre.CAFE,
                description: '既存の説明',
                has_try_benefit: false,
                stamp_count: 3,
                is_approved: true
            }

            const updatedShop = {
                ...existingShop,
                name: '更新されたカフェ',
                has_try_benefit: true,
                stamp_count: 10
            }

            mockShopService.getShop.mockResolvedValue({ data: existingShop })
            mockShopService.updateShop.mockResolvedValue({ data: updatedShop })

            await wrapper.vm.$nextTick()

            // Update form data
            await wrapper.find('[data-testid="shop-name"]').setValue('更新されたカフェ')
            await wrapper.find('[data-testid="shop-has-try-benefit"]').setValue(true)
            await wrapper.find('[data-testid="shop-stamp-count"]').setValue(10)

            // Submit form
            await wrapper.find('form').trigger('submit.prevent')

            expect(mockShopService.updateShop).toHaveBeenCalledWith(1, expect.objectContaining({
                name: '更新されたカフェ',
                has_try_benefit: true,
                stamp_count: 10
            }))
        })

        it('should handle validation errors from server', async () => {
            wrapper = createWrapper()

            const validationError = {
                response: {
                    status: 422,
                    data: {
                        errors: {
                            name: ['店舗名は既に使用されています'],
                            genre: ['無効なジャンルです']
                        }
                    }
                }
            }

            mockShopService.createShop.mockRejectedValue(validationError)

            // Fill form and submit
            await wrapper.find('[data-testid="shop-name"]').setValue('重複カフェ')
            await wrapper.find('[data-testid="shop-genre"]').setValue('invalid-genre')
            await wrapper.find('form').trigger('submit.prevent')

            await wrapper.vm.$nextTick()

            expect(wrapper.text()).toContain('店舗名は既に使用されています')
            expect(wrapper.text()).toContain('無効なジャンルです')
        })

        it('should handle network errors', async () => {
            wrapper = createWrapper()

            const networkError = new Error('ネットワークエラー')
            mockShopService.createShop.mockRejectedValue(networkError)

            // Fill form and submit
            await wrapper.find('[data-testid="shop-name"]').setValue('テストカフェ')
            await wrapper.find('[data-testid="shop-genre"]').setValue(ShopGenre.CAFE)
            await wrapper.find('form').trigger('submit.prevent')

            await wrapper.vm.$nextTick()

            expect(wrapper.text()).toContain('お店の登録に失敗しました')
        })
    })

    describe('TypeScript Type Safety', () => {
        it('should enforce ShopFormData interface', () => {
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

            expect(validFormData.name).toBe('テストカフェ')
            expect(validFormData.genre).toBe(ShopGenre.CAFE)
            expect(validFormData.has_try_benefit).toBe(true)
            expect(validFormData.stamp_count).toBe(5)
        })

        it('should enforce ShopGenre enum values', () => {
            const validGenres = Object.values(ShopGenre)

            expect(validGenres).toContain(ShopGenre.CAFE)
            expect(validGenres).toContain(ShopGenre.RESTAURANT)
            expect(validGenres).toContain(ShopGenre.RAMEN)
            expect(validGenres).toContain(ShopGenre.IZAKAYA)
            expect(validGenres).toContain(ShopGenre.YAKINIKU)

            // Should have exactly 20 genres
            expect(validGenres).toHaveLength(20)
        })
    })

    describe('Genre Selection', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should display all 20 genre options', async () => {
            const genreSelect = wrapper.find('[data-testid="shop-genre"]')

            // Open dropdown
            await genreSelect.trigger('click')
            await wrapper.vm.$nextTick()

            const genreOptions = Object.values(ShopGenre)

            genreOptions.forEach(genre => {
                expect(wrapper.text()).toContain(genre)
            })
        })

        it('should allow genre selection and clearing', async () => {
            const genreSelect = wrapper.find('[data-testid="shop-genre"]')

            // Select a genre
            await genreSelect.setValue(ShopGenre.CAFE)
            expect(wrapper.vm.form.genre).toBe(ShopGenre.CAFE)

            // Clear selection
            await genreSelect.setValue('')
            expect(wrapper.vm.form.genre).toBeUndefined()
        })
    })

    describe('Try特典 and Stamp Count Features', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should toggle Try特典 switch', async () => {
            const tryBenefitSwitch = wrapper.find('[data-testid="shop-has-try-benefit"]')

            // Initially false
            expect(wrapper.vm.form.has_try_benefit).toBe(false)

            // Toggle to true
            await tryBenefitSwitch.setValue(true)
            expect(wrapper.vm.form.has_try_benefit).toBe(true)

            // Toggle back to false
            await tryBenefitSwitch.setValue(false)
            expect(wrapper.vm.form.has_try_benefit).toBe(false)
        })

        it('should handle stamp count input', async () => {
            const stampCountField = wrapper.find('[data-testid="shop-stamp-count"]')

            // Set stamp count
            await stampCountField.setValue(10)
            expect(wrapper.vm.form.stamp_count).toBe(10)

            // Set to zero
            await stampCountField.setValue(0)
            expect(wrapper.vm.form.stamp_count).toBe(0)
        })
    })
})