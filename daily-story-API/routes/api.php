<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Resources\UserResource;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController; // ここを修正
use App\Http\Controllers\StoryController;

// 新規ユーザー登録
Route::post('/register', [AuthController::class, 'register']);

// ログイン
Route::post('/login', [AuthController::class, 'login']);

// 認証が必要なAPI（Sanctum）
Route::middleware('auth:sanctum')->group(function () {

    // 自分のユーザー情報取得
    Route::get('/user', function (Request $request) {
        return new UserResource($request->user());
    });

    // プロフィール更新
    Route::put('/users/{id}', [UserController::class, 'update']);

    // ストーリー（ショート物語）の投稿・取得
    Route::get('/stories', [StoryController::class, 'index']);
    
    Route::post('/stories', [StoryController::class, 'store']);

    // 特定ユーザーのストーリー一覧
    Route::get('/users/{user}/stories', [StoryController::class, 'indexByUser']);
});