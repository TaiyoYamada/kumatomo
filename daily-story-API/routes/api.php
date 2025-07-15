<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Resources\UserResource;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\StoryController;
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

    // ストーリー（ショート物語）の投稿・取得
    Route::get('/stories', [StoryController::class, 'index']);

    Route::post('/stories', [StoryController::class, 'store']);

    // 特定ユーザーのストーリー一覧
    Route::get('/users/{user}/stories', [StoryController::class, 'indexByUser']);
});
