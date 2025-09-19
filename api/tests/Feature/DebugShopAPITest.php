<?php

namespace Tests\Feature;

use App\Models\Shop;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DebugShopAPITest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_can_fetch_shops_with_genres_parameter()
    {
        // Create shops with genres
        Shop::factory()->create([
            'name' => 'Ramen Shop',
            'genre' => 'ラーメン',
            'is_approved' => true
        ]);

        Shop::factory()->create([
            'name' => 'Cafe Shop',
            'genre' => 'カフェ',
            'is_approved' => true
        ]);

        $response = $this->getJson('/api/shops?genres=ラーメン,カフェ');

        // Debug the response
        if ($response->status() !== 200) {
            dump('Response status: ' . $response->status());
            dump('Response content: ' . $response->getContent());
        }

        $response->assertStatus(200);
    }
}