<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\ImageService;
use App\Services\ImageValidationService;
use App\Services\ImageErrorHandler;
use Illuminate\Support\Facades\Log;

class UnifiedImageUploadController extends Controller
{
    protected $imageService;
    protected $validationService;
    protected $errorHandler;

    public function __construct(ImageService $imageService)
    {
        $this->imageService = $imageService;
        $this->validationService = new ImageValidationService();
        $this->errorHandler = new ImageErrorHandler();
    }

    /**
     * 統合画像アップロードエンドポイント
     */
    public function upload(Request $request)
    {
        Log::info('Unified image upload request', [
            'context' => $request->input('context', 'post'),
            'files_count' => count($request->allFiles()),
            'user_id' => $request->user()->id ?? null
        ]);

        try {
            // リクエストバリデーション
            $validated = $request->validate([
                'image' => 'required|file',
                'context' => 'nullable|string|in:post,profile,cover',
            ]);

            $context = $validated['context'] ?? 'post';
            $image = $validated['image'];

            // 画像処理
            $result = $this->imageService->processImage($image, $context);

            Log::info('Unified image upload success', [
                'context' => $context,
                'urls' => $result,
                'user_id' => $request->user()->id ?? null
            ]);

            return $this->errorHandler->createSuccessResponse([
                'url' => $result['medium'], // デフォルトは中サイズ
                'urls' => [
                    'thumbnail' => $result['thumbnail'],
                    'medium' => $result['medium'],
                    'original' => $result['original'] ?? $result['large']
                ],
                'metadata' => $result['metadata'],
                'context' => $context
            ], '画像のアップロードが完了しました');

        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->errorHandler->handleValidationErrors(
                $e->errors(),
                ['context' => $request->input('context', 'post')]
            );
        } catch (\InvalidArgumentException $e) {
            return $this->errorHandler->handleValidationErrors(
                [$e->getMessage()],
                ['context' => $request->input('context', 'post')]
            );
        } catch (\Exception $e) {
            return $this->errorHandler->handleProcessingErrors($e, [
                'context' => $request->input('context', 'post'),
                'user_id' => $request->user()->id ?? null
            ]);
        }
    }

    /**
     * 複数画像の一括アップロード
     */
    public function uploadMultiple(Request $request)
    {
        Log::info('Multiple image upload request', [
            'context' => $request->input('context', 'post'),
            'files_count' => count($request->file('images', [])),
            'user_id' => $request->user()->id ?? null
        ]);

        try {
            $validated = $request->validate([
                'images' => 'required|array|max:5',
                'images.*' => 'required|file',
                'context' => 'nullable|string|in:post,profile,cover',
            ]);

            $context = $validated['context'] ?? 'post';
            $images = $validated['images'];
            $results = [];

            foreach ($images as $index => $image) {
                try {
                    $result = $this->imageService->processImage($image, $context);
                    $results[] = [
                        'url' => $result['medium'],
                        'urls' => [
                            'thumbnail' => $result['thumbnail'],
                            'medium' => $result['medium'],
                            'original' => $result['original'] ?? $result['large']
                        ],
                        'metadata' => $result['metadata'],
                        'index' => $index
                    ];
                } catch (\Exception $e) {
                    Log::error("Failed to process image {$index}", [
                        'error' => $e->getMessage(),
                        'context' => $context
                    ]);
                    // 個別の画像エラーは配列に含めて続行
                    $results[] = [
                        'error' => $e->getMessage(),
                        'index' => $index
                    ];
                }
            }

            Log::info('Multiple image upload completed', [
                'context' => $context,
                'success_count' => count(array_filter($results, fn($r) => !isset($r['error']))),
                'total_count' => count($results)
            ]);

            return $this->errorHandler->createSuccessResponse([
                'images' => $results,
                'context' => $context
            ], '複数画像のアップロードが完了しました');

        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->errorHandler->handleValidationErrors(
                $e->errors(),
                ['context' => $request->input('context', 'post')]
            );
        } catch (\Exception $e) {
            return $this->errorHandler->handleProcessingErrors($e, [
                'context' => $request->input('context', 'post'),
                'user_id' => $request->user()->id ?? null
            ]);
        }
    }
}