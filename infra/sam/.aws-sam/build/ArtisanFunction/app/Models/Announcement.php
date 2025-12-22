<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'published_at',
        'is_active',
        'priority',
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'is_active' => 'boolean',
        'priority' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Scope to get active and published announcements
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
                     ->where(function ($query) {
                         $query->whereNull('published_at')
                               ->orWhere('published_at', '<=', now());
                     });
    }

    // Scope for ordering
    public function scopeOrdered($query)
    {
        return $query->orderBy('priority', 'desc')
                     ->orderBy('published_at', 'desc')
                     ->orderBy('created_at', 'desc');
    }
}
