// Error Types and Interfaces for TypeScript Admin Panel

export enum ErrorType {
    NETWORK_ERROR = 'NETWORK_ERROR',
    VALIDATION_ERROR = 'VALIDATION_ERROR',
    AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR',
    AUTHORIZATION_ERROR = 'AUTHORIZATION_ERROR',
    NOT_FOUND_ERROR = 'NOT_FOUND_ERROR',
    SERVER_ERROR = 'SERVER_ERROR',
    TIMEOUT_ERROR = 'TIMEOUT_ERROR',
    OFFLINE_ERROR = 'OFFLINE_ERROR',
    RATE_LIMIT_ERROR = 'RATE_LIMIT_ERROR',
    UNKNOWN_ERROR = 'UNKNOWN_ERROR'
}

export enum ErrorSeverity {
    LOW = 'low',
    MEDIUM = 'medium',
    HIGH = 'high',
    CRITICAL = 'critical'
}

export interface BaseError {
    readonly id: string
    readonly type: ErrorType
    readonly severity: ErrorSeverity
    readonly message: string
    readonly timestamp: Date
    readonly context?: string
    readonly userFriendlyMessage?: string
    readonly recoverySuggestion?: string
    readonly isRetryable: boolean
    readonly retryCount?: number
    readonly maxRetries?: number
}

export interface NetworkError extends BaseError {
    readonly type: ErrorType.NETWORK_ERROR
    readonly statusCode?: number
    readonly responseTime?: number
    readonly endpoint?: string
    readonly method?: string
}

export interface ValidationError extends BaseError {
    readonly type: ErrorType.VALIDATION_ERROR
    readonly field?: string
    readonly validationRule?: string
    readonly expectedFormat?: string
    readonly actualValue?: unknown
}

export interface AuthenticationError extends BaseError {
    readonly type: ErrorType.AUTHENTICATION_ERROR
    readonly authMethod?: string
    readonly tokenExpired?: boolean
    readonly requiresReauth?: boolean
}

export interface AuthorizationError extends BaseError {
    readonly type: ErrorType.AUTHORIZATION_ERROR
    readonly requiredPermission?: string
    readonly userRole?: string
    readonly resourceId?: string
}

export interface ServerError extends BaseError {
    readonly type: ErrorType.SERVER_ERROR
    readonly statusCode: number
    readonly serverMessage?: string
    readonly errorCode?: string
    readonly stackTrace?: string
}

export interface TimeoutError extends BaseError {
    readonly type: ErrorType.TIMEOUT_ERROR
    readonly timeoutDuration: number
    readonly operation?: string
}

export interface RateLimitError extends BaseError {
    readonly type: ErrorType.RATE_LIMIT_ERROR
    readonly limit: number
    readonly resetTime?: Date
    readonly retryAfter?: number
}

export type AppError =
    | NetworkError
    | ValidationError
    | AuthenticationError
    | AuthorizationError
    | ServerError
    | TimeoutError
    | RateLimitError
    | BaseError

// Error Response from API
export interface ApiErrorResponse {
    error: {
        type: string
        message: string
        code?: string
        details?: Record<string, unknown>
        timestamp: string
    }
    meta?: {
        requestId: string
        endpoint: string
        method: string
    }
}

// Validation Error Details
export interface ValidationErrorDetails {
    field: string
    message: string
    rule: string
    value?: unknown
}

export interface ValidationErrorResponse {
    message: string
    errors: Record<string, string[]>
    details?: ValidationErrorDetails[]
}

// Error Handler Configuration
export interface ErrorHandlerConfig {
    enableRetry: boolean
    maxRetries: number
    retryDelay: number
    enableLogging: boolean
    enableUserNotification: boolean
    enableErrorReporting: boolean
    reportingEndpoint?: string
}

// Error Context for better debugging
export interface ErrorContext {
    userId?: string
    sessionId?: string
    userAgent?: string
    url?: string
    timestamp: Date
    additionalData?: Record<string, unknown>
}

// Error Recovery Strategy
export interface ErrorRecoveryStrategy {
    canRecover: boolean
    recoveryAction?: () => Promise<void>
    fallbackAction?: () => void
    userAction?: {
        label: string
        action: () => void
    }
}

// Error Notification
export interface ErrorNotification {
    id: string
    type: 'error' | 'warning' | 'info'
    title: string
    message: string
    duration?: number
    actions?: Array<{
        label: string
        action: () => void
        style?: 'primary' | 'secondary' | 'danger'
    }>
    dismissible: boolean
    persistent?: boolean
}

// Error Statistics
export interface ErrorStatistics {
    totalErrors: number
    errorsByType: Record<ErrorType, number>
    errorsBySeverity: Record<ErrorSeverity, number>
    averageResponseTime?: number
    errorRate: number
    lastError?: AppError
    timeRange: {
        start: Date
        end: Date
    }
}

// Error Filter Options
export interface ErrorFilterOptions {
    types?: ErrorType[]
    severities?: ErrorSeverity[]
    dateRange?: {
        start: Date
        end: Date
    }
    searchQuery?: string
    userId?: string
    endpoint?: string
}

// Error Handler State
export interface ErrorHandlerState {
    errors: AppError[]
    notifications: ErrorNotification[]
    isOnline: boolean
    retryQueue: Array<{
        error: AppError
        retryFn: () => Promise<void>
        attempt: number
    }>
    statistics: ErrorStatistics
}

