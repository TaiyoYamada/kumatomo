// Network status monitoring
let isOnline = navigator.onLine
let networkListeners = []

// Listen for network status changes
window.addEventListener('online', () => {
    isOnline = true
    networkListeners.forEach(listener => listener(true))
})

window.addEventListener('offline', () => {
    isOnline = false
    networkListeners.forEach(listener => listener(false))
})

// Error types and codes
export const ERROR_TYPES = {
    NETWORK_ERROR: 'NETWORK_ERROR',
    VALIDATION_ERROR: 'VALIDATION_ERROR',
    AUTHENTICATION_ERROR: 'AUTHENTICATION_ERROR',
    AUTHORIZATION_ERROR: 'AUTHORIZATION_ERROR',
    NOT_FOUND_ERROR: 'NOT_FOUND_ERROR',
    SERVER_ERROR: 'SERVER_ERROR',
    TIMEOUT_ERROR: 'TIMEOUT_ERROR',
    OFFLINE_ERROR: 'OFFLINE_ERROR',
    UNKNOWN_ERROR: 'UNKNOWN_ERROR'
}

// User-friendly error messages
const ERROR_MESSAGES = {
    [ERROR_TYPES.NETWORK_ERROR]: 'ネットワークエラーが発生しました',
    [ERROR_TYPES.VALIDATION_ERROR]: '入力データに問題があります',
    [ERROR_TYPES.AUTHENTICATION_ERROR]: '認証が必要です',
    [ERROR_TYPES.AUTHORIZATION_ERROR]: 'アクセス権限がありません',
    [ERROR_TYPES.NOT_FOUND_ERROR]: 'リソースが見つかりません',
    [ERROR_TYPES.SERVER_ERROR]: 'サーバーエラーが発生しました',
    [ERROR_TYPES.TIMEOUT_ERROR]: 'リクエストがタイムアウトしました',
    [ERROR_TYPES.OFFLINE_ERROR]: 'インターネット接続がありません',
    [ERROR_TYPES.UNKNOWN_ERROR]: '予期しないエラーが発生しました'
}

// Recovery suggestions
const RECOVERY_SUGGESTIONS = {
    [ERROR_TYPES.NETWORK_ERROR]: 'ネットワーク接続を確認してください',
    [ERROR_TYPES.VALIDATION_ERROR]: '入力内容を確認して再試行してください',
    [ERROR_TYPES.AUTHENTICATION_ERROR]: 'ログインし直してください',
    [ERROR_TYPES.AUTHORIZATION_ERROR]: '管理者に連絡してください',
    [ERROR_TYPES.NOT_FOUND_ERROR]: 'リソースが削除されている可能性があります',
    [ERROR_TYPES.SERVER_ERROR]: 'しばらく時間をおいてから再試行してください',
    [ERROR_TYPES.TIMEOUT_ERROR]: '通信環境を確認して再試行してください',
    [ERROR_TYPES.OFFLINE_ERROR]: 'インターネット接続を確認してください',
    [ERROR_TYPES.UNKNOWN_ERROR]: 'ページを再読み込みしてください'
}

// Retryable error types
const RETRYABLE_ERRORS = [
    ERROR_TYPES.NETWORK_ERROR,
    ERROR_TYPES.SERVER_ERROR,
    ERROR_TYPES.TIMEOUT_ERROR
]

export const getErrorType = (error) => {
    // Check if offline
    if (!isOnline) {
        return ERROR_TYPES.OFFLINE_ERROR
    }

    if (error.response) {
        const { status } = error.response

        switch (status) {
            case 401:
                return ERROR_TYPES.AUTHENTICATION_ERROR
            case 403:
                return ERROR_TYPES.AUTHORIZATION_ERROR
            case 404:
                return ERROR_TYPES.NOT_FOUND_ERROR
            case 422:
                return ERROR_TYPES.VALIDATION_ERROR
            case 408:
            case 504:
                return ERROR_TYPES.TIMEOUT_ERROR
            case 500:
            case 502:
            case 503:
                return ERROR_TYPES.SERVER_ERROR
            default:
                return ERROR_TYPES.UNKNOWN_ERROR
        }
    } else if (error.request) {
        // Network error
        if (error.code === 'ECONNABORTED') {
            return ERROR_TYPES.TIMEOUT_ERROR
        }
        return ERROR_TYPES.NETWORK_ERROR
    } else {
        return ERROR_TYPES.UNKNOWN_ERROR
    }
}

