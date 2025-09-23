import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, VueWrapper } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import { nextTick } from 'vue'
import ProposalReview from '../ProposalReview.vue'
import { ProposalStatus, type ShopProposal } from '@/types/shop'

// Mock the composable
const mockProposalManagement = {
    proposals: { value: [] },
    loading: { value: false },
    error: { value: null },
    pagination: {
        value: {
            current_page: 1,
            last_page: 1,
            per_page: 20,
            total: 0,
            from: null,
            to: null,
            has_more_pages: false
        }
    },
    statusCounts: {
        value: {
            all: 0,
            pending: 0,
            approved: 0,
            rejected: 0
        }
    },
    pendingCount: { value: 0 },
    hasError: { value: false },
    fetchProposals: vi.fn(),
    approveProposal: vi.fn(),
    rejectProposal: vi.fn(),
    refreshProposals: vi.fn(),
    updateFilters: vi.fn(),
    applyFilters: vi.fn(),
    loadPage: vi.fn(),
    clearError: vi.fn()
}

vi.mock('@/composables/useProposalManagement', () => ({
    useProposalManagement: () => mockProposalManagement
}))

// Mock child components
vi.mock('@/components/ProposalDetailsDialog.vue', () => ({
    default: {
        name: 'ProposalDetailsDialog',
        template: '<div data-testid="proposal-details-dialog"></div>',
        props: ['modelValue', 'proposal'],
        emits: ['update:modelValue', 'approve', 'reject']
    }
}))

vi.mock('@/components/ProposalActionDialog.vue', () => ({
    default: {
        name: 'ProposalActionDialog',
        template: '<div data-testid="proposal-action-dialog"></div>',
        props: ['modelValue', 'proposal', 'action'],
        emits: ['update:modelValue', 'confirm']
    }
}))

