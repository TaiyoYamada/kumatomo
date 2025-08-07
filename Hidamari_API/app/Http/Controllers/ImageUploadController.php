<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ImageUploadController extends Controller
{
    public function store(Request $request)
    {
        \Log::info('画像アップロードリクエスト受信', [
            'headers' => $request->headers->all(),
            'files' => $request->allFiles(),
            'content_type' => $request->header('Content-Type'),
        ]);

        try {
            $data = $request->validate([
                'image' => 'required|image|max:5120', // 最大5MB
            ]);

            \Log::info('バリデーション成功', ['image_info' => [
                'name' => $data['image']->getClientOriginalName(),
                'size' => $data['image']->getSize(),
                'mime' => $data['image']->getMimeType(),
            ]]);

            $path = $data['image']->store('uploads', 'public'); // storage/app/public/uploads/
            $url = url("storage/{$path}");

            \Log::info('画像アップロード成功', ['path' => $path, 'url' => $url]);

            return response()->json([
                'url' => $url // http://localhost:8000/storage/uploads/xxxx.jpg
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
}