export const getErrorMessage = (error) => {
    // Check for offline status first
    if (!isOnline) {
        return ERROR_MESSAGES[ERROR_TYPES.OFFLINE_ERROR]
    }

    if (error.response) {
        const { status, data } = error.response

        // Handle structured error response from API
        if (data && data.error) {
            return data.error.message || ERROR_MESSAGES[getErrorType(error)]
        }

        // Handle validation errors
        if (status === 422 && data.errors) {
            const firstError = Object.values(data.errors)[0]
            return Array.isArray(firstError) ? firstError[0] : firstError
        }

        // Handle other data messages
        if (data.message) {
            return data.message
        }

        // Fallback to status-based messages
        return ERROR_MESSAGES[getErrorType(error)]
    }

    const errorType = getErrorType(error)
    return ERROR_MESSAGES[errorType]
}

export const getRecoverySuggestion = (error) => {
    const errorType = getErrorType(error)
    return RECOVERY_SUGGESTIONS[errorType]
}

export const isRetryableError = (error) => {
    const errorType = getErrorType(error)
    return RETRYABLE_ERRORS.includes(errorType)
}

export const getRetryDelay = (error, attempt = 1) => {
    const errorType = getErrorType(error)
    const baseDelay = {
        [ERROR_TYPES.NETWORK_ERROR]: 2000,
        [ERROR_TYPES.SERVER_ERROR]: 5000,
        [ERROR_TYPES.TIMEOUT_ERROR]: 3000
    }[errorType] || 2000

    // Exponential backoff with jitter
    return baseDelay * Math.pow(2, attempt - 1) + Math.random() * 1000
}

export const handleApiError = (error, defaultMessage = 'エラーが発生しました') => {
    console.error('API Error:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        type: getErrorType(error),
        isOnline,
        timestamp: new Date().toISOString()
    })

    return getErrorMessage(error) || defaultMessage
}

// Enhanced error handler with retry logic
export const handleApiErrorWithRetry = async (error, retryFn, maxRetries = 3, currentAttempt = 1) => {
    const errorType = getErrorType(error)

    console.error(`API Error (Attempt ${currentAttempt}/${maxRetries}):`, {
        message: error.message,
        type: errorType,
        isRetryable: isRetryableError(error),
        timestamp: new Date().toISOString()
    })

    // If error is retryable and we haven't exceeded max retries
    if (isRetryableError(error) && currentAttempt < maxRetries) {
        const delay = getRetryDelay(error, currentAttempt)

        console.log(`Retrying in ${delay}ms...`)

        await new Promise(resolve => setTimeout(resolve, delay))

        try {
            return await retryFn()
        } catch (retryError) {
            return handleApiErrorWithRetry(retryError, retryFn, maxRetries, currentAttempt + 1)
        }
    }

    // If not retryable or max retries exceeded, throw the error
    throw error
}

// Network status utilities
export const isNetworkOnline = () => isOnline

export const onNetworkStatusChange = (callback) => {
    networkListeners.push(callback)

    // Return unsubscribe function
    return () => {
        const index = networkListeners.indexOf(callback)
        if (index > -1) {
            networkListeners.splice(index, 1)
        }
    }
}

// Error notification helper
export const createErrorNotification = (error, context = '') => {
    const errorType = getErrorType(error)
    const message = getErrorMessage(error)
    const suggestion = getRecoverySuggestion(error)

    return {
        type: 'error',
        title: 'エラーが発生しました',
        message,
        suggestion,
        context,
        errorType,
        isRetryable: isRetryableError(error),
        timestamp: new Date().toISOString()
    }
}