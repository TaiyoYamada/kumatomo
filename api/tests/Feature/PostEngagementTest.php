<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use App\Models\Like;
use App\Models\Bookmark;
use App\Models\Comment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class PostEngagementTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    /** @test */
    public function post_index_includes_engagement_data_for_authenticated_users()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $otherUser->id]);

        // Create engagement data
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $otherUser->id]);
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        Comment::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->getJson('/api/posts');

        $response->assertStatus(200)
            ->assertJsonStructure([
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
            ])
            ->assertJsonFragment([
                'like_count' => 2,
                'bookmark_count' => 1,
                'comment_count' => 1,
                'is_liked_by_current_user' => true,
                'is_bookmarked_by_current_user' => true
            ]);
    }

    /** @test */
    public function post_show_includes_engagement_data_and_comments()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create();

        // Create engagement data
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        $comment = Comment::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->getJson("/api/posts/{$post->id}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'id',
                'content',
                'like_count',
                'bookmark_count',
                'comment_count',
                'is_liked_by_current_user',
                'is_bookmarked_by_current_user',
                'user',
                'images',
                'comments' => [
                    '*' => [
                        'id',
                        'content',
                        'user' => [
                            'id',
                            'name',
                            'username',
                            'profile_image_url'
                        ]
                    ]
                ]
            ])
            ->assertJsonFragment([
                'like_count' => 1,
                'bookmark_count' => 1,
                'comment_count' => 1,
                'is_liked_by_current_user' => true,
                'is_bookmarked_by_current_user' => true
            ]);
    }

    /** @test */
    public function posts_by_user_includes_engagement_data()
    {
        $user = User::factory()->create();
        $postOwner = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $postOwner->id]);

        // Create engagement data
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->getJson("/api/users/{$postOwner->id}/posts");

        $response->assertStatus(200)
            ->assertJsonStructure([
                '*' => [
                    'id',
                    'content',
                    'like_count',
                    'bookmark_count',
                    'comment_count',
                    'is_liked_by_current_user',
                    'is_bookmarked_by_current_user'
                ]
            ])
            ->assertJsonFragment([
                'like_count' => 1,
                'bookmark_count' => 1,
                'is_liked_by_current_user' => true,
                'is_bookmarked_by_current_user' => true
            ]);
    }

    /** @test */
    public function unauthenticated_users_dont_get_engagement_status()
    {
        $post = Post::factory()->create();
        Like::factory()->create(['post_id' => $post->id]);

        $response = $this->getJson('/api/posts');

        $response->assertStatus(200);
        
        $postData = $response->json()[0];
        $this->assertArrayNotHasKey('like_count', $postData);
        $this->assertArrayNotHasKey('is_liked_by_current_user', $postData);
    }
}