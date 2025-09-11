<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class UnifiedImageUploadTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_single_image_upload_success()
    {
        $user = User::factory()->create();
        $image = UploadedFile::fake()->image('test.jpg', 800, 600);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/images/upload', [
                'image' => $image,
                'context' => 'post'
            ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'url',
                    'urls' => ['thumbnail', 'medium', 'original'],
                    'metadata',
                    'context'
                ]
            ]);
    }

    public function test_multiple_image_upload_success()
    {
        $user = User::factory()->create();
        $images = [
            UploadedFile::fake()->image('test1.jpg', 800, 600),
            UploadedFile::fake()->image('test2.jpg', 800, 600)
        ];

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/images/upload-multiple', [
                'images' => $images,
                'context' => 'post'
            ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'images' => [
                        '*' => [
                            'url',
                            'urls' => ['thumbnail', 'medium', 'original'],
                            'metadata',
                            'index'
                        ]
                    ],
                    'context'
                ]
            ]);
    }

    public function test_image_validation_failure()
    {
        $user = User::factory()->create();
        $invalidFile = UploadedFile::fake()->create('test.txt', 100);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/images/upload', [
                'image' => $invalidFile,
                'context' => 'post'
            ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'error' => [
                    'code',
                    'message',
                    'details'
                ]
            ]);
    }

    public function test_unauthenticated_upload_fails()
    {
        $image = UploadedFile::fake()->image('test.jpg', 800, 600);

        $response = $this->postJson('/api/images/upload', [
            'image' => $image,
            'context' => 'post'
        ]);

        $response->assertStatus(401);
    }
}