<?php
namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    // 新規ユーザー作成時に大量割り当て可能な属性
    protected $fillable = [
        'email',
        'password',               // パスワードも含める
        'name',
        'birthDate',
        'profileImageURL',
        'partnerId',
        'pairId',
        'relationshipStartDate',
        'bio',
        'interests',
        'relationshipStatus',
    ];

    // データのキャスト
    protected $casts = [
        'birthDate' => 'date',
        'relationshipStartDate' => 'date',
        'interests' => 'array',
        'email_verified_at' => 'datetime',
        'password' => 'hashed',   // パスワードをハッシュ化
    ];

    // パスワードを暗号化して保存
    public static function boot()
    {
        parent::boot();

        static::creating(function ($user) {
            if ($user->password) {
                $user->password = bcrypt($user->password);  // パスワードのハッシュ化
            }
        });
    }
}
