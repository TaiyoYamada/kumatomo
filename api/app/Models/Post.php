<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    /**
     * 一括代入可能な属性。
     */
    protected $fillable = [
        'user_id',
        'content',
        'image_url',
        'tags',
        'shop_id',
    ];

    protected $casts = [
        'tags' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * この投稿が関連するお店を取得。
     */
    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    /**
     * この投稿の画像を取得。
     */
    public function images()
    {
        return $this->hasMany(PostImage::class)->orderBy('display_order');
    }

    /**
     * Get the comments for the post.
     */
    public function comments()
    {
        return $this->hasMany(Comment::class)->orderBy('created_at', 'asc');
    }

    /**
     * Get the likes for the post.
     */
    public function likes()
    {
        return $this->hasMany(Like::class);
    }

    /**
     * Get the bookmarks for the post.
     */
    public function bookmarks()
    {
        return $this->hasMany(Bookmark::class);
    }

    /**
     * Get the like count for the post.
     */
    public function getLikeCountAttribute()
    {
        return $this->likes()->count();
    }

    /**
     * Get the bookmark count for the post.
     */
    public function getBookmarkCountAttribute()
    {
        return $this->bookmarks()->count();
    }

    /**
     * Get the comment count for the post.
     */
    public function getCommentCountAttribute()
    {
        return $this->comments()->count();
    }

    /**
     * Check if the post is liked by a specific user.
     */
    public function isLikedByUser($userId)
    {
        return $this->likes()->where('user_id', $userId)->exists();
    }

    /**
     * Check if the post is bookmarked by a specific user.
     */
    public function isBookmarkedByUser($userId)
    {
        return $this->bookmarks()->where('user_id', $userId)->exists();
    }

    /**
     * Get engagement data for a specific user.
     */
    public function getEngagementDataForUser($userId)
    {
        return [
            'like_count' => $this->like_count,
            'bookmark_count' => $this->bookmark_count,
            'comment_count' => $this->comment_count,
            'is_liked_by_current_user' => $this->isLikedByUser($userId),
            'is_bookmarked_by_current_user' => $this->isBookmarkedByUser($userId),
        ];
    }
}
