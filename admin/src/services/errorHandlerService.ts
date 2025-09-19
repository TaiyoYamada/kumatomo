import { ref, reactive, computed } from 'vue'
import type {
    AppError,
    ErrorType,
    ErrorSeverity,
    NetworkStatus,
    RetryConfig,
    ErrorNotification,
    ErrorContext,
    ErrorHandlerState,
    LoadingOperation,
    LoadingState,
    ErrorStatistics,
    ErrorFilterOptions
} from '@/types/error'
import {
    createNetworkError,
    createValidationError,
    createAuthenticationError,
    createServerError,
    isRetryableError,
    ErrorType as ErrorTypeEnum
} from '@/types/error'

class ErrorHandlerService {
    private state = reactive<ErrorHandlerState>({
        errors: [],
        notifications: [],
        isOnline: navigator.onLine,
        retryQueue: [],
        statistics: {
            totalErrors: 0,
            errorsByType: {} as Record<ErrorType, number>,
            errorsBySeverity: {} as Record<ErrorSeverity, number>,
            errorRate: 0,
            timeRange: {
                start: new Date(),
                end: new Date()
            }
        }
    })

    private loadingOperations = reactive<Map<string, LoadingOperation>>(new Map())
    private config: RetryConfig = {
        maxAttempts: 3,
        baseDelay: 1000,
        maxDelay: 30000,
        backoffMultiplier: 2,
        jitter: true
    }

    private networkStatus = reactive<NetworkStatus>({
        isOnline: navigator.onLine,
        connectionType: 'unknown'
    })

    constructor() {
        this.setupNetworkMonitoring()
        this.setupPerformanceMonitoring()
    }

    // MARK: - Network Monitoring

    private setupNetworkMonitoring(): void {
        // Basic online/offline detection
        window.addEventListener('online', () => {
            this.state.isOnline = true
            this.networkStatus.isOnline = true
            this.handleNetworkReconnection()
        })

        window.addEventListener('offline', () => {
            this.state.isOnline = false
            this.networkStatus.isOnline = false
            this.handleNetworkDisconnection()
        })

        // Enhanced network monitoring with Connection API
        if ('connection' in navigator) {
            const connection = (navigator as any).connection

            this.updateNetworkStatus(connection)

            connection.addEventListener('change', () => {
                this.updateNetworkStatus(connection)
            })
        }
    }

    private updateNetworkStatus(connection: any): void {
        this.networkStatus.connectionType = connection.type || 'unknown'
        this.networkStatus.effectiveType = connection.effectiveType
        this.networkStatus.downlink = connection.downlink
        this.networkStatus.rtt = connection.rtt
        this.networkStatus.saveData = connection.saveData
    }

