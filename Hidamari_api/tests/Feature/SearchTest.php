<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Shop;
use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SearchTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // テスト用のユーザーを作成
        $this->user = User::factory()->create();
        
        // テスト用のお店を作成
        $this->shop = Shop::factory()->create([
            'name' => 'テストカフェ',
            'description' => '美味しいコーヒーが飲めるお店',
            'genre' => 'カフェ'
        ]);
        
        // テスト用の投稿を作成
        $this->post = Post::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id,
            'content' => 'テストカフェで美味しいコーヒーを飲みました'
        ]);
    }

    public function test_search_returns_both_posts_and_shops()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=テスト');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'posts' => [
                        '*' => [
                            'id',
                            'content',
                            'user',
                            'shop',
                            'images'
                        ]
                    ],
                    'shops' => [
                        '*' => [
                            'id',
                            'name',
                            'description',
                            'genre'
                        ]
                    ],
                    'pagination'
                ],
                'query',
                'type'
            ]);

        $data = $response->json('data');
        $this->assertNotEmpty($data['posts']);
        $this->assertNotEmpty($data['shops']);
    }

    public function test_search_filters_posts_only()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=テスト&type=posts');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertNotEmpty($data['posts']);
        $this->assertEmpty($data['shops']);
    }

    public function test_search_filters_shops_only()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=テスト&type=shops');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertEmpty($data['posts']);
        $this->assertNotEmpty($data['shops']);
    }

    public function test_search_requires_query_parameter()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['q']);
    }

    public function test_search_validates_query_length()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=' . str_repeat('a', 101));

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['q']);
    }

    public function test_search_validates_type_parameter()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=テスト&type=invalid');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['type']);
    }

    public function test_search_returns_empty_results_for_no_matches()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=存在しないキーワード');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertEmpty($data['posts']);
        $this->assertEmpty($data['shops']);
    }
}