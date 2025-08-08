export const getErrorMessage = (error) => {
    if (error.response) {
        // Server responded with error status
        const { status, data } = error.response

        if (status === 422 && data.errors) {
            // Validation errors
            const firstError = Object.values(data.errors)[0]
            return Array.isArray(firstError) ? firstError[0] : firstError
        }

        if (data.message) {
            return data.message
        }

        switch (status) {
            case 401:
                return '認証が必要です'
            case 403:
                return 'アクセス権限がありません'
            case 404:
                return 'リソースが見つかりません'
            case 500:
                return 'サーバーエラーが発生しました'
            default:
                return `エラーが発生しました (${status})`
        }
    } else if (error.request) {
        // Network error
        return 'ネットワークエラーが発生しました'
    } else {
        // Other error
        return error.message || '予期しないエラーが発生しました'
    }
}

export const handleApiError = (error, defaultMessage = 'エラーが発生しました') => {
    console.error('API Error:', error)
    return getErrorMessage(error) || defaultMessage
}