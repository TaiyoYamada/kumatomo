<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ImageUploadController;
use App\Http\Controllers\ShopController;
use App\Http\Controllers\AdminShopController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\ImageController;

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

    // 投稿の詳細取得
    Route::get('/posts/{post}', [PostController::class, 'show']);

    // 投稿の更新
    Route::put('/posts/{post}', [PostController::class, 'update']);

    // 投稿の削除
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);

    // 特定ユーザーのストーリー一覧
    Route::get('/users/{user}/posts', [PostController::class, 'indexByUser']);

    // 特定お店の投稿一覧
    Route::get('/shops/{shopId}/posts', [PostController::class, 'indexByShop']);

    // 画像配信（認証不要）
    Route::get('/images/{path}', [ImageController::class, 'show'])->where('path', '.*');


    // 統合検索API
    Route::get('/search', [SearchController::class, 'search']);

    Route::get('/shops', [ShopController::class, 'index']);
    Route::get('/shops/search', [ShopController::class, 'search']);
    Route::get('/shops/{id}', [ShopController::class, 'show']);
    Route::get('/shops/{id}/posts', [ShopController::class, 'posts']);



    // 管理者用お店管理API
    Route::prefix('admin')->group(function () {
        Route::get('/shops', [AdminShopController::class, 'index']);
        Route::post('/shops', [AdminShopController::class, 'store']);
        Route::get('/shops/{id}', [AdminShopController::class, 'show']);
        Route::put('/shops/{id}', [AdminShopController::class, 'update']);
        Route::delete('/shops/{id}', [AdminShopController::class, 'destroy']);
    });
});