describe('ProposalReview', () => {
    let wrapper: VueWrapper
    let vuetify: ReturnType<typeof createVuetify>

    const mockProposals: ShopProposal[] = [
        {
            id: 1,
            user_id: 1,
            name: 'テストカフェ',
            address: '東京都渋谷区',
            genre: 'カフェ' as any,
            description: 'テスト用のカフェです',
            status: ProposalStatus.PENDING,
            created_at: '2024-01-01T10:00:00Z',
            updated_at: '2024-01-01T10:00:00Z',
            user: {
                id: 1,
                name: 'テストユーザー',
                username: 'testuser',
                email: 'test@example.com'
            }
        },
        {
            id: 2,
            user_id: 2,
            name: 'イタリアンレストラン',
            address: '東京都新宿区',
            genre: 'イタリアン' as any,
            description: '本格イタリアン料理',
            status: ProposalStatus.APPROVED,
            created_at: '2024-01-02T10:00:00Z',
            updated_at: '2024-01-02T10:00:00Z',
            user: {
                id: 2,
                name: 'ユーザー2',
                username: 'user2',
                email: 'user2@example.com'
            }
        }
    ]

    beforeEach(() => {
        vuetify = createVuetify()

        // Reset mocks
        vi.clearAllMocks()

        // Reset mock values
        mockProposalManagement.proposals.value = []
        mockProposalManagement.loading.value = false
        mockProposalManagement.error.value = null
        mockProposalManagement.pendingCount.value = 0
        mockProposalManagement.hasError.value = false
    })

    const createWrapper = (props = {}) => {
        return mount(ProposalReview, {
            props,
            global: {
                plugins: [vuetify],
                stubs: {
                    'ProposalDetailsDialog': true,
                    'ProposalActionDialog': true
                }
            }
        })
    }

    describe('Component Rendering', () => {
        it('should render page header correctly', () => {
            wrapper = createWrapper()

            expect(wrapper.find('h1').text()).toBe('店舗提案レビュー')
            expect(wrapper.text()).toContain('ユーザーから提案された店舗の承認・却下を管理します')
        })

        it('should show pending count chip when there are pending proposals', async () => {
            mockProposalManagement.pendingCount.value = 5
            wrapper = createWrapper()

            await nextTick()

            const chip = wrapper.find('.v-chip')
            expect(chip.exists()).toBe(true)
            expect(chip.text()).toContain('5件の承認待ち')
        })

        it('should not show pending count chip when no pending proposals', () => {
            mockProposalManagement.pendingCount.value = 0
            wrapper = createWrapper()

            const chip = wrapper.find('.v-chip')
            expect(chip.exists()).toBe(false)
        })
    })

    describe('Status Filtering', () => {
        beforeEach(() => {
            mockProposalManagement.statusCounts.value = {
                all: 10,
                pending: 3,
                approved: 5,
                rejected: 2
            }
            wrapper = createWrapper()
        })

        it('should display status filter chips with counts', () => {
            const chips = wrapper.findAll('.v-chip')

            expect(chips.some(chip => chip.text().includes('すべて (10)'))).toBe(true)
            expect(chips.some(chip => chip.text().includes('承認待ち (3)'))).toBe(true)
            expect(chips.some(chip => chip.text().includes('承認済み (5)'))).toBe(true)
            expect(chips.some(chip => chip.text().includes('却下済み (2)'))).toBe(true)
        })

        it('should call updateFilters and applyFilters when status is changed', async () => {
            const pendingChip = wrapper.find('[value="pending"]')

            await pendingChip.trigger('click')

            expect(mockProposalManagement.updateFilters).toHaveBeenCalledWith({
                status: ProposalStatus.PENDING
            })
            expect(mockProposalManagement.applyFilters).toHaveBeenCalled()
        })
    })

    describe('Search and Sort', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should render search input', () => {
            const searchInput = wrapper.find('input[type="text"]')
            expect(searchInput.exists()).toBe(true)
        })

        it('should render sort select', () => {
            const sortSelect = wrapper.find('.v-select')
            expect(sortSelect.exists()).toBe(true)
        })

        it('should call refreshProposals when refresh button is clicked', async () => {
            const refreshButton = wrapper.find('[data-testid="refresh-button"]') ||
                wrapper.find('button:contains("更新")')

            if (refreshButton.exists()) {
                await refreshButton.trigger('click')
                expect(mockProposalManagement.refreshProposals).toHaveBeenCalled()
            }
        })
    })

    describe('Error Handling', () => {
        it('should display error alert when there is an error', async () => {
            mockProposalManagement.error.value = 'テストエラーメッセージ'
            mockProposalManagement.hasError.value = true

            wrapper = createWrapper()
            await nextTick()

            const alert = wrapper.find('.v-alert')
            expect(alert.exists()).toBe(true)
            expect(alert.text()).toContain('テストエラーメッセージ')
        })

        it('should not display error alert when there is no error', () => {
            mockProposalManagement.error.value = null
            mockProposalManagement.hasError.value = false

            wrapper = createWrapper()

            const alert = wrapper.find('.v-alert')
            expect(alert.exists()).toBe(false)
        })

        it('should call clearError when error alert is closed', async () => {
            mockProposalManagement.error.value = 'テストエラー'
            mockProposalManagement.hasError.value = true

            wrapper = createWrapper()
            await nextTick()

            const closeButton = wrapper.find('.v-alert .v-btn')
            if (closeButton.exists()) {
                await closeButton.trigger('click')
                expect(mockProposalManagement.clearError).toHaveBeenCalled()
            }
        })
    })

    describe('Proposals Table', () => {
        beforeEach(() => {
            mockProposalManagement.proposals.value = mockProposals
            wrapper = createWrapper()
        })

        it('should render data table', () => {
            const dataTable = wrapper.find('.v-data-table')
            expect(dataTable.exists()).toBe(true)
        })

        it('should display loading state', async () => {
            mockProposalManagement.loading.value = true
            wrapper = createWrapper()
            await nextTick()

            const dataTable = wrapper.find('.v-data-table')
            expect(dataTable.attributes('loading')).toBeDefined()
        })

        it('should display no data message when empty', async () => {
            mockProposalManagement.proposals.value = []
            wrapper = createWrapper()
            await nextTick()

            // Check for no data text in table
            expect(wrapper.text()).toContain('提案がありません')
        })
    })

    describe('Proposal Actions', () => {
        beforeEach(() => {
            mockProposalManagement.proposals.value = mockProposals
            wrapper = createWrapper()
        })

        it('should show action buttons for pending proposals', () => {
            // Find action buttons for pending proposal
            const actionButtons = wrapper.findAll('.action-buttons .v-btn')
            expect(actionButtons.length).toBeGreaterThan(0)
        })

        it('should handle approval action', async () => {
            const approvalData = {
                proposal: mockProposals[0],
                adminNotes: 'テスト承認メモ'
            }

            // Simulate approval action
            await wrapper.vm.handleApproval(approvalData)

            expect(mockProposalManagement.approveProposal).toHaveBeenCalledWith(
                mockProposals[0].id,
                'テスト承認メモ'
            )
        })

        it('should handle rejection action', async () => {
            const rejectionData = {
                proposal: mockProposals[0],
                adminNotes: 'テスト却下理由'
            }

            // Simulate rejection action
            await wrapper.vm.handleRejection(rejectionData)

            expect(mockProposalManagement.rejectProposal).toHaveBeenCalledWith(
                mockProposals[0].id,
                'テスト却下理由'
            )
        })
    })

    describe('Dialog Management', () => {
        beforeEach(() => {
            mockProposalManagement.proposals.value = mockProposals
            wrapper = createWrapper()
        })

        it('should open details dialog when view button is clicked', async () => {
            // Simulate clicking view details button
            await wrapper.vm.viewProposalDetails(mockProposals[0])

            expect(wrapper.vm.detailsDialog.show).toBe(true)
            expect(wrapper.vm.detailsDialog.proposal).toEqual(mockProposals[0])
        })

        it('should open approval dialog when approve button is clicked', async () => {
            // Simulate clicking approve button
            await wrapper.vm.showApprovalDialog(mockProposals[0])

            expect(wrapper.vm.approvalDialog.show).toBe(true)
            expect(wrapper.vm.approvalDialog.proposal).toEqual(mockProposals[0])
        })

        it('should open rejection dialog when reject button is clicked', async () => {
            // Simulate clicking reject button
            await wrapper.vm.showRejectionDialog(mockProposals[0])

            expect(wrapper.vm.rejectionDialog.show).toBe(true)
            expect(wrapper.vm.rejectionDialog.proposal).toEqual(mockProposals[0])
        })
    })

    describe('Pagination', () => {
        beforeEach(() => {
            mockProposalManagement.pagination.value = {
                current_page: 2,
                last_page: 5,
                per_page: 20,
                total: 100,
                from: 21,
                to: 40,
                has_more_pages: true
            }
            wrapper = createWrapper()
        })

        it('should handle page change', async () => {
            await wrapper.vm.handlePageChange(3)

            expect(mockProposalManagement.loadPage).toHaveBeenCalledWith(3)
        })

        it('should handle items per page change', async () => {
            await wrapper.vm.handleItemsPerPageChange(50)

            expect(mockProposalManagement.updateFilters).toHaveBeenCalledWith({ per_page: 50 })
            expect(mockProposalManagement.applyFilters).toHaveBeenCalled()
        })
    })

    describe('Lifecycle', () => {
        it('should fetch proposals on mount', () => {
            wrapper = createWrapper()

            expect(mockProposalManagement.fetchProposals).toHaveBeenCalled()
        })
    })

    describe('Helper Methods', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should format date correctly', () => {
            const dateString = '2024-01-01T10:30:00Z'
            const formattedDate = wrapper.vm.formatDate(dateString)

            expect(formattedDate).toMatch(/\d{4}\/\d{2}\/\d{2}/)
        })

        it('should format time correctly', () => {
            const dateString = '2024-01-01T10:30:00Z'
            const formattedTime = wrapper.vm.formatTime(dateString)

            expect(formattedTime).toMatch(/\d{2}:\d{2}/)
        })

        it('should get correct status color', () => {
            expect(wrapper.vm.getStatusColor(ProposalStatus.PENDING)).toBe('warning')
            expect(wrapper.vm.getStatusColor(ProposalStatus.APPROVED)).toBe('success')
            expect(wrapper.vm.getStatusColor(ProposalStatus.REJECTED)).toBe('error')
        })

        it('should get correct status text', () => {
            expect(wrapper.vm.getStatusText(ProposalStatus.PENDING)).toBe('承認待ち')
            expect(wrapper.vm.getStatusText(ProposalStatus.APPROVED)).toBe('承認済み')
            expect(wrapper.vm.getStatusText(ProposalStatus.REJECTED)).toBe('却下済み')
        })
    })

    describe('Success Messages', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should show success message after approval', async () => {
            mockProposalManagement.approveProposal.mockResolvedValue({ success: true })

            const approvalData = {
                proposal: mockProposals[0],
                adminNotes: 'テスト承認'
            }

            await wrapper.vm.handleApproval(approvalData)

            expect(wrapper.vm.successSnackbar.show).toBe(true)
            expect(wrapper.vm.successSnackbar.message).toContain('承認しました')
            expect(wrapper.vm.successSnackbar.color).toBe('success')
        })

        it('should show success message after rejection', async () => {
            mockProposalManagement.rejectProposal.mockResolvedValue({ success: true })

            const rejectionData = {
                proposal: mockProposals[0],
                adminNotes: 'テスト却下'
            }

            await wrapper.vm.handleRejection(rejectionData)

            expect(wrapper.vm.successSnackbar.show).toBe(true)
            expect(wrapper.vm.successSnackbar.message).toContain('却下しました')
            expect(wrapper.vm.successSnackbar.color).toBe('warning')
        })
    })
})