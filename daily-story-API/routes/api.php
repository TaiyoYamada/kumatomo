<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ImageUploadController;

// 新規ユーザー登録
Route::post('/register', [AuthController::class, 'register']);

// ログイン
Route::post('/login', [AuthController::class, 'login']);

// 認証が必要なAPI
Route::middleware('auth:sanctum')->group(function () {

    // 自分のユーザー情報取得
    Route::get('/user', [UserController::class, 'me']);
    // Route::get('/users/{id}', [UserController::class, 'updateprofile']);

    Route::post('/upload-image', [ImageUploadController::class, 'store']);

    // プロフィール更新
    Route::put('/user/update', [UserController::class, 'update']);

    // 投稿の取得
    Route::get('/posts', [PostController::class, 'index']);

    // 投稿の作成
    Route::post('/posts', [PostController::class, 'store']);

    // 特定ユーザーのストーリー一覧
    Route::get('/users/{user}/posts', [PostController::class, 'indexByUser']);
});
