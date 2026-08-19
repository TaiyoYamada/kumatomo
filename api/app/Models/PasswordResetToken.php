<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PasswordResetToken extends Model
{
    protected $fillable = [
        'email',
        'code',
        'token',
        'verified',
        'expires_at',
    ];

    protected $casts = [
        'verified' => 'boolean',
        'expires_at' => 'datetime',
    ];

    /**
     * コードが有効期限内かどうかを確認
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * コードが検証済みかどうかを確認
     */
    public function isVerified(): bool
    {
        return $this->verified;
    }
}
