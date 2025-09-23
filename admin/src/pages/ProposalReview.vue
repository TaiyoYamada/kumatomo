<template>
    <div class="proposal-review">
        <!-- Page Header -->
        <div class="page-header mb-6">
            <div class="d-flex justify-space-between align-center">
                <div>
                    <h1 class="text-h4 font-weight-bold mb-2">店舗提案レビュー</h1>
                    <p class="text-body-1 text-medium-emphasis">
                        ユーザーから提案された店舗の承認・却下を管理します
                    </p>
                </div>
                <v-chip v-if="pendingCount > 0" color="warning" variant="tonal" size="large">
                    <v-icon start>mdi-clock-outline</v-icon>
                    {{ pendingCount }}件の承認待ち
                </v-chip>
            </div>
        </div>

        <!-- Filters and Controls -->
        <v-card class="filters-card mb-6" elevation="1">
            <v-card-text>
                <div class="filters-grid">
                    <!-- Status Filter -->
                    <div class="filter-group">
                        <label class="filter-label text-body-2 font-weight-medium mb-2">ステータス</label>
                        <v-chip-group v-model="selectedStatus" @update:model-value="handleStatusFilter" mandatory
                            selected-class="text-primary">
                            <v-chip value="all" variant="outlined"
                                :class="{ 'bg-primary text-white': selectedStatus === 'all' }">
                                すべて ({{ statusCounts.all }})
                            </v-chip>
                            <v-chip :value="ProposalStatus.PENDING" variant="outlined" color="warning"
                                :class="{ 'bg-warning text-white': selectedStatus === ProposalStatus.PENDING }">
                                承認待ち ({{ statusCounts.pending }})
                            </v-chip>
                            <v-chip :value="ProposalStatus.APPROVED" variant="outlined" color="success"
                                :class="{ 'bg-success text-white': selectedStatus === ProposalStatus.APPROVED }">
                                承認済み ({{ statusCounts.approved }})
                            </v-chip>
                            <v-chip :value="ProposalStatus.REJECTED" variant="outlined" color="error"
                                :class="{ 'bg-error text-white': selectedStatus === ProposalStatus.REJECTED }">
                                却下済み ({{ statusCounts.rejected }})
                            </v-chip>
                        </v-chip-group>
                    </div>

                    <!-- Search and Sort -->
                    <div class="filter-controls d-flex gap-4">
                        <v-text-field v-model="searchQuery" label="店舗名で検索" prepend-inner-icon="mdi-magnify"
                            variant="outlined" density="compact" hide-details clearable
                            @update:model-value="handleSearch" style="max-width: 300px;" />

                        <v-select v-model="sortBy" :items="sortOptions" label="並び順" variant="outlined" density="compact"
                            hide-details @update:model-value="handleSort" style="max-width: 200px;" />

                        <v-btn @click="refreshProposals" :loading="loading" variant="outlined" color="primary">
                            <v-icon start>mdi-refresh</v-icon>
                            更新
                        </v-btn>
                    </div>
                </div>
            </v-card-text>
        </v-card>

        <!-- Error Alert -->
        <v-alert v-if="hasError" type="error" variant="tonal" closable class="mb-6" @click:close="clearError">
            {{ error }}
        </v-alert>

        <!-- Proposals Table -->
        <v-card elevation="1">
            <v-data-table :items="proposals" :headers="tableHeaders" :loading="loading"
                :items-per-page="pagination.per_page" :page="pagination.current_page"
                :server-items-length="pagination.total" @update:page="handlePageChange"
                @update:items-per-page="handleItemsPerPageChange" class="proposals-table" no-data-text="提案がありません"
                loading-text="読み込み中...">
                <!-- Status Column -->
                <template v-slot:item.status="{ item }">
                    <v-chip :color="getStatusColor(item.status)" variant="tonal" size="small">
                        <v-icon start size="16">{{ getStatusIcon(item.status) }}</v-icon>
                        {{ getStatusText(item.status) }}
                    </v-chip>
                </template>

                <!-- Genre Column -->
                <template v-slot:item.genre="{ item }">
                    <v-chip v-if="item.genre" :color="getGenreColor(item.genre)" variant="tonal" size="small">
                        {{ item.genre }}
                    </v-chip>
                    <span v-else class="text-medium-emphasis">未設定</span>
                </template>

                <!-- User Column -->
                <template v-slot:item.user="{ item }">
                    <div v-if="item.user" class="user-info">
                        <div class="text-body-2 font-weight-medium">{{ item.user.name }}</div>
                        <div class="text-caption text-medium-emphasis">{{ item.user.username }}</div>
                    </div>
                    <span v-else class="text-medium-emphasis">不明</span>
                </template>

                <!-- Created At Column -->
                <template v-slot:item.created_at="{ item }">
                    <div class="date-info">
                        <div class="text-body-2">{{ formatDate(item.created_at) }}</div>
                        <div class="text-caption text-medium-emphasis">{{ formatTime(item.created_at) }}</div>
                    </div>
                </template>

                <!-- Actions Column -->
                <template v-slot:item.actions="{ item }">
                    <div class="action-buttons d-flex gap-2">
                        <!-- View Details -->
                        <v-btn @click="viewProposalDetails(item)" variant="text" color="primary" size="small"
                            icon="mdi-eye" />

                        <!-- Approve Button -->
                        <v-btn v-if="item.status === ProposalStatus.PENDING" @click="showApprovalDialog(item)"
                            :loading="item.processing" variant="text" color="success" size="small" icon="mdi-check" />

                        <!-- Reject Button -->
                        <v-btn v-if="item.status === ProposalStatus.PENDING" @click="showRejectionDialog(item)"
                            :loading="item.processing" variant="text" color="error" size="small" icon="mdi-close" />

                        <!-- Convert to Shop (for approved proposals) -->
                        <v-btn v-if="item.status === ProposalStatus.APPROVED" @click="convertToShop(item)"
                            variant="text" color="primary" size="small" icon="mdi-store-plus" />
                    </div>
                </template>
            </v-data-table>
        </v-card>

        <!-- Proposal Details Dialog -->
        <ProposalDetailsDialog v-model="detailsDialog.show" :proposal="detailsDialog.proposal" @approve="handleApproval"
            @reject="handleRejection" />

        <!-- Approval Dialog -->
        <ProposalActionDialog v-model="approvalDialog.show" :proposal="approvalDialog.proposal" action="approve"
            @confirm="handleApproval" />

        <!-- Rejection Dialog -->
        <ProposalActionDialog v-model="rejectionDialog.show" :proposal="rejectionDialog.proposal" action="reject"
            @confirm="handleRejection" />

        <!-- Success Snackbar -->
        <v-snackbar v-model="successSnackbar.show" :color="successSnackbar.color" timeout="4000">
            {{ successSnackbar.message }}
            <template v-slot:actions>
                <v-btn variant="text" @click="successSnackbar.show = false">
                    閉じる
                </v-btn>
            </template>
        </v-snackbar>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useProposalManagement } from '@/composables/useProposalManagement'
