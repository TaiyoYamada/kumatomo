<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ImageController;

Route::get('/', function () {
    return view('welcome');
});

// 画像配信ルート
// 推奨: publicディスク配下を /images/{path} で配信
Route::get('/images/{path}', [ImageController::class, 'show'])->where('path', '.*');

// 新形式: publicディスク配下を任意パスで配信 (/storage/{path})
Route::get('/storage/{path}', [ImageController::class, 'show'])->where('path', '.*');

// 旧形式の互換: /storage/uploads/{filename}
Route::get('/storage/uploads/{filename}', [ImageController::class, 'showStorage'])->where('filename', '.*');
