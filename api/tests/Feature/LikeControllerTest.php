<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use App\Models\Like;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class LikeControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    /** @test */
    public function it_can_toggle_like_on_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();

        // Like the post
        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/like");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'is_liked' => true,
                'like_count' => 1
            ]);

        $this->assertDatabaseHas('likes', [
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        // Unlike the post
        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/like");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'is_liked' => false,
                'like_count' => 0
            ]);

        $this->assertDatabaseMissing('likes', [
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    /** @test */
    public function it_can_remove_like_from_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();
        
        // Create a like first
        Like::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $response = $this->actingAs($user)
            ->deleteJson("/api/posts/{$post->id}/like");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'is_liked' => false,
                'like_count' => 0
            ]);

        $this->assertDatabaseMissing('likes', [
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    /** @test */
    public function it_returns_404_when_removing_non_existent_like()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();

        $response = $this->actingAs($user)
            ->deleteJson("/api/posts/{$post->id}/like");

        $response->assertStatus(404)
            ->assertJsonFragment([
                'message' => 'いいねが見つかりません'
            ]);
    }

    /** @test */
    public function it_can_get_liked_posts()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create();
        $post2 = Post::factory()->create();
        $post3 = Post::factory()->create();

        // Like post1 and post2
        Like::factory()->create(['post_id' => $post1->id, 'user_id' => $user->id]);
        Like::factory()->create(['post_id' => $post2->id, 'user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->getJson('/api/user/liked-posts');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'content',
                        'like_count',
                        'bookmark_count',
                        'comment_count',
                        'is_liked_by_current_user',
                        'is_bookmarked_by_current_user',
                        'user',
                        'images'
                    ]
                ]
            ]);
    }

    /** @test */
    public function it_can_paginate_liked_posts()
    {
        $user = User::factory()->create();
        
        // Create 15 posts and like them all
        for ($i = 0; $i < 15; $i++) {
            $post = Post::factory()->create();
            Like::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        }

        $response = $this->actingAs($user)
            ->getJson('/api/user/liked-posts?per_page=5&page=1');

        $response->assertStatus(200)
            ->assertJsonCount(5, 'data')
            ->assertJsonStructure([
                'data',
                'current_page',
                'per_page',
                'total'
            ]);

        $this->assertEquals(5, $response->json('per_page'));
        $this->assertEquals(15, $response->json('total'));
    }

    /** @test */
    public function it_requires_authentication_for_like_actions()
    {
        $post = Post::factory()->create();

        $response = $this->postJson("/api/posts/{$post->id}/like");
        $response->assertStatus(401);

        $response = $this->deleteJson("/api/posts/{$post->id}/like");
        $response->assertStatus(401);

        $response = $this->getJson('/api/user/liked-posts');
        $response->assertStatus(401);
    }
}