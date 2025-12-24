<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use App\Models\Comment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CommentControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    /** @test */
    public function it_can_get_comments_for_a_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        $comment = Comment::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id,
            'content' => 'Test comment'
        ]);

        $response = $this->actingAs($user)
            ->getJson("/api/posts/{$post->id}/comments");

        $response->assertStatus(200)
            ->assertJsonCount(1)
            ->assertJsonFragment([
                'content' => 'Test comment'
            ]);
    }

    /** @test */
    public function it_can_create_a_comment()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);

        $commentData = [
            'content' => 'This is a test comment'
        ];

        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/comments", $commentData);

        $response->assertStatus(201)
            ->assertJsonFragment([
                'content' => 'This is a test comment',
                'post_id' => $post->id,
                'user_id' => $user->id
            ]);

        $this->assertDatabaseHas('comments', [
            'content' => 'This is a test comment',
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    /** @test */
    public function it_validates_comment_content()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);

        // Test empty content
        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/comments", ['content' => '']);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['general']);

        // Test content too long
        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/comments", [
                'content' => str_repeat('a', 1001)
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['content']);
    }

    /** @test */
    public function it_can_create_comment_with_image()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);

        $image = UploadedFile::fake()->image('comment.jpg', 500, 500);

        $commentData = [
            'content' => 'Comment with image',
            'image' => $image
        ];

        $response = $this->actingAs($user)
            ->postJson("/api/posts/{$post->id}/comments", $commentData);

        $response->assertStatus(201)
            ->assertJsonFragment([
                'content' => 'Comment with image'
            ])
            ->assertJsonStructure([
                'id',
                'content',
                'image_url',
                'user'
            ]);
    }

    /** @test */
    public function it_can_delete_own_comment()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        $comment = Comment::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $response = $this->actingAs($user)
            ->deleteJson("/api/comments/{$comment->id}");

        $response->assertStatus(200)
            ->assertJsonFragment([
                'message' => 'コメントが削除されました'
            ]);

        $this->assertDatabaseMissing('comments', [
            'id' => $comment->id
        ]);
    }

    /** @test */
    public function it_cannot_delete_other_users_comment()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        $comment = Comment::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user1->id
        ]);

        $response = $this->actingAs($user2)
            ->deleteJson("/api/comments/{$comment->id}");

        $response->assertStatus(403);

        $this->assertDatabaseHas('comments', [
            'id' => $comment->id
        ]);
    }

    /** @test */
    public function post_owner_can_delete_comments_on_their_post()
    {
        $postOwner = User::factory()->create();
        $commenter = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $postOwner->id]);
        $comment = Comment::factory()->create([
            'post_id' => $post->id,
            'user_id' => $commenter->id
        ]);

        $response = $this->actingAs($postOwner)
            ->deleteJson("/api/comments/{$comment->id}");

        $response->assertStatus(200);

        $this->assertDatabaseMissing('comments', [
            'id' => $comment->id
        ]);
    }
}