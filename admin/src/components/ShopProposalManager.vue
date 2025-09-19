<template>
    <v-card class="shop-proposal-manager" elevation="1">
        <v-card-title class="d-flex align-center justify-space-between">
            <div class="d-flex align-center">
                <v-icon class="me-2">mdi-store-plus</v-icon>
                <span>店舗提案管理</span>
            </div>
            <v-chip :text="`${proposals.length}件の提案`" color="info" variant="tonal" />
        </v-card-title>

        <v-divider />

        <!-- Filters -->
        <v-card-text class="pb-0">
            <v-row align="center">
                <v-col cols="12" md="4">
                    <v-select v-model="statusFilter" :items="statusFilterOptions" label="ステータス" variant="outlined"
                        density="comfortable" hide-details @update:model-value="handleFilter" />
                </v-col>

                <v-col cols="12" md="4">
                    <v-select v-model="genreFilter" :items="genreFilterOptions" label="ジャンル" variant="outlined"
                        density="comfortable" hide-details clearable @update:model-value="handleFilter" />
                </v-col>

                <v-col cols="12" md="4">
                    <v-text-field v-model="searchQuery" label="店舗名で検索" variant="outlined" density="comfortable"
                        hide-details clearable prepend-inner-icon="mdi-magnify" @input="handleSearch" />
                </v-col>
            </v-row>
        </v-card-text>

        <!-- Loading State -->
        <v-card-text v-if="loading" class="text-center py-8">
            <v-progress-circular indeterminate color="primary" class="mb-4" />
            <p class="text-body-1">読み込み中...</p>
        </v-card-text>

        <!-- Error State -->
        <v-alert v-if="error" type="error" class="ma-4" closable @click:close="error = ''">
            {{ error }}
        </v-alert>

        <!-- Proposals List -->
        <v-card-text v-if="!loading && !error">
            <v-data-table :headers="headers" :items="filteredProposals" :loading="loading" item-key="id"
                no-data-text="提案が見つかりませんでした。" loading-text="読み込み中..." class="proposals-table">
                <template v-slot:item.name="{ item }">
                    <div class="proposal-info">
                        <div class="text-body-1 font-weight-medium">{{ item.name }}</div>
                        <div v-if="item.description" class="text-body-2 text-medium-emphasis mt-1">
                            {{ truncateText(item.description, 50) }}
                        </div>
                    </div>
                </template>

                <template v-slot:item.genre="{ item }">
                    <v-chip v-if="item.genre" :text="item.genre" :color="getGenreColor(item.genre)" variant="tonal"
                        size="small" />
                    <span v-else class="text-medium-emphasis">-</span>
                </template>

                <template v-slot:item.status="{ item }">
                    <v-chip :color="getStatusColor(item.status)" :text="getStatusText(item.status)" variant="tonal"
                        size="small" />
                </template>

                <template v-slot:item.user="{ item }">
                    <div v-if="item.user" class="user-info">
                        <div class="text-body-2">{{ item.user.name }}</div>
                        <div class="text-caption text-medium-emphasis">{{ item.user.username }}</div>
                    </div>
                    <span v-else class="text-medium-emphasis">-</span>
                </template>

                <template v-slot:item.created_at="{ item }">
                    <span class="text-body-2">{{ formatDate(item.created_at) }}</span>
                </template>

                <template v-slot:item.actions="{ item }">
                    <div class="actions d-flex ga-2">
                        <v-btn v-if="item.status === ProposalStatus.PENDING" @click="openApprovalDialog(item)"
                            color="success" variant="outlined" size="small" prepend-icon="mdi-check">
                            承認
                        </v-btn>
                        <v-btn v-if="item.status === ProposalStatus.PENDING" @click="openRejectionDialog(item)"
                            color="error" variant="outlined" size="small" prepend-icon="mdi-close">
                            却下
                        </v-btn>
                        <v-btn @click="viewProposal(item)" color="info" variant="outlined" size="small"
                            prepend-icon="mdi-eye">
                            詳細
                        </v-btn>
                    </div>
                </template>
            </v-data-table>
        </v-card-text>

        <!-- Approval Dialog -->
        <v-dialog v-model="showApprovalDialog" max-width="500">
            <v-card>
                <v-card-title class="text-h6 font-weight-bold">
                    提案を承認
                </v-card-title>

                <v-card-text class="py-4">
                    <p class="text-body-1 mb-4">
                        「{{ selectedProposal?.name }}」を承認して店舗として登録しますか？
                    </p>

                    <v-textarea v-model="adminNotes" label="管理者メモ（任意）" placeholder="承認理由や追加情報を入力してください"
                        variant="outlined" rows="3" counter="500" />
                </v-card-text>

                <v-card-actions>
                    <v-spacer />
                    <v-btn @click="closeApprovalDialog" variant="outlined" color="grey">
                        キャンセル
                    </v-btn>
                    <v-btn @click="approveProposal" :loading="processing" color="success" variant="flat">
                        承認
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Rejection Dialog -->
        <v-dialog v-model="showRejectionDialog" max-width="500">
            <v-card>
                <v-card-title class="text-h6 font-weight-bold">
                    提案を却下
                </v-card-title>

                <v-card-text class="py-4">
                    <p class="text-body-1 mb-4">
                        「{{ selectedProposal?.name }}」を却下しますか？
                    </p>

                    <v-textarea v-model="adminNotes" label="却下理由（必須）" placeholder="却下理由を入力してください" variant="outlined"
                        rows="3" counter="500" :rules="rejectionNotesRules" required />
                </v-card-text>

                <v-card-actions>
                    <v-spacer />
                    <v-btn @click="closeRejectionDialog" variant="outlined" color="grey">
                        キャンセル
                    </v-btn>
                    <v-btn @click="rejectProposal" :loading="processing" :disabled="!adminNotes.trim()" color="error"
                        variant="flat">
                        却下
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Proposal Detail Dialog -->
        <v-dialog v-model="showDetailDialog" max-width="600">
            <v-card v-if="selectedProposal">
                <v-card-title class="text-h6 font-weight-bold">
                    提案詳細
                </v-card-title>

                <v-card-text class="py-4">
                    <v-row>
                        <v-col cols="12" md="6">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">店舗名</div>
                                <div class="text-body-1">{{ selectedProposal.name }}</div>
                            </div>
                        </v-col>

                        <v-col cols="12" md="6">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">ジャンル</div>
                                <div class="text-body-1">{{ selectedProposal.genre || '-' }}</div>
                            </div>
                        </v-col>

                        <v-col cols="12">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">住所</div>
                                <div class="text-body-1">{{ selectedProposal.address || '-' }}</div>
                            </div>
                        </v-col>

                        <v-col cols="12">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">説明</div>
                                <div class="text-body-1">{{ selectedProposal.description || '-' }}</div>
                            </div>
                        </v-col>

                        <v-col cols="12" md="6">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">提案者</div>
                                <div class="text-body-1">
                                    {{ selectedProposal.user?.name || '-' }}
                                    <span v-if="selectedProposal.user?.username" class="text-medium-emphasis">
                                        (@{{ selectedProposal.user.username }})
                                    </span>
                                </div>
                            </div>
                        </v-col>

                        <v-col cols="12" md="6">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">提案日</div>
                                <div class="text-body-1">{{ formatDate(selectedProposal.created_at) }}</div>
                            </div>
                        </v-col>

                        <v-col v-if="selectedProposal.admin_notes" cols="12">
                            <div class="detail-item">
                                <div class="text-caption text-medium-emphasis">管理者メモ</div>
                                <div class="text-body-1">{{ selectedProposal.admin_notes }}</div>
                            </div>
                        </v-col>
                    </v-row>
                </v-card-text>

                <v-card-actions>
                    <v-spacer />
                    <v-btn @click="closeDetailDialog" color="primary" variant="flat">
                        閉じる
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </v-card>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useShopApi } from '@/composables/useShopApi'
import {
    ShopGenre,
    ProposalStatus,
    getGenreOptions,
    getGenreColor,
    type ShopProposal
} from '@/types/shop'

