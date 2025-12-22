<?php

namespace App\Services;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class ErrorHandlingService
{
    /**
     * Error codes for different types of errors
     */
    const ERROR_CODES = [
        'VALIDATION_ERROR' => 'VALIDATION_ERROR',
        'AUTHENTICATION_REQUIRED' => 'AUTHENTICATION_REQUIRED',
        'ACCESS_DENIED' => 'ACCESS_DENIED',
        'RESOURCE_NOT_FOUND' => 'RESOURCE_NOT_FOUND',
        'SHOP_NOT_FOUND' => 'SHOP_NOT_FOUND',
        'POST_NOT_FOUND' => 'POST_NOT_FOUND',
        'USER_NOT_FOUND' => 'USER_NOT_FOUND',
        'IMAGE_UPLOAD_FAILED' => 'IMAGE_UPLOAD_FAILED',
        'DATABASE_CONNECTION_ERROR' => 'DATABASE_CONNECTION_ERROR',
        'NETWORK_ERROR' => 'NETWORK_ERROR',
        'RATE_LIMIT_EXCEEDED' => 'RATE_LIMIT_EXCEEDED',
        'INTERNAL_SERVER_ERROR' => 'INTERNAL_SERVER_ERROR',
        'SERVICE_UNAVAILABLE' => 'SERVICE_UNAVAILABLE',
    ];

    /**
     * User-friendly error messages in Japanese
     */
    const ERROR_MESSAGES = [
        'VALIDATION_ERROR' => '入力データに問題があります',
        'AUTHENTICATION_REQUIRED' => '認証が必要です',
        'ACCESS_DENIED' => 'アクセス権限がありません',
        'RESOURCE_NOT_FOUND' => 'リソースが見つかりません',
        'SHOP_NOT_FOUND' => 'お店が見つかりません',
        'POST_NOT_FOUND' => '投稿が見つかりません',
        'USER_NOT_FOUND' => 'ユーザーが見つかりません',
        'IMAGE_UPLOAD_FAILED' => '画像のアップロードに失敗しました',
        'DATABASE_CONNECTION_ERROR' => 'データベース接続エラーが発生しました',
        'NETWORK_ERROR' => 'ネットワークエラーが発生しました',
        'RATE_LIMIT_EXCEEDED' => 'リクエスト制限を超えています',
        'INTERNAL_SERVER_ERROR' => 'サーバーエラーが発生しました',
        'SERVICE_UNAVAILABLE' => 'サービスが一時的に利用できません',
    ];

    /**
     * Recovery suggestions for different error types
     */
    const RECOVERY_SUGGESTIONS = [
        'VALIDATION_ERROR' => '入力内容を確認して再試行してください',
        'AUTHENTICATION_REQUIRED' => 'ログインし直してください',
        'ACCESS_DENIED' => '管理者に連絡してください',
        'RESOURCE_NOT_FOUND' => 'リソースが削除されている可能性があります',
        'SHOP_NOT_FOUND' => 'お店が削除されている可能性があります',
        'POST_NOT_FOUND' => '投稿が削除されている可能性があります',
        'USER_NOT_FOUND' => 'ユーザーが削除されている可能性があります',
        'IMAGE_UPLOAD_FAILED' => '画像ファイルを確認して再試行してください',
        'DATABASE_CONNECTION_ERROR' => 'しばらく時間をおいてから再試行してください',
        'NETWORK_ERROR' => 'ネットワーク接続を確認してください',
        'RATE_LIMIT_EXCEEDED' => 'しばらく時間をおいてから再試行してください',
        'INTERNAL_SERVER_ERROR' => 'しばらく時間をおいてから再試行してください',
        'SERVICE_UNAVAILABLE' => 'サービスの復旧をお待ちください',
    ];