// Loading State Types
export enum LoadingState {
    IDLE = 'idle',
    LOADING = 'loading',
    SUCCESS = 'success',
    ERROR = 'error'
}

export interface LoadingOperation {
    id: string
    name: string
    description?: string
    state: LoadingState
    progress?: number
    startTime: Date
    endTime?: Date
    error?: AppError
    isCancellable: boolean
    priority: 'low' | 'normal' | 'high' | 'critical'
}

export interface LoadingManager {
    operations: Map<string, LoadingOperation>
    globalState: LoadingState
    isLoading: boolean
    hasErrors: boolean
}

// Network Status
export interface NetworkStatus {
    isOnline: boolean
    connectionType?: 'wifi' | 'cellular' | 'ethernet' | 'unknown'
    effectiveType?: '2g' | '3g' | '4g' | '5g'
    downlink?: number
    rtt?: number
    saveData?: boolean
}

// Retry Configuration
export interface RetryConfig {
    maxAttempts: number
    baseDelay: number
    maxDelay: number
    backoffMultiplier: number
    jitter: boolean
    retryCondition?: (error: AppError) => boolean
}

// Error Boundary Props
export interface ErrorBoundaryState {
    hasError: boolean
    error?: Error
    errorInfo?: {
        componentStack: string
    }
}

// Form Error State
export interface FormErrorState {
    hasErrors: boolean
    fieldErrors: Record<string, string>
    globalError?: string
    isSubmitting: boolean
}

// API Response Wrapper
export interface ApiResponse<T = unknown> {
    data?: T
    error?: ApiErrorResponse
    meta?: {
        pagination?: {
            page: number
            perPage: number
            total: number
            totalPages: number
        }
        requestId: string
        timestamp: string
    }
}

// Error Event Types
export type ErrorEvent =
    | { type: 'ERROR_OCCURRED'; payload: AppError }
    | { type: 'ERROR_RESOLVED'; payload: { errorId: string } }
    | { type: 'RETRY_ATTEMPTED'; payload: { errorId: string; attempt: number } }
    | { type: 'NETWORK_STATUS_CHANGED'; payload: NetworkStatus }
    | { type: 'LOADING_STARTED'; payload: LoadingOperation }
    | { type: 'LOADING_COMPLETED'; payload: { operationId: string; result?: unknown } }
    | { type: 'LOADING_FAILED'; payload: { operationId: string; error: AppError } }

// Type Guards
export const isNetworkError = (error: AppError): error is NetworkError => {
    return error.type === ErrorType.NETWORK_ERROR
}

export const isValidationError = (error: AppError): error is ValidationError => {
    return error.type === ErrorType.VALIDATION_ERROR
}

export const isAuthenticationError = (error: AppError): error is AuthenticationError => {
    return error.type === ErrorType.AUTHENTICATION_ERROR
}

export const isServerError = (error: AppError): error is ServerError => {
    return error.type === ErrorType.SERVER_ERROR
}

export const isRetryableError = (error: AppError): boolean => {
    return error.isRetryable && (error.retryCount ?? 0) < (error.maxRetries ?? 3)
}

// Error Factory Functions
export const createNetworkError = (
    message: string,
    statusCode?: number,
    endpoint?: string,
    method?: string
): NetworkError => ({
    id: crypto.randomUUID(),
    type: ErrorType.NETWORK_ERROR,
    severity: statusCode && statusCode >= 500 ? ErrorSeverity.HIGH : ErrorSeverity.MEDIUM,
    message,
    timestamp: new Date(),
    statusCode,
    endpoint,
    method,
    isRetryable: statusCode ? statusCode >= 500 || statusCode === 408 : true,
    userFriendlyMessage: 'ネットワークエラーが発生しました',
    recoverySuggestion: 'ネットワーク接続を確認してください'
})

export const createValidationError = (
    message: string,
    field?: string,
    validationRule?: string
): ValidationError => ({
    id: crypto.randomUUID(),
    type: ErrorType.VALIDATION_ERROR,
    severity: ErrorSeverity.LOW,
    message,
    timestamp: new Date(),
    field,
    validationRule,
    isRetryable: false,
    userFriendlyMessage: '入力内容に問題があります',
    recoverySuggestion: '入力内容を確認して再試行してください'
})

export const createAuthenticationError = (
    message: string,
    tokenExpired = false
): AuthenticationError => ({
    id: crypto.randomUUID(),
    type: ErrorType.AUTHENTICATION_ERROR,
    severity: ErrorSeverity.MEDIUM,
    message,
    timestamp: new Date(),
    tokenExpired,
    requiresReauth: true,
    isRetryable: false,
    userFriendlyMessage: '認証が必要です',
    recoverySuggestion: 'ログインし直してください'
})

export const createServerError = (
    message: string,
    statusCode: number,
    serverMessage?: string
): ServerError => ({
    id: crypto.randomUUID(),
    type: ErrorType.SERVER_ERROR,
    severity: statusCode >= 500 ? ErrorSeverity.HIGH : ErrorSeverity.MEDIUM,
    message,
    timestamp: new Date(),
    statusCode,
    serverMessage,
    isRetryable: statusCode >= 500,
    userFriendlyMessage: 'サーバーエラーが発生しました',
    recoverySuggestion: 'しばらく時間をおいてから再試行してください'
})