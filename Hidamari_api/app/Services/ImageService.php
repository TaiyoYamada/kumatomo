<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Facades\Image;

class ImageService
{
    /**
     * 複数の画像をアップロードして処理する
     *
     * @param array $images UploadedFileの配列
     * @param string $directory 保存ディレクトリ
     * @return array 処理された画像のURL配列
     */
    public function uploadMultipleImages(array $images, string $directory = 'uploads'): array
    {
        $uploadedImages = [];

        foreach ($images as $image) {
            $uploadedImages[] = $this->uploadAndProcessImage($image, $directory);
        }

        return $uploadedImages;
    }

    /**
     * 単一の画像をアップロードして処理する
     *
     * @param UploadedFile $image
     * @param string $directory
     * @return string 処理された画像のURL
     */
    public function uploadAndProcessImage(UploadedFile $image, string $directory = 'uploads'): string
    {
        // 一意のファイル名を生成
        $filename = uniqid() . '_' . time() . '.' . $image->getClientOriginalExtension();
        $path = $directory . '/' . $filename;

        // 画像をリサイズして保存
        $processedImage = $this->resizeImage($image);
        Storage::disk('public')->put($path, $processedImage);

        return url("storage/{$path}");
    }

    /**
     * 画像をリサイズする
     *
     * @param UploadedFile $image
     * @param int $maxWidth 最大幅
     * @param int $maxHeight 最大高さ
     * @param int $quality 品質 (1-100)
     * @return string リサイズされた画像データ
     */
    private function resizeImage(UploadedFile $image, int $maxWidth = 1200, int $maxHeight = 1200, int $quality = 85): string
    {
        // Intervention/Imageが利用可能な場合はリサイズ処理を行う
        if (class_exists('Intervention\Image\Facades\Image')) {
            $img = Image::make($image->getRealPath());
            
            // アスペクト比を保持してリサイズ
            $img->resize($maxWidth, $maxHeight, function ($constraint) {
                $constraint->aspectRatio();
                $constraint->upsize(); // 元画像より大きくしない
            });

            return $img->encode($image->getClientOriginalExtension(), $quality)->__toString();
        }

        // Intervention/Imageが利用できない場合は元の画像をそのまま返す
        return file_get_contents($image->getRealPath());
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