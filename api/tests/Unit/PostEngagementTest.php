<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Post;
use App\Models\User;
use App\Models\Comment;
use App\Models\Like;
use App\Models\Bookmark;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PostEngagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_post_has_many_comments()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        Comment::factory()->count(3)->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertCount(3, $post->comments);
        $this->assertInstanceOf(Comment::class, $post->comments->first());
    }

    public function test_post_has_many_likes()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user2->id]);

        $this->assertCount(2, $post->likes);
        $this->assertInstanceOf(Like::class, $post->likes->first());
    }

    public function test_post_has_many_bookmarks()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user2->id]);

        $this->assertCount(2, $post->bookmarks);
        $this->assertInstanceOf(Bookmark::class, $post->bookmarks->first());
    }

    public function test_post_like_count_attribute()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user2->id]);

        $this->assertEquals(2, $post->like_count);
    }

    public function test_post_bookmark_count_attribute()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user2->id]);

        $this->assertEquals(2, $post->bookmark_count);
    }

    public function test_post_comment_count_attribute()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        Comment::factory()->count(3)->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertEquals(3, $post->comment_count);
    }

    public function test_post_is_liked_by_user()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);

        $this->assertTrue($post->isLikedByUser($user1->id));
        $this->assertFalse($post->isLikedByUser($user2->id));
    }

    public function test_post_is_bookmarked_by_user()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);

        $this->assertTrue($post->isBookmarkedByUser($user1->id));
        $this->assertFalse($post->isBookmarkedByUser($user2->id));
    }

    public function test_post_get_engagement_data_for_user()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user1->id]);
        
        // Create engagement data
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);
        Like::factory()->create(['post_id' => $post->id, 'user_id' => $user2->id]);
        Bookmark::factory()->create(['post_id' => $post->id, 'user_id' => $user1->id]);
        Comment::factory()->count(2)->create(['post_id' => $post->id, 'user_id' => $user1->id]);

        $engagementData = $post->getEngagementDataForUser($user1->id);

        $this->assertEquals(2, $engagementData['like_count']);
        $this->assertEquals(1, $engagementData['bookmark_count']);
        $this->assertEquals(2, $engagementData['comment_count']);
        $this->assertTrue($engagementData['is_liked_by_current_user']);
        $this->assertTrue($engagementData['is_bookmarked_by_current_user']);
    }

    public function test_user_has_many_comments()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['user_id' => $user->id]);
        
        Comment::factory()->count(2)->create([
            'post_id' => $post->id,
            'user_id' => $user->id
        ]);

        $this->assertCount(2, $user->comments);
        $this->assertInstanceOf(Comment::class, $user->comments->first());
    }

    public function test_user_has_many_likes()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create(['user_id' => $user->id]);
        $post2 = Post::factory()->create(['user_id' => $user->id]);
        
        Like::factory()->create(['post_id' => $post1->id, 'user_id' => $user->id]);
        Like::factory()->create(['post_id' => $post2->id, 'user_id' => $user->id]);

        $this->assertCount(2, $user->likes);
        $this->assertInstanceOf(Like::class, $user->likes->first());
    }

    public function test_user_has_many_bookmarks()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create(['user_id' => $user->id]);
        $post2 = Post::factory()->create(['user_id' => $user->id]);
        
        Bookmark::factory()->create(['post_id' => $post1->id, 'user_id' => $user->id]);
        Bookmark::factory()->create(['post_id' => $post2->id, 'user_id' => $user->id]);

        $this->assertCount(2, $user->bookmarks);
        $this->assertInstanceOf(Bookmark::class, $user->bookmarks->first());
    }

    public function test_user_liked_posts_relationship()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create(['user_id' => $user->id]);
        $post2 = Post::factory()->create(['user_id' => $user->id]);
        
        Like::factory()->create(['post_id' => $post1->id, 'user_id' => $user->id]);
        Like::factory()->create(['post_id' => $post2->id, 'user_id' => $user->id]);

        $likedPosts = $user->likedPosts;
        
        $this->assertCount(2, $likedPosts);
        $this->assertInstanceOf(Post::class, $likedPosts->first());
        $this->assertTrue($likedPosts->contains($post1));
        $this->assertTrue($likedPosts->contains($post2));
    }

    public function test_user_bookmarked_posts_relationship()
    {
        $user = User::factory()->create();
        $post1 = Post::factory()->create(['user_id' => $user->id]);
        $post2 = Post::factory()->create(['user_id' => $user->id]);
        
        Bookmark::factory()->create(['post_id' => $post1->id, 'user_id' => $user->id]);
        Bookmark::factory()->create(['post_id' => $post2->id, 'user_id' => $user->id]);

        $bookmarkedPosts = $user->bookmarkedPosts;
        
        $this->assertCount(2, $bookmarkedPosts);
        $this->assertInstanceOf(Post::class, $bookmarkedPosts->first());
        $this->assertTrue($bookmarkedPosts->contains($post1));
        $this->assertTrue($bookmarkedPosts->contains($post2));
    }
}
