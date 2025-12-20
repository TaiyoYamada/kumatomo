<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use App\Models\PostImage;
use App\Services\ImageService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PostTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_can_create_post_with_multiple_images()
    {
        $user = User::factory()->create();

        $images = [
            UploadedFile::fake()->image('image1.jpg'),
            UploadedFile::fake()->image('image2.jpg'),
            UploadedFile::fake()->image('image3.jpg'),
        ];

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'images' => $images,
            'tags' => ['テスト', 'グルメ'],
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'id',
            'content',
            'tags',
            'user' => ['id', 'name'],
            'images' => [
                '*' => ['id', 'image_url', 'display_order']
            ]
        ]);

        // データベースに保存されているかチェック
        $this->assertDatabaseHas('posts', [
            'content' => 'テスト投稿です',
            'user_id' => $user->id,
        ]);

        // 画像が3枚保存されているかチェック
        $post = Post::latest()->first();
        $this->assertCount(3, $post->images);
        
        // 表示順が正しく設定されているかチェック
        $images = $post->images->sortBy('display_order');
        $this->assertEquals(1, $images->first()->display_order);
        $this->assertEquals(3, $images->last()->display_order);
    }

    public function test_can_create_post_with_legacy_image_url()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'レガシー投稿です',
            'image_url' => 'https://example.com/image.jpg',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('posts', [
            'content' => 'レガシー投稿です',
            'image_url' => 'https://example.com/image.jpg',
            'user_id' => $user->id,
        ]);
    }

    public function test_validates_maximum_images()
    {
        $user = User::factory()->create();

        $images = [];
        for ($i = 0; $i < 6; $i++) {
            $images[] = UploadedFile::fake()->image("image{$i}.jpg");
        }

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'images' => $images,
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['images']);
    }

    public function test_validates_content_length()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => str_repeat('あ', 501), // 501文字
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['content']);
    }

    public function test_can_update_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user)->putJson("/api/posts/{$post->id}", [
            'content' => '更新された投稿です',
            'tags' => ['更新', 'テスト'],
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('posts', [
            'id' => $post->id,
            'content' => '更新された投稿です',
        ]);
    }

    public function test_cannot_update_other_users_post()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);

        $response = $this->actingAs($user2)->putJson("/api/posts/{$post->id}", [
            'content' => '他人の投稿を更新',
        ]);

        $response->assertStatus(403);
    }

    public function test_can_delete_post_with_images()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        // 投稿に画像を追加
        PostImage::factory()->count(2)->create(['post_id' => $post->id]);

        $response = $this->actingAs($user)->deleteJson("/api/posts/{$post->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('posts', ['id' => $post->id]);
        $this->assertDatabaseMissing('post_images', ['post_id' => $post->id]);
    }

    public function test_cannot_delete_other_users_post()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);

        $response = $this->actingAs($user2)->deleteJson("/api/posts/{$post->id}");

        $response->assertStatus(403);
        $this->assertDatabaseHas('posts', ['id' => $post->id]);
    }

    public function test_posts_include_relationships()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create([
            'user_id' => $user->id,
        ]);
        
        PostImage::factory()->count(2)->create(['post_id' => $post->id]);

        $response = $this->actingAs($user)->getJson('/api/posts');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            '*' => [
                'id',
                'content',
                'user' => ['id', 'name'],
                'images' => [
                    '*' => ['id', 'image_url', 'display_order']
                ]
            ]
        ]);
    }
}