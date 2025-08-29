<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use App\Models\Shop;
use App\Models\Area;
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
        $shop = Shop::factory()->create();
        $areas = Area::factory()->count(2)->create();

        $images = [
            UploadedFile::fake()->image('image1.jpg'),
            UploadedFile::fake()->image('image2.jpg'),
            UploadedFile::fake()->image('image3.jpg'),
        ];

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'shop_id' => $shop->id,
            'area_ids' => $areas->pluck('id')->toArray(),
            'place_name' => 'テスト場所',
            'latitude' => 35.6762,
            'longitude' => 139.6503,
            'images' => $images,
            'tags' => ['テスト', 'グルメ'],
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'id',
            'content',
            'shop_id',
            'place_name',
            'latitude',
            'longitude',
            'tags',
            'user' => ['id', 'name'],
            'shop' => ['id', 'name'],
            'areas' => [
                '*' => ['id', 'name']
            ],
            'images' => [
                '*' => ['id', 'image_url', 'display_order']
            ]
        ]);

        // データベースに保存されているかチェック
        $this->assertDatabaseHas('posts', [
            'content' => 'テスト投稿です',
            'shop_id' => $shop->id,
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
        $area = Area::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'レガシー投稿です',
            'area_ids' => [$area->id],
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
        $area = Area::factory()->create();

        $images = [];
        for ($i = 0; $i < 5; $i++) { // Changed to 5 since max is now 4
            $images[] = UploadedFile::fake()->image("image{$i}.jpg");
        }

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'area_ids' => [$area->id],
            'images' => $images,
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['images']);
    }

    public function test_validates_content_length()
    {
        $user = User::factory()->create();
        $area = Area::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => str_repeat('あ', 201), // 201文字 (max is now 200)
            'area_ids' => [$area->id],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['content']);
    }

    public function test_validates_required_areas()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['area_ids']);
    }

    public function test_validates_maximum_areas()
    {
        $user = User::factory()->create();
        $areas = Area::factory()->count(6)->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'area_ids' => $areas->pluck('id')->toArray(),
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['area_ids']);
    }

    public function test_validates_area_existence()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'area_ids' => [999], // Non-existent area ID
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['area_ids.0']);
    }

    public function test_can_create_post_with_location_data()
    {
        $user = User::factory()->create();
        $area = Area::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/posts', [
            'content' => 'テスト投稿です',
            'area_ids' => [$area->id],
            'place_name' => '東京駅',
            'latitude' => 35.6812,
            'longitude' => 139.7671,
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('posts', [
            'content' => 'テスト投稿です',
            'place_name' => '東京駅',
            'latitude' => 35.6812,
            'longitude' => 139.7671,
            'user_id' => $user->id,
        ]);
    }

    public function test_can_update_post()
    {
        $user = User::factory()->create();
        $shop = Shop::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user)->putJson("/api/posts/{$post->id}", [
            'content' => '更新された投稿です',
            'shop_id' => $shop->id,
            'tags' => ['更新', 'テスト'],
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('posts', [
            'id' => $post->id,
            'content' => '更新された投稿です',
            'shop_id' => $shop->id,
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

    public function test_can_get_posts_by_shop()
    {
        $user = User::factory()->create();
        $shop = Shop::factory()->create();
        
        // お店に関連する投稿を3つ作成
        Post::factory()->count(3)->create([
            'user_id' => $user->id,
            'shop_id' => $shop->id,
        ]);

        // 他のお店の投稿も作成（結果に含まれないはず）
        $otherShop = Shop::factory()->create();
        Post::factory()->create([
            'user_id' => $user->id,
            'shop_id' => $otherShop->id,
        ]);

        $response = $this->actingAs($user)->getJson("/api/shops/{$shop->id}/posts");

        $response->assertStatus(200);
        $response->assertJsonCount(3, 'data');
        
        // 全ての投稿が指定されたお店のものかチェック
        $posts = $response->json('data');
        foreach ($posts as $post) {
            $this->assertEquals($shop->id, $post['shop_id']);
        }
    }

    public function test_posts_include_relationships()
    {
        $user = User::factory()->create();
        $shop = Shop::factory()->create();
        $areas = Area::factory()->count(2)->create();
        $post = Post::factory()->create([
            'user_id' => $user->id,
            'shop_id' => $shop->id,
        ]);
        
        $post->areas()->attach($areas->pluck('id'));
        PostImage::factory()->count(2)->create(['post_id' => $post->id]);

        $response = $this->actingAs($user)->getJson('/api/posts');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            '*' => [
                'id',
                'content',
                'user' => ['id', 'name'],
                'shop' => ['id', 'name'],
                'areas' => [
                    '*' => ['id', 'name']
                ],
                'images' => [
                    '*' => ['id', 'image_url', 'display_order']
                ]
            ]
        ]);
    }

    public function test_can_get_user_posts()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $shop = Shop::factory()->create();
        $areas = Area::factory()->count(2)->create();
        
        // Create posts for the target user with area and location data
        $userPosts = Post::factory()->count(3)->create([
            'user_id' => $user->id,
            'shop_id' => $shop->id,
            'place_name' => 'Test Location',
            'latitude' => 35.6762,
            'longitude' => 139.6503,
        ]);
        
        // Associate areas with user posts
        foreach ($userPosts as $post) {
            $post->areas()->attach($areas->pluck('id'));
            PostImage::factory()->count(2)->create(['post_id' => $post->id]);
        }

        // Create posts for other user (should not be included)
        Post::factory()->count(2)->create([
            'user_id' => $otherUser->id,
        ]);

        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts");

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'content',
                    'place_name',
                    'latitude',
                    'longitude',
                    'user' => ['id', 'name'],
                    'shop' => ['id', 'name'],
                    'areas' => [
                        '*' => ['id', 'name']
                    ],
                    'images' => [
                        '*' => ['id', 'image_url', 'display_order']
                    ]
                ]
            ],
            'current_page',
            'per_page',
            'total'
        ]);

        // Verify only user's posts are returned
        $posts = $response->json('data');
        $this->assertCount(3, $posts);
        
        foreach ($posts as $post) {
            $this->assertEquals($user->id, $post['user']['id']);
            $this->assertEquals('Test Location', $post['place_name']);
            $this->assertEquals(35.6762, $post['latitude']);
            $this->assertEquals(139.6503, $post['longitude']);
            $this->assertCount(2, $post['areas']);
            $this->assertCount(2, $post['images']);
        }
    }

    public function test_user_posts_pagination()
    {
        $user = User::factory()->create();
        $area = Area::factory()->create();
        
        // Create 15 posts for pagination testing
        $posts = Post::factory()->count(15)->create(['user_id' => $user->id]);
        
        foreach ($posts as $post) {
            $post->areas()->attach($area->id);
        }

        // Test first page with default per_page (10)
        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts");
        
        $response->assertStatus(200);
        $response->assertJsonPath('current_page', 1);
        $response->assertJsonPath('per_page', 10);
        $response->assertJsonPath('total', 15);
        $this->assertCount(10, $response->json('data'));

        // Test second page
        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts?page=2");
        
        $response->assertStatus(200);
        $response->assertJsonPath('current_page', 2);
        $response->assertJsonPath('per_page', 10);
        $response->assertJsonPath('total', 15);
        $this->assertCount(5, $response->json('data'));

        // Test custom per_page
        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts?per_page=5");
        
        $response->assertStatus(200);
        $response->assertJsonPath('current_page', 1);
        $response->assertJsonPath('per_page', 5);
        $response->assertJsonPath('total', 15);
        $this->assertCount(5, $response->json('data'));
    }

    public function test_user_posts_empty_result()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        
        // Create posts for other user only
        Post::factory()->count(3)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts");

        $response->assertStatus(200);
        $response->assertJsonPath('total', 0);
        $this->assertCount(0, $response->json('data'));
    }

    public function test_user_posts_validation()
    {
        $user = User::factory()->create();

        // Test invalid page parameter
        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts?page=0");
        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['page']);

        // Test invalid per_page parameter (too high)
        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts?per_page=100");
        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['per_page']);

        // Test invalid per_page parameter (too low)
        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts?per_page=0");
        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['per_page']);
    }

    public function test_user_posts_include_area_and_location_data()
    {
        $user = User::factory()->create();
        $areas = Area::factory()->count(3)->create();
        
        $post = Post::factory()->create([
            'user_id' => $user->id,
            'place_name' => 'Shibuya Sky',
            'latitude' => 35.6580,
            'longitude' => 139.7016,
        ]);
        
        $post->areas()->attach($areas->pluck('id'));

        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts");

        $response->assertStatus(200);
        $postData = $response->json('data.0');
        
        $this->assertEquals('Shibuya Sky', $postData['place_name']);
        $this->assertEquals(35.6580, $postData['latitude']);
        $this->assertEquals(139.7016, $postData['longitude']);
        $this->assertCount(3, $postData['areas']);
        
        // Verify area data structure
        foreach ($postData['areas'] as $area) {
            $this->assertArrayHasKey('id', $area);
            $this->assertArrayHasKey('name', $area);
        }
    }

    public function test_user_posts_ordered_by_latest()
    {
        $user = User::factory()->create();
        $area = Area::factory()->create();
        
        // Create posts with specific timestamps
        $oldPost = Post::factory()->create([
            'user_id' => $user->id,
            'content' => 'Old post',
            'created_at' => now()->subDays(2),
        ]);
        $oldPost->areas()->attach($area->id);
        
        $newPost = Post::factory()->create([
            'user_id' => $user->id,
            'content' => 'New post',
            'created_at' => now()->subDay(),
        ]);
        $newPost->areas()->attach($area->id);
        
        $newestPost = Post::factory()->create([
            'user_id' => $user->id,
            'content' => 'Newest post',
            'created_at' => now(),
        ]);
        $newestPost->areas()->attach($area->id);

        $response = $this->actingAs($user)->getJson("/api/users/{$user->id}/posts");

        $response->assertStatus(200);
        $posts = $response->json('data');
        
        // Verify posts are ordered by latest first
        $this->assertEquals('Newest post', $posts[0]['content']);
        $this->assertEquals('New post', $posts[1]['content']);
        $this->assertEquals('Old post', $posts[2]['content']);
    }
}