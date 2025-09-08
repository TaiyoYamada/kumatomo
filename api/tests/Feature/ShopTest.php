<?php

namespace Tests\Feature;

use App\Models\Shop;
use App\Models\User;
use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class ShopTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    /** @test */
    public function it_can_get_shops_list()
    {
        Shop::factory()->count(3)->create();

        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data' => [
                         '*' => [
                             'id',
                             'name',
                             'description',
                             'address',
                             'phone',
                             'business_hours',
                             'genre',
                             'latitude',
                             'longitude',
                             'image_url',
                             'created_at',
                             'updated_at'
                         ]
                     ],
                     'pagination' => [
                         'current_page',
                         'last_page',
                         'per_page',
                         'total'
                     ]
                 ]);
    }

    /** @test */
    public function it_can_filter_shops_by_genre()
    {
        Shop::factory()->create(['genre' => 'レストラン']);
        Shop::factory()->create(['genre' => 'カフェ']);
        Shop::factory()->create(['genre' => 'レストラン']);

        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops?genre=レストラン');

        $response->assertStatus(200);
        $this->assertEquals(2, count($response->json('data')));
        
        foreach ($response->json('data') as $shop) {
            $this->assertEquals('レストラン', $shop['genre']);
        }
    }

    /** @test */
    public function it_can_search_shops_by_location()
    {
        // 東京駅周辺のお店
        Shop::factory()->create([
            'name' => '東京駅近くのお店',
            'latitude' => 35.6812,
            'longitude' => 139.7671
        ]);

        // 大阪駅周辺のお店（遠い）
        Shop::factory()->create([
            'name' => '大阪駅近くのお店',
            'latitude' => 34.7024,
            'longitude' => 135.4959
        ]);

        // 東京駅から半径10km以内で検索
        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops?lat=35.6812&lng=139.7671&radius=10');

        $response->assertStatus(200);
        $this->assertEquals(1, count($response->json('data')));
        $this->assertEquals('東京駅近くのお店', $response->json('data.0.name'));
    }

    /** @test */
    public function it_can_search_shops_by_keyword()
    {
        Shop::factory()->create([
            'name' => 'おいしいラーメン店',
            'description' => '醤油ラーメンが自慢のお店です'
        ]);

        Shop::factory()->create([
            'name' => 'イタリアンレストラン',
            'description' => 'パスタとピザが美味しいお店'
        ]);

        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops/search?q=ラーメン');

        $response->assertStatus(200);
        $this->assertEquals(1, count($response->json('data')));
        $this->assertEquals('おいしいラーメン店', $response->json('data.0.name'));
    }

    /** @test */
    public function it_can_search_shops_by_description()
    {
        Shop::factory()->create([
            'name' => 'ABC Restaurant',
            'description' => '美味しいパスタが自慢のお店です'
        ]);

        Shop::factory()->create([
            'name' => 'XYZ Cafe',
            'description' => 'コーヒーとケーキが人気'
        ]);

        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops/search?q=パスタ');

        $response->assertStatus(200);
        $this->assertEquals(1, count($response->json('data')));
        $this->assertEquals('ABC Restaurant', $response->json('data.0.name'));
    }

    /** @test */
    public function it_can_search_shops_by_address()
    {
        Shop::factory()->create([
            'name' => 'Test Shop',
            'address' => '東京都渋谷区渋谷1-1-1'
        ]);

        Shop::factory()->create([
            'name' => 'Another Shop',
            'address' => '大阪府大阪市北区梅田1-1-1'
        ]);

        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops/search?q=渋谷');

        $response->assertStatus(200);
        $this->assertEquals(1, count($response->json('data')));
        $this->assertEquals('Test Shop', $response->json('data.0.name'));
    }

    /** @test */
    public function it_validates_search_parameters()
    {
        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops/search?q=');

        $response->assertStatus(422)
                 ->assertJsonStructure([
                     'error' => [
                         'code',
                         'message',
                         'details'
                     ]
                 ]);
    }

    /** @test */
    public function it_can_paginate_search_results()
    {
        // 15個のお店を作成
        Shop::factory()->count(15)->create([
            'name' => 'テストショップ'
        ]);

        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops/search?q=テストショップ&per_page=10');

        $response->assertStatus(200);
        $this->assertEquals(10, count($response->json('data')));
        $this->assertEquals(2, $response->json('pagination.last_page'));
        $this->assertEquals(15, $response->json('pagination.total'));
    }

    /** @test */
    public function it_can_combine_filters()
    {
        Shop::factory()->create([
            'name' => 'ラーメン太郎',
            'genre' => 'ラーメン',
            'latitude' => 35.6812,
            'longitude' => 139.7671
        ]);

        Shop::factory()->create([
            'name' => 'ラーメン次郎',
            'genre' => 'ラーメン',
            'latitude' => 34.7024, // 大阪（遠い）
            'longitude' => 135.4959
        ]);

        Shop::factory()->create([
            'name' => 'カフェ太郎',
            'genre' => 'カフェ',
            'latitude' => 35.6812,
            'longitude' => 139.7671
        ]);

        // ジャンル、位置情報、キーワードを組み合わせて検索
        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops?genre=ラーメン&lat=35.6812&lng=139.7671&radius=10&q=太郎');

        $response->assertStatus(200);
        $this->assertEquals(1, count($response->json('data')));
        $this->assertEquals('ラーメン太郎', $response->json('data.0.name'));
    }

    /** @test */
    public function it_can_get_shop_details()
    {
        $shop = Shop::factory()->create();
        
        // お店に関連する投稿を作成
        $posts = Post::factory()->count(3)->create([
            'shop_id' => $shop->id,
            'user_id' => $this->user->id
        ]);

        $response = $this->actingAs($this->user)
                         ->getJson("/api/shops/{$shop->id}");

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data' => [
                         'id',
                         'name',
                         'description',
                         'address',
                         'phone',
                         'business_hours',
                         'genre',
                         'latitude',
                         'longitude',
                         'image_url',
                         'posts' => [
                             '*' => [
                                 'id',
                                 'content',
                                 'user',
                                 'images'
                             ]
                         ]
                     ]
                 ]);
    }

    /** @test */
    public function it_returns_404_for_non_existent_shop()
    {
        $response = $this->actingAs($this->user)
                         ->getJson('/api/shops/999');

        $response->assertStatus(404)
                 ->assertJson([
                     'error' => [
                         'code' => 'SHOP_NOT_FOUND',
                         'message' => 'お店が見つかりません'
                     ]
                 ]);
    }

    /** @test */
    public function it_can_get_posts_for_specific_shop()
    {
        $shop = Shop::factory()->create();
        
        // 特定のお店の投稿を作成
        Post::factory()->count(5)->create([
            'shop_id' => $shop->id,
            'user_id' => $this->user->id
        ]);

        // 他のお店の投稿も作成
        Post::factory()->count(3)->create([
            'shop_id' => Shop::factory()->create()->id,
            'user_id' => $this->user->id
        ]);

        $response = $this->actingAs($this->user)
                         ->getJson("/api/shops/{$shop->id}/posts");

        $response->assertStatus(200);
        $this->assertEquals(5, count($response->json('data')));
        
        foreach ($response->json('data') as $post) {
            $this->assertEquals($shop->id, $post['shop_id']);
        }
    }
}