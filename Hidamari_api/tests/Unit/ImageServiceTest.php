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
        
        $this->assertIsString($result);
        $this->assertStringContainsString('storage/uploads/', $result);
        
        // Verify file was stored
        $path = str_replace(url('storage/'), '', $result);
        $this->assertTrue(Storage::disk('public')->exists($path));
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
            $this->assertIsString($result);
            $this->assertStringContainsString('storage/uploads/', $result);
            
            // Verify file was stored
            $path = str_replace(url('storage/'), '', $result);
            $this->assertTrue(Storage::disk('public')->exists($path));
        }
    }
}