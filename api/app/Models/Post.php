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
}
