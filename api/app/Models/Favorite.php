<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Favorite extends Model
{
    use HasFactory;

    /**
     * 一括代入可能な属性。
     */
    protected $fillable = [
        'user_id',
        'shop_id',
    ];

    /**
     * 属性のキャスト。
     */
    protected $casts = [
        'user_id' => 'integer',
        'shop_id' => 'integer',
    ];

    /**
     * このお気に入りが属するユーザーを取得。
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * このお気に入りが属するお店を取得。
     */
    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    /**
     * ユーザーとお店の組み合わせでお気に入りを検索するスコープ。
     */
    public function scopeForUserAndShop($query, $userId, $shopId)
    {
        return $query->where('user_id', $userId)->where('shop_id', $shopId);
    }

    /**
     * 特定のユーザーのお気に入りを取得するスコープ。
     */
    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * 特定のお店のお気に入りを取得するスコープ。
     */
    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }
}