<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Services\ImageService;

class ImageUploadController extends Controller
{
    protected $imageService;

    public function __construct(ImageService $imageService)
    {
        $this->imageService = $imageService;
    }

    public function store(Request $request)
    {
        \Log::info('画像アップロードリクエスト受信', [
            'headers' => $request->headers->all(),
            'files' => $request->allFiles(),
            'content_type' => $request->header('Content-Type'),
        ]);

        try {
            $data = $request->validate([
                'image' => 'required|image|max:10240', // 最大10MB（処理前）
            ]);

            \Log::info('バリデーション成功', ['image_info' => [
                'name' => $data['image']->getClientOriginalName(),
                'size' => $data['image']->getSize(),
                'mime' => $data['image']->getMimeType(),
            ]]);

            // 画像を処理してアップロード
            $result = $this->imageService->uploadAndProcessImage($data['image']);

            \Log::info('画像アップロード成功', [
                'original' => $result['original'],
                'medium' => $result['medium'],
                'thumbnail' => $result['thumbnail'],
                'metadata' => $result['metadata']
            ]);

            return response()->json([
                'url' => $result['medium'], // デフォルトは中サイズを返す
                'urls' => [
                    'original' => $result['original'],
                    'medium' => $result['medium'],
                    'thumbnail' => $result['thumbnail']
                ],
                'metadata' => $result['metadata']
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::error('バリデーションエラー', ['errors' => $e->errors()]);
            return response()->json([
                'error' => 'バリデーションエラー',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('画像アップロードエラー', ['message' => $e->getMessage()]);
            return response()->json([
                'error' => '画像アップロードに失敗しました',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * 複数画像の一括アップロード
     */
    public function storeMultiple(Request $request)
    {
        \Log::info('複数画像アップロードリクエスト受信');

        try {
            $data = $request->validate([
                'images' => 'required|array|max:5',
                'images.*' => 'required|image|max:10240',
            ]);

            $results = $this->imageService->uploadMultipleImages($data['images']);

            \Log::info('複数画像アップロード成功', ['count' => count($results)]);

            return response()->json([
                'images' => array_map(function($result) {
                    return [
                        'url' => $result['medium'],
                        'urls' => [
                            'original' => $result['original'],
                            'medium' => $result['medium'],
                            'thumbnail' => $result['thumbnail']
                        ],
                        'metadata' => $result['metadata']
                    ];
                }, $results)
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::error('複数画像バリデーションエラー', ['errors' => $e->errors()]);
            return response()->json([
                'error' => 'バリデーションエラー',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('複数画像アップロードエラー', ['message' => $e->getMessage()]);
            return response()->json([
                'error' => '複数画像アップロードに失敗しました',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}
