<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Facades\Image;
use Illuminate\Support\Facades\Log;

class ImageService
{
    protected $validationService;
    protected $errorHandler;

    // 画像サイズ設定
    const THUMBNAIL_SIZE = 300;
    const MEDIUM_SIZE = 800;
    const LARGE_SIZE = 1200;
    
    // 品質設定
    const HIGH_QUALITY = 90;
    const MEDIUM_QUALITY = 80;
    const LOW_QUALITY = 70;

    // コンテキスト別設定
    const CONTEXT_SETTINGS = [
        'profile' => [
            'sizes' => ['thumbnail' => 150, 'medium' => 400, 'original' => 800],
            'quality' => self::HIGH_QUALITY,
            'directory' => 'profile_images'
        ],
        'cover' => [
            'sizes' => ['thumbnail' => 300, 'medium' => 800, 'original' => 1200],
            'quality' => self::HIGH_QUALITY,
            'directory' => 'cover_images'
        ],
        'post' => [
            'sizes' => ['thumbnail' => 300, 'medium' => 800, 'original' => 1200],
            'quality' => self::MEDIUM_QUALITY,
            'directory' => 'uploads'
        ]
    ];

    public function __construct()
    {
        // 依存関係は必要に応じて後で注入
    }

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
     * 統合された画像処理メソッド
     */
    public function processImage(UploadedFile $image, string $context = 'post'): array
    {
        // 簡単なバリデーション
        if (!$this->isValidImage($image)) {
            throw new \InvalidArgumentException('無効な画像ファイルです');
        }

        $settings = self::CONTEXT_SETTINGS[$context] ?? self::CONTEXT_SETTINGS['post'];
        $filename = $this->generateUniqueFilename($image);
        $directory = $settings['directory'];
        
        $result = [
            'original' => null,
            'medium' => null,
            'thumbnail' => null,
            'metadata' => $this->getImageMetadata($image),
            'context' => $context
        ];

        try {
            // 各サイズの画像を生成
            foreach ($settings['sizes'] as $size => $dimension) {
                $processedImage = $this->resizeAndOptimizeImage(
                    $image, 
                    $dimension, 
                    $dimension, 
                    $settings['quality']
                );
                
                $path = "{$size}_{$directory}/{$filename}";
                Storage::disk('public')->put($path, $processedImage);
                // Use Storage::url() so base path follows filesystem config
                $result[$size] = url(Storage::disk('public')->url($path));
                
                Log::info("Generated {$size} image", [
                    'path' => $path,
                    'url' => $result[$size]
                ]);
            }

            return $result;
        } catch (\Exception $e) {
            Log::error('Image processing failed', [
                'error' => $e->getMessage(),
                'context' => $context,
                'filename' => $filename
            ]);
            throw $e;
        }
    }

    /**
     * 簡単な画像バリデーション
     */
    private function isValidImage(UploadedFile $image): bool
    {
        $allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        
        $mimeType = $image->getMimeType();
        $extension = strtolower($image->getClientOriginalExtension());
        
        return in_array($mimeType, $allowedMimes) && in_array($extension, $allowedExtensions);
    }

    /**
     * 単一の画像をアップロードして処理する（後方互換性）
     *
     * @param UploadedFile $image
     * @param string $directory
     * @param bool $generateThumbnails サムネイル生成フラグ
     * @return array 処理された画像の情報
     */
    public function uploadAndProcessImage(UploadedFile $image, string $directory = 'uploads', bool $generateThumbnails = true): array
    {
        return $this->processImage($image, 'post');
    }

    /**
     * uploadImage alias for backward compatibility
     */
    public function uploadImage(UploadedFile $image, string $directory = 'uploads', bool $generateThumbnails = true): array
    {
        return $this->uploadAndProcessImage($image, $directory, $generateThumbnails);
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
    private function resizeAndOptimizeImage(UploadedFile $image, int $maxWidth = 1200, int $maxHeight = 1200, int $quality = 85): string
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
        // URLからパスを抽出（/images または /storage の両方に対応）
        $baseImages = rtrim(url('images/'), '/');
        $baseStorage = rtrim(url('storage/'), '/');
        $path = $imageUrl;
        if (str_starts_with($path, $baseImages)) {
            $path = ltrim(substr($path, strlen($baseImages)), '/');
        } elseif (str_starts_with($path, $baseStorage)) {
            $path = ltrim(substr($path, strlen($baseStorage)), '/');
        }
        
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
