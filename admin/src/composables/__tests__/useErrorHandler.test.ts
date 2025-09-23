import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { defineComponent, ref } from 'vue'
import {
    useErrorHandler,
    useLoadingState,
    useAsyncOperation,
    useFormErrorHandler,
    useRetryableOperation,
    useNetworkStatus
} from '../useErrorHandler'
import { errorHandlerService } from '@/services/errorHandlerService'
import type { AppError } from '@/types/error'
import { ErrorType, createNetworkError } from '@/types/error'

// Mock the error handler service
vi.mock('@/services/errorHandlerService', () => ({
    errorHandlerService: {
        handleError: vi.fn(),
        clearErrors: vi.fn(),
        dismissNotification: vi.fn(),
        retryLastOperation: vi.fn(),
        showErrorDetails: vi.fn(),
        getErrors: vi.fn(() => []),
        startLoading: vi.fn(),
        updateLoadingProgress: vi.fn(),
        completeLoading: vi.fn(),
        failLoading: vi.fn(),
        cancelLoading: vi.fn(),
        get isOnline() { return true },
        get hasErrors() { return false },
        get hasNotifications() { return false },
        get isLoading() { return false },
        get errors() { return [] },
        get notifications() { return [] },
        get statistics() { return { totalErrors: 0, errorsByType: {}, errorsBySeverity: {}, errorRate: 0, timeRange: { start: new Date(), end: new Date() } } },
        get networkInfo() { return { isOnline: true, connectionType: 'wifi' } },
        get loadingOperationsArray() { return [] }
    }
}))

describe('useErrorHandler', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('should provide error handling functionality', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useErrorHandler()
            },
            template: '<div></div>'
        })

        // When
        const wrapper = mount(TestComponent)
        const {
            isOnline,
            hasErrors,
            hasNotifications,
            isLoading,
            handleError,
            clearErrors,
            dismissNotification
        } = wrapper.vm

        // Then
        expect(isOnline).toBe(true)
        expect(hasErrors).toBe(false)
        expect(hasNotifications).toBe(false)
        expect(isLoading).toBe(false)
        expect(typeof handleError).toBe('function')
        expect(typeof clearErrors).toBe('function')
        expect(typeof dismissNotification).toBe('function')
    })

    it('should handle errors through service', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                const { handleError } = useErrorHandler()
                return { handleError }
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const error = new Error('Test error')
        const context = 'Test context'

        // When
        wrapper.vm.handleError(error, context)

        // Then
        expect(errorHandlerService.handleError).toHaveBeenCalledWith(error, context)
    })

    it('should clear errors through service', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                const { clearErrors } = useErrorHandler()
                return { clearErrors }
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)

        // When
        wrapper.vm.clearErrors()

        // Then
        expect(errorHandlerService.clearErrors).toHaveBeenCalled()
    })
})

describe('useLoadingState', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('should provide loading state management', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useLoadingState()
            },
            template: '<div></div>'
        })

        // When
        const wrapper = mount(TestComponent)
        const {
            startLoading,
            updateProgress,
            completeLoading,
            failLoading,
            cancelLoading
        } = wrapper.vm

        // Then
        expect(typeof startLoading).toBe('function')
        expect(typeof updateProgress).toBe('function')
        expect(typeof completeLoading).toBe('function')
        expect(typeof failLoading).toBe('function')
        expect(typeof cancelLoading).toBe('function')
    })

    it('should start loading operations', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                const { startLoading } = useLoadingState()
                return { startLoading }
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const id = 'test-operation'
        const name = 'Test Operation'

        // When
        wrapper.vm.startLoading(id, name)

        // Then
        expect(errorHandlerService.startLoading).toHaveBeenCalledWith(id, name, undefined, undefined)
    })

    it('should update loading progress', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                const { updateProgress } = useLoadingState()
                return { updateProgress }
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const id = 'test-operation'
        const progress = 50

        // When
        wrapper.vm.updateProgress(id, progress)

        // Then
        expect(errorHandlerService.updateLoadingProgress).toHaveBeenCalledWith(id, progress)
    })
})

describe('useAsyncOperation', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('should execute async operations with loading state', async () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useAsyncOperation()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { execute, loading, data, error } = wrapper.vm

        const mockOperation = vi.fn().mockResolvedValue('success result')

        // When
        const result = await execute(mockOperation, {
            loadingName: 'Test Operation',
            context: 'Test context'
        })

        // Then
        expect(mockOperation).toHaveBeenCalled()
        expect(result).toBe('success result')
        expect(data.value).toBe('success result')
        expect(error.value).toBeNull()
        expect(loading.value).toBe(false)
    })

    it('should handle async operation errors', async () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useAsyncOperation()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { execute, loading, data, error } = wrapper.vm

        const testError = new Error('Test error')
        const mockOperation = vi.fn().mockRejectedValue(testError)

        // When
        const result = await execute(mockOperation, {
            context: 'Test context'
        })

        // Then
        expect(mockOperation).toHaveBeenCalled()
        expect(result).toBeNull()
        expect(data.value).toBeNull()
        expect(error.value).toBeTruthy()
        expect(loading.value).toBe(false)
        expect(errorHandlerService.handleError).toHaveBeenCalledWith(testError, 'Test context')
    })

    it('should reset state correctly', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useAsyncOperation()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { reset, loading, data, error } = wrapper.vm

        // Set some initial state
        data.value = 'some data'
        error.value = createNetworkError('Some error')

        // When
        reset()

        // Then
        expect(loading.value).toBe(false)
        expect(data.value).toBeNull()
        expect(error.value).toBeNull()
    })
})