    private setupPerformanceMonitoring(): void {
        // Monitor page visibility for better error context
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.pauseRetryQueue()
            } else {
                this.resumeRetryQueue()
            }
        })
    }

    // MARK: - Error Handling

    public handleError(error: any, context?: string): AppError {
        const appError = this.convertToAppError(error, context)

        // Add to error collection
        this.state.errors.unshift(appError)
        this.updateStatistics(appError)

        // Log error
        this.logError(appError)

        // Show notification if appropriate
        if (this.shouldShowNotification(appError)) {
            this.showErrorNotification(appError)
        }

        // Add to retry queue if retryable
        if (isRetryableError(appError)) {
            this.addToRetryQueue(appError)
        }

        return appError
    }

    private convertToAppError(error: any, context?: string): AppError {
        const errorContext: ErrorContext = {
            url: window.location.href,
            userAgent: navigator.userAgent,
            timestamp: new Date(),
            additionalData: { context }
        }

        // Handle Axios errors
        if (error.response) {
            const { status, data } = error.response

            switch (status) {
                case 401:
                    return createAuthenticationError(
                        data?.message || 'Authentication required',
                        data?.token_expired || false
                    )

                case 403:
                    return {
                        id: crypto.randomUUID(),
                        type: ErrorTypeEnum.AUTHORIZATION_ERROR,
                        severity: 'medium' as ErrorSeverity,
                        message: data?.message || 'Access denied',
                        timestamp: new Date(),
                        context,
                        isRetryable: false,
                        userFriendlyMessage: 'アクセス権限がありません',
                        recoverySuggestion: '管理者に連絡してください'
                    }

                case 404:
                    return {
                        id: crypto.randomUUID(),
                        type: ErrorTypeEnum.NOT_FOUND_ERROR,
                        severity: 'low' as ErrorSeverity,
                        message: data?.message || 'Resource not found',
                        timestamp: new Date(),
                        context,
                        isRetryable: false,
                        userFriendlyMessage: 'リソースが見つかりません',
                        recoverySuggestion: 'URLを確認してください'
                    }

                case 422:
                    return createValidationError(
                        data?.message || 'Validation failed',
                        data?.field,
                        data?.rule
                    )

                case 429:
                    return {
                        id: crypto.randomUUID(),
                        type: ErrorTypeEnum.RATE_LIMIT_ERROR,
                        severity: 'medium' as ErrorSeverity,
                        message: 'Rate limit exceeded',
                        timestamp: new Date(),
                        context,
                        isRetryable: true,
                        maxRetries: 5,
                        userFriendlyMessage: 'リクエスト制限を超えています',
                        recoverySuggestion: 'しばらく時間をおいてから再試行してください'
                    }

                case 408:
                case 504:
                    return {
                        id: crypto.randomUUID(),
                        type: ErrorTypeEnum.TIMEOUT_ERROR,
                        severity: 'medium' as ErrorSeverity,
                        message: 'Request timeout',
                        timestamp: new Date(),
                        context,
                        isRetryable: true,
                        userFriendlyMessage: 'リクエストがタイムアウトしました',
                        recoverySuggestion: '通信環境を確認して再試行してください'
                    }

                default:
                    return createServerError(
                        data?.message || 'Server error',
                        status,
                        data?.error
                    )
            }
        }

        // Handle network errors
        if (error.request) {
            return createNetworkError(
                error.message || 'Network error',
                undefined,
                error.config?.url,
                error.config?.method
            )
        }

        // Handle validation errors from forms
        if (error.name === 'ValidationError') {
            return createValidationError(error.message, error.field, error.rule)
        }

        // Default error
        return {
            id: crypto.randomUUID(),
            type: ErrorTypeEnum.UNKNOWN_ERROR,
            severity: 'medium' as ErrorSeverity,
            message: error.message || 'Unknown error occurred',
            timestamp: new Date(),
            context,
            isRetryable: false,
            userFriendlyMessage: '予期しないエラーが発生しました',
            recoverySuggestion: 'ページを再読み込みしてください'
        }
    }

    // MARK: - Retry Logic

    private addToRetryQueue(error: AppError, retryFn?: () => Promise<void>): void {
        if (!retryFn) return

        this.state.retryQueue.push({
            error,
            retryFn,
            attempt: 0
        })

        this.processRetryQueue()
    }

    private async processRetryQueue(): Promise<void> {
        if (this.state.retryQueue.length === 0) return

        const item = this.state.retryQueue[0]

        if (!isRetryableError(item.error)) {
            this.state.retryQueue.shift()
            return this.processRetryQueue()
        }

        const delay = this.calculateRetryDelay(item.attempt)

        setTimeout(async () => {
            try {
                await item.retryFn()
                this.state.retryQueue.shift()
                this.showSuccessNotification('操作が正常に完了しました')
            } catch (error) {
                item.attempt++

                if (item.attempt >= (item.error.maxRetries || this.config.maxAttempts)) {
                    this.state.retryQueue.shift()
                    this.handleError(error, `Retry failed after ${item.attempt} attempts`)
                }
            }

            this.processRetryQueue()
        }, delay)
    }

    private calculateRetryDelay(attempt: number): number {
        const delay = Math.min(
            this.config.baseDelay * Math.pow(this.config.backoffMultiplier, attempt),
            this.config.maxDelay
        )

        if (this.config.jitter) {
            return delay + Math.random() * 1000
        }

        return delay
    }

    private pauseRetryQueue(): void {
        // Implementation for pausing retry queue when page is hidden
    }

    private resumeRetryQueue(): void {
        // Implementation for resuming retry queue when page becomes visible
    }

    // MARK: - Loading State Management

    public startLoading(
        id: string,
        name: string,
        description?: string,
        options?: {
            isCancellable?: boolean
            priority?: 'low' | 'normal' | 'high' | 'critical'
        }
    ): void {
        const operation: LoadingOperation = {
            id,
            name,
            description,
            state: LoadingState.LOADING,
            startTime: new Date(),
            isCancellable: options?.isCancellable || false,
            priority: options?.priority || 'normal'
        }

        this.loadingOperations.set(id, operation)
    }

    public updateLoadingProgress(id: string, progress: number): void {
        const operation = this.loadingOperations.get(id)
        if (operation) {
            operation.progress = Math.max(0, Math.min(100, progress))
        }
    }

    public completeLoading(id: string, result?: any): void {
        const operation = this.loadingOperations.get(id)
        if (operation) {
            operation.state = LoadingState.SUCCESS
            operation.endTime = new Date()

            // Remove after a delay to allow UI transitions
            setTimeout(() => {
                this.loadingOperations.delete(id)
            }, 1000)
        }
    }

    public failLoading(id: string, error: AppError): void {
        const operation = this.loadingOperations.get(id)
        if (operation) {
            operation.state = LoadingState.ERROR
            operation.error = error
            operation.endTime = new Date()
        }
    }

    public cancelLoading(id: string): void {
        this.loadingOperations.delete(id)
    }

    // MARK: - Notifications

    private shouldShowNotification(error: AppError): boolean {
        // Don't show notifications for validation errors (handled by forms)
        if (error.type === ErrorTypeEnum.VALIDATION_ERROR) {
            return false
        }

        // Don't show notifications for low severity errors
        if (error.severity === 'low') {
            return false
        }

        return true
    }

    private showErrorNotification(error: AppError): void {
        const notification: ErrorNotification = {
            id: error.id,
            type: 'error',
            title: 'エラーが発生しました',
            message: error.userFriendlyMessage || error.message,
            duration: this.getNotificationDuration(error.severity),
            dismissible: true,
            actions: []
        }

        // Add retry action if retryable
        if (isRetryableError(error)) {
            notification.actions?.push({
                label: '再試行',
                action: () => this.retryLastOperation(error.id),
                style: 'primary'
            })
        }

        // Add recovery suggestion as action
        if (error.recoverySuggestion) {
            notification.actions?.push({
                label: '詳細',
                action: () => this.showErrorDetails(error),
                style: 'secondary'
            })
        }

        this.state.notifications.unshift(notification)

        // Auto-remove after duration
        if (notification.duration) {
            setTimeout(() => {
                this.dismissNotification(notification.id)
            }, notification.duration)
        }
    }

    private showSuccessNotification(message: string): void {
        const notification: ErrorNotification = {
            id: crypto.randomUUID(),
            type: 'info',
            title: '成功',
            message,
            duration: 3000,
            dismissible: true
        }

        this.state.notifications.unshift(notification)

        setTimeout(() => {
            this.dismissNotification(notification.id)
        }, notification.duration!)
    }

    private getNotificationDuration(severity: ErrorSeverity): number {
        switch (severity) {
            case 'low':
                return 3000
            case 'medium':
                return 5000
            case 'high':
                return 8000
            case 'critical':
                return 0 // Persistent
            default:
                return 5000
        }
    }

    public dismissNotification(id: string): void {
        const index = this.state.notifications.findIndex(n => n.id === id)
        if (index !== -1) {
            this.state.notifications.splice(index, 1)
        }
    }

    // MARK: - Network Event Handlers

    private handleNetworkReconnection(): void {
        // Retry failed network operations
        this.processRetryQueue()

        // Show reconnection notification
        this.showSuccessNotification('インターネット接続が復旧しました')
    }

    private handleNetworkDisconnection(): void {
        // Show offline notification
        const notification: ErrorNotification = {
            id: 'offline',
            type: 'warning',
            title: 'オフライン',
            message: 'インターネット接続がありません',
            persistent: true,
            dismissible: false
        }

        this.state.notifications.unshift(notification)
    }

    // MARK: - Statistics and Analytics

    private updateStatistics(error: AppError): void {
        this.state.statistics.totalErrors++

        // Update error counts by type
        if (!this.state.statistics.errorsByType[error.type]) {
            this.state.statistics.errorsByType[error.type] = 0
        }
        this.state.statistics.errorsByType[error.type]++

        // Update error counts by severity
        if (!this.state.statistics.errorsBySeverity[error.severity]) {
            this.state.statistics.errorsBySeverity[error.severity] = 0
        }
        this.state.statistics.errorsBySeverity[error.severity]++

        // Update error rate (errors per minute)
        const timeWindow = 60000 // 1 minute
        const recentErrors = this.state.errors.filter(
            e => Date.now() - e.timestamp.getTime() < timeWindow
        )
        this.state.statistics.errorRate = recentErrors.length

        // Update last error
        this.state.statistics.lastError = error
    }

    private logError(error: AppError): void {
        const logLevel = this.getLogLevel(error.severity)
        const logMessage = `[${logLevel}] ${error.type}: ${error.message}`

        console.group(logMessage)
        console.log('Error ID:', error.id)
        console.log('Timestamp:', error.timestamp.toISOString())
        console.log('Context:', error.context)
        console.log('Retryable:', error.isRetryable)
        console.log('User Message:', error.userFriendlyMessage)
        console.log('Recovery:', error.recoverySuggestion)
        console.groupEnd()

        // Send to external logging service in production
        if (process.env.NODE_ENV === 'production') {
            this.sendErrorToLoggingService(error)
        }
    }

    private getLogLevel(severity: ErrorSeverity): string {
        switch (severity) {
            case 'low':
                return 'INFO'
            case 'medium':
                return 'WARN'
            case 'high':
                return 'ERROR'
            case 'critical':
                return 'FATAL'
            default:
                return 'ERROR'
        }
    }

    private sendErrorToLoggingService(error: AppError): void {
        // Implementation for sending errors to external logging service
        // This could be Sentry, LogRocket, or custom logging endpoint
    }

    // MARK: - Public API

    public getErrors(filter?: ErrorFilterOptions): AppError[] {
        let filteredErrors = [...this.state.errors]

        if (filter) {
            if (filter.types) {
                filteredErrors = filteredErrors.filter(e => filter.types!.includes(e.type))
            }

            if (filter.severities) {
                filteredErrors = filteredErrors.filter(e => filter.severities!.includes(e.severity))
            }

            if (filter.dateRange) {
                filteredErrors = filteredErrors.filter(e =>
                    e.timestamp >= filter.dateRange!.start &&
                    e.timestamp <= filter.dateRange!.end
                )
            }

            if (filter.searchQuery) {
                const query = filter.searchQuery.toLowerCase()
                filteredErrors = filteredErrors.filter(e =>
                    e.message.toLowerCase().includes(query) ||
                    e.userFriendlyMessage?.toLowerCase().includes(query) ||
                    e.context?.toLowerCase().includes(query)
                )
            }
        }

        return filteredErrors
    }

    public clearErrors(): void {
        this.state.errors = []
        this.updateStatisticsAfterClear()
    }

    public retryLastOperation(errorId: string): void {
        const retryItem = this.state.retryQueue.find(item => item.error.id === errorId)
        if (retryItem) {
            retryItem.retryFn()
        }
    }

    public showErrorDetails(error: AppError): void {
        // Implementation for showing detailed error information
        // This could open a modal or navigate to an error details page
    }

    private updateStatisticsAfterClear(): void {
        this.state.statistics = {
            totalErrors: 0,
            errorsByType: {} as Record<ErrorType, number>,
            errorsBySeverity: {} as Record<ErrorSeverity, number>,
            errorRate: 0,
            timeRange: {
                start: new Date(),
                end: new Date()
            }
        }
    }

    // MARK: - Computed Properties

    public get isOnline(): boolean {
        return this.state.isOnline
    }

    public get hasErrors(): boolean {
        return this.state.errors.length > 0
    }

    public get hasNotifications(): boolean {
        return this.state.notifications.length > 0
    }

    public get isLoading(): boolean {
        return this.loadingOperations.size > 0
    }

    public get loadingOperationsArray(): LoadingOperation[] {
        return Array.from(this.loadingOperations.values())
    }

    public get criticalErrors(): AppError[] {
        return this.state.errors.filter(e => e.severity === 'critical')
    }

    public get statistics(): ErrorStatistics {
        return this.state.statistics
    }

    public get notifications(): ErrorNotification[] {
        return this.state.notifications
    }

    public get networkInfo(): NetworkStatus {
        return this.networkStatus
    }
}

// Create singleton instance
export const errorHandlerService = new ErrorHandlerService()
export default errorHandlerService