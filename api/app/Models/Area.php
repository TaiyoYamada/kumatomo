<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Area extends Model
{
    use HasFactory;

    /**
     * 一括代入可能な属性。
     */
    protected $fillable = [
        'name',
    ];

    /**
     * このエリアに関連する投稿を取得（多対多）。
     */
    public function posts()
    {
        return $this->belongsToMany(Post::class, 'area_post')
                    ->withTimestamps();
    }

    /**
     * エリア名で検索するスコープ。
     */
    public function scopeSearch($query, $keyword)
    {
        return $query->where('name', 'LIKE', "%{$keyword}%");
    }

    /**
     * 名前順でソートするスコープ。
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('name');
    }
}