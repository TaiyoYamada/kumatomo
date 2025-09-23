<template>
    <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="800px"
        persistent>
        <v-card v-if="proposal" class="proposal-details-dialog">
            <!-- Dialog Header -->
            <v-card-title class="dialog-header d-flex align-center justify-space-between">
                <div class="header-content">
                    <h2 class="text-h5 font-weight-bold">提案詳細</h2>
                    <v-chip :color="getStatusColor(proposal.status)" variant="tonal" size="small" class="ml-3">
                        <v-icon start size="16">{{ getStatusIcon(proposal.status) }}</v-icon>
                        {{ getStatusText(proposal.status) }}
                    </v-chip>
                </div>
                <v-btn @click="$emit('update:modelValue', false)" variant="text" icon="mdi-close" size="small" />
            </v-card-title>

            <v-divider />

            <!-- Dialog Content -->
            <v-card-text class="dialog-content pa-6">
                <div class="details-grid">
                    <!-- Basic Information -->
                    <div class="info-section">
                        <h3 class="section-title text-h6 font-weight-medium mb-4">基本情報</h3>
                        <div class="info-grid">
                            <div class="info-item">
                                <label class="info-label text-body-2 font-weight-medium">提案ID</label>
                                <div class="info-value text-body-1">#{{ proposal.id }}</div>
                            </div>

                            <div class="info-item">
                                <label class="info-label text-body-2 font-weight-medium">店舗名</label>
                                <div class="info-value text-body-1 font-weight-medium">{{ proposal.name }}</div>
                            </div>

                            <div class="info-item">
                                <label class="info-label text-body-2 font-weight-medium">ジャンル</label>
                                <div class="info-value">
                                    <v-chip v-if="proposal.genre" :color="getGenreColor(proposal.genre)" variant="tonal"
                                        size="small">
                                        {{ proposal.genre }}
                                    </v-chip>
                                    <span v-else class="text-medium-emphasis">未設定</span>
                                </div>
                            </div>

                            <div class="info-item">
                                <label class="info-label text-body-2 font-weight-medium">住所</label>
                                <div class="info-value text-body-1">
                                    {{ proposal.address || '未設定' }}
                                </div>
                            </div>

                            <div class="info-item full-width">
                                <label class="info-label text-body-2 font-weight-medium">説明</label>
                                <div class="info-value text-body-1">
                                    <div v-if="proposal.description" class="description-text">
                                        {{ proposal.description }}
                                    </div>
                                    <span v-else class="text-medium-emphasis">説明なし</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- User Information -->
                    <div class="info-section">
                        <h3 class="section-title text-h6 font-weight-medium mb-4">提案者情報</h3>
                        <div class="user-card">
                            <v-avatar color="primary" size="48" class="mr-4">
                                <v-icon color="white">mdi-account</v-icon>
                            </v-avatar>
                            <div class="user-details">
                                <div v-if="proposal.user">
                                    <div class="text-body-1 font-weight-medium">{{ proposal.user.name }}</div>
                                    <div class="text-body-2 text-medium-emphasis">@{{ proposal.user.username }}</div>
                                    <div class="text-body-2 text-medium-emphasis">{{ proposal.user.email }}</div>
                                </div>
                                <div v-else class="text-medium-emphasis">
                                    ユーザー情報が取得できません
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Timeline Information -->
                    <div class="info-section">
                        <h3 class="section-title text-h6 font-weight-medium mb-4">タイムライン</h3>
                        <div class="timeline">
                            <div class="timeline-item">
                                <v-icon color="primary" class="timeline-icon">mdi-plus-circle</v-icon>
                                <div class="timeline-content">
                                    <div class="timeline-title text-body-1 font-weight-medium">提案作成</div>
                                    <div class="timeline-date text-body-2 text-medium-emphasis">
                                        {{ formatDateTime(proposal.created_at) }}
                                    </div>
                                </div>
                            </div>

                            <div v-if="proposal.updated_at !== proposal.created_at" class="timeline-item">
                                <v-icon color="info" class="timeline-icon">mdi-pencil-circle</v-icon>
                                <div class="timeline-content">
                                    <div class="timeline-title text-body-1 font-weight-medium">最終更新</div>
                                    <div class="timeline-date text-body-2 text-medium-emphasis">
                                        {{ formatDateTime(proposal.updated_at) }}
                                    </div>
                                </div>
                            </div>

                            <div v-if="proposal.status !== ProposalStatus.PENDING" class="timeline-item">
                                <v-icon :color="proposal.status === ProposalStatus.APPROVED ? 'success' : 'error'"
                                    class="timeline-icon">
                                    {{ proposal.status === ProposalStatus.APPROVED ? 'mdi-check-circle' :
                                    'mdi-close-circle' }}
                                </v-icon>
                                <div class="timeline-content">
                                    <div class="timeline-title text-body-1 font-weight-medium">
                                        {{ proposal.status === ProposalStatus.APPROVED ? '承認' : '却下' }}
                                    </div>
                                    <div class="timeline-date text-body-2 text-medium-emphasis">
                                        {{ formatDateTime(proposal.updated_at) }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Admin Notes -->
                    <div v-if="proposal.admin_notes" class="info-section">
                        <h3 class="section-title text-h6 font-weight-medium mb-4">管理者メモ</h3>
                        <v-card variant="tonal" color="info" class="admin-notes">
                            <v-card-text>
                                <div class="text-body-1">{{ proposal.admin_notes }}</div>
                            </v-card-text>
                        </v-card>
                    </div>
                </div>
            </v-card-text>

            <v-divider />

            <!-- Dialog Actions -->
            <v-card-actions class="dialog-actions pa-6">
                <v-spacer />

                <!-- Action buttons for pending proposals -->
                <div v-if="proposal.status === ProposalStatus.PENDING" class="action-buttons d-flex gap-3">
                    <v-btn @click="handleReject" variant="outlined" color="error" :loading="processing">
                        <v-icon start>mdi-close</v-icon>
                        却下
                    </v-btn>

                    <v-btn @click="handleApprove" variant="flat" color="success" :loading="processing">
                        <v-icon start>mdi-check</v-icon>
                        承認
                    </v-btn>
                </div>

                <!-- Close button for processed proposals -->
                <v-btn v-else @click="$emit('update:modelValue', false)" variant="outlined" color="primary">
                    閉じる
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ProposalStatus, getGenreColor, type ShopProposal } from '@/types/shop'

