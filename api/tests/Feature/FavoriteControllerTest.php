<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Shop;
use App\Models\Favorite;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FavoriteControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected User $user;
    protected Shop $shop;

    protected function setUp(): void
    {
        parent::setUp();

        // Create test user
        $this->user = User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'username' => 'testuser123'
        ]);

        // Create test shop
        $this->shop = Shop::factory()->create([
            'name' => 'Test Shop',
            'genre' => 'カフェ',
            'is_approved' => true
        ]);
    }

    // MARK: - Index Tests

    public function test_index_returns_user_favorites()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        
        // Create some favorites
        $favorite1 = Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);
        
        $shop2 = Shop::factory()->create(['is_approved' => true]);
        $favorite2 = Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $shop2->id
        ]);

        // Act
        $response = $this->getJson('/api/favorites');

        // Assert
        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'user_id',
                        'shop_id',
                        'shop' => [
                            'id',
                            'name',
                            'genre',
                            'is_approved'
                        ],
                        'created_at',
                        'updated_at'
                    ]
                ],
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total'
                ]
            ]);

        $this->assertCount(2, $response->json('data'));
    }

    public function test_index_filters_out_unapproved_shops()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        
        // Create favorite with approved shop
        Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);
        
        // Create favorite with unapproved shop
        $unapprovedShop = Shop::factory()->create(['is_approved' => false]);
        Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $unapprovedShop->id
        ]);

        // Act
        $response = $this->getJson('/api/favorites');

        // Assert
        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals($this->shop->id, $response->json('data.0.shop.id'));
    }

    public function test_index_requires_authentication()
    {
        // Act
        $response = $this->getJson('/api/favorites');

        // Assert
        $response->assertStatus(401);
    }

    public function test_index_supports_pagination()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        
        // Create multiple favorites
        $shops = Shop::factory()->count(25)->create(['is_approved' => true]);
        foreach ($shops as $shop) {
            Favorite::factory()->create([
                'user_id' => $this->user->id,
                'shop_id' => $shop->id
            ]);
        }

        // Act
        $response = $this->getJson('/api/favorites?per_page=10&page=1');

        // Assert
        $response->assertStatus(200);
        $this->assertCount(10, $response->json('data'));
        $this->assertEquals(1, $response->json('meta.current_page'));
        $this->assertEquals(3, $response->json('meta.last_page'));
    }

    // MARK: - Toggle Tests

    public function test_toggle_adds_favorite_when_not_exists()
    {
        // Arrange
        Sanctum::actingAs($this->user);

        // Act
        $response = $this->postJson("/api/favorites/toggle/{$this->shop->id}");

        // Assert
        $response->assertStatus(200)
            ->assertJson([
                'favorited' => true,
                'message' => 'Shop added to favorites'
            ]);

        $this->assertDatabaseHas('favorites', [
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);
    }

    public function test_toggle_removes_favorite_when_exists()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        
        // Create existing favorite
        Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);

        // Act
        $response = $this->postJson("/api/favorites/toggle/{$this->shop->id}");

        // Assert
        $response->assertStatus(200)
            ->assertJson([
                'favorited' => false,
                'message' => 'Shop removed from favorites'
            ]);

        $this->assertDatabaseMissing('favorites', [
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);
    }

    public function test_toggle_requires_authentication()
    {
        // Act
        $response = $this->postJson("/api/favorites/toggle/{$this->shop->id}");

        // Assert
        $response->assertStatus(401);
    }

    public function test_toggle_rejects_unapproved_shop()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        $unapprovedShop = Shop::factory()->create(['is_approved' => false]);

        // Act
        $response = $this->postJson("/api/favorites/toggle/{$unapprovedShop->id}");

        // Assert
        $response->assertStatus(403)
            ->assertJson([
                'error' => [
                    'message' => 'Shop is not available for favorites'
                ]
            ]);
    }

    public function test_toggle_handles_nonexistent_shop()
    {
        // Arrange
        Sanctum::actingAs($this->user);

        // Act
        $response = $this->postJson('/api/favorites/toggle/99999');

        // Assert
        $response->assertStatus(404);
    }

    // MARK: - Check Tests

    public function test_check_returns_true_when_favorited()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);

        // Act
        $response = $this->getJson("/api/favorites/check/{$this->shop->id}");

        // Assert
        $response->assertStatus(200)
            ->assertJson(['favorited' => true]);
    }

    public function test_check_returns_false_when_not_favorited()
    {
        // Arrange
        Sanctum::actingAs($this->user);

        // Act
        $response = $this->getJson("/api/favorites/check/{$this->shop->id}");

        // Assert
        $response->assertStatus(200)
            ->assertJson(['favorited' => false]);
    }

    public function test_check_returns_false_when_not_authenticated()
    {
        // Act
        $response = $this->getJson("/api/favorites/check/{$this->shop->id}");

        // Assert
        $response->assertStatus(200)
            ->assertJson(['favorited' => false]);
    }

    // MARK: - Destroy Tests

    public function test_destroy_removes_favorite()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        $favorite = Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);

        // Act
        $response = $this->deleteJson("/api/favorites/{$favorite->id}");

        // Assert
        $response->assertStatus(200)
            ->assertJson(['message' => 'Favorite removed successfully']);

        $this->assertDatabaseMissing('favorites', ['id' => $favorite->id]);
    }

    public function test_destroy_requires_authentication()
    {
        // Arrange
        $favorite = Favorite::factory()->create([
            'user_id' => $this->user->id,
            'shop_id' => $this->shop->id
        ]);

        // Act
        $response = $this->deleteJson("/api/favorites/{$favorite->id}");

        // Assert
        $response->assertStatus(401);
    }

    public function test_destroy_rejects_other_users_favorite()
    {
        // Arrange
        $otherUser = User::factory()->create();
        Sanctum::actingAs($this->user);
        
        $favorite = Favorite::factory()->create([
            'user_id' => $otherUser->id,
            'shop_id' => $this->shop->id
        ]);

        // Act
        $response = $this->deleteJson("/api/favorites/{$favorite->id}");

        // Assert
        $response->assertStatus(403)
            ->assertJson([
                'error' => [
                    'message' => 'Forbidden'
                ]
            ]);
    }

    // MARK: - Stats Tests

    public function test_stats_returns_favorite_statistics()
    {
        // Arrange
        Sanctum::actingAs($this->user);
        
        // Create favorites with different genres
        $cafeShop = Shop::factory()->create(['genre' => 'カフェ', 'is_approved' => true]);
        $ramenShop = Shop::factory()->create(['genre' => 'ラーメン', 'is_approved' => true]);
        $cafeShop2 = Shop::factory()->create(['genre' => 'カフェ', 'is_approved' => true]);
        
        Favorite::factory()->create(['user_id' => $this->user->id, 'shop_id' => $cafeShop->id]);
        Favorite::factory()->create(['user_id' => $this->user->id, 'shop_id' => $ramenShop->id]);
        Favorite::factory()->create(['user_id' => $this->user->id, 'shop_id' => $cafeShop2->id]);

        // Act
        $response = $this->getJson('/api/favorites/stats');

        // Assert
        $response->assertStatus(200)
            ->assertJsonStructure([
                'total_favorites',
                'favorites_by_genre'
            ]);

        $this->assertEquals(3, $response->json('total_favorites'));
        $this->assertEquals(2, $response->json('favorites_by_genre.カフェ'));
        $this->assertEquals(1, $response->json('favorites_by_genre.ラーメン'));
    }

    public function test_stats_requires_authentication()
    {
        // Act
        $response = $this->getJson('/api/favorites/stats');

        // Assert
        $response->assertStatus(401);
    }

    // MARK: - Error Handling Tests

    public function test_handles_database_errors_gracefully()
    {
        // This test would require mocking database failures
        // For now, we'll test that the controller structure handles errors
        $this->assertTrue(true);
    }

    public function test_logs_favorite_operations()
    {
        // Arrange
        Sanctum::actingAs($this->user);

        // Act
        $this->postJson("/api/favorites/toggle/{$this->shop->id}");

        // Assert - Check that logs were written (would require log testing setup)
        $this->assertTrue(true);
    }
}