    /**
     * Create a standardized error response
     */
    public static function createErrorResponse(
        string $errorCode,
        ?string $customMessage = null,
        ?array $details = null,
        int $statusCode = 400
    ): JsonResponse {
        $message = $customMessage ?? self::ERROR_MESSAGES[$errorCode] ?? 'エラーが発生しました';
        
        $response = [
            'error' => [
                'code' => $errorCode,
                'message' => $message,
                'recovery_suggestion' => self::RECOVERY_SUGGESTIONS[$errorCode] ?? null,
                'timestamp' => now()->toISOString(),
            ]
        ];

        if ($details) {
            $response['error']['details'] = $details;
        }

        // Add debug information in non-production environments
        if (app()->bound('env') && !app()->environment('production')) {
            $response['error']['debug'] = [
                'environment' => app()->environment(),
                'request_id' => request() ? request()->header('X-Request-ID', uniqid()) : uniqid(),
            ];
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Log error with context
     */
    public static function logError(
        Throwable $exception,
        string $context = '',
        array $additionalData = []
    ): void {
        $logData = [
            'message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString(),
            'context' => $context,
            'user_id' => auth()->id(),
            'request_url' => request()->fullUrl(),
            'request_method' => request()->method(),
            'user_agent' => request()->userAgent(),
            'ip_address' => request()->ip(),
            'additional_data' => $additionalData,
        ];

        Log::error('Application Error', $logData);
    }

    /**
     * Handle shop-related errors
     */
    public static function handleShopError(Throwable $exception, string $operation = ''): JsonResponse
    {
        self::logError($exception, "Shop operation: {$operation}");

        if (str_contains($exception->getMessage(), 'not found')) {
            return self::createErrorResponse('SHOP_NOT_FOUND', null, null, 404);
        }

        if (str_contains($exception->getMessage(), 'validation')) {
            return self::createErrorResponse('VALIDATION_ERROR', null, null, 422);
        }

        return self::createErrorResponse('INTERNAL_SERVER_ERROR', null, null, 500);
    }

    /**
     * Handle post-related errors
     */
    public static function handlePostError(Throwable $exception, string $operation = ''): JsonResponse
    {
        self::logError($exception, "Post operation: {$operation}");

        if (str_contains($exception->getMessage(), 'not found')) {
            return self::createErrorResponse('POST_NOT_FOUND', null, null, 404);
        }

        if (str_contains($exception->getMessage(), 'image') || str_contains($exception->getMessage(), 'upload')) {
            return self::createErrorResponse('IMAGE_UPLOAD_FAILED', null, null, 400);
        }

        if (str_contains($exception->getMessage(), 'validation')) {
            return self::createErrorResponse('VALIDATION_ERROR', null, null, 422);
        }

        return self::createErrorResponse('INTERNAL_SERVER_ERROR', null, null, 500);
    }

    /**
     * Handle image upload errors
     */
    public static function handleImageUploadError(Throwable $exception): JsonResponse
    {
        self::logError($exception, 'Image upload operation');

        $details = [];
        
        if (str_contains($exception->getMessage(), 'size')) {
            $details['reason'] = 'ファイルサイズが大きすぎます';
        } elseif (str_contains($exception->getMessage(), 'type')) {
            $details['reason'] = 'サポートされていないファイル形式です';
        } elseif (str_contains($exception->getMessage(), 'storage')) {
            $details['reason'] = 'ストレージの容量が不足しています';
        }

        return self::createErrorResponse(
            'IMAGE_UPLOAD_FAILED',
            null,
            $details,
            400
        );
    }

    /**
     * Check if error should be retried
     */
    public static function isRetryableError(string $errorCode): bool
    {
        $retryableErrors = [
            'DATABASE_CONNECTION_ERROR',
            'NETWORK_ERROR',
            'SERVICE_UNAVAILABLE',
            'INTERNAL_SERVER_ERROR',
        ];

        return in_array($errorCode, $retryableErrors);
    }

    /**
     * Get retry delay in seconds based on error type
     */
    public static function getRetryDelay(string $errorCode): int
    {
        $retryDelays = [
            'DATABASE_CONNECTION_ERROR' => 5,
            'NETWORK_ERROR' => 3,
            'SERVICE_UNAVAILABLE' => 10,
            'INTERNAL_SERVER_ERROR' => 5,
            'RATE_LIMIT_EXCEEDED' => 60,
        ];

        return $retryDelays[$errorCode] ?? 5;
    }
}