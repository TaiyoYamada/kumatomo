import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import { errorHandlerService } from '../errorHandlerService'
import type { AppError, ErrorType, ErrorSeverity } from '@/types/error'
import { ErrorType as ErrorTypeEnum, createNetworkError, createValidationError } from '@/types/error'

// Mock navigator and window objects
const mockNavigator = {
    onLine: true,
    userAgent: 'test-agent',
    connection: {
        type: 'wifi',
        effectiveType: '4g',
        downlink: 10,
        rtt: 50,
        saveData: false,
        addEventListener: vi.fn()
    }
}

const mockWindow = {
    location: {
        href: 'http://localhost:3000/test'
    },
    addEventListener: vi.fn(),
    removeEventListener: vi.fn()
}

// Setup global mocks
Object.defineProperty(global, 'navigator', {
    value: mockNavigator,
    writable: true
})

Object.defineProperty(global, 'window', {
    value: mockWindow,
    writable: true
})

Object.defineProperty(global, 'crypto', {
    value: {
        randomUUID: () => 'test-uuid-' + Math.random().toString(36).substr(2, 9)
    }
})

describe('ErrorHandlerService', () => {
    beforeEach(() => {
        // Reset service state
        errorHandlerService.clearErrors()
        vi.clearAllMocks()
    })

    afterEach(() => {
        vi.restoreAllMocks()
    })

    describe('Error Handling', () => {
        it('should handle network errors correctly', () => {
            // Given
            const networkError = {
                request: {},
                message: 'Network Error',
                code: 'NETWORK_ERROR'
            }

            // When
            const appError = errorHandlerService.handleError(networkError, 'Test context')

            // Then
            expect(appError.type).toBe(ErrorTypeEnum.NETWORK_ERROR)
            expect(appError.message).toBe('Network Error')
            expect(appError.context).toBe('Test context')
            expect(appError.isRetryable).toBe(true)
            expect(errorHandlerService.hasErrors).toBe(true)
        })

        it('should handle API errors with different status codes', () => {
            const testCases = [
                { status: 401, expectedType: ErrorTypeEnum.AUTHENTICATION_ERROR },
                { status: 403, expectedType: ErrorTypeEnum.AUTHORIZATION_ERROR },
                { status: 404, expectedType: ErrorTypeEnum.NOT_FOUND_ERROR },
                { status: 422, expectedType: ErrorTypeEnum.VALIDATION_ERROR },
                { status: 429, expectedType: ErrorTypeEnum.RATE_LIMIT_ERROR },
                { status: 500, expectedType: ErrorTypeEnum.SERVER_ERROR },
                { status: 504, expectedType: ErrorTypeEnum.TIMEOUT_ERROR }
            ]

            testCases.forEach(({ status, expectedType }) => {
                // Given
                const apiError = {
                    response: {
                        status,
                        data: { message: `Error ${status}` }
                    }
                }

                // When
                const appError = errorHandlerService.handleError(apiError)

                // Then
                expect(appError.type).toBe(expectedType)
                expect(appError.message).toContain(`Error ${status}`)
            })
        })

        it('should handle validation errors with field information', () => {
            // Given
            const validationError = {
                response: {
                    status: 422,
                    data: {
                        message: 'Validation failed',
                        field: 'email',
                        rule: 'required'
                    }
                }
            }

            // When
            const appError = errorHandlerService.handleError(validationError)

            // Then
            expect(appError.type).toBe(ErrorTypeEnum.VALIDATION_ERROR)
            expect(appError.message).toBe('Validation failed')
            expect(appError.isRetryable).toBe(false)
        })

        it('should create proper error statistics', () => {
            // Given
            const errors = [
                { request: {}, message: 'Network Error 1' },
                { response: { status: 500, data: { message: 'Server Error' } } },
                { response: { status: 422, data: { message: 'Validation Error' } } },
                { request: {}, message: 'Network Error 2' }
            ]

            // When
            errors.forEach(error => errorHandlerService.handleError(error))
            const statistics = errorHandlerService.statistics

            // Then
            expect(statistics.totalErrors).toBe(4)
            expect(statistics.errorsByType[ErrorTypeEnum.NETWORK_ERROR]).toBe(2)
            expect(statistics.errorsByType[ErrorTypeEnum.SERVER_ERROR]).toBe(1)
            expect(statistics.errorsByType[ErrorTypeEnum.VALIDATION_ERROR]).toBe(1)
        })

        it('should filter errors correctly', () => {
            // Given
            const networkError = { request: {}, message: 'Network Error' }
            const serverError = { response: { status: 500, data: { message: 'Server Error' } } }

            errorHandlerService.handleError(networkError)
            errorHandlerService.handleError(serverError)

            // When
            const networkErrors = errorHandlerService.getErrors({
                types: [ErrorTypeEnum.NETWORK_ERROR]
            })
            const serverErrors = errorHandlerService.getErrors({
                types: [ErrorTypeEnum.SERVER_ERROR]
            })

            // Then
            expect(networkErrors).toHaveLength(1)
            expect(networkErrors[0].type).toBe(ErrorTypeEnum.NETWORK_ERROR)
            expect(serverErrors).toHaveLength(1)
            expect(serverErrors[0].type).toBe(ErrorTypeEnum.SERVER_ERROR)
        })

        it('should clear errors correctly', () => {
            // Given
            errorHandlerService.handleError({ message: 'Test error' })
            expect(errorHandlerService.hasErrors).toBe(true)

            // When
            errorHandlerService.clearErrors()

            // Then
            expect(errorHandlerService.hasErrors).toBe(false)
            expect(errorHandlerService.statistics.totalErrors).toBe(0)
        })
    })

    describe('Loading State Management', () => {
        it('should start and track loading operations', () => {
            // Given
            const operationId = 'test-operation'
            const operationName = 'Test Operation'

            // When
            errorHandlerService.startLoading(operationId, operationName)

            // Then
            expect(errorHandlerService.isLoading).toBe(true)
            expect(errorHandlerService.loadingOperationsArray).toHaveLength(1)

            const operation = errorHandlerService.loadingOperationsArray[0]
            expect(operation.id).toBe(operationId)
            expect(operation.name).toBe(operationName)
            expect(operation.state).toBe('loading')
        })

        it('should update loading progress', () => {
            // Given
            const operationId = 'test-operation'
            errorHandlerService.startLoading(operationId, 'Test')

            // When
            errorHandlerService.updateLoadingProgress(operationId, 50)

            // Then
            const operation = errorHandlerService.loadingOperationsArray.find(op => op.id === operationId)
            expect(operation?.progress).toBe(50)
        })

        it('should complete loading operations', async () => {
            // Given
            const operationId = 'test-operation'
            errorHandlerService.startLoading(operationId, 'Test')

            // When
            errorHandlerService.completeLoading(operationId, 'success result')

            // Then
            const operation = errorHandlerService.loadingOperationsArray.find(op => op.id === operationId)
            expect(operation?.state).toBe('success')
            expect(operation?.endTime).toBeDefined()

            // Wait for cleanup
            await new Promise(resolve => setTimeout(resolve, 1100))
            expect(errorHandlerService.loadingOperationsArray).toHaveLength(0)
        })

        it('should handle loading failures', () => {
            // Given
            const operationId = 'test-operation'
            const error = createNetworkError('Test error')
            errorHandlerService.startLoading(operationId, 'Test')

            // When
            errorHandlerService.failLoading(operationId, error)

            // Then
            const operation = errorHandlerService.loadingOperationsArray.find(op => op.id === operationId)
            expect(operation?.state).toBe('error')
            expect(operation?.error).toBe(error)
            expect(operation?.endTime).toBeDefined()
        })

        it('should cancel loading operations', () => {
            // Given
            const operationId = 'test-operation'
            errorHandlerService.startLoading(operationId, 'Test')

            // When
            errorHandlerService.cancelLoading(operationId)

            // Then
            expect(errorHandlerService.loadingOperationsArray).toHaveLength(0)
        })
    })

    describe('Network Status Monitoring', () => {
        it('should detect online status', () => {
            // Given
            mockNavigator.onLine = true

            // Then
            expect(errorHandlerService.isOnline).toBe(true)
        })

        it('should detect offline status', () => {
            // Given
            mockNavigator.onLine = false

            // Then
            expect(errorHandlerService.isOnline).toBe(false)
        })

        it('should provide network information', () => {
            // When
            const networkInfo = errorHandlerService.networkInfo

            // Then
            expect(networkInfo.isOnline).toBe(true)
            expect(networkInfo.connectionType).toBe('wifi')
            expect(networkInfo.effectiveType).toBe('4g')
            expect(networkInfo.downlink).toBe(10)
            expect(networkInfo.rtt).toBe(50)
            expect(networkInfo.saveData).toBe(false)
        })
    })

    describe('Notification Management', () => {
        it('should show notifications for appropriate errors', () => {
            // Given
            const serverError = {
                response: {
                    status: 500,
                    data: { message: 'Server Error' }
                }
            }

            // When
            errorHandlerService.handleError(serverError)

            // Then
            expect(errorHandlerService.hasNotifications).toBe(true)
            expect(errorHandlerService.notifications).toHaveLength(1)

            const notification = errorHandlerService.notifications[0]
            expect(notification.type).toBe('error')
            expect(notification.title).toBe('エラーが発生しました')
        })

        it('should not show notifications for validation errors', () => {
            // Given
            const validationError = {
                response: {
                    status: 422,
                    data: { message: 'Validation Error' }
                }
            }

            // When
            errorHandlerService.handleError(validationError)

            // Then
            expect(errorHandlerService.hasNotifications).toBe(false)
        })

        it('should dismiss notifications', () => {
            // Given
            const error = { response: { status: 500, data: { message: 'Error' } } }
            errorHandlerService.handleError(error)
            const notificationId = errorHandlerService.notifications[0].id

            // When
            errorHandlerService.dismissNotification(notificationId)

            // Then
            expect(errorHandlerService.notifications).toHaveLength(0)
        })
    })

    describe('Error Type Conversion', () => {
        it('should convert axios timeout errors correctly', () => {
            // Given
            const timeoutError = {
                code: 'ECONNABORTED',
                request: {}
            }

            // When
            const appError = errorHandlerService.handleError(timeoutError)

            // Then
            expect(appError.type).toBe(ErrorTypeEnum.TIMEOUT_ERROR)
            expect(appError.isRetryable).toBe(true)
        })

        it('should handle unknown errors gracefully', () => {
            // Given
            const unknownError = new Error('Unknown error')

            // When
            const appError = errorHandlerService.handleError(unknownError)

            // Then
            expect(appError.type).toBe(ErrorTypeEnum.UNKNOWN_ERROR)
            expect(appError.message).toBe('Unknown error')
            expect(appError.isRetryable).toBe(false)
        })

        it('should handle errors without messages', () => {
            // Given
            const errorWithoutMessage = {}

            // When
            const appError = errorHandlerService.handleError(errorWithoutMessage)

            // Then
            expect(appError.type).toBe(ErrorTypeEnum.UNKNOWN_ERROR)
            expect(appError.message).toBe('Unknown error occurred')
        })
    })

    describe('Performance and Edge Cases', () => {
        it('should handle many errors efficiently', () => {
            // Given
            const startTime = performance.now()
            const errorCount = 1000

            // When
            for (let i = 0; i < errorCount; i++) {
                errorHandlerService.handleError({
                    message: `Error ${i}`
                })
            }
            const endTime = performance.now()

            // Then
            expect(endTime - startTime).toBeLessThan(1000) // Should complete in less than 1 second
            expect(errorHandlerService.statistics.totalErrors).toBe(errorCount)
        })

        it('should handle concurrent loading operations', () => {
            // Given
            const operationCount = 100
            const operationIds: string[] = []

            // When
            for (let i = 0; i < operationCount; i++) {
                const id = `operation-${i}`
                operationIds.push(id)
                errorHandlerService.startLoading(id, `Operation ${i}`)
            }

            // Then
            expect(errorHandlerService.loadingOperationsArray).toHaveLength(operationCount)

            // Complete all operations
            operationIds.forEach(id => {
                errorHandlerService.completeLoading(id)
            })
        })

        it('should handle malformed error objects', () => {
            // Given
            const malformedErrors = [
                null,
                undefined,
                '',
                0,
                false,
                [],
                { response: null },
                { response: { status: 'invalid' } }
            ]

            // When & Then
            malformedErrors.forEach(error => {
                expect(() => {
                    errorHandlerService.handleError(error)
                }).not.toThrow()
            })
        })
    })

    describe('Integration Scenarios', () => {
        it('should handle error during loading operation', () => {
            // Given
            const operationId = 'failing-operation'
            errorHandlerService.startLoading(operationId, 'Failing Operation')

            // When
            const networkError = { request: {}, message: 'Network failed' }
            const appError = errorHandlerService.handleError(networkError)
            errorHandlerService.failLoading(operationId, appError)

            // Then
            expect(errorHandlerService.hasErrors).toBe(true)
            const operation = errorHandlerService.loadingOperationsArray.find(op => op.id === operationId)
            expect(operation?.state).toBe('error')
            expect(operation?.error).toBe(appError)
        })

        it('should handle network reconnection scenario', () => {
            // Given
            mockNavigator.onLine = false
            const offlineError = { request: {}, message: 'Offline error' }
            errorHandlerService.handleError(offlineError)

            // When - simulate network reconnection
            mockNavigator.onLine = true
            // Trigger online event
            const onlineHandler = mockWindow.addEventListener.mock.calls
                .find(call => call[0] === 'online')?.[1]
            if (onlineHandler) {
                onlineHandler()
            }

            // Then
            expect(errorHandlerService.isOnline).toBe(true)
            // Should show reconnection notification
            expect(errorHandlerService.hasNotifications).toBe(true)
        })
    })
})