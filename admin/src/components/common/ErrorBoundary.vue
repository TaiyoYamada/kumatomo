<template>
    <div>
        <slot v-if="!hasError" />

        <div v-else class="error-boundary">
            <v-card class="mx-auto" max-width="600">
                <v-card-title class="error-boundary__title">
                    <v-icon color="error" class="mr-2">mdi-alert-circle</v-icon>
                    予期しないエラーが発生しました
                </v-card-title>

                <v-card-text>
                    <div class="error-boundary__content">
                        <p class="mb-4">
                            申し訳ございませんが、アプリケーションでエラーが発生しました。
                            この問題は自動的に報告されます。
                        </p>

                        <v-expansion-panels v-if="showDetails" variant="accordion">
                            <v-expansion-panel>
                                <v-expansion-panel-title>
                                    <v-icon class="mr-2">mdi-information</v-icon>
                                    エラー詳細
                                </v-expansion-panel-title>
                                <v-expansion-panel-text>
                                    <div class="error-details">
                                        <div class="error-details__item">
                                            <strong>エラーメッセージ:</strong>
                                            <code>{{ errorInfo.message }}</code>
                                        </div>

                                        <div class="error-details__item">
                                            <strong>発生時刻:</strong>
                                            {{ formatTimestamp(errorInfo.timestamp) }}
                                        </div>

                                        <div class="error-details__item">
                                            <strong>エラーID:</strong>
                                            <code>{{ errorInfo.id }}</code>
                                        </div>

                                        <div v-if="errorInfo.componentStack" class="error-details__item">
                                            <strong>コンポーネントスタック:</strong>
                                            <pre class="error-stack">{{ errorInfo.componentStack }}</pre>
                                        </div>
                                    </div>
                                </v-expansion-panel-text>
                            </v-expansion-panel>
                        </v-expansion-panels>
                    </div>
                </v-card-text>

                <v-card-actions>
                    <v-btn color="primary" @click="handleReload" :loading="isReloading">
                        <v-icon class="mr-2">mdi-refresh</v-icon>
                        ページを再読み込み
                    </v-btn>

                    <v-btn color="secondary" @click="handleRetry" :disabled="!canRetry">
                        <v-icon class="mr-2">mdi-replay</v-icon>
                        再試行
                    </v-btn>

                    <v-spacer />

                    <v-btn variant="text" @click="showDetails = !showDetails">
                        {{ showDetails ? '詳細を隠す' : '詳細を表示' }}
                    </v-btn>
                </v-card-actions>
            </v-card>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onErrorCaptured, onMounted } from 'vue'
import type { ErrorBoundaryState } from '@/types/error'
import { useErrorHandler } from '@/composables/useErrorHandler'

interface Props {
    fallback?: string
    onError?: (error: Error, errorInfo: any) => void
    enableRetry?: boolean
    enableReporting?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    fallback: '',
    enableRetry: true,
    enableReporting: true
})

const emit = defineEmits<{
    error: [error: Error, errorInfo: any]
    retry: []
    reload: []
}>()

// State
const hasError = ref(false)
const showDetails = ref(false)
const isReloading = ref(false)
const canRetry = ref(true)
const retryCount = ref(0)
const maxRetries = 3

const errorInfo = ref({
    id: '',
    message: '',
    timestamp: new Date(),
    componentStack: '',
    errorBoundary: true
})

const { handleError } = useErrorHandler()

// Error capture
onErrorCaptured((error: Error, instance, info: string) => {
    console.error('Error captured by ErrorBoundary:', error)

    hasError.value = true
    canRetry.value = retryCount.value < maxRetries

    errorInfo.value = {
        id: crypto.randomUUID(),
        message: error.message || 'Unknown error',
        timestamp: new Date(),
        componentStack: info,
        errorBoundary: true
    }

    // Handle error through error service
    const appError = handleError(error, 'Error Boundary')

    // Call custom error handler if provided
    if (props.onError) {
        props.onError(error, errorInfo.value)
    }

    // Emit error event
    emit('error', error, errorInfo.value)

    // Report error if enabled
    if (props.enableReporting) {
        reportError(error, errorInfo.value)
    }

    // Prevent the error from propagating
    return false
})

// Methods
const handleRetry = (): void => {
    if (!canRetry.value) return

    retryCount.value++
    hasError.value = false
    canRetry.value = retryCount.value < maxRetries

    emit('retry')

    // Reset error state after a short delay to allow component re-render
    setTimeout(() => {
        if (hasError.value) {
            canRetry.value = false
        }
    }, 1000)
}

const handleReload = (): void => {
    isReloading.value = true

    emit('reload')

    // Reload the page after a short delay
    setTimeout(() => {
        window.location.reload()
    }, 500)
}

const formatTimestamp = (timestamp: Date): string => {
    return new Intl.DateTimeFormat('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    }).format(timestamp)
}

const reportError = (error: Error, info: any): void => {
    // Implementation for error reporting
    // This could send to Sentry, LogRocket, or custom endpoint

    const errorReport = {
        message: error.message,
        stack: error.stack,
        componentStack: info.componentStack,
        timestamp: info.timestamp,
        userAgent: navigator.userAgent,
        url: window.location.href,
        userId: localStorage.getItem('userId'), // If available
        sessionId: sessionStorage.getItem('sessionId') // If available
    }

    console.log('Error report:', errorReport)

    // Send to reporting service
    // fetch('/api/errors', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify(errorReport)
    // }).catch(console.error)
}

// Reset error state when component is mounted
onMounted(() => {
    hasError.value = false
    retryCount.value = 0
    canRetry.value = true
})
</script>

<style scoped>
.error-boundary {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 400px;
    padding: 20px;
}

.error-boundary__title {
    color: rgb(var(--v-theme-error));
    font-weight: 600;
}

.error-boundary__content {
    text-align: left;
}

.error-details {
    font-family: monospace;
    font-size: 0.875rem;
}

.error-details__item {
    margin-bottom: 12px;
    padding: 8px;
    background-color: rgb(var(--v-theme-surface-variant));
    border-radius: 4px;
}

.error-details__item strong {
    display: block;
    margin-bottom: 4px;
    color: rgb(var(--v-theme-on-surface));
}

.error-details__item code {
    background-color: rgb(var(--v-theme-surface));
    padding: 2px 4px;
    border-radius: 2px;
    font-size: 0.8rem;
}

.error-stack {
    background-color: rgb(var(--v-theme-surface));
    padding: 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    line-height: 1.4;
    overflow-x: auto;
    white-space: pre-wrap;
    word-break: break-all;
}
</style>