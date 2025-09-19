<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Shop extends Model
{
    use HasFactory;

    /**
     * 一括代入可能な属性。
     */
    protected $fillable = [
        'name',
        'description',
        'address',
        'phone',
        'business_hours',
        'genre',
        'latitude',
        'longitude',
        'image_url',
        'has_try_benefit',
        'stamp_count',
        'is_approved'
    ];

    /**
     * 属性のキャスト。
     */
    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'has_try_benefit' => 'boolean',
        'stamp_count' => 'integer',
        'is_approved' => 'boolean',
    ];

    /**
     * このお店に関連する投稿を取得。
     */
    public function posts()
    {
        return $this->hasMany(Post::class);
    }

    /**
     * このお店をお気に入りにしているユーザーを取得。
     */
    public function favorites()
    {
        return $this->hasMany(Favorite::class);
    }

    /**
     * このお店をお気に入りにしているユーザーを取得（多対多）。
     */
    public function favoritedByUsers()
    {
        return $this->belongsToMany(User::class, 'favorites');
    }

    /**
     * 位置情報に基づいて近くのお店を検索するスコープ。
     */
    public function scopeNearby($query, $latitude, $longitude, $radius = 10)
    {
        return $query->selectRaw("
            *,
            (6371 * acos(cos(radians(?)) 
            * cos(radians(latitude)) 
            * cos(radians(longitude) - radians(?)) 
            + sin(radians(?)) 
            * sin(radians(latitude)))) AS distance
        ", [$latitude, $longitude, $latitude])
        ->having('distance', '<', $radius)
        ->orderBy('distance');
    }

    /**
     * ジャンルで絞り込むスコープ。
     */
    public function scopeByGenre($query, $genre)
    {
        return $query->where('genre', $genre);
    }

    /**
     * キーワード検索スコープ。
     */
    public function scopeSearch($query, $keyword)
    {
        return $query->where(function ($q) use ($keyword) {
            $q->where('name', 'LIKE', "%{$keyword}%")
              ->orWhere('description', 'LIKE', "%{$keyword}%")
              ->orWhere('address', 'LIKE', "%{$keyword}%");
        });
    }
}