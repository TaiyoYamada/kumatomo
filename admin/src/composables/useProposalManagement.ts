import { ref, computed } from 'vue'
import { apiClient } from '@/services/apiClient'
import { ProposalStatus } from '@/types/shop'
import type { ShopProposal, Shop } from '@/types/shop'
import type { PaginatedResponse } from '@/types/api'

// Proposal filter interface
export interface ProposalFilters {
    status?: ProposalStatus | 'all'
    genre?: string
    search?: string
    sort_by?: 'created_at' | 'name' | 'status'
    sort_order?: 'asc' | 'desc'
}



// Proposal action result
export interface ProposalActionResult {
    success: boolean
    data?: Shop | null
    error?: string
}

export const useProposalManagement = () => {
    // Reactive state
    const proposals = ref<ShopProposal[]>([])
    const loading = ref(false)
    const error = ref<string | null>(null)
    const pagination = ref({
        current_page: 1,
        last_page: 1,
        per_page: 20,
        total: 0,
        from: null as number | null,
        to: null as number | null,
        has_more_pages: false
    })
    const filters = ref<ProposalFilters>({
        status: 'all',
        sort_by: 'created_at',
        sort_order: 'desc'
    })

    // Computed properties
    const hasError = computed(() => error.value !== null)
    const isEmpty = computed(() => proposals.value.length === 0)
    const hasMorePages = computed(() => pagination.value.has_more_pages)

    // Status counts for filtering
    const statusCounts = computed(() => {
        const counts = {
            all: pagination.value.total,
            pending: 0,
            approved: 0,
            rejected: 0
        }

        proposals.value.forEach(proposal => {
            counts[proposal.status]++
        })

        return counts
    })

    // Filtered proposals by status
    const filteredProposals = computed(() => {
        if (filters.value.status === 'all') {
            return proposals.value
        }
        return proposals.value.filter(proposal => proposal.status === filters.value.status)
    })

    // Pending proposals count
    const pendingCount = computed(() =>
        proposals.value.filter(p => p.status === ProposalStatus.PENDING).length
    )

    // Utility methods
    const setLoading = (isLoading: boolean): void => {
        loading.value = isLoading
    }

    const setError = (errorMessage: string | null): void => {
        error.value = errorMessage
    }

    const clearError = (): void => {
        error.value = null
    }

    const setProposalProcessing = (proposalId: number, processing: boolean): void => {
        const proposal = proposals.value.find(p => p.id === proposalId)
        if (proposal) {
            proposal.processing = processing
        }
    }

    // API methods
    const fetchProposals = async (params?: {
        page?: number
        per_page?: number
        status?: ProposalStatus | 'all'
        genre?: string
        search?: string
        sort_by?: string
        sort_order?: string
    }): Promise<void> => {
        setLoading(true)
        clearError()

        try {
            // Build query parameters
            const queryParams: Record<string, any> = {
                page: params?.page || pagination.value.current_page,
                per_page: params?.per_page || pagination.value.per_page
            }

            if (params?.status && params.status !== 'all') {
                queryParams.status = params.status
            }
            if (params?.genre) {
                queryParams.genre = params.genre
            }
            if (params?.search) {
                queryParams.search = params.search
            }
            if (params?.sort_by) {
                queryParams.sort_by = params.sort_by
            }
            if (params?.sort_order) {
                queryParams.sort_order = params.sort_order
            }

            const response: PaginatedResponse<ShopProposal> = await apiClient.getAdminShopProposals(queryParams)

            proposals.value = response.data
            pagination.value = response.pagination

            // Update filters
            if (params) {
                filters.value = {
                    ...filters.value,
                    ...params
                }
            }

            console.log(`✅ Loaded ${response.data.length} proposals`)
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'Failed to fetch proposals'
            setError(errorMessage)
            console.error('Failed to fetch proposals:', err)
        } finally {
            setLoading(false)
        }
    }

    const approveProposal = async (proposalId: number, adminNotes?: string): Promise<ProposalActionResult> => {
        setProposalProcessing(proposalId, true)
        clearError()

        try {
            const response = await apiClient.approveShopProposal(proposalId)

            // Update proposal status in local state
            const proposalIndex = proposals.value.findIndex(p => p.id === proposalId)
            if (proposalIndex !== -1) {
                proposals.value[proposalIndex] = {
                    ...proposals.value[proposalIndex],
                    status: ProposalStatus.APPROVED,
                    admin_notes: adminNotes
                }
            }

            console.log(`✅ Proposal ${proposalId} approved successfully`)
            return {
                success: true,
                data: response.data
            }
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'Failed to approve proposal'
            setError(errorMessage)
            console.error('Failed to approve proposal:', err)
            return {
                success: false,
                error: errorMessage
            }
        } finally {
            setProposalProcessing(proposalId, false)
        }
    }

    const rejectProposal = async (proposalId: number, adminNotes?: string): Promise<ProposalActionResult> => {
        setProposalProcessing(proposalId, true)
        clearError()

        try {
            await apiClient.rejectShopProposal(proposalId, adminNotes)

            // Update proposal status in local state
            const proposalIndex = proposals.value.findIndex(p => p.id === proposalId)
            if (proposalIndex !== -1) {
                proposals.value[proposalIndex] = {
                    ...proposals.value[proposalIndex],
                    status: ProposalStatus.REJECTED,
                    admin_notes: adminNotes
                }
            }

            console.log(`✅ Proposal ${proposalId} rejected successfully`)
            return {
                success: true
            }
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'Failed to reject proposal'
            setError(errorMessage)
            console.error('Failed to reject proposal:', err)
            return {
                success: false,
                error: errorMessage
            }
        } finally {
            setProposalProcessing(proposalId, false)
        }
    }

    const getProposal = async (proposalId: number): Promise<ShopProposal | null> => {
        setLoading(true)
        clearError()

        try {
            const response = await apiClient.getShopProposal(proposalId)
            return response.data
        } catch (err) {
            const errorMessage = err instanceof Error ? err.message : 'Failed to fetch proposal'
            setError(errorMessage)
            console.error('Failed to fetch proposal:', err)
            return null
        } finally {
            setLoading(false)
        }
    }

    // Filter and pagination methods
    const updateFilters = (newFilters: Partial<ProposalFilters>): void => {
        filters.value = {
            ...filters.value,
            ...newFilters
        }
    }

    const applyFilters = async (): Promise<void> => {
        await fetchProposals({
            page: 1, // Reset to first page when applying filters
            ...filters.value
        })
    }

    const loadPage = async (page: number): Promise<void> => {
        if (page >= 1 && page <= pagination.value.last_page) {
            await fetchProposals({
                page,
                ...filters.value
            })
        }
    }

    const loadNextPage = async (): Promise<void> => {
        if (pagination.value.has_more_pages) {
            await loadPage(pagination.value.current_page + 1)
        }
    }

    const loadPreviousPage = async (): Promise<void> => {
        if (pagination.value.current_page > 1) {
            await loadPage(pagination.value.current_page - 1)
        }
    }

    const refreshProposals = async (): Promise<void> => {
        await fetchProposals({
            page: pagination.value.current_page,
            ...filters.value
        })
    }

    // Bulk operations
    const bulkApproveProposals = async (proposalIds: number[]): Promise<ProposalActionResult[]> => {
        const results: ProposalActionResult[] = []

        for (const id of proposalIds) {
            const result = await approveProposal(id)
            results.push(result)
        }

        return results
    }

    const bulkRejectProposals = async (proposalIds: number[], adminNotes?: string): Promise<ProposalActionResult[]> => {
        const results: ProposalActionResult[] = []

        for (const id of proposalIds) {
            const result = await rejectProposal(id, adminNotes)
            results.push(result)
        }

        return results
    }

    // Reset state
    const resetState = (): void => {
        proposals.value = []
        loading.value = false
        error.value = null
        pagination.value = {
            current_page: 1,
            last_page: 1,
            per_page: 20,
            total: 0,
            from: null,
            to: null,
            has_more_pages: false
        }
        filters.value = {
            status: 'all',
            sort_by: 'created_at',
            sort_order: 'desc'
        }
    }

    return {
        // State
        proposals,
        loading,
        error,
        pagination,
        filters,
        statusCounts,
        filteredProposals,
        pendingCount,

        // Computed
        hasError,
        isEmpty,
        hasMorePages,

        // Methods
        fetchProposals,
        approveProposal,
        rejectProposal,
        getProposal,
        updateFilters,
        applyFilters,
        loadPage,
        loadNextPage,
        loadPreviousPage,
        refreshProposals,
        bulkApproveProposals,
        bulkRejectProposals,
        clearError,
        resetState
    }
}