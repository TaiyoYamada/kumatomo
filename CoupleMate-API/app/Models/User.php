<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'email',
        'fullName',
        'birthDate',
        'profileImageURL',
        'partnerId',
        'pairId',
        'relationshipStartDate',
        'bio',
        'interests',
        'relationshipStatus',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'birthDate' => 'date',
        'relationshipStartDate' => 'date',
        'interests' => 'array',
        'password' => 'hashed',
    ];
}
