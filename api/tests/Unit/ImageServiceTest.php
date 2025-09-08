<?php

namespace Tests\Unit;

use App\Services\ImageService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ImageServiceTest extends TestCase
{
    protected ImageService $imageService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->imageService = new ImageService();
        Storage::fake('public');
    }

    public function test_can_instantiate_image_service()
    {
        $this->assertInstanceOf(ImageService::class, $this->imageService);
    }

    public function test_delete_image_extracts_path_correctly()
    {
        $imageUrl = 'http://localhost:8000/storage/uploads/test.jpg';
        
        // Create a fake file to delete
        Storage::disk('public')->put('uploads/test.jpg', 'fake content');
        
        $result = $this->imageService->deleteImage($imageUrl);
        
        $this->assertTrue($result);
        $this->assertFalse(Storage::disk('public')->exists('uploads/test.jpg'));
    }

    public function test_delete_image_returns_false_for_nonexistent_file()
    {
        $imageUrl = 'http://localhost:8000/storage/uploads/nonexistent.jpg';
        
        $result = $this->imageService->deleteImage($imageUrl);
        
        $this->assertFalse($result);
    }

    public function test_delete_multiple_images()
    {
        $imageUrls = [
            'http://localhost:8000/storage/uploads/test1.jpg',
            'http://localhost:8000/storage/uploads/test2.jpg',
            'http://localhost:8000/storage/uploads/nonexistent.jpg',
        ];
        
        // Create fake files
        Storage::disk('public')->put('uploads/test1.jpg', 'fake content 1');
        Storage::disk('public')->put('uploads/test2.jpg', 'fake content 2');
        
        $results = $this->imageService->deleteMultipleImages($imageUrls);
        
        $this->assertCount(3, $results);
        $this->assertTrue($results[0]); // test1.jpg deleted
        $this->assertTrue($results[1]); // test2.jpg deleted
        $this->assertFalse($results[2]); // nonexistent.jpg not found
    }

    public function test_upload_and_process_image()
    {
        $image = UploadedFile::fake()->image('test.jpg', 800, 600);
        
        $result = $this->imageService->uploadAndProcessImage($image);
        
        $this->assertIsArray($result);
        $this->assertArrayHasKey('original', $result);
        $this->assertArrayHasKey('medium', $result);
        $this->assertArrayHasKey('thumbnail', $result);
        $this->assertArrayHasKey('metadata', $result);
        
        // Verify URLs are strings and contain storage path
        $this->assertIsString($result['original']);
        $this->assertStringContainsString('storage/original_uploads/', $result['original']);
        $this->assertStringContainsString('storage/medium_uploads/', $result['medium']);
        $this->assertStringContainsString('storage/thumb_uploads/', $result['thumbnail']);
        
        // Verify metadata
        $this->assertIsArray($result['metadata']);
        $this->assertArrayHasKey('original_name', $result['metadata']);
        $this->assertArrayHasKey('size', $result['metadata']);
        $this->assertArrayHasKey('width', $result['metadata']);
        $this->assertArrayHasKey('height', $result['metadata']);
        
        // Verify files were stored
        $originalPath = str_replace(url('storage/'), '', $result['original']);
        $mediumPath = str_replace(url('storage/'), '', $result['medium']);
        $thumbnailPath = str_replace(url('storage/'), '', $result['thumbnail']);
        
        $this->assertTrue(Storage::disk('public')->exists($originalPath));
        $this->assertTrue(Storage::disk('public')->exists($mediumPath));
        $this->assertTrue(Storage::disk('public')->exists($thumbnailPath));
    }

    public function test_upload_multiple_images()
    {
        $images = [
            UploadedFile::fake()->image('test1.jpg'),
            UploadedFile::fake()->image('test2.jpg'),
            UploadedFile::fake()->image('test3.jpg'),
        ];
        
        $results = $this->imageService->uploadMultipleImages($images);
        
        $this->assertCount(3, $results);
        
        foreach ($results as $result) {
            $this->assertIsArray($result);
            $this->assertArrayHasKey('original', $result);
            $this->assertArrayHasKey('medium', $result);
            $this->assertArrayHasKey('thumbnail', $result);
            $this->assertArrayHasKey('metadata', $result);
            
            // Verify files were stored
            $originalPath = str_replace(url('storage/'), '', $result['original']);
            $mediumPath = str_replace(url('storage/'), '', $result['medium']);
            $thumbnailPath = str_replace(url('storage/'), '', $result['thumbnail']);
            
            $this->assertTrue(Storage::disk('public')->exists($originalPath));
            $this->assertTrue(Storage::disk('public')->exists($mediumPath));
            $this->assertTrue(Storage::disk('public')->exists($thumbnailPath));
        }
    }
}