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
    ];

    /**
     * キャスト（自動型変換）
     */
    protected $casts = [
        'followers_count' => 'integer',
        'following_count' => 'integer',
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
        return $this->hasMany(Story::class);
    }
}
