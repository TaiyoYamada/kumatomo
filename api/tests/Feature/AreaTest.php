<?php

namespace Tests\Feature;

use App\Models\Area;
use App\Models\User;
use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class AreaTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    /** @test */
    public function it_can_get_areas_list()
    {
        // Create test areas
        Area::factory()->create(['name' => '渋谷区']);
        Area::factory()->create(['name' => '新宿区']);
        Area::factory()->create(['name' => '港区']);

        $response = $this->actingAs($this->user)
                         ->getJson('/api/areas');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     '*' => [
                         'id',
                         'name',
                         'created_at',
                         'updated_at'
                     ]
                 ]);

        $this->assertEquals(3, count($response->json()));
        
        // Check that areas are ordered by name
        $areas = $response->json();
        $this->assertEquals('新宿区', $areas[0]['name']);
        $this->assertEquals('渋谷区', $areas[1]['name']);
        $this->assertEquals('港区', $areas[2]['name']);
    }

    /** @test */
    public function it_returns_empty_array_when_no_areas_exist()
    {
        $response = $this->actingAs($this->user)
                         ->getJson('/api/areas');

        $response->assertStatus(200)
                 ->assertJson([]);
    }

    /** @test */
    public function it_can_get_posts_for_specific_area()
    {
        // Create area and posts
        $area = Area::factory()->create(['name' => '渋谷区']);
        $otherArea = Area::factory()->create(['name' => '新宿区']);
        
        // Create posts associated with the area
        $posts = Post::factory()->count(3)->create([
            'user_id' => $this->user->id
        ]);
        
        // Associate posts with the area
        foreach ($posts as $post) {
            $post->areas()->attach($area->id);
        }
        
        // Create posts for other area (should not be included)
        $otherPosts = Post::factory()->count(2)->create([
            'user_id' => $this->user->id
        ]);
        
        foreach ($otherPosts as $post) {
            $post->areas()->attach($otherArea->id);
        }

        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts");

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data' => [
                         '*' => [
                             'id',
                             'content',
                             'user_id',
                             'user',
                             'shop',
                             'images',
                             'areas',
                             'created_at',
                             'updated_at'
                         ]
                     ],
                     'current_page',
                     'last_page',
                     'per_page',
                     'total'
                 ]);

        $this->assertEquals(3, count($response->json('data')));
        $this->assertEquals(3, $response->json('total'));
    }

    /** @test */
    public function it_returns_empty_array_when_area_has_no_posts()
    {
        $area = Area::factory()->create(['name' => '渋谷区']);

        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts");

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data',
                     'current_page',
                     'last_page',
                     'per_page',
                     'total'
                 ]);

        $this->assertEquals(0, count($response->json('data')));
        $this->assertEquals(0, $response->json('total'));
    }

    /** @test */
    public function it_returns_404_when_area_does_not_exist()
    {
        $response = $this->actingAs($this->user)
                         ->getJson('/api/areas/999/posts');

        $response->assertStatus(404)
                 ->assertJson([
                     'error' => [
                         'code' => 'AREA_NOT_FOUND',
                         'message' => '指定されたエリアが見つかりません'
                     ]
                 ]);
    }

    /** @test */
    public function it_can_paginate_area_posts()
    {
        $area = Area::factory()->create(['name' => '渋谷区']);
        
        // Create 15 posts
        $posts = Post::factory()->count(15)->create([
            'user_id' => $this->user->id
        ]);
        
        // Associate all posts with the area
        foreach ($posts as $post) {
            $post->areas()->attach($area->id);
        }

        // Test first page with 10 items per page
        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts?per_page=10&page=1");

        $response->assertStatus(200);
        $this->assertEquals(10, count($response->json('data')));
        $this->assertEquals(1, $response->json('current_page'));
        $this->assertEquals(2, $response->json('last_page'));
        $this->assertEquals(15, $response->json('total'));

        // Test second page
        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts?per_page=10&page=2");

        $response->assertStatus(200);
        $this->assertEquals(5, count($response->json('data')));
        $this->assertEquals(2, $response->json('current_page'));
    }

    /** @test */
    public function it_validates_pagination_parameters()
    {
        $area = Area::factory()->create(['name' => '渋谷区']);

        // Test invalid page parameter
        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts?page=0");

        $response->assertStatus(422)
                 ->assertJsonStructure([
                     'error' => [
                         'code',
                         'message',
                         'details'
                     ]
                 ]);

        // Test invalid per_page parameter
        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts?per_page=100");

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
    public function it_orders_area_posts_by_latest()
    {
        $area = Area::factory()->create(['name' => '渋谷区']);
        
        // Create posts with different timestamps
        $oldPost = Post::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => now()->subDays(2)
        ]);
        
        $newPost = Post::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => now()->subDay()
        ]);
        
        $newestPost = Post::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => now()
        ]);
        
        // Associate all posts with the area
        $oldPost->areas()->attach($area->id);
        $newPost->areas()->attach($area->id);
        $newestPost->areas()->attach($area->id);

        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts");

        $response->assertStatus(200);
        
        $posts = $response->json('data');
        $this->assertEquals($newestPost->id, $posts[0]['id']);
        $this->assertEquals($newPost->id, $posts[1]['id']);
        $this->assertEquals($oldPost->id, $posts[2]['id']);
    }

    /** @test */
    public function it_includes_related_data_in_area_posts()
    {
        $area = Area::factory()->create(['name' => '渋谷区']);
        $post = Post::factory()->create([
            'user_id' => $this->user->id
        ]);
        
        $post->areas()->attach($area->id);

        $response = $this->actingAs($this->user)
                         ->getJson("/api/areas/{$area->id}/posts");

        $response->assertStatus(200);
        
        $postData = $response->json('data.0');
        $this->assertArrayHasKey('user', $postData);
        $this->assertArrayHasKey('shop', $postData);
        $this->assertArrayHasKey('images', $postData);
        $this->assertArrayHasKey('areas', $postData);
        
        // Check that the area is included in the areas relationship
        $this->assertEquals(1, count($postData['areas']));
        $this->assertEquals($area->id, $postData['areas'][0]['id']);
        $this->assertEquals($area->name, $postData['areas'][0]['name']);
    }

    /** @test */
    public function it_requires_authentication_for_areas_endpoint()
    {
        $response = $this->getJson('/api/areas');
        $response->assertStatus(401);
    }

    /** @test */
    public function it_requires_authentication_for_area_posts_endpoint()
    {
        $area = Area::factory()->create();
        
        $response = $this->getJson("/api/areas/{$area->id}/posts");
        $response->assertStatus(401);
    }
}