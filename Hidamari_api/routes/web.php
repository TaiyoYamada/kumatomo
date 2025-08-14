<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ImageController;

Route::get('/', function () {
    return view('welcome');
});

// 古い形式の画像配信ルート（後方互換性のため）
Route::get('/storage/uploads/{filename}', [ImageController::class, 'showStorage'])->where('filename', '.*');
