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
        'website',
        'profile_image_url',
        'partner_id',
        'pair_id',
        'followers_count',
        'following_count',
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
     * 日付として扱う属性（SoftDeletesなど）
     */
    protected $dates = [
        'created_at',
        'updated_at',
        'deleted_at',
    ];

    /**
     * リレーション（例: パートナー）
     */
    public function partner()
    {
        return $this->belongsTo(User::class, 'partner_id');
    }

    /**
     * ペア関係（必要であれば）
     */
    public function pair()
    {
        return $this->belongsTo(Pair::class, 'pair_id');
    }
}
