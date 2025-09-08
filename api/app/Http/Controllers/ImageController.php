<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

class ImageController extends Controller
{
    /**
     * 画像ファイルを配信する
     */
    public function show(Request $request, $path)
    {
        // パスをデコード
        $decodedPath = urldecode($path);
        
        // セキュリティチェック: パストラバーサル攻撃を防ぐ
        if (strpos($decodedPath, '..') !== false) {
            abort(404);
        }
        
        // デバッグログ
        \Log::info('画像リクエスト', [
            'original_path' => $path,
            'decoded_path' => $decodedPath,
            'exists' => Storage::disk('public')->exists($decodedPath)
        ]);
        
        // ファイルの存在確認
        if (!Storage::disk('public')->exists($decodedPath)) {
            // 利用可能なファイル一覧をログ出力（デバッグ用）
            $files = Storage::disk('public')->allFiles('uploads');
            \Log::info('利用可能ファイル', ['files' => $files]);
            abort(404);
        }
        
        // ファイルの内容を取得
        $file = Storage::disk('public')->get($decodedPath);
        $mimeType = Storage::disk('public')->mimeType($decodedPath);
        
        return response($file, 200)
            ->header('Content-Type', $mimeType)
            ->header('Cache-Control', 'public, max-age=31536000'); // 1年間キャッシュ
    }

    /**
     * 古い形式の画像ファイルを配信する（/storage/uploads/用）
     */
    public function showStorage(Request $request, $filename)
    {
        // uploadsディレクトリのファイルパスを構築
        $path = 'uploads/' . $filename;
        
        // セキュリティチェック: パストラバーサル攻撃を防ぐ
        if (strpos($filename, '..') !== false) {
            abort(404);
        }
        
        // デバッグログ
        \Log::info('古い形式の画像リクエスト', [
            'filename' => $filename,
            'path' => $path,
            'exists' => Storage::disk('public')->exists($path)
        ]);
        
        // ファイルの存在確認
        if (!Storage::disk('public')->exists($path)) {
            abort(404);
        }
        
        // ファイルの内容を取得
        $file = Storage::disk('public')->get($path);
        $mimeType = Storage::disk('public')->mimeType($path);
        
        return response($file, 200)
            ->header('Content-Type', $mimeType)
            ->header('Cache-Control', 'public, max-age=31536000'); // 1年間キャッシュ
    }
}