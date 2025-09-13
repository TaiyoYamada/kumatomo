<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use App\Models\Bookmark;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class BookmarkControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    /** @test */
    public function it_can_toggle_bookmark_on_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();

        // Bookmark the post
        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/bookmark");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'is_bookmarked' => true,
                'bookmark_count' => 1
            ]);

        $this->assertDatabaseHas('bookmarks', [
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        // Remove bookmark
        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/bookmark");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'is_bookmarked' => false,
                'bookmark_count' => 0
            ]);

        $this->assertDatabaseMissing('bookmarks', [
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    /** @test */
    public function it_can_remove_bookmark_from_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();
        
        // Create a bookmark first
        Bookmark::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $response = $this->actingAs($user)
            ->deleteJson("/api/posts/{$post->id}/bookmark");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'is_bookmarked' => false,
                'bookmark_count' => 0
            ]);

        $this->assertDatabaseMissing('bookmarks', [
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    /** @test */
    public function it_returns_404_when_removing_non_existent_bookmark()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();

        $response = $this->actingAs($user)
            ->deleteJson("/api/posts/{$post->id}/bookmark");

        $response->assertStatus(404)
            ->assertJsonFragment([
                'message' => 'ブックマークが見つかりません'
            ]);
    }

    /** @test */
    public function it_can_get_bookmarked_posts()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create();
        $post2 = Post::factory()->create();
        $post3 = Post::factory()->create();

        // Bookmark post1 and post2
        Bookmark::factory()->create(['post_id' => $post1->id, 'user_id' => $user->id]);
        Bookmark::factory()->create(['post_id' => $post2->id, 'user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->getJson('/api/user/bookmarked-posts');

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
    public function it_can_paginate_bookmarked_posts()
    {
        $user = User::factory()->create();
        
        // Create 15 posts and bookmark them all
        for ($i = 0; $i < 15; $i++) {
            $post = Post::factory()->create();
            Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        }

        $response = $this->actingAs($user)
            ->getJson('/api/user/bookmarked-posts?per_page=5&page=1');

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
    public function it_requires_authentication_for_bookmark_actions()
    {
        $post = Post::factory()->create();

        $response = $this->postJson("/api/posts/{$post->id}/bookmark");
        $response->assertStatus(401);

        $response = $this->deleteJson("/api/posts/{$post->id}/bookmark");
        $response->assertStatus(401);

        $response = $this->getJson('/api/user/bookmarked-posts');
        $response->assertStatus(401);
    }
}