<?php

namespace Tests\Feature;

use App\Models\Shop;
use App\Models\User;
use App\Models\Favorite;
use App\Models\ShopProposal;
use App\Enums\ShopGenre;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use Laravel\Sanctum\Sanctum;

class EnhancedShopAPITest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Create test user
        $this->user = User::factory()->create();
        
        // Create test shops with different genres
        $this->shops = Shop::factory()->count(15)->create([
            'is_approved' => true,
            'latitude' => $this->faker->latitude(35.0, 36.0), // Around Tokyo area
            'longitude' => $this->faker->longitude(139.0, 140.0),
        ]);
        
        // Set specific genres for testing
        $genres = ['ラーメン', 'カフェ', '居酒屋', '焼肉', 'スイーツ'];
        foreach ($this->shops->take(5) as $index => $shop) {
            $shop->update(['genre' => $genres[$index]]);
        }
    }

    /** @test */
    public function it_can_fetch_shops_with_multi_genre_filtering()
    {
        $response = $this->getJson('/api/shops?genres=ラーメン,カフェ');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'data' => [
                        '*' => [
                            'id', 'name', 'genre', 'latitude', 'longitude',
                            'has_try_benefit', 'stamp_count', 'is_approved'
                        ]
                    ],
                    'pagination' => [
                        'current_page', 'last_page', 'per_page', 'total',
                        'from', 'to', 'has_more_pages'
                    ],
                    'filters' => [
                        'genres', 'location', 'search', 'sort_by', 'sort_order'
                    ]
                ]);

        $data = $response->json('data');
        foreach ($data as $shop) {
            $this->assertContains($shop['genre'], ['ラーメン', 'カフェ']);
        }
    }

    /** @test */
    public function it_can_fetch_shops_with_location_filtering()
    {
        $lat = 35.6762;
        $lng = 139.6503;
        $radius = 5;

        $response = $this->getJson("/api/shops?lat={$lat}&lng={$lng}&radius={$radius}");

        $response->assertStatus(200);
        
        $data = $response->json('data');
        foreach ($data as $shop) {
            $this->assertArrayHasKey('distance', $shop);
            $this->assertLessThanOrEqual($radius, $shop['distance']);
        }
    }

    /** @test */
    public function it_can_sort_shops_by_different_fields()
    {
        $response = $this->getJson('/api/shops?sort_by=name&sort_order=asc');
        $response->assertStatus(200);

        $data = $response->json('data');
        $names = array_column($data, 'name');
        $sortedNames = $names;
        sort($sortedNames);
        $this->assertEquals($sortedNames, $names);
    }

    /** @test */
    public function it_validates_shop_list_parameters()
    {
        $response = $this->getJson('/api/shops?lat=invalid&lng=200&radius=-5');

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['lat', 'lng', 'radius']);
    }

    /** @test */
    public function it_can_fetch_user_favorites_with_filtering()
    {
        Sanctum::actingAs($this->user);

        // Create some favorites
        $favoriteShops = $this->shops->take(3);
        foreach ($favoriteShops as $shop) {
            Favorite::create([
                'user_id' => $this->user->id,
                'shop_id' => $shop->id
            ]);
        }

        $response = $this->getJson('/api/favorites');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'data' => [
                        '*' => [
                            'id', 'user_id', 'shop_id', 'created_at',
                            'name', 'genre', 'address' // Shop fields from join
                        ]
                    ],
                    'pagination',
                    'filters'
                ]);

        $this->assertCount(3, $response->json('data'));
    }

    /** @test */
    public function it_can_filter_favorites_by_genre()
    {
        Sanctum::actingAs($this->user);

        // Create favorites with specific genres
        $ramenShop = $this->shops->where('genre', 'ラーメン')->first();
        $cafeShop = $this->shops->where('genre', 'カフェ')->first();
        
        Favorite::create(['user_id' => $this->user->id, 'shop_id' => $ramenShop->id]);
        Favorite::create(['user_id' => $this->user->id, 'shop_id' => $cafeShop->id]);

        $response = $this->getJson('/api/favorites?genres=ラーメン');

        $response->assertStatus(200);
        $data = $response->json('data');
        
        $this->assertCount(1, $data);
        $this->assertEquals('ラーメン', $data[0]['genre']);
    }

    /** @test */
    public function it_can_filter_favorites_by_location()
    {
        Sanctum::actingAs($this->user);

        // Create a favorite
        $shop = $this->shops->first();
        $shop->update(['latitude' => 35.6762, 'longitude' => 139.6503]);
        
        Favorite::create(['user_id' => $this->user->id, 'shop_id' => $shop->id]);

        $response = $this->getJson('/api/favorites?lat=35.6762&lng=139.6503&radius=1');

        $response->assertStatus(200);
        $data = $response->json('data');
        
        $this->assertCount(1, $data);
        $this->assertArrayHasKey('distance', $data[0]);
    }

    /** @test */
    public function it_can_toggle_favorite_status()
    {
        Sanctum::actingAs($this->user);
        $shop = $this->shops->first();

        // Add to favorites
        $response = $this->postJson("/api/favorites/toggle/{$shop->id}");
        $response->assertStatus(200)
                ->assertJson(['favorited' => true]);

        $this->assertDatabaseHas('favorites', [
            'user_id' => $this->user->id,
            'shop_id' => $shop->id
        ]);

        // Remove from favorites
        $response = $this->postJson("/api/favorites/toggle/{$shop->id}");
        $response->assertStatus(200)
                ->assertJson(['favorited' => false]);

        $this->assertDatabaseMissing('favorites', [
            'user_id' => $this->user->id,
            'shop_id' => $shop->id
        ]);
    }

    /** @test */
    public function it_can_check_favorite_status()
    {
        Sanctum::actingAs($this->user);
        $shop = $this->shops->first();

        // Check when not favorited
        $response = $this->getJson("/api/favorites/check/{$shop->id}");
        $response->assertStatus(200)
                ->assertJson(['favorited' => false]);

        // Add to favorites
        Favorite::create(['user_id' => $this->user->id, 'shop_id' => $shop->id]);

        // Check when favorited
        $response = $this->getJson("/api/favorites/check/{$shop->id}");
        $response->assertStatus(200)
                ->assertJson(['favorited' => true]);
    }

    /** @test */
    public function it_can_get_favorite_statistics()
    {
        Sanctum::actingAs($this->user);

        // Create favorites with different genres
        $ramenShop = $this->shops->where('genre', 'ラーメン')->first();
        $cafeShop = $this->shops->where('genre', 'カフェ')->first();
        
        Favorite::create(['user_id' => $this->user->id, 'shop_id' => $ramenShop->id]);
        Favorite::create(['user_id' => $this->user->id, 'shop_id' => $cafeShop->id]);

        $response = $this->getJson('/api/favorites/stats');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'total_favorites',
                    'favorites_by_genre'
                ]);

        $stats = $response->json();
        $this->assertEquals(2, $stats['total_favorites']);
        $this->assertArrayHasKey('ラーメン', $stats['favorites_by_genre']);
        $this->assertArrayHasKey('カフェ', $stats['favorites_by_genre']);
    }

    /** @test */
    public function it_requires_authentication_for_favorite_operations()
    {
        $shop = $this->shops->first();

        $this->postJson("/api/favorites/toggle/{$shop->id}")
             ->assertStatus(401);

        $this->getJson('/api/favorites')
             ->assertStatus(401);

        $this->getJson('/api/favorites/stats')
             ->assertStatus(401);
    }

    /** @test */
    public function it_handles_pagination_correctly()
    {
        $response = $this->getJson('/api/shops?per_page=5&page=1');

        $response->assertStatus(200);
        
        $pagination = $response->json('pagination');
        $this->assertEquals(1, $pagination['current_page']);
        $this->assertEquals(5, $pagination['per_page']);
        $this->assertLessThanOrEqual(5, count($response->json('data')));
    }

    /** @test */
    public function it_limits_per_page_parameter()
    {
        $response = $this->getJson('/api/shops?per_page=100');

        $response->assertStatus(200);
        
        $pagination = $response->json('pagination');
        $this->assertLessThanOrEqual(50, $pagination['per_page']);
    }

    /** @test */
    public function it_only_returns_approved_shops()
    {
        // Create unapproved shop
        Shop::factory()->create(['is_approved' => false]);

        $response = $this->getJson('/api/shops');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        foreach ($data as $shop) {
            $this->assertTrue($shop['is_approved']);
        }
    }

    /** @test */
    public function it_can_search_shops_with_keyword()
    {
        $shop = $this->shops->first();
        $shop->update(['name' => 'Test Ramen Shop']);

        $response = $this->getJson('/api/shops?q=Test');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        $this->assertGreaterThan(0, count($data));
        $this->assertStringContainsString('Test', $data[0]['name']);
    }

    /** @test */
    public function it_handles_empty_results_gracefully()
    {
        $response = $this->getJson('/api/shops?genres=NonExistentGenre');

        $response->assertStatus(200)
                ->assertJson([
                    'data' => [],
                    'pagination' => [
                        'total' => 0
                    ]
                ]);
    }

    /** @test */
    public function it_maintains_backward_compatibility_with_single_genre_filter()
    {
        $response = $this->getJson('/api/shops?genre=ラーメン');

        $response->assertStatus(200);
        
        $data = $response->json('data');
        foreach ($data as $shop) {
            if ($shop['genre']) {
                $this->assertEquals('ラーメン', $shop['genre']);
            }
        }
    }
}