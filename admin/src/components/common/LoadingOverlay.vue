<template>
    <div v-if="show" class="loading-overlay" :class="overlayClasses">
        <div class="loading-overlay__backdrop" @click="handleBackdropClick" />

        <div class="loading-overlay__content" :class="contentClasses">
            <!-- Loading Animation -->
            <div class="loading-animation">
                <v-progress-circular v-if="!operation?.progress" :size="size" :width="4" color="primary"
                    indeterminate />

                <v-progress-circular v-else :size="size" :width="4" :model-value="operation.progress" color="primary">
                    <span class="progress-text">
                        {{ Math.round(operation.progress || 0) }}%
                    </span>
                </v-progress-circular>
            </div>

            <!-- Content -->
            <div class="loading-content">
                <h3 class="loading-title">
                    {{ operation?.name || title }}
                </h3>

                <p v-if="operation?.description || message" class="loading-message">
                    {{ operation?.description || message }}
                </p>

                <div v-if="showDetails && operation" class="loading-details">
                    <div class="detail-item">
                        <span class="detail-label">状態:</span>
                        <v-chip :color="stateColor" size="small">
                            {{ stateText }}
                        </v-chip>
                    </div>

                    <div v-if="operation.startTime" class="detail-item">
                        <span class="detail-label">経過時間:</span>
                        <span class="detail-value">{{ elapsedTime }}</span>
                    </div>

                    <div class="detail-item">
                        <span class="detail-label">優先度:</span>
                        <v-chip :color="priorityColor" size="small">
                            {{ priorityText }}
                        </v-chip>
                    </div>
                </div>

                <!-- Actions -->
                <div v-if="showActions" class="loading-actions">
                    <v-btn v-if="operation?.isCancellable && !operation.error" variant="outlined" size="small"
                        @click="handleCancel">
                        <v-icon class="mr-1">mdi-close</v-icon>
                        キャンセル
                    </v-btn>

                    <v-btn v-if="operation?.error" color="error" variant="outlined" size="small" @click="handleRetry">
                        <v-icon class="mr-1">mdi-refresh</v-icon>
                        再試行
                    </v-btn>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import type { LoadingOperation, LoadingState } from '@/types/error'
import { useLoadingState } from '@/composables/useErrorHandler'

interface Props {
    show: boolean
    operation?: LoadingOperation
    title?: string
    message?: string
    size?: number
    persistent?: boolean
    showDetails?: boolean
    showActions?: boolean
    variant?: 'overlay' | 'inline' | 'modal'
}

const props = withDefaults(defineProps<Props>(), {
    title: '読み込み中...',
    message: '',
    size: 60,
    persistent: false,
    showDetails: false,
    showActions: true,
    variant: 'overlay'
})

const emit = defineEmits<{
    cancel: []
    retry: []
    backdropClick: []
}>()

// Composables
const { cancelLoading } = useLoadingState()

// State
const elapsedSeconds = ref(0)
let intervalId: number | null = null

// Computed
const overlayClasses = computed(() => ({
    'loading-overlay--persistent': props.persistent,
    'loading-overlay--modal': props.variant === 'modal',
    'loading-overlay--inline': props.variant === 'inline'
}))

const contentClasses = computed(() => ({
    'loading-overlay__content--error': props.operation?.error,
    'loading-overlay__content--success': props.operation?.state === 'success',
    [`loading-overlay__content--${props.operation?.priority}`]: props.operation?.priority
}))

const stateColor = computed(() => {
    if (!props.operation) return 'primary'

    switch (props.operation.state) {
        case 'loading':
            return 'primary'
        case 'success':
            return 'success'
        case 'error':
            return 'error'
        default:
            return 'primary'
    }
})

const stateText = computed(() => {
    if (!props.operation) return '読み込み中'

    switch (props.operation.state) {
        case 'loading':
            return '処理中'
        case 'success':
            return '完了'
        case 'error':
            return 'エラー'
        default:
            return '待機中'
    }
})

const priorityColor = computed(() => {
    if (!props.operation) return 'default'

    switch (props.operation.priority) {
        case 'low':
            return 'grey'
        case 'normal':
            return 'blue'
        case 'high':
            return 'orange'
        case 'critical':
            return 'red'
        default:
            return 'default'
    }
})

