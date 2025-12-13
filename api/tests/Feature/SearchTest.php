<?php

namespace Tests\Feature;

use App\Models\User;
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
        
        // テスト用の投稿を作成
        $this->post = Post::factory()->create([
            'user_id' => $this->user->id,
            'content' => 'テスト投稿です'
        ]);
    }

    public function test_search_returns_posts()
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
                            'images'
                        ]
                    ],
                    'pagination'
                ],
                'query',
                'type'
            ]);

        $data = $response->json('data');
        $this->assertNotEmpty($data['posts']);
    }

    public function test_search_filters_posts_only()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/search?q=テスト&type=posts');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertNotEmpty($data['posts']);
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
    }
}