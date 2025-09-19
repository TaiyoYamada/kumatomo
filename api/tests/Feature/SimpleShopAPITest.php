<?php

namespace Tests\Feature;

use App\Models\Shop;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SimpleShopAPITest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_fetch_shops_basic()
    {
        // Create a simple shop
        Shop::factory()->create([
            'name' => 'Test Shop',
            'is_approved' => true
        ]);

        $response = $this->getJson('/api/shops');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'data' => [
                        '*' => ['id', 'name']
                    ]
                ]);
    }
}