const priorityText = computed(() => {
    if (!props.operation) return '通常'

    switch (props.operation.priority) {
        case 'low':
            return '低'
        case 'normal':
            return '通常'
        case 'high':
            return '高'
        case 'critical':
            return '緊急'
        default:
            return '通常'
    }
})

const elapsedTime = computed(() => {
    const seconds = elapsedSeconds.value
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60

    if (minutes > 0) {
        return `${minutes}分${remainingSeconds}秒`
    }
    return `${seconds}秒`
})

// Methods
const handleCancel = (): void => {
    if (props.operation?.id) {
        cancelLoading(props.operation.id)
    }
    emit('cancel')
}

const handleRetry = (): void => {
    emit('retry')
}

const handleBackdropClick = (): void => {
    if (!props.persistent) {
        emit('backdropClick')
    }
}

const startTimer = (): void => {
    if (intervalId) return

    intervalId = window.setInterval(() => {
        if (props.operation?.startTime) {
            elapsedSeconds.value = Math.floor(
                (Date.now() - props.operation.startTime.getTime()) / 1000
            )
        } else {
            elapsedSeconds.value++
        }
    }, 1000)
}

const stopTimer = (): void => {
    if (intervalId) {
        clearInterval(intervalId)
        intervalId = null
    }
}

// Lifecycle
onMounted(() => {
    if (props.show) {
        startTimer()
    }
})

onUnmounted(() => {
    stopTimer()
})

// Watch for show prop changes
watch(() => props.show, (newShow) => {
    if (newShow) {
        startTimer()
    } else {
        stopTimer()
        elapsedSeconds.value = 0
    }
})
</script>

<style scoped>
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
}

.loading-overlay--inline {
    position: relative;
    min-height: 200px;
}

.loading-overlay--modal {
    z-index: 10000;
}

.loading-overlay__backdrop {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(2px);
}

.loading-overlay--inline .loading-overlay__backdrop {
    background-color: rgba(var(--v-theme-surface), 0.8);
}

.loading-overlay__content {
    position: relative;
    background: rgb(var(--v-theme-surface));
    border-radius: 12px;
    padding: 32px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
    max-width: 400px;
    width: 90%;
    text-align: center;
    transition: all 0.3s ease;
}

.loading-overlay--inline .loading-overlay__content {
    box-shadow: none;
    background: transparent;
}

.loading-overlay__content--error {
    border-left: 4px solid rgb(var(--v-theme-error));
}

.loading-overlay__content--success {
    border-left: 4px solid rgb(var(--v-theme-success));
}

.loading-overlay__content--critical {
    border: 2px solid rgb(var(--v-theme-error));
    animation: pulse 2s infinite;
}

@keyframes pulse {

    0%,
    100% {
        border-color: rgb(var(--v-theme-error));
    }

    50% {
        border-color: rgba(var(--v-theme-error), 0.5);
    }
}

.loading-animation {
    margin-bottom: 24px;
}

.progress-text {
    font-size: 0.875rem;
    font-weight: 600;
    color: rgb(var(--v-theme-primary));
}

.loading-content {
    display: flex;
    flex-direction: column;
    gap: 16px;
}

.loading-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: rgb(var(--v-theme-on-surface));
    margin: 0;
}

.loading-message {
    font-size: 0.875rem;
    color: rgb(var(--v-theme-on-surface-variant));
    margin: 0;
    line-height: 1.5;
}

.loading-details {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 16px;
    background: rgb(var(--v-theme-surface-variant));
    border-radius: 8px;
    font-size: 0.875rem;
}

.detail-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.detail-label {
    font-weight: 500;
    color: rgb(var(--v-theme-on-surface-variant));
}

.detail-value {
    font-family: monospace;
    color: rgb(var(--v-theme-on-surface));
}

.loading-actions {
    display: flex;
    gap: 12px;
    justify-content: center;
    margin-top: 8px;
}

/* Responsive design */
@media (max-width: 600px) {
    .loading-overlay__content {
        padding: 24px;
        margin: 16px;
    }

    .loading-title {
        font-size: 1.125rem;
    }

    .loading-message {
        font-size: 0.8125rem;
    }
}
</style>