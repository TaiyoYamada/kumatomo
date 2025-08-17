import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import StoreDeleteDialog from '../StoreDeleteDialog.vue'
import type { Store } from '../../types/store'

// Mock the useStoreApi composable
const mockDeleteStore = vi.fn()
vi.mock('../../composables/useStoreApi', () => ({
    useStoreApi: () => ({
        deleteStore: mockDeleteStore
    })
}))

// Create Vuetify instance for testing
const vuetify = createVuetify()

// Mock store data
const mockStore: Store = {
    id: 1,
    name: 'テスト店舗',
    description: 'テスト用の店舗です',
    address: '東京都渋谷区テスト1-1-1',
    phone: '03-1234-5678',
    business_hours: '10:00-22:00',
    genre: 'レストラン',
    latitude: 35.6762,
    longitude: 139.6503,
    image_url: 'https://example.com/image.jpg',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z'
}

describe('StoreDeleteDialog', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('renders correctly when dialog is open with store data', () => {
        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: mockStore
            },
            global: {
                plugins: [vuetify]
            }
        })

        // Check if dialog is rendered
        expect(wrapper.find('.v-dialog').exists()).toBe(true)

        // Check if store name is displayed
        expect(wrapper.text()).toContain('テスト店舗')

        // Check if confirmation message is displayed
        expect(wrapper.text()).toContain('以下の店舗を削除しますか？')

        // Check if warning message is displayed
        expect(wrapper.text()).toContain('この操作は取り消すことができません')
    })

    it('displays store information correctly', () => {
        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: mockStore
            },
            global: {
                plugins: [vuetify]
            }
        })

        // Check store details
        expect(wrapper.text()).toContain(mockStore.name)
        expect(wrapper.text()).toContain(mockStore.address)
        expect(wrapper.text()).toContain(mockStore.genre)
        expect(wrapper.text()).toContain(mockStore.phone)
    })

    it('emits update:modelValue when cancel button is clicked', async () => {
        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: mockStore
            },
            global: {
                plugins: [vuetify]
            }
        })

        // Find and click cancel button
        const cancelButton = wrapper.find('button:contains("キャンセル")')
        await cancelButton.trigger('click')

        // Check if event was emitted
        expect(wrapper.emitted('update:modelValue')).toBeTruthy()
        expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([false])
    })

    it('calls deleteStore and emits store-deleted on successful deletion', async () => {
        mockDeleteStore.mockResolvedValue(true)

        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: mockStore
            },
            global: {
                plugins: [vuetify]
            }
        })

        // Find and click delete button
        const deleteButton = wrapper.find('button:contains("削除する")')
        await deleteButton.trigger('click')

        // Wait for async operations
        await wrapper.vm.$nextTick()

        // Check if deleteStore was called with correct ID
        expect(mockDeleteStore).toHaveBeenCalledWith(mockStore.id)

        // Check if events were emitted
        expect(wrapper.emitted('store-deleted')).toBeTruthy()
        expect(wrapper.emitted('store-deleted')?.[0]).toEqual([mockStore.id])
        expect(wrapper.emitted('update:modelValue')).toBeTruthy()
    })

    it('displays error message on deletion failure', async () => {
        const errorMessage = '削除に失敗しました'
        mockDeleteStore.mockRejectedValue(new Error(errorMessage))

        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: mockStore
            },
            global: {
                plugins: [vuetify]
            }
        })

        // Find and click delete button
        const deleteButton = wrapper.find('button:contains("削除する")')
        await deleteButton.trigger('click')

        // Wait for async operations
        await wrapper.vm.$nextTick()

        // Check if error message is displayed
        expect(wrapper.text()).toContain(errorMessage)

        // Check that dialog is still open (no update:modelValue with false)
        const updateEvents = wrapper.emitted('update:modelValue')
        expect(updateEvents?.some(event => event[0] === false)).toBeFalsy()
    })

    it('shows appropriate message when no store is selected', () => {
        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: null
            },
            global: {
                plugins: [vuetify]
            }
        })

        expect(wrapper.text()).toContain('削除する店舗が選択されていません')
    })

    it('disables delete button when no store is selected', () => {
        const wrapper = mount(StoreDeleteDialog, {
            props: {
                modelValue: true,
                store: null
            },
            global: {
                plugins: [vuetify]
            }
        })

        const deleteButton = wrapper.find('button:contains("削除する")')
        expect(deleteButton.attributes('disabled')).toBeDefined()
    })
})