// Composables
const {
    proposals,
    loading,
    error,
    fetchProposals,
    approveProposal: approveProposalApi,
    rejectProposal: rejectProposalApi
} = useShopApi()

// Reactive state
const statusFilter = ref<ProposalStatus | ''>('')
const genreFilter = ref<ShopGenre | ''>('')
const searchQuery = ref('')
const selectedProposal = ref<ShopProposal | null>(null)
const adminNotes = ref('')
const processing = ref(false)

// Dialog states
const showApprovalDialog = ref(false)
const showRejectionDialog = ref(false)
const showDetailDialog = ref(false)

// Filter options
const statusFilterOptions = computed(() => [
    { title: '全ステータス', value: '' },
    { title: '承認待ち', value: ProposalStatus.PENDING },
    { title: '承認済み', value: ProposalStatus.APPROVED },
    { title: '却下', value: ProposalStatus.REJECTED }
])

const genreFilterOptions = computed(() => [
    { title: '全ジャンル', value: '' },
    ...getGenreOptions().map(option => ({
        title: option.label,
        value: option.value
    }))
])

// Filtered proposals
const filteredProposals = computed(() => {
    let filtered = proposals.value

    if (statusFilter.value) {
        filtered = filtered.filter(p => p.status === statusFilter.value)
    }

    if (genreFilter.value) {
        filtered = filtered.filter(p => p.genre === genreFilter.value)
    }

    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(p =>
            p.name.toLowerCase().includes(query) ||
            (p.description && p.description.toLowerCase().includes(query))
        )
    }

    return filtered
})

