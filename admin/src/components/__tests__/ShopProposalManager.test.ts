import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createVuetify } from 'vuetify'
import ShopProposalManager from '@/components/ShopProposalManager.vue'
import { ShopGenre, ProposalStatus, type ShopProposal } from '@/types/shop'

// Mock the shop API composable
const mockUseShopApi = {
    proposals: vi.fn(() => []),
    loading: vi.fn(() => false),
    error: vi.fn(() => ''),
    fetchProposals: vi.fn(),
    approveProposal: vi.fn(),
    rejectProposal: vi.fn()
}

vi.mock('@/composables/useShopApi', () => ({
    useShopApi: () => mockUseShopApi
}))

// Create Vuetify instance
const vuetify = createVuetify()

describe('ShopProposalManager', () => {
    let wrapper: any

    const mockProposals: ShopProposal[] = [
        {
            id: 1,
            user_id: 1,
            name: 'テストカフェ',
            address: '東京都渋谷区',
            genre: ShopGenre.CAFE,
            description: '素敵なカフェです',
            status: ProposalStatus.PENDING,
            admin_notes: null,
            created_at: '2024-01-01T00:00:00Z',
            updated_at: '2024-01-01T00:00:00Z',
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
            name: 'ラーメン店',
            address: '東京都新宿区',
            genre: ShopGenre.RAMEN,
            description: '美味しいラーメン店',
            status: ProposalStatus.APPROVED,
            admin_notes: '承認しました',
            created_at: '2024-01-02T00:00:00Z',
            updated_at: '2024-01-02T00:00:00Z',
            user: {
                id: 2,
                name: 'ユーザー2',
                username: 'user2',
                email: 'user2@example.com'
            }
        },
        {
            id: 3,
            user_id: 3,
            name: '却下された店',
            address: '東京都品川区',
            genre: ShopGenre.RESTAURANT,
            description: '却下された店舗',
            status: ProposalStatus.REJECTED,
            admin_notes: '情報が不十分です',
            created_at: '2024-01-03T00:00:00Z',
            updated_at: '2024-01-03T00:00:00Z',
            user: {
                id: 3,
                name: 'ユーザー3',
                username: 'user3',
                email: 'user3@example.com'
            }
        }
    ]

    beforeEach(() => {
        vi.clearAllMocks()
        mockUseShopApi.proposals.mockReturnValue(mockProposals)
        mockUseShopApi.loading.mockReturnValue(false)
        mockUseShopApi.error.mockReturnValue('')
    })

    const createWrapper = () => {
        return mount(ShopProposalManager, {
            global: {
                plugins: [vuetify]
            }
        })
    }

    describe('Component Rendering', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should render component title and proposal count', () => {
            expect(wrapper.text()).toContain('店舗提案管理')
            expect(wrapper.text()).toContain('3件の提案')
        })

        it('should render filter options', () => {
            expect(wrapper.text()).toContain('ステータス')
            expect(wrapper.text()).toContain('ジャンル')
            expect(wrapper.text()).toContain('店舗名で検索')
        })

        it('should render proposals table', () => {
            expect(wrapper.text()).toContain('テストカフェ')
            expect(wrapper.text()).toContain('ラーメン店')
            expect(wrapper.text()).toContain('却下された店')
        })

        it('should display proposal status chips with correct colors', () => {
            const statusChips = wrapper.findAll('.v-chip')

            // Find status chips (excluding genre chips)
            const pendingChip = statusChips.find((chip: any) => chip.text() === '承認待ち')
            const approvedChip = statusChips.find((chip: any) => chip.text() === '承認済み')
            const rejectedChip = statusChips.find((chip: any) => chip.text() === '却下')

            expect(pendingChip).toBeTruthy()
            expect(approvedChip).toBeTruthy()
            expect(rejectedChip).toBeTruthy()
        })
    })

    describe('Filtering', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should filter by status', async () => {
            const statusFilter = wrapper.find('[data-testid="status-filter"]')

            // Filter by pending status
            await statusFilter.setValue(ProposalStatus.PENDING)
            await wrapper.vm.$nextTick()

            const filteredProposals = wrapper.vm.filteredProposals
            expect(filteredProposals).toHaveLength(1)
            expect(filteredProposals[0].name).toBe('テストカフェ')
        })

        it('should filter by genre', async () => {
            const genreFilter = wrapper.find('[data-testid="genre-filter"]')

            // Filter by cafe genre
            await genreFilter.setValue(ShopGenre.CAFE)
            await wrapper.vm.$nextTick()

            const filteredProposals = wrapper.vm.filteredProposals
            expect(filteredProposals).toHaveLength(1)
            expect(filteredProposals[0].genre).toBe(ShopGenre.CAFE)
        })

        it('should filter by search query', async () => {
            const searchField = wrapper.find('[data-testid="search-query"]')

            // Search for "ラーメン"
            await searchField.setValue('ラーメン')
            await wrapper.vm.$nextTick()

            const filteredProposals = wrapper.vm.filteredProposals
            expect(filteredProposals).toHaveLength(1)
            expect(filteredProposals[0].name).toBe('ラーメン店')
        })

        it('should combine multiple filters', async () => {
            const statusFilter = wrapper.find('[data-testid="status-filter"]')
            const genreFilter = wrapper.find('[data-testid="genre-filter"]')

            // Filter by pending status and cafe genre
            await statusFilter.setValue(ProposalStatus.PENDING)
            await genreFilter.setValue(ShopGenre.CAFE)
            await wrapper.vm.$nextTick()

            const filteredProposals = wrapper.vm.filteredProposals
            expect(filteredProposals).toHaveLength(1)
            expect(filteredProposals[0].name).toBe('テストカフェ')
        })
    })

    describe('Proposal Actions', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should show approve and reject buttons for pending proposals', () => {
            const actionButtons = wrapper.findAll('.v-btn')

            const approveButton = actionButtons.find((btn: any) => btn.text().includes('承認'))
            const rejectButton = actionButtons.find((btn: any) => btn.text().includes('却下'))

            expect(approveButton).toBeTruthy()
            expect(rejectButton).toBeTruthy()
        })

        it('should open approval dialog when approve button is clicked', async () => {
            const approveButton = wrapper.find('[data-testid="approve-button-1"]')

            await approveButton.trigger('click')
            await wrapper.vm.$nextTick()

            expect(wrapper.vm.showApprovalDialog).toBe(true)
            expect(wrapper.vm.selectedProposal?.id).toBe(1)
        })

        it('should open rejection dialog when reject button is clicked', async () => {
            const rejectButton = wrapper.find('[data-testid="reject-button-1"]')

            await rejectButton.trigger('click')
            await wrapper.vm.$nextTick()

            expect(wrapper.vm.showRejectionDialog).toBe(true)
            expect(wrapper.vm.selectedProposal?.id).toBe(1)
        })

        it('should open detail dialog when view button is clicked', async () => {
            const viewButton = wrapper.find('[data-testid="view-button-1"]')

            await viewButton.trigger('click')
            await wrapper.vm.$nextTick()

            expect(wrapper.vm.showDetailDialog).toBe(true)
            expect(wrapper.vm.selectedProposal?.id).toBe(1)
        })
    })

    describe('Approval Process', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should approve proposal with admin notes', async () => {
            mockUseShopApi.approveProposal.mockResolvedValue({ id: 1, name: 'テストカフェ' })

            // Open approval dialog
            await wrapper.vm.openApprovalDialog(mockProposals[0])

            // Add admin notes
            const adminNotesField = wrapper.find('[data-testid="admin-notes"]')
            await adminNotesField.setValue('承認理由: 良い提案です')

            // Click approve button
            const approveButton = wrapper.find('[data-testid="confirm-approve"]')
            await approveButton.trigger('click')

            expect(mockUseShopApi.approveProposal).toHaveBeenCalledWith(1)
            expect(mockUseShopApi.fetchProposals).toHaveBeenCalled()
        })

        it('should handle approval errors', async () => {
            const errorMessage = '承認に失敗しました'
            mockUseShopApi.approveProposal.mockRejectedValue(new Error(errorMessage))

            // Open approval dialog and approve
            await wrapper.vm.openApprovalDialog(mockProposals[0])
            await wrapper.vm.approveProposal()

            expect(wrapper.vm.error).toBe(errorMessage)
        })
    })

    describe('Rejection Process', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should reject proposal with required admin notes', async () => {
            mockUseShopApi.rejectProposal.mockResolvedValue(true)

            // Open rejection dialog
            await wrapper.vm.openRejectionDialog(mockProposals[0])

            // Add required admin notes
            wrapper.vm.adminNotes = '却下理由: 情報が不十分です'

            // Reject proposal
            await wrapper.vm.rejectProposal()

            expect(mockUseShopApi.rejectProposal).toHaveBeenCalledWith(1, '却下理由: 情報が不十分です')
            expect(mockUseShopApi.fetchProposals).toHaveBeenCalled()
        })

        it('should require admin notes for rejection', () => {
            wrapper.vm.openRejectionDialog(mockProposals[0])

            // Try to reject without notes
            const rejectButton = wrapper.find('[data-testid="confirm-reject"]')
            expect(rejectButton.attributes('disabled')).toBeDefined()
        })

        it('should validate admin notes length', () => {
            const longNotes = 'a'.repeat(501)

            const rules = wrapper.vm.rejectionNotesRules
            const lengthRule = rules[1]

            expect(lengthRule(longNotes)).toBe('却下理由は500文字以内で入力してください')
        })
    })

    describe('TypeScript Type Safety', () => {
        it('should enforce ProposalStatus enum', () => {
            const validStatuses = Object.values(ProposalStatus)

            expect(validStatuses).toContain(ProposalStatus.PENDING)
            expect(validStatuses).toContain(ProposalStatus.APPROVED)
            expect(validStatuses).toContain(ProposalStatus.REJECTED)
            expect(validStatuses).toHaveLength(3)
        })

        it('should enforce ShopProposal interface', () => {
            const proposal: ShopProposal = mockProposals[0]

            expect(typeof proposal.id).toBe('number')
            expect(typeof proposal.name).toBe('string')
            expect(typeof proposal.status).toBe('string')
            expect(proposal.status).toBe(ProposalStatus.PENDING)
            expect(proposal.genre).toBe(ShopGenre.CAFE)
        })
    })

    describe('Helper Functions', () => {
        beforeEach(() => {
            wrapper = createWrapper()
        })

        it('should get correct status color', () => {
            expect(wrapper.vm.getStatusColor(ProposalStatus.PENDING)).toBe('warning')
            expect(wrapper.vm.getStatusColor(ProposalStatus.APPROVED)).toBe('success')
            expect(wrapper.vm.getStatusColor(ProposalStatus.REJECTED)).toBe('error')
        })

        it('should get correct status text', () => {
            expect(wrapper.vm.getStatusText(ProposalStatus.PENDING)).toBe('承認待ち')
            expect(wrapper.vm.getStatusText(ProposalStatus.APPROVED)).toBe('承認済み')
            expect(wrapper.vm.getStatusText(ProposalStatus.REJECTED)).toBe('却下')
        })

        it('should truncate long text', () => {
            const longText = 'This is a very long text that should be truncated'
            const truncated = wrapper.vm.truncateText(longText, 20)

            expect(truncated).toBe('This is a very long ...')
            expect(truncated.length).toBeLessThanOrEqual(23) // 20 + '...'
        })

        it('should format date correctly', () => {
            const dateString = '2024-01-01T00:00:00Z'
            const formatted = wrapper.vm.formatDate(dateString)

            expect(formatted).toMatch(/\d{4}\/\d{1,2}\/\d{1,2}/)
        })
    })

    describe('Loading and Error States', () => {
        it('should show loading state', () => {
            mockUseShopApi.loading.mockReturnValue(true)
            wrapper = createWrapper()

            expect(wrapper.text()).toContain('読み込み中')
        })

        it('should show error state', () => {
            const errorMessage = 'データの取得に失敗しました'
            mockUseShopApi.error.mockReturnValue(errorMessage)
            wrapper = createWrapper()

            expect(wrapper.text()).toContain(errorMessage)
        })

        it('should clear error when close button is clicked', async () => {
            mockUseShopApi.error.mockReturnValue('エラーメッセージ')
            wrapper = createWrapper()

            const closeButton = wrapper.find('[data-testid="error-close"]')
            await closeButton.trigger('click')

            expect(wrapper.vm.error).toBe('')
        })
    })
})