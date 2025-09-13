<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Bookmark;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Database\QueryException;

class BookmarkModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_bookmark_belongs_to_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        $bookmark = Bookmark::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertInstanceOf(Post::class, $bookmark->post);
        $this->assertEquals($post->id, $bookmark->post->id);
    }

    public function test_bookmark_belongs_to_user()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        $bookmark = Bookmark::factory()->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertInstanceOf(User::class, $bookmark->user);
        $this->assertEquals($user->id, $bookmark->user->id);
    }

    public function test_bookmark_fillable_attributes()
    {
        $bookmark = new Bookmark();
        $fillable = $bookmark->getFillable();

        $this->assertContains('post_id', $fillable);
        $this->assertContains('user_id', $fillable);
    }

    public function test_bookmark_casts()
    {
        $bookmark = new Bookmark();
        $casts = $bookmark->getCasts();

        $this->assertEquals('datetime', $casts['created_at']);
        $this->assertEquals('datetime', $casts['updated_at']);
    }

    public function test_bookmark_can_be_created()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        $bookmark = Bookmark::create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertDatabaseHas('bookmarks', [
            'id' => $bookmark->id,
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    public function test_duplicate_bookmark_throws_exception()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        // Create first bookmark
        Bookmark::create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        // Attempt to create duplicate bookmark should throw exception
        $this->expectException(QueryException::class);
        
        Bookmark::create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);
    }

    public function test_user_can_bookmark_multiple_posts()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create(['user_id' => $user->id]);
        $post2 = Post::factory()->create(['user_id' => $user->id]);
        
        $bookmark1 = Bookmark::create([
            'post_id' => $post1->id,
            'user_id' => $user->id
        ]);

        $bookmark2 = Bookmark::create([
            'post_id' => $post2->id,
            'user_id' => $user->id
        ]);

        $this->assertDatabaseHas('bookmarks', ['id' => $bookmark1->id]);
        $this->assertDatabaseHas('bookmarks', ['id' => $bookmark2->id]);
    }

    public function test_post_can_be_bookmarked_by_multiple_users()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        $bookmark1 = Bookmark::create([
            'post_id' => $post->id,
            'user_id' => $user1->id
        ]);

        $bookmark2 = Bookmark::create([
            'post_id' => $post->id,
            'user_id' => $user2->id
        ]);

        $this->assertDatabaseHas('bookmarks', ['id' => $bookmark1->id]);
        $this->assertDatabaseHas('bookmarks', ['id' => $bookmark2->id]);
    }
}
