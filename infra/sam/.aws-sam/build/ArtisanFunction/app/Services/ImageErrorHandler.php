<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Illuminate\Http\JsonResponse;

class ImageErrorHandler
{
    /**
     * バリデーションエラーの処理
     */
    public function handleValidationErrors(array $errors, array $context = []): JsonResponse
    {
        Log::warning('Image validation failed', [
            'errors' => $errors,
            'context' => $context
        ]);

        return response()->json([
            'error' => [
                'code' => 'VALIDATION_FAILED',
                'message' => '画像のバリデーションに失敗しました',
                'details' => $errors
            ]
        ], 422);
    }

    /**
     * 画像処理エラーの処理
     */
    public function handleProcessingErrors(\Exception $e, array $context = []): JsonResponse
    {
        Log::error('Image processing failed', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'context' => $context
        ]);

        return response()->json([
            'error' => [
                'code' => 'PROCESSING_FAILED',
                'message' => '画像の処理中にエラーが発生しました',
                'details' => config('app.debug') ? $e->getMessage() : '内部エラーが発生しました'
            ]
        ], 500);
    }

    /**
     * ストレージエラーの処理
     */
    public function handleStorageErrors(\Exception $e, array $context = []): JsonResponse
    {
        Log::error('Image storage failed', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'context' => $context
        ]);

        return response()->json([
            'error' => [
                'code' => 'STORAGE_FAILED',
                'message' => '画像の保存中にエラーが発生しました',
                'details' => config('app.debug') ? $e->getMessage() : 'ストレージエラーが発生しました'
            ]
        ], 500);
    }

    /**
     * 一般的なエラーの処理
     */
    public function handleGenericError(\Exception $e, array $context = []): JsonResponse
    {
        Log::error('Image operation failed', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'context' => $context
        ]);

        return response()->json([
            'error' => [
                'code' => 'IMAGE_OPERATION_FAILED',
                'message' => '画像操作中にエラーが発生しました',
                'details' => config('app.debug') ? $e->getMessage() : '予期しないエラーが発生しました'
            ]
        ], 500);
    }

    /**
     * 成功レスポンスの生成
     */
    public function createSuccessResponse(array $data, string $message = '操作が完了しました'): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data
        ]);
    }
}