// Table headers
const headers = [
    { title: 'ID', key: 'id', sortable: true, width: '80px' },
    { title: '店舗名', key: 'name', sortable: true },
    { title: 'ジャンル', key: 'genre', sortable: true, width: '120px' },
    { title: 'ステータス', key: 'status', sortable: true, width: '120px' },
    { title: '提案者', key: 'user', sortable: false, width: '150px' },
    { title: '提案日', key: 'created_at', sortable: true, width: '120px' },
    { title: '操作', key: 'actions', sortable: false, width: '200px' }
]

// Validation rules
const rejectionNotesRules = [
    (v: string) => !!v.trim() || '却下理由は必須です',
    (v: string) => v.length <= 500 || '却下理由は500文字以内で入力してください'
]

// Helper functions
const getStatusColor = (status: ProposalStatus): string => {
    switch (status) {
        case ProposalStatus.PENDING:
            return 'warning'
        case ProposalStatus.APPROVED:
            return 'success'
        case ProposalStatus.REJECTED:
            return 'error'
        default:
            return 'grey'
    }
}

const getStatusText = (status: ProposalStatus): string => {
    switch (status) {
        case ProposalStatus.PENDING:
            return '承認待ち'
        case ProposalStatus.APPROVED:
            return '承認済み'
        case ProposalStatus.REJECTED:
            return '却下'
        default:
            return '不明'
    }
}

const truncateText = (text: string, maxLength: number): string => {
    if (text.length <= maxLength) return text
    return text.substring(0, maxLength) + '...'
}

const formatDate = (dateString: string): string => {
    return new Date(dateString).toLocaleDateString('ja-JP')
}

// Event handlers
const handleFilter = (): void => {
    // Filtering is handled by computed property
}

const handleSearch = (): void => {
    // Search is handled by computed property
}

const openApprovalDialog = (proposal: ShopProposal): void => {
    selectedProposal.value = proposal
    adminNotes.value = ''
    showApprovalDialog.value = true
}

const closeApprovalDialog = (): void => {
    showApprovalDialog.value = false
    selectedProposal.value = null
    adminNotes.value = ''
}

const openRejectionDialog = (proposal: ShopProposal): void => {
    selectedProposal.value = proposal
    adminNotes.value = ''
    showRejectionDialog.value = true
}

const closeRejectionDialog = (): void => {
    showRejectionDialog.value = false
    selectedProposal.value = null
    adminNotes.value = ''
}

const viewProposal = (proposal: ShopProposal): void => {
    selectedProposal.value = proposal
    showDetailDialog.value = true
}

const closeDetailDialog = (): void => {
    showDetailDialog.value = false
    selectedProposal.value = null
}

const approveProposal = async (): Promise<void> => {
    if (!selectedProposal.value) return

    try {
        processing.value = true
        const result = await approveProposalApi(selectedProposal.value.id)

        if (result) {
            closeApprovalDialog()
            // Refresh proposals list
            await fetchProposals()
        }
    } catch (err: any) {
        error.value = err.message || '提案の承認に失敗しました'
    } finally {
        processing.value = false
    }
}

const rejectProposal = async (): Promise<void> => {
    if (!selectedProposal.value || !adminNotes.value.trim()) return

    try {
        processing.value = true
        const success = await rejectProposalApi(selectedProposal.value.id, adminNotes.value)

        if (success) {
            closeRejectionDialog()
            // Refresh proposals list
            await fetchProposals()
        }
    } catch (err: any) {
        error.value = err.message || '提案の却下に失敗しました'
    } finally {
        processing.value = false
    }
}

// Lifecycle
onMounted(() => {
    fetchProposals()
})
</script>

<style scoped>
.shop-proposal-manager {
    width: 100%;
}

.proposal-info {
    min-width: 200px;
}

.user-info {
    min-width: 120px;
}

.detail-item {
    margin-bottom: 16px;
}

.detail-item:last-child {
    margin-bottom: 0;
}

.actions {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
}

/* Responsive design */
@media (max-width: 768px) {
    .actions {
        flex-direction: column;
        align-items: stretch;
    }

    .actions .v-btn {
        width: 100%;
    }
}

/* Data table customization */
.proposals-table :deep(.v-data-table__wrapper) {
    border-radius: 0;
}

.proposals-table :deep(.v-data-table-header) {
    background-color: rgb(var(--v-theme-surface));
}

.proposals-table :deep(.v-data-table-header th) {
    font-weight: 600;
    color: rgb(var(--v-theme-on-surface));
    font-size: 0.875rem;
}

.proposals-table :deep(.v-data-table__tr:hover) {
    background-color: rgba(var(--v-theme-primary), 0.04);
}
</style>