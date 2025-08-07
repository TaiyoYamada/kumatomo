<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * 一括代入可能な属性
     */
    protected $fillable = [
        'email',
        'password',
        'name',
        'bio',
        'city',
        'birthday',
        'website',
        'post_count',
        'followers_count',
        'following_count',
        'profile_image_url', // プロフィール背景のURL
        'profile_icon_image_url', // プロフィールアイコンのURL
        'has_completed_setup',
        'created_at',
    ];

    /**
     * キャスト（自動型変換）
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'followers_count' => 'integer',
        'following_count' => 'integer',
        'has_completed_setup' => 'boolean',
        'password' => 'hashed',
    ];

    /**
     * 非表示にする属性（APIレスポンスに含めない）
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * ユーザーが投稿したストーリーを取得
     */
    public function stories()
    {
        return $this->hasMany(Post::class);
    }

    /**
     * ユーザーが投稿した投稿を取得（storiesのエイリアス）
     */
    public function posts()
    {
        return $this->hasMany(Post::class);
    }
}