describe('useFormErrorHandler', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('should handle form validation errors', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useFormErrorHandler()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { handleFormError, fieldErrors, globalError, hasErrors } = wrapper.vm

        const validationError = {
            response: {
                status: 422,
                data: {
                    message: 'Validation failed',
                    errors: {
                        email: ['Email is required'],
                        password: ['Password must be at least 8 characters']
                    }
                }
            }
        }

        // When
        handleFormError(validationError)

        // Then
        expect(fieldErrors.value.email).toBe('Email is required')
        expect(fieldErrors.value.password).toBe('Password must be at least 8 characters')
        expect(globalError.value).toBe('Validation failed')
        expect(hasErrors.value).toBe(true)
    })

    it('should handle non-validation errors', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useFormErrorHandler()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { handleFormError, globalError } = wrapper.vm

        const serverError = {
            response: {
                status: 500,
                data: { message: 'Server error' }
            }
        }

        // Mock the error handler service to return a specific error
        vi.mocked(errorHandlerService.handleError).mockReturnValue({
            id: 'test-id',
            type: ErrorType.SERVER_ERROR,
            severity: 'high',
            message: 'Server error',
            timestamp: new Date(),
            isRetryable: true,
            userFriendlyMessage: 'サーバーエラーが発生しました'
        } as AppError)

        // When
        handleFormError(serverError)

        // Then
        expect(globalError.value).toBe('サーバーエラーが発生しました')
        expect(errorHandlerService.handleError).toHaveBeenCalledWith(serverError, 'Form submission')
    })

    it('should clear field errors', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useFormErrorHandler()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { handleFormError, clearFieldError, hasFieldError } = wrapper.vm

        const validationError = {
            response: {
                status: 422,
                data: {
                    errors: { email: ['Email is required'] }
                }
            }
        }

        handleFormError(validationError)
        expect(hasFieldError('email')).toBe(true)

        // When
        clearFieldError('email')

        // Then
        expect(hasFieldError('email')).toBe(false)
    })

    it('should clear all errors', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useFormErrorHandler()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { handleFormError, clearAllErrors, hasErrors } = wrapper.vm

        const validationError = {
            response: {
                status: 422,
                data: {
                    message: 'Validation failed',
                    errors: { email: ['Email is required'] }
                }
            }
        }

        handleFormError(validationError)
        expect(hasErrors.value).toBe(true)

        // When
        clearAllErrors()

        // Then
        expect(hasErrors.value).toBe(false)
    })
})

describe('useRetryableOperation', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('should retry failed operations', async () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useRetryableOperation()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { executeWithRetry, canRetry, retryCount } = wrapper.vm

        let attemptCount = 0
        const mockOperation = vi.fn().mockImplementation(() => {
            attemptCount++
            if (attemptCount < 3) {
                throw new Error('Temporary failure')
            }
            return Promise.resolve('success')
        })

        // When
        const result = await executeWithRetry(mockOperation, {
            maxRetries: 3,
            retryDelay: 10 // Short delay for testing
        })

        // Then
        expect(result).toBe('success')
        expect(attemptCount).toBe(3)
        expect(retryCount.value).toBe(0) // Reset after success
    })

    it('should respect max retry limit', async () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useRetryableOperation()
            },
            template: '<div></div>'
        })
        const wrapper = mount(TestComponent)
        const { executeWithRetry, retryCount } = wrapper.vm

        const mockOperation = vi.fn().mockRejectedValue(new Error('Persistent failure'))

        // When & Then
        await expect(executeWithRetry(mockOperation, {
            maxRetries: 2,
            retryDelay: 10
        })).rejects.toThrow('Persistent failure')

        expect(retryCount.value).toBe(2)
    })
})

describe('useNetworkStatus', () => {
    beforeEach(() => {
        vi.clearAllMocks()
    })

    it('should provide network status information', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useNetworkStatus()
            },
            template: '<div></div>'
        })

        // When
        const wrapper = mount(TestComponent)
        const { isOnline, networkInfo, isSlowConnection, shouldLimitData } = wrapper.vm

        // Then
        expect(isOnline.value).toBe(true)
        expect(networkInfo.value).toEqual({ isOnline: true, connectionType: 'wifi' })
        expect(typeof isSlowConnection.value).toBe('boolean')
        expect(typeof shouldLimitData.value).toBe('boolean')
    })

    it('should detect slow connections', () => {
        // Given
        const TestComponent = defineComponent({
            setup() {
                return useNetworkStatus()
            },
            template: '<div></div>'
        })

        // Mock slow connection
        vi.mocked(errorHandlerService.networkInfo, 'get').mockReturnValue({
            isOnline: true,
            connectionType: 'cellular',
            effectiveType: '2g',
            downlink: 0.5,
            saveData: false
        })

        // When
        const wrapper = mount(TestComponent)
        const { isSlowConnection, shouldLimitData } = wrapper.vm

        // Then
        expect(isSlowConnection.value).toBe(true)
        expect(shouldLimitData.value).toBe(true)
    })
})