// Props
interface Props {
    modelValue: boolean
    proposal: ShopProposal | null
}

// Emits
interface Emits {
    (e: 'update:modelValue', value: boolean): void
    (e: 'approve', data: { proposal: ShopProposal; adminNotes?: string }): void
    (e: 'reject', data: { proposal: ShopProposal; adminNotes?: string }): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Reactive state
const processing = ref(false)

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
const formatDateTime = (dateString: string): string => {
    const date = new Date(dateString)
    return date.toLocaleString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    })
}

// Action handlers
const handleApprove = () => {
    if (!props.proposal) return

    emit('approve', {
        proposal: props.proposal
    })
}

const handleReject = () => {
    if (!props.proposal) return

    emit('reject', {
        proposal: props.proposal
    })
}
</script>

<style scoped>
.proposal-details-dialog {
    border-radius: 12px;
}

.dialog-header {
    background: rgba(var(--v-theme-surface), 1);
    border-bottom: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
    padding: 1.5rem 2rem;
}

.header-content {
    display: flex;
    align-items: center;
}

.dialog-content {
    max-height: 70vh;
    overflow-y: auto;
}

.details-grid {
    display: flex;
    flex-direction: column;
    gap: 2rem;
}

.info-section {
    display: flex;
    flex-direction: column;
}

.section-title {
    color: rgba(var(--v-theme-on-surface), 0.87);
    border-bottom: 2px solid rgba(var(--v-theme-primary), 0.2);
    padding-bottom: 0.5rem;
}

.info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-top: 1rem;
}

.info-item {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.info-item.full-width {
    grid-column: 1 / -1;
}

.info-label {
    color: rgba(var(--v-theme-on-surface), 0.6);
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.info-value {
    color: rgba(var(--v-theme-on-surface), 0.87);
}

.description-text {
    background: rgba(var(--v-theme-surface-variant), 0.5);
    padding: 1rem;
    border-radius: 8px;
    border-left: 4px solid rgba(var(--v-theme-primary), 0.5);
}

.user-card {
    display: flex;
    align-items: center;
    padding: 1rem;
    background: rgba(var(--v-theme-surface-variant), 0.3);
    border-radius: 8px;
    margin-top: 1rem;
}

.user-details {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
}

.timeline {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-top: 1rem;
}

.timeline-item {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.timeline-icon {
    flex-shrink: 0;
}

.timeline-content {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
}

.admin-notes {
    margin-top: 1rem;
}

.dialog-actions {
    background: rgba(var(--v-theme-surface), 1);
    border-top: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
}

.action-buttons {
    display: flex;
    gap: 0.75rem;
}

/* Responsive design */
@media (max-width: 600px) {
    .dialog-header {
        padding: 1rem;
    }

    .dialog-content {
        padding: 1rem !important;
    }

    .dialog-actions {
        padding: 1rem !important;
    }

    .info-grid {
        grid-template-columns: 1fr;
    }

    .user-card {
        flex-direction: column;
        text-align: center;
        gap: 1rem;
    }

    .action-buttons {
        flex-direction: column;
        width: 100%;
    }
}
</style>