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
        'place_name',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'tags' => 'array',
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
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
     * この投稿が関連するエリアを取得（多対多）。
     */
    public function areas()
    {
        return $this->belongsToMany(Area::class, 'area_post')
                    ->withTimestamps();
    }

    /**
     * エリアIDの配列を受け取って関連付けを行う。
     * 
     * @param array $areaIds
     * @return void
     */
    public function syncAreas(array $areaIds)
    {
        // 最大5つのエリアまで許可
        $limitedAreaIds = array_slice($areaIds, 0, 5);
        $this->areas()->sync($limitedAreaIds);
    }

    /**
     * 投稿に関連付けられたエリアIDの配列を取得。
     * 
     * @return array
     */
    public function getAreaIdsAttribute()
    {
        return $this->areas()->pluck('areas.id')->toArray();
    }

    /**
     * 投稿作成・更新時のバリデーションルール。
     * 
     * @return array
     */
    public static function validationRules()
    {
        return [
            'content' => 'required|string|max:200',
            'area_ids' => 'required|array|min:1|max:5',
            'area_ids.*' => 'integer|exists:areas,id',
            'place_name' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'shop_id' => 'nullable|integer|exists:shops,id',
        ];
    }

    /**
     * 投稿更新時のバリデーションルール。
     * 
     * @return array
     */
    public static function updateValidationRules()
    {
        return [
            'content' => 'sometimes|required|string|max:200',
            'area_ids' => 'sometimes|required|array|min:1|max:5',
            'area_ids.*' => 'integer|exists:areas,id',
            'place_name' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'shop_id' => 'nullable|integer|exists:shops,id',
        ];
    }

    /**
     * 特定のエリアに関連する投稿を取得するスコープ。
     * 
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param int $areaId
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeByArea($query, $areaId)
    {
        return $query->whereHas('areas', function ($q) use ($areaId) {
            $q->where('areas.id', $areaId);
        });
    }

    /**
     * 位置情報を持つ投稿のみを取得するスコープ。
     * 
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeWithLocation($query)
    {
        return $query->whereNotNull('latitude')
                    ->whereNotNull('longitude');
    }

    /**
     * 特定の位置から指定した半径内の投稿を取得するスコープ。
     * 
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param float $latitude
     * @param float $longitude
     * @param float $radius キロメートル単位
     * @return \Illuminate\Database\Eloquent\Builder
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
}
