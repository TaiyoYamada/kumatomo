<template>
    <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="500px"
        persistent>
        <v-card v-if="proposal" class="proposal-action-dialog">
            <!-- Dialog Header -->
            <v-card-title class="dialog-header">
                <div class="header-content d-flex align-center">
                    <v-icon :color="action === 'approve' ? 'success' : 'error'" size="24" class="mr-3">
                        {{ action === 'approve' ? 'mdi-check-circle' : 'mdi-close-circle' }}
                    </v-icon>
                    <h2 class="text-h6 font-weight-bold">
                        {{ action === 'approve' ? '提案を承認' : '提案を却下' }}
                    </h2>
                </div>
            </v-card-title>

            <v-divider />

            <!-- Dialog Content -->
            <v-card-text class="dialog-content pa-6">
                <!-- Proposal Summary -->
                <div class="proposal-summary mb-4">
                    <h3 class="text-body-1 font-weight-medium mb-2">対象提案</h3>
                    <v-card variant="tonal" color="primary" class="proposal-card">
                        <v-card-text class="pa-4">
                            <div class="d-flex align-center justify-space-between">
                                <div>
                                    <div class="text-h6 font-weight-bold">{{ proposal.name }}</div>
                                    <div class="text-body-2 text-medium-emphasis">
                                        ID: #{{ proposal.id }}
                                    </div>
                                    <div v-if="proposal.address" class="text-body-2 text-medium-emphasis">
                                        {{ proposal.address }}
                                    </div>
                                </div>
                                <v-chip v-if="proposal.genre" :color="getGenreColor(proposal.genre)" variant="tonal"
                                    size="small">
                                    {{ proposal.genre }}
                                </v-chip>
                            </div>
                        </v-card-text>
                    </v-card>
                </div>

                <!-- Action Confirmation -->
                <div class="action-confirmation mb-4">
                    <v-alert :type="action === 'approve' ? 'success' : 'warning'" variant="tonal" class="mb-4">
                        <div class="alert-content">
                            <div class="text-body-1 font-weight-medium mb-2">
                                {{ action === 'approve' ? '承認の確認' : '却下の確認' }}
                            </div>
                            <div class="text-body-2">
                                <template v-if="action === 'approve'">
                                    この提案を承認すると、新しい店舗として登録されます。
                                    承認後は取り消すことができませんので、内容をよく確認してください。
                                </template>
                                <template v-else>
                                    この提案を却下すると、提案者に通知が送信されます。
                                    却下理由を明確に記載することをお勧めします。
                                </template>
                            </div>
                        </div>
                    </v-alert>
                </div>

                <!-- Admin Notes -->
                <div class="admin-notes">
                    <v-textarea v-model="adminNotes" :label="action === 'approve' ? '承認メモ（任意）' : '却下理由'" :placeholder="action === 'approve'
                        ? '承認に関するメモがあれば記入してください...'
                        : '却下理由を具体的に記入してください...'" variant="outlined" rows="4" :rules="action === 'reject' ? [requiredRule] : []"
                        :required="action === 'reject'" counter="500" maxlength="500" hide-details="auto" />
                    <div class="text-caption text-medium-emphasis mt-2">
                        <template v-if="action === 'approve'">
                            承認メモは提案者には表示されませんが、管理履歴として保存されます。
                        </template>
                        <template v-else>
                            却下理由は提案者に通知されます。建設的なフィードバックを心がけてください。
                        </template>
                    </div>
                </div>

                <!-- Additional Options for Approval -->
                <div v-if="action === 'approve'" class="approval-options mt-4">
                    <v-divider class="mb-4" />
                    <h3 class="text-body-1 font-weight-medium mb-3">承認オプション</h3>

                    <v-checkbox v-model="createShopImmediately" label="承認と同時に店舗を作成する" color="primary" hide-details />

                    <v-checkbox v-model="notifyUser" label="提案者に承認通知を送信する" color="primary" hide-details class="mt-2" />
                </div>
            </v-card-text>

            <v-divider />

            <!-- Dialog Actions -->
            <v-card-actions class="dialog-actions pa-6">
                <v-btn @click="$emit('update:modelValue', false)" variant="outlined" color="default"
                    :disabled="processing">
                    キャンセル
                </v-btn>

                <v-spacer />

                <v-btn @click="handleConfirm" :variant="action === 'approve' ? 'flat' : 'outlined'"
                    :color="action === 'approve' ? 'success' : 'error'" :loading="processing"
                    :disabled="action === 'reject' && !adminNotes.trim()">
                    <v-icon start>
                        {{ action === 'approve' ? 'mdi-check' : 'mdi-close' }}
                    </v-icon>
                    {{ action === 'approve' ? '承認する' : '却下する' }}
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { getGenreColor, type ShopProposal } from '@/types/shop'

// Props
interface Props {
    modelValue: boolean
    proposal: ShopProposal | null
    action: 'approve' | 'reject'
}

// Emits
interface Emits {
    (e: 'update:modelValue', value: boolean): void
    (e: 'confirm', data: {
        proposal: ShopProposal
        adminNotes?: string
        options?: {
            createShopImmediately?: boolean
            notifyUser?: boolean
        }
    }): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Reactive state
const processing = ref(false)
const adminNotes = ref('')
const createShopImmediately = ref(true)
const notifyUser = ref(true)

// Validation rules
const requiredRule = (value: string) => {
    return !!value?.trim() || '却下理由は必須です'
}

// Methods
const handleConfirm = () => {
    if (!props.proposal) return

    // Validate required fields
    if (props.action === 'reject' && !adminNotes.value.trim()) {
        return
    }

    processing.value = true

    const data = {
        proposal: props.proposal,
        adminNotes: adminNotes.value.trim() || undefined,
        ...(props.action === 'approve' && {
            options: {
                createShopImmediately: createShopImmediately.value,
                notifyUser: notifyUser.value
            }
        })
    }

    emit('confirm', data)

    // Reset processing state after a delay (will be handled by parent)
    setTimeout(() => {
        processing.value = false
    }, 1000)
}

const resetForm = () => {
    adminNotes.value = ''
    createShopImmediately.value = true
    notifyUser.value = true
    processing.value = false
}

// Watch for dialog close to reset form
watch(() => props.modelValue, (newValue) => {
    if (!newValue) {
        resetForm()
    }
})

// Watch for proposal change to reset form
watch(() => props.proposal, () => {
    resetForm()
})
</script>

<style scoped>
.proposal-action-dialog {
    border-radius: 12px;
}

.dialog-header {
    background: rgba(var(--v-theme-surface), 1);
    border-bottom: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
    padding: 1.5rem 2rem;
}

.header-content {
    width: 100%;
}

.dialog-content {
    max-height: 60vh;
    overflow-y: auto;
}

.proposal-summary {
    border-bottom: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
    padding-bottom: 1rem;
}

.proposal-card {
    border: 1px solid rgba(var(--v-theme-primary), 0.2);
}

.action-confirmation .alert-content {
    display: flex;
    flex-direction: column;
}

.admin-notes {
    margin-top: 1rem;
}

.approval-options {
    background: rgba(var(--v-theme-surface-variant), 0.3);
    padding: 1rem;
    border-radius: 8px;
}

.dialog-actions {
    background: rgba(var(--v-theme-surface), 1);
    border-top: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
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
        flex-direction: column;
        gap: 0.75rem;
    }

    .dialog-actions .v-spacer {
        display: none;
    }

    .dialog-actions .v-btn {
        width: 100%;
    }
}
</style>