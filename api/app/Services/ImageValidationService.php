<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;

class ImageValidationService
{
    // 許可されるMIMEタイプ
    const ALLOWED_MIME_TYPES = [
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/gif',
        'image/webp'
    ];

    // 許可される拡張子
    const ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

    // コンテキスト別のファイルサイズ制限（バイト）
    const SIZE_LIMITS = [
        'profile' => 5 * 1024 * 1024,    // 5MB
        'post' => 10 * 1024 * 1024,      // 10MB
        'cover' => 8 * 1024 * 1024,      // 8MB
        'default' => 10 * 1024 * 1024    // 10MB
    ];

    // 最大画像サイズ（ピクセル）
    const MAX_DIMENSIONS = [
        'width' => 4096,
        'height' => 4096
    ];

    /**
     * 画像ファイルの包括的なバリデーション
     */
    public function validateImage(UploadedFile $file, string $context = 'default'): array
    {
        $errors = [];

        // ファイルタイプの検証
        if (!$this->validateFileType($file)) {
            $errors[] = '許可されていないファイル形式です。JPEG、PNG、GIF、WebPのみ対応しています。';
        }

        // ファイルサイズの検証
        if (!$this->validateFileSize($file, $context)) {
            $maxSize = $this->getMaxSizeForContext($context);
            $errors[] = "ファイルサイズが大きすぎます。最大{$maxSize}MBまでです。";
        }

        // 画像の寸法検証
        if (!$this->validateDimensions($file)) {
            $errors[] = '画像サイズが大きすぎます。最大4096x4096ピクセルまでです。';
        }

        // セキュリティ検証
        if (!$this->validateSecurity($file)) {
            $errors[] = 'セキュリティ上の問題が検出されました。';
        }

        return [
            'valid' => empty($errors),
            'errors' => $errors
        ];
    }

    /**
     * ファイルタイプの検証
     */
    public function validateFileType(UploadedFile $file): bool
    {
        // MIMEタイプの検証
        $mimeType = $file->getMimeType();
        if (!in_array($mimeType, self::ALLOWED_MIME_TYPES)) {
            Log::warning('Invalid MIME type', ['mime' => $mimeType]);
            return false;
        }

        // 拡張子の検証
        $extension = strtolower($file->getClientOriginalExtension());
        if (!in_array($extension, self::ALLOWED_EXTENSIONS)) {
            Log::warning('Invalid extension', ['extension' => $extension]);
            return false;
        }

        // ファイルの実際の内容を検証
        $imageInfo = @getimagesize($file->getRealPath());
        if ($imageInfo === false) {
            Log::warning('Invalid image file', ['path' => $file->getRealPath()]);
            return false;
        }

        return true;
    }

    /**
     * ファイルサイズの検証
     */
    public function validateFileSize(UploadedFile $file, string $context = 'default'): bool
    {
        $maxSize = self::SIZE_LIMITS[$context] ?? self::SIZE_LIMITS['default'];
        return $file->getSize() <= $maxSize;
    }

    /**
     * 画像寸法の検証
     */
    public function validateDimensions(UploadedFile $file): bool
    {
        $imageInfo = @getimagesize($file->getRealPath());
        if ($imageInfo === false) {
            return false;
        }

        $width = $imageInfo[0];
        $height = $imageInfo[1];

        return $width <= self::MAX_DIMENSIONS['width'] && 
               $height <= self::MAX_DIMENSIONS['height'];
    }

    /**
     * セキュリティ検証
     */
    public function validateSecurity(UploadedFile $file): bool
    {
        // ファイルの先頭バイトを確認してマジックナンバーをチェック
        $handle = fopen($file->getRealPath(), 'rb');
        if (!$handle) {
            return false;
        }

        $header = fread($handle, 10);
        fclose($handle);

        // 一般的な画像ファイルのマジックナンバー
        $validHeaders = [
            "\xFF\xD8\xFF",           // JPEG
            "\x89\x50\x4E\x47",       // PNG
            "\x47\x49\x46\x38",       // GIF
            "\x52\x49\x46\x46",       // WebP (RIFF)
        ];

        foreach ($validHeaders as $validHeader) {
            if (strpos($header, $validHeader) === 0) {
                return true;
            }
        }

        Log::warning('Invalid file header', ['header' => bin2hex($header)]);
        return false;
    }

    /**
     * コンテキストに応じた最大ファイルサイズを取得（MB単位）
     */
    private function getMaxSizeForContext(string $context): int
    {
        $bytes = self::SIZE_LIMITS[$context] ?? self::SIZE_LIMITS['default'];
        return round($bytes / (1024 * 1024));
    }
}