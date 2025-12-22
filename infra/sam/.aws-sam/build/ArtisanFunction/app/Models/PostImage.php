<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PostImage extends Model
{
    use HasFactory;

    /**
     * 一括代入可能な属性。
     */
    protected $fillable = [
        'post_id',
        'image_url',
        'display_order'
    ];

    /**
     * 属性のキャスト。
     */
    protected $casts = [
        'display_order' => 'integer',
    ];

    /**
     * この画像が属する投稿を取得。
     */
    public function post()
    {
        return $this->belongsTo(Post::class);
    }

    /**
     * 表示順でソートするスコープ。
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('display_order');
    }
}