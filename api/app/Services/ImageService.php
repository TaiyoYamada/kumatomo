<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Facades\Image;

class ImageService
{
    // 画像サイズ設定
    const THUMBNAIL_SIZE = 300;
    const MEDIUM_SIZE = 800;
    const LARGE_SIZE = 1200;
    
    // 品質設定
    const HIGH_QUALITY = 90;
    const MEDIUM_QUALITY = 80;
    const LOW_QUALITY = 70;

    /**
     * 複数の画像をアップロードして処理する
     *
     * @param array $images UploadedFileの配列
     * @param string $directory 保存ディレクトリ
     * @param bool $generateThumbnails サムネイル生成フラグ
     * @return array 処理された画像のURL配列
     */
    public function uploadMultipleImages(array $images, string $directory = 'uploads', bool $generateThumbnails = true): array
    {
        $uploadedImages = [];

        foreach ($images as $image) {
            $result = $this->uploadAndProcessImage($image, $directory, $generateThumbnails);
            $uploadedImages[] = $result;
        }

        return $uploadedImages;
    }

    /**
     * 単一の画像をアップロードして処理する
     *
     * @param UploadedFile $image
     * @param string $directory
     * @param bool $generateThumbnails サムネイル生成フラグ
     * @return array 処理された画像の情報
     */
    public function uploadAndProcessImage(UploadedFile $image, string $directory = 'uploads', bool $generateThumbnails = true): array
    {
        // ファイル名とパスの生成
        $filename = $this->generateUniqueFilename($image);
        $basePath = $directory . '/' . $filename;
        
        $result = [
            'original' => null,
            'medium' => null,
            'thumbnail' => null,
            'metadata' => $this->getImageMetadata($image)
        ];

        // オリジナル画像の処理と保存
        $originalImage = $this->processImage($image, self::LARGE_SIZE, self::LARGE_SIZE, self::HIGH_QUALITY);
        $originalPath = 'original_' . $basePath;
        Storage::disk('public')->put($originalPath, $originalImage);
        $result['original'] = url("storage/{$originalPath}");

        // 中サイズ画像の生成
        $mediumImage = $this->processImage($image, self::MEDIUM_SIZE, self::MEDIUM_SIZE, self::MEDIUM_QUALITY);
        $mediumPath = 'medium_' . $basePath;
        Storage::disk('public')->put($mediumPath, $mediumImage);
        $result['medium'] = url("storage/{$mediumPath}");

        // サムネイル画像の生成
        if ($generateThumbnails) {
            $thumbnailImage = $this->processImage($image, self::THUMBNAIL_SIZE, self::THUMBNAIL_SIZE, self::LOW_QUALITY);
            $thumbnailPath = 'thumb_' . $basePath;
            Storage::disk('public')->put($thumbnailPath, $thumbnailImage);
            $result['thumbnail'] = url("storage/{$thumbnailPath}");
        }

        return $result;
    }

    /**
     * 画像を処理する（リサイズ、最適化）
     *
     * @param UploadedFile $image
     * @param int $maxWidth 最大幅
     * @param int $maxHeight 最大高さ
     * @param int $quality 品質 (1-100)
     * @return string 処理された画像データ
     */
    private function processImage(UploadedFile $image, int $maxWidth = 1200, int $maxHeight = 1200, int $quality = 85): string
    {
        // Intervention/Imageが利用可能な場合はリサイズ処理を行う
        if (class_exists('Intervention\Image\Facades\Image')) {
            $img = Image::make($image->getRealPath());
            
            // EXIF情報に基づく自動回転
            $img->orientate();
            
            // アスペクト比を保持してリサイズ
            $img->resize($maxWidth, $maxHeight, function ($constraint) {
                $constraint->aspectRatio();
                $constraint->upsize(); // 元画像より大きくしない
            });

            // 画像の最適化
            $img->sharpen(10); // 軽いシャープネス
            
            // フォーマットに応じた最適化
            $extension = strtolower($image->getClientOriginalExtension());
            if (in_array($extension, ['jpg', 'jpeg'])) {
                return $img->encode('jpg', $quality)->__toString();
            } elseif ($extension === 'png') {
                // PNGの場合は透明度を保持
                return $img->encode('png')->__toString();
            } elseif ($extension === 'webp') {
                return $img->encode('webp', $quality)->__toString();
            }

            return $img->encode($extension, $quality)->__toString();
        }

        // Intervention/Imageが利用できない場合は元の画像をそのまま返す
        return file_get_contents($image->getRealPath());
    }

    /**
     * 一意のファイル名を生成
     */
    private function generateUniqueFilename(UploadedFile $image): string
    {
        $extension = $image->getClientOriginalExtension();
        $hash = hash('sha256', $image->getRealPath() . microtime());
        return substr($hash, 0, 32) . '_' . time() . '.' . $extension;
    }

    /**
     * 画像のメタデータを取得
     */
    private function getImageMetadata(UploadedFile $image): array
    {
        $metadata = [
            'original_name' => $image->getClientOriginalName(),
            'size' => $image->getSize(),
            'mime_type' => $image->getMimeType(),
            'extension' => $image->getClientOriginalExtension(),
        ];

        // 画像の寸法を取得
        if ($imageInfo = getimagesize($image->getRealPath())) {
            $metadata['width'] = $imageInfo[0];
            $metadata['height'] = $imageInfo[1];
            $metadata['aspect_ratio'] = round($imageInfo[0] / $imageInfo[1], 2);
        }

        return $metadata;
    }

    /**
     * 画像の遅延読み込み用のレスポンシブURLを生成
     */
    public function generateResponsiveUrls(string $baseUrl): array
    {
        $pathInfo = pathinfo($baseUrl);
        $directory = dirname($pathInfo['dirname']);
        $filename = $pathInfo['filename'] . '.' . $pathInfo['extension'];

        return [
            'thumbnail' => str_replace($filename, 'thumb_' . $filename, $baseUrl),
            'medium' => str_replace($filename, 'medium_' . $filename, $baseUrl),
            'original' => str_replace($filename, 'original_' . $filename, $baseUrl),
        ];
    }

    /**
     * 画像ファイルを削除する
     *
     * @param string $imageUrl
     * @return bool
     */
    public function deleteImage(string $imageUrl): bool
    {
        // URLからパスを抽出
        $path = str_replace(url('storage/'), '', $imageUrl);
        
        if (Storage::disk('public')->exists($path)) {
            return Storage::disk('public')->delete($path);
        }

        return false;
    }

    /**
     * 複数の画像ファイルを削除する
     *
     * @param array $imageUrls
     * @return array 削除結果の配列
     */
    public function deleteMultipleImages(array $imageUrls): array
    {
        $results = [];

        foreach ($imageUrls as $imageUrl) {
            $results[] = $this->deleteImage($imageUrl);
        }

        return $results;
    }
}