import { ProposalStatus, getGenreColor, type ShopProposal } from '@/types/shop'
import ProposalDetailsDialog from '@/components/ProposalDetailsDialog.vue'
import ProposalActionDialog from '@/components/ProposalActionDialog.vue'

// Composables
const {
    proposals,
    loading,
    error,
    pagination,
    statusCounts,
    pendingCount,
    hasError,
    fetchProposals,
    approveProposal,
    rejectProposal,
    refreshProposals,
    updateFilters,
    applyFilters,
    loadPage,
    clearError
} = useProposalManagement()

// Reactive state
const selectedStatus = ref<ProposalStatus | 'all'>('all')
const searchQuery = ref('')
const sortBy = ref('created_at_desc')

// Dialog states
const detailsDialog = ref({
    show: false,
    proposal: null as ShopProposal | null
})

const approvalDialog = ref({
    show: false,
    proposal: null as ShopProposal | null
})

const rejectionDialog = ref({
    show: false,
    proposal: null as ShopProposal | null
})

const successSnackbar = ref({
    show: false,
    message: '',
    color: 'success'
})

// Table configuration
const tableHeaders = [
    {
        title: 'ID',
        key: 'id',
        sortable: true,
        width: '80px'
    },
    {
        title: '店舗名',
        key: 'name',
        sortable: true,
        width: '200px'
    },
    {
        title: 'ジャンル',
        key: 'genre',
        sortable: true,
        width: '120px'
    },
    {
        title: '住所',
        key: 'address',
        sortable: false,
        width: '250px'
    },
    {
        title: 'ステータス',
        key: 'status',
        sortable: true,
        width: '120px'
    },
    {
        title: '提案者',
        key: 'user',
        sortable: false,
        width: '150px'
    },
    {
        title: '作成日時',
        key: 'created_at',
        sortable: true,
        width: '150px'
    },
    {
        title: '操作',
        key: 'actions',
        sortable: false,
        width: '150px',
        align: 'center'
    }
]

const sortOptions = [
    { title: '作成日時（新しい順）', value: 'created_at_desc' },
    { title: '作成日時（古い順）', value: 'created_at_asc' },
    { title: '店舗名（昇順）', value: 'name_asc' },
    { title: '店舗名（降順）', value: 'name_desc' },
    { title: 'ステータス', value: 'status_asc' }
]

// Computed properties
const currentFilters = computed(() => ({
    status: selectedStatus.value,
    search: searchQuery.value,
    sort_by: sortBy.value.split('_')[0],
    sort_order: sortBy.value.split('_')[1] || 'desc'
}))

