<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AIChatLog extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     */
    protected $table = 'ai_chat_logs';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'user_id',
        'provider',
        'request_timestamp',
        'response_timestamp',
        'response_time_ms',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'request_timestamp' => 'datetime',
        'response_timestamp' => 'datetime',
        'response_time_ms' => 'integer',
        'user_id' => 'integer',
    ];

    /**
     * Get the user that owns the AI chat log.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Calculate response time in milliseconds from timestamps.
     * 
     * @return int|null
     */
    public function calculateResponseTime(): ?int
    {
        if ($this->request_timestamp && $this->response_timestamp) {
            return $this->request_timestamp->diffInMilliseconds($this->response_timestamp);
        }
        
        return null;
    }

    /**
     * Scope to filter by provider.
     */
    public function scopeByProvider($query, string $provider)
    {
        return $query->where('provider', $provider);
    }

    /**
     * Scope to filter by user.
     */
    public function scopeByUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope to filter by date range.
     */
    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('request_timestamp', [$startDate, $endDate]);
    }
}