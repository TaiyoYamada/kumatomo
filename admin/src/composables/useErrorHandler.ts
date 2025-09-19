import { ref, computed, onMounted, onUnmounted } from 'vue'
import type {
    AppError,
    ErrorType,
    ErrorNotification,
    LoadingOperation,
    ErrorFilterOptions,
    RetryConfig
} from '@/types/error'
import { errorHandlerService } from '@/services/errorHandlerService'
import { isRetryableError } from '@/types/error'

export function useErrorHandler() {
    // Reactive state
    const isOnline = computed(() => errorHandlerService.isOnline)
    const hasErrors = computed(() => errorHandlerService.hasErrors)
    const hasNotifications = computed(() => errorHandlerService.hasNotifications)
    const isLoading = computed(() => errorHandlerService.isLoading)
    const errors = computed(() => errorHandlerService.getErrors())
    const notifications = computed(() => errorHandlerService.notifications)
    const statistics = computed(() => errorHandlerService.statistics)
    const networkInfo = computed(() => errorHandlerService.networkInfo)
    const loadingOperations = computed(() => errorHandlerService.loadingOperationsArray)

    // Methods
    const handleError = (error: any, context?: string): AppError => {
        return errorHandlerService.handleError(error, context)
    }

    const clearErrors = (): void => {
        errorHandlerService.clearErrors()
    }

    const dismissNotification = (id: string): void => {
        errorHandlerService.dismissNotification(id)
    }

    const retryOperation = (errorId: string): void => {
        errorHandlerService.retryLastOperation(errorId)
    }

    const showErrorDetails = (error: AppError): void => {
        errorHandlerService.showErrorDetails(error)
    }

    const getFilteredErrors = (filter: ErrorFilterOptions): AppError[] => {
        return errorHandlerService.getErrors(filter)
    }

    return {
        // State
        isOnline,
        hasErrors,
        hasNotifications,
        isLoading,
        errors,
        notifications,
        statistics,
        networkInfo,
        loadingOperations,

        // Methods
        handleError,
        clearErrors,
        dismissNotification,
        retryOperation,
        showErrorDetails,
        getFilteredErrors
    }
}

export function useLoadingState() {
    const startLoading = (
        id: string,
        name: string,
        description?: string,
        options?: {
            isCancellable?: boolean
            priority?: 'low' | 'normal' | 'high' | 'critical'
        }
    ): void => {
        errorHandlerService.startLoading(id, name, description, options)
    }

    const updateProgress = (id: string, progress: number): void => {
        errorHandlerService.updateLoadingProgress(id, progress)
    }

    const completeLoading = (id: string, result?: any): void => {
        errorHandlerService.completeLoading(id, result)
    }

    const failLoading = (id: string, error: AppError): void => {
        errorHandlerService.failLoading(id, error)
    }

    const cancelLoading = (id: string): void => {
        errorHandlerService.cancelLoading(id)
    }

    const isOperationLoading = (id: string): boolean => {
        return errorHandlerService.loadingOperationsArray.some(op => op.id === id)
    }

    const getLoadingOperation = (id: string): LoadingOperation | undefined => {
        return errorHandlerService.loadingOperationsArray.find(op => op.id === id)
    }

    return {
        startLoading,
        updateProgress,
        completeLoading,
        failLoading,
        cancelLoading,
        isOperationLoading,
        getLoadingOperation
    }
}

export function useAsyncOperation<T = any>() {
    const loading = ref(false)
    const error = ref<AppError | null>(null)
    const data = ref<T | null>(null)

    const execute = async (
        operation: () => Promise<T>,
        options?: {
            loadingId?: string
            loadingName?: string
            context?: string
            showNotification?: boolean
        }
    ): Promise<T | null> => {
        loading.value = true
        error.value = null

        const loadingId = options?.loadingId || crypto.randomUUID()

        if (options?.loadingName) {
            errorHandlerService.startLoading(loadingId, options.loadingName)
        }

        try {
            const result = await operation()
            data.value = result

            if (options?.loadingName) {
                errorHandlerService.completeLoading(loadingId, result)
            }

            return result
        } catch (err) {
            const appError = errorHandlerService.handleError(err, options?.context)
            error.value = appError

            if (options?.loadingName) {
                errorHandlerService.failLoading(loadingId, appError)
            }

            return null
        } finally {
            loading.value = false
        }
    }

    const retry = async (): Promise<T | null> => {
        if (error.value && isRetryableError(error.value)) {
            error.value = null
            // Note: This would need the original operation to be stored
            // Implementation depends on specific use case
        }
        return null
    }

    const reset = (): void => {
        loading.value = false
        error.value = null
        data.value = null
    }

    return {
        loading: computed(() => loading.value),
        error: computed(() => error.value),
        data: computed(() => data.value),
        execute,
        retry,
        reset
    }
}

