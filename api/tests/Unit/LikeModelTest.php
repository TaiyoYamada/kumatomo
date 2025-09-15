<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Like;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Database\QueryException;

class LikeModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_like_belongs_to_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        $like = Like::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertInstanceOf(Post::class, $like->post);
        $this->assertEquals($post->id, $like->post->id);
    }

    public function test_like_belongs_to_user()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        $like = Like::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertInstanceOf(User::class, $like->user);
        $this->assertEquals($user->id, $like->user->id);
    }

    public function test_like_fillable_attributes()
    {
        $like = new Like();
        $fillable = $like->getFillable();

        $this->assertContains('post_id', $fillable);
        $this->assertContains('user_id', $fillable);
    }

    public function test_like_casts()
    {
        $like = new Like();
        $casts = $like->getCasts();

        $this->assertEquals('datetime', $casts['created_at']);
        $this->assertEquals('datetime', $casts['updated_at']);
    }

    public function test_like_can_be_created()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        $like = Like::create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertDatabaseHas('likes', [
            'id' => $like->id,
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    public function test_duplicate_like_throws_exception()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        // Create first like
        Like::create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        // Attempt to create duplicate like should throw exception
        $this->expectException(QueryException::class);
        
        Like::create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    public function test_user_can_like_multiple_posts()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create(['user_id' => $user->id]);
        $post2 = Post::factory()->create(['user_id' => $user->id]);
        
        $like1 = Like::create([
            'post_id' => $post1->id,
            'user_id' => $user->id
        ]);

        $like2 = Like::create([
            'post_id' => $post2->id,
            'user_id' => $user->id
        ]);

        $this->assertDatabaseHas('likes', ['id' => $like1->id]);
        $this->assertDatabaseHas('likes', ['id' => $like2->id]);
    }

    public function test_post_can_be_liked_by_multiple_users()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        $like1 = Like::create([
            'post_id' => $post->id,
            'user_id' => $user1->id
        ]);

        $like2 = Like::create([
            'post_id' => $post->id,
            'user_id' => $user2->id
        ]);

        $this->assertDatabaseHas('likes', ['id' => $like1->id]);
        $this->assertDatabaseHas('likes', ['id' => $like2->id]);
    }
}