// Methods
const handleStatusFilter = (status: ProposalStatus | 'all') => {
    selectedStatus.value = status
    updateFilters({ status })
    applyFilters()
}

const handleSearch = () => {
    updateFilters({ search: searchQuery.value })
    // Debounce search
    setTimeout(() => {
        applyFilters()
    }, 500)
}

const handleSort = () => {
    const [sort_by, sort_order] = sortBy.value.split('_')
    updateFilters({ sort_by, sort_order })
    applyFilters()
}

const handlePageChange = (page: number) => {
    loadPage(page)
}

const handleItemsPerPageChange = (itemsPerPage: number) => {
    updateFilters({ per_page: itemsPerPage })
    applyFilters()
}

// Status helpers
const getStatusColor = (status: ProposalStatus): string => {
    const colors = {
        [ProposalStatus.PENDING]: 'warning',
        [ProposalStatus.APPROVED]: 'success',
        [ProposalStatus.REJECTED]: 'error'
    }
    return colors[status] || 'default'
}

const getStatusIcon = (status: ProposalStatus): string => {
    const icons = {
        [ProposalStatus.PENDING]: 'mdi-clock-outline',
        [ProposalStatus.APPROVED]: 'mdi-check-circle',
        [ProposalStatus.REJECTED]: 'mdi-close-circle'
    }
    return icons[status] || 'mdi-help-circle'
}

const getStatusText = (status: ProposalStatus): string => {
    const texts = {
        [ProposalStatus.PENDING]: '承認待ち',
        [ProposalStatus.APPROVED]: '承認済み',
        [ProposalStatus.REJECTED]: '却下済み'
    }
    return texts[status] || '不明'
}

// Date formatting
const formatDate = (dateString: string): string => {
    const date = new Date(dateString)
    return date.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    })
}

const formatTime = (dateString: string): string => {
    const date = new Date(dateString)
    return date.toLocaleTimeString('ja-JP', {
        hour: '2-digit',
        minute: '2-digit'
    })
}

// Dialog methods
const viewProposalDetails = (proposal: ShopProposal) => {
    detailsDialog.value = {
        show: true,
        proposal
    }
}

const showApprovalDialog = (proposal: ShopProposal) => {
    approvalDialog.value = {
        show: true,
        proposal
    }
}

const showRejectionDialog = (proposal: ShopProposal) => {
    rejectionDialog.value = {
        show: true,
        proposal
    }
}

// Action handlers
const handleApproval = async (data: { proposal: ShopProposal; adminNotes?: string }) => {
    const result = await approveProposal(data.proposal.id, data.adminNotes)

    if (result.success) {
        showSuccessMessage(`提案「${data.proposal.name}」を承認しました`, 'success')
        approvalDialog.value.show = false
        detailsDialog.value.show = false
    }
}

const handleRejection = async (data: { proposal: ShopProposal; adminNotes?: string }) => {
    const result = await rejectProposal(data.proposal.id, data.adminNotes)

    if (result.success) {
        showSuccessMessage(`提案「${data.proposal.name}」を却下しました`, 'warning')
        rejectionDialog.value.show = false
        detailsDialog.value.show = false
    }
}

const convertToShop = (proposal: ShopProposal) => {
    // Navigate to shop creation form with proposal data
    // This would be implemented based on your routing structure
    console.log('Convert to shop:', proposal)
}

const showSuccessMessage = (message: string, color: string = 'success') => {
    successSnackbar.value = {
        show: true,
        message,
        color
    }
}

// Lifecycle
onMounted(() => {
    fetchProposals()
})

// Watch for filter changes
watch(currentFilters, (newFilters) => {
    updateFilters(newFilters)
}, { deep: true })
</script>

<style scoped>
.proposal-review {
    padding: 1.5rem;
}

.page-header {
    border-bottom: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
    padding-bottom: 1.5rem;
}

.filters-card {
    border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
}

.filters-grid {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

.filter-group {
    display: flex;
    flex-direction: column;
}

.filter-label {
    display: block;
    color: rgba(var(--v-theme-on-surface), 0.87);
}

.filter-controls {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 1rem;
}

.proposals-table {
    border-radius: 8px;
}

.user-info {
    display: flex;
    flex-direction: column;
}

.date-info {
    display: flex;
    flex-direction: column;
}

.action-buttons {
    justify-content: center;
}

/* Responsive design */
@media (max-width: 960px) {
    .filter-controls {
        flex-direction: column;
        align-items: stretch;
    }

    .filter-controls>* {
        max-width: none !important;
    }
}

@media (max-width: 600px) {
    .proposal-review {
        padding: 1rem;
    }

    .page-header .d-flex {
        flex-direction: column;
        align-items: flex-start;
        gap: 1rem;
    }
}
</style>