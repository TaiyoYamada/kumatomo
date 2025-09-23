<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShopProposal extends Model
{
    use HasFactory;

    /**
     * 一括代入可能な属性。
     */
    protected $fillable = [
        'user_id',
        'name',
        'address',
        'genre',
        'description',
        'status',
        'admin_notes',
    ];

    /**
     * 属性のキャスト。
     */
    protected $casts = [
        'user_id' => 'integer',
    ];

    /**
     * 提案ステータスの定数。
     */
    const STATUS_PENDING = 'pending';
    const STATUS_APPROVED = 'approved';
    const STATUS_REJECTED = 'rejected';

    /**
     * 利用可能なステータス一覧を取得。
     */
    public static function getAvailableStatuses()
    {
        return [
            self::STATUS_PENDING,
            self::STATUS_APPROVED,
            self::STATUS_REJECTED,
        ];
    }

    /**
     * この提案が属するユーザーを取得。
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * 承認待ちの提案を取得するスコープ。
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * 承認済みの提案を取得するスコープ。
     */
    public function scopeApproved($query)
    {
        return $query->where('status', self::STATUS_APPROVED);
    }

    /**
     * 却下された提案を取得するスコープ。
     */
    public function scopeRejected($query)
    {
        return $query->where('status', self::STATUS_REJECTED);
    }

    /**
     * 特定のユーザーの提案を取得するスコープ。
     */
    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * ステータスでフィルタリングするスコープ。
     */
    public function scopeByStatus($query, $status)
    {
        return $query->where('status', $status);
    }

    /**
     * 提案を承認する。
     */
    public function approve($adminNotes = null)
    {
        $this->status = self::STATUS_APPROVED;
        if ($adminNotes) {
            $this->admin_notes = $adminNotes;
        }
        return $this->save();
    }

    /**
     * 提案を却下する。
     */
    public function reject($adminNotes = null)
    {
        $this->status = self::STATUS_REJECTED;
        if ($adminNotes) {
            $this->admin_notes = $adminNotes;
        }
        return $this->save();
    }

    /**
     * 提案が承認待ちかどうかを判定。
     */
    public function isPending()
    {
        return $this->status === self::STATUS_PENDING;
    }

    /**
     * 提案が承認済みかどうかを判定。
     */
    public function isApproved()
    {
        return $this->status === self::STATUS_APPROVED;
    }

    /**
     * 提案が却下されたかどうかを判定。
     */
    public function isRejected()
    {
        return $this->status === self::STATUS_REJECTED;
    }
}