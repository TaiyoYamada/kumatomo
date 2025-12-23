<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PortalSlide extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'image_url',
        'title',
        'link_url',
        'sort_order',
        'is_active',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'sort_order' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Accessor: imageURL (absolute URL)
     */
    public function getImageURLAttribute(): ?string
    {
        $path = $this->attributes['image_url'] ?? null;
        if (!$path) {
            return null;
        }
        if (preg_match('/^https?:\/\//i', $path)) {
            return $path;
        }
        return url($path);
    }

    /**
     * Append camelCase keys for clients
     */
    protected $appends = ['imageURL'];

    /**
     * Scope: active slides only
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope: ordered by sort_order
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order', 'asc');
    }
}
