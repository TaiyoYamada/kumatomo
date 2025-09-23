import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { nextTick } from 'vue'
import { useProposalManagement } from '../useProposalManagement'
import { apiClient } from '@/services/apiClient'
import { ProposalStatus, type ShopProposal, type Shop } from '@/types/shop'
import type { PaginatedResponse, ApiResponse } from '@/types/api'

// Mock the API client
vi.mock('@/services/apiClient', () => ({
    apiClient: {
        getAdminShopProposals: vi.fn(),
        approveShopProposal: vi.fn(),
        rejectShopProposal: vi.fn(),
        getShopProposal: vi.fn()
    }
}))

describe('useProposalManagement', () => {
    let composable: ReturnType<typeof useProposalManagement>

    // Mock data
    const mockProposal: ShopProposal = {
        id: 1,
        user_id: 1,
        name: 'テストカフェ',
        address: '東京都渋谷区',
        genre: 'カフェ' as any,
        description: 'テスト用のカフェです',
        status: ProposalStatus.PENDING,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        user: {
            id: 1,
            name: 'テストユーザー',
            username: 'testuser',
            email: 'test@example.com'
        }
    }

    const mockShop: Shop = {
        id: 1,
        name: 'テストカフェ',
        address: '東京都渋谷区',
        genre: 'カフェ' as any,
        description: 'テスト用のカフェです',
        has_try_benefit: false,
        stamp_count: 0,
        is_approved: true,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z'
    }

    const mockPaginatedResponse: PaginatedResponse<ShopProposal> = {
        data: [mockProposal],
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

    beforeEach(() => {
        composable = useProposalManagement()
        vi.clearAllMocks()
    })

    afterEach(() => {
        composable.resetState()
    })

    describe('fetchProposals', () => {
        it('should fetch proposals successfully', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.getAdminShopProposals.mockResolvedValue(mockPaginatedResponse)

            // Act
            await composable.fetchProposals()

            // Assert
            expect(mockApiClient.getAdminShopProposals).toHaveBeenCalledWith({
                page: 1,
                per_page: 20
            })
            expect(composable.proposals.value).toEqual([mockProposal])
            expect(composable.pagination.value.total).toBe(1)
            expect(composable.loading.value).toBe(false)
            expect(composable.error.value).toBeNull()
        })

        it('should handle fetch proposals error', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            const errorMessage = 'Failed to fetch proposals'
            mockApiClient.getAdminShopProposals.mockRejectedValue(new Error(errorMessage))

            // Act
            await composable.fetchProposals()

            // Assert
            expect(composable.proposals.value).toEqual([])
            expect(composable.loading.value).toBe(false)
            expect(composable.error.value).toBe(errorMessage)
        })

        it('should fetch proposals with filters', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.getAdminShopProposals.mockResolvedValue(mockPaginatedResponse)

            const filters = {
                status: ProposalStatus.PENDING,
                genre: 'カフェ',
                search: 'テスト',
                sort_by: 'name',
                sort_order: 'asc'
            }

            // Act
            await composable.fetchProposals(filters)

            // Assert
            expect(mockApiClient.getAdminShopProposals).toHaveBeenCalledWith({
                page: 1,
                per_page: 20,
                ...filters
            })
        })

        it('should not include "all" status in API call', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.getAdminShopProposals.mockResolvedValue(mockPaginatedResponse)

            // Act
            await composable.fetchProposals({ status: 'all' })

            // Assert
            expect(mockApiClient.getAdminShopProposals).toHaveBeenCalledWith({
                page: 1,
                per_page: 20
                // status should not be included
            })
        })
    })

    describe('approveProposal', () => {
        it('should approve proposal successfully', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            const mockResponse: ApiResponse<Shop> = { data: mockShop }
            mockApiClient.approveShopProposal.mockResolvedValue(mockResponse)

            // Set initial state
            composable.proposals.value = [mockProposal]

            // Act
            const result = await composable.approveProposal(1, 'Approved for testing')

            // Assert
            expect(mockApiClient.approveShopProposal).toHaveBeenCalledWith(1)
            expect(result.success).toBe(true)
            expect(result.data).toEqual(mockShop)
            expect(composable.proposals.value[0].status).toBe(ProposalStatus.APPROVED)
            expect(composable.proposals.value[0].admin_notes).toBe('Approved for testing')
        })

        it('should handle approve proposal error', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            const errorMessage = 'Failed to approve proposal'
            mockApiClient.approveShopProposal.mockRejectedValue(new Error(errorMessage))

            // Set initial state
            composable.proposals.value = [mockProposal]

            // Act
            const result = await composable.approveProposal(1)

            // Assert
            expect(result.success).toBe(false)
            expect(result.error).toBe(errorMessage)
            expect(composable.error.value).toBe(errorMessage)
        })

        it('should set processing state correctly', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.approveShopProposal.mockImplementation(() =>
                new Promise(resolve => setTimeout(() => resolve({ data: mockShop }), 100))
            )

            // Set initial state
            const proposalWithProcessing = { ...mockProposal, processing: false }
            composable.proposals.value = [proposalWithProcessing]

            // Act
            const approvalPromise = composable.approveProposal(1)

            // Assert processing state is set
            await nextTick()
            expect(composable.proposals.value[0].processing).toBe(true)

            // Wait for completion
            await approvalPromise

            // Assert processing state is cleared
            expect(composable.proposals.value[0].processing).toBe(false)
        })
    })

    describe('rejectProposal', () => {
        it('should reject proposal successfully', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.rejectShopProposal.mockResolvedValue({})

            // Set initial state
            composable.proposals.value = [mockProposal]

            // Act
            const result = await composable.rejectProposal(1, 'Not suitable for our platform')

            // Assert
            expect(mockApiClient.rejectShopProposal).toHaveBeenCalledWith(1, 'Not suitable for our platform')
            expect(result.success).toBe(true)
            expect(composable.proposals.value[0].status).toBe(ProposalStatus.REJECTED)
            expect(composable.proposals.value[0].admin_notes).toBe('Not suitable for our platform')
        })

        it('should handle reject proposal error', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            const errorMessage = 'Failed to reject proposal'
            mockApiClient.rejectShopProposal.mockRejectedValue(new Error(errorMessage))

            // Set initial state
            composable.proposals.value = [mockProposal]

            // Act
            const result = await composable.rejectProposal(1, 'Rejection reason')

            // Assert
            expect(result.success).toBe(false)
            expect(result.error).toBe(errorMessage)
            expect(composable.error.value).toBe(errorMessage)
        })
    })

    describe('getProposal', () => {
        it('should get single proposal successfully', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            const mockResponse: ApiResponse<ShopProposal> = { data: mockProposal }
            mockApiClient.getShopProposal.mockResolvedValue(mockResponse)

            // Act
            const result = await composable.getProposal(1)

            // Assert
            expect(mockApiClient.getShopProposal).toHaveBeenCalledWith(1)
            expect(result).toEqual(mockProposal)
        })

        it('should handle get proposal error', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            const errorMessage = 'Failed to fetch proposal'
            mockApiClient.getShopProposal.mockRejectedValue(new Error(errorMessage))

            // Act
            const result = await composable.getProposal(1)

            // Assert
            expect(result).toBeNull()
            expect(composable.error.value).toBe(errorMessage)
        })
    })

    describe('filtering and pagination', () => {
        beforeEach(() => {
            const proposals = [
                { ...mockProposal, id: 1, status: ProposalStatus.PENDING },
                { ...mockProposal, id: 2, status: ProposalStatus.APPROVED },
                { ...mockProposal, id: 3, status: ProposalStatus.REJECTED }
            ]
            composable.proposals.value = proposals
        })

        it('should filter proposals by status', () => {
            // Act
            composable.updateFilters({ status: ProposalStatus.PENDING })

            // Assert
            expect(composable.filteredProposals.value).toHaveLength(1)
            expect(composable.filteredProposals.value[0].status).toBe(ProposalStatus.PENDING)
        })

        it('should show all proposals when status is "all"', () => {
            // Act
            composable.updateFilters({ status: 'all' })

            // Assert
            expect(composable.filteredProposals.value).toHaveLength(3)
        })

        it('should calculate status counts correctly', () => {
            // Assert
            expect(composable.statusCounts.value.pending).toBe(1)
            expect(composable.statusCounts.value.approved).toBe(1)
            expect(composable.statusCounts.value.rejected).toBe(1)
        })

        it('should calculate pending count correctly', () => {
            // Assert
            expect(composable.pendingCount.value).toBe(1)
        })
    })

    describe('bulk operations', () => {
        it('should bulk approve proposals', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.approveShopProposal.mockResolvedValue({ data: mockShop })

            // Act
            const results = await composable.bulkApproveProposals([1, 2, 3])

            // Assert
            expect(mockApiClient.approveShopProposal).toHaveBeenCalledTimes(3)
            expect(results).toHaveLength(3)
            expect(results.every(r => r.success)).toBe(true)
        })

        it('should bulk reject proposals', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.rejectShopProposal.mockResolvedValue({})

            // Act
            const results = await composable.bulkRejectProposals([1, 2, 3], 'Bulk rejection')

            // Assert
            expect(mockApiClient.rejectShopProposal).toHaveBeenCalledTimes(3)
            expect(results).toHaveLength(3)
            expect(results.every(r => r.success)).toBe(true)
        })
    })

    describe('pagination methods', () => {
        beforeEach(() => {
            composable.pagination.value = {
                current_page: 2,
                last_page: 5,
                per_page: 20,
                total: 100,
                from: 21,
                to: 40,
                has_more_pages: true
            }
        })

        it('should load next page', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.getAdminShopProposals.mockResolvedValue(mockPaginatedResponse)

            // Act
            await composable.loadNextPage()

            // Assert
            expect(mockApiClient.getAdminShopProposals).toHaveBeenCalledWith(
                expect.objectContaining({ page: 3 })
            )
        })

        it('should load previous page', async () => {
            // Arrange
            const mockApiClient = apiClient as any
            mockApiClient.getAdminShopProposals.mockResolvedValue(mockPaginatedResponse)

            // Act
            await composable.loadPreviousPage()

            // Assert
            expect(mockApiClient.getAdminShopProposals).toHaveBeenCalledWith(
                expect.objectContaining({ page: 1 })
            )
        })

        it('should not load next page if on last page', async () => {
            // Arrange
            composable.pagination.value.has_more_pages = false
            const mockApiClient = apiClient as any

            // Act
            await composable.loadNextPage()

            // Assert
            expect(mockApiClient.getAdminShopProposals).not.toHaveBeenCalled()
        })

        it('should not load previous page if on first page', async () => {
            // Arrange
            composable.pagination.value.current_page = 1
            const mockApiClient = apiClient as any

            // Act
            await composable.loadPreviousPage()

            // Assert
            expect(mockApiClient.getAdminShopProposals).not.toHaveBeenCalled()
        })
    })

    describe('computed properties', () => {
        it('should calculate hasError correctly', () => {
            expect(composable.hasError.value).toBe(false)

            composable.error.value = 'Test error'
            expect(composable.hasError.value).toBe(true)
        })

        it('should calculate isEmpty correctly', () => {
            expect(composable.isEmpty.value).toBe(true)

            composable.proposals.value = [mockProposal]
            expect(composable.isEmpty.value).toBe(false)
        })

        it('should calculate hasMorePages correctly', () => {
            expect(composable.hasMorePages.value).toBe(false)

            composable.pagination.value.has_more_pages = true
            expect(composable.hasMorePages.value).toBe(true)
        })
    })

    describe('state management', () => {
        it('should reset state correctly', () => {
            // Arrange - set some state
            composable.proposals.value = [mockProposal]
            composable.error.value = 'Test error'
            composable.pagination.value.current_page = 5

            // Act
            composable.resetState()

            // Assert
            expect(composable.proposals.value).toEqual([])
            expect(composable.error.value).toBeNull()
            expect(composable.pagination.value.current_page).toBe(1)
        })

        it('should clear error correctly', () => {
            // Arrange
            composable.error.value = 'Test error'

            // Act
            composable.clearError()

            // Assert
            expect(composable.error.value).toBeNull()
        })
    })
})