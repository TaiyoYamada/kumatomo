<?php
// app/Models/Memory.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Memory extends Model
{
    protected $fillable = [
        'author_id',
        'title',
        'date',
        'location',
        'notes',
        'photos',
    ];
    
    protected $casts = [
        'photos' => 'array',
    ];
    
}