export function useFormErrorHandler() {
    const fieldErrors = ref<Record<string, string>>({})
    const globalError = ref<string>('')
    const isSubmitting = ref(false)

    const handleFormError = (error: any): void => {
        if (error.response?.status === 422) {
            // Handle validation errors
            const validationErrors = error.response.data.errors || {}

            fieldErrors.value = {}
            Object.keys(validationErrors).forEach(field => {
                const messages = validationErrors[field]
                fieldErrors.value[field] = Array.isArray(messages) ? messages[0] : messages
            })

            globalError.value = error.response.data.message || '入力内容に問題があります'
        } else {
            // Handle other errors
            const appError = errorHandlerService.handleError(error, 'Form submission')
            globalError.value = appError.userFriendlyMessage || appError.message
        }
    }

    const clearFieldError = (field: string): void => {
        delete fieldErrors.value[field]
    }

    const clearAllErrors = (): void => {
        fieldErrors.value = {}
        globalError.value = ''
    }

    const hasFieldError = (field: string): boolean => {
        return !!fieldErrors.value[field]
    }

    const getFieldError = (field: string): string => {
        return fieldErrors.value[field] || ''
    }

    const hasErrors = computed(() => {
        return Object.keys(fieldErrors.value).length > 0 || !!globalError.value
    })

    return {
        fieldErrors: computed(() => fieldErrors.value),
        globalError: computed(() => globalError.value),
        isSubmitting: computed(() => isSubmitting.value),
        hasErrors,
        handleFormError,
        clearFieldError,
        clearAllErrors,
        hasFieldError,
        getFieldError,
        setSubmitting: (value: boolean) => { isSubmitting.value = value }
    }
}

export function useRetryableOperation<T = any>() {
    const { execute } = useAsyncOperation<T>()
    const retryCount = ref(0)
    const maxRetries = ref(3)
    const retryDelay = ref(1000)

    let lastOperation: (() => Promise<T>) | null = null
    let lastOptions: any = null

    const executeWithRetry = async (
        operation: () => Promise<T>,
        options?: {
            maxRetries?: number
            retryDelay?: number
            backoffMultiplier?: number
            context?: string
        }
    ): Promise<T | null> => {
        lastOperation = operation
        lastOptions = options

        maxRetries.value = options?.maxRetries || 3
        retryDelay.value = options?.retryDelay || 1000
        retryCount.value = 0

        return await attemptOperation()
    }

    const attemptOperation = async (): Promise<T | null> => {
        if (!lastOperation) return null

        try {
            const result = await execute(lastOperation, {
                context: lastOptions?.context,
                loadingName: retryCount.value > 0 ? `再試行中 (${retryCount.value}/${maxRetries.value})` : undefined
            })

            retryCount.value = 0
            return result
        } catch (error) {
            retryCount.value++

            if (retryCount.value < maxRetries.value) {
                const delay = retryDelay.value * Math.pow(lastOptions?.backoffMultiplier || 2, retryCount.value - 1)

                await new Promise(resolve => setTimeout(resolve, delay))
                return await attemptOperation()
            }

            throw error
        }
    }

    const retry = async (): Promise<T | null> => {
        if (lastOperation && retryCount.value < maxRetries.value) {
            return await attemptOperation()
        }
        return null
    }

    const canRetry = computed(() => {
        return lastOperation !== null && retryCount.value < maxRetries.value
    })

    return {
        executeWithRetry,
        retry,
        canRetry,
        retryCount: computed(() => retryCount.value),
        maxRetries: computed(() => maxRetries.value)
    }
}

export function useNetworkStatus() {
    const isOnline = computed(() => errorHandlerService.isOnline)
    const networkInfo = computed(() => errorHandlerService.networkInfo)

    const isSlowConnection = computed(() => {
        const info = networkInfo.value
        return info.effectiveType === '2g' || info.effectiveType === '3g' ||
            (info.downlink !== undefined && info.downlink < 1)
    })

    const shouldLimitData = computed(() => {
        return networkInfo.value.saveData || isSlowConnection.value
    })

    return {
        isOnline,
        networkInfo,
        isSlowConnection,
        shouldLimitData
    }
}