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
use App\Http\Controllers\AIController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\LikeController;
use App\Http\Controllers\BookmarkController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\ShopProposalController;
use App\Http\Controllers\MunicipalityController;

// API動作確認用のテストルート
Route::get('/', function () {
    return response()->json([
        'message' => 'kumatomo API is working!',
        'version' => '1.0.0',
        'timestamp' => now()->toISOString()
    ]);
});

// 市区町村（掲示板用タグ）一覧（認証不要）
Route::get('/municipalities', [MunicipalityController::class, 'index']);

// 新規ユーザー登録
Route::post('/register', [AuthController::class, 'register']);

// ログイン
Route::post('/login', [AuthController::class, 'login']);

// AI Health Check (認証不要)
Route::get('/ai/health', [AIController::class, 'health']);

// プロフィール作成（認証不要 - 新規ユーザー登録用）
Route::post('/users', [UserController::class, 'store']);

// Public favorite check endpoint (no auth required)
Route::get('/favorites/check/{shop}', [FavoriteController::class, 'check']);

// Public shop endpoints (no auth required)
Route::get('/shops', [ShopController::class, 'index']);
Route::get('/shops/search', [ShopController::class, 'search']);
Route::get('/shops/{id}', [ShopController::class, 'show']);
Route::get('/shops/{id}/posts', [ShopController::class, 'posts']);

// 認証が必要なAPI
Route::middleware('auth:sanctum')->group(function () {

    // 自分のユーザー情報取得
    Route::get('/user', [UserController::class, 'me']);
    
    // 特定ユーザーのプロフィール取得
    Route::get('/users/{id}', [UserController::class, 'show']);
    
    // プロフィール更新
    Route::put('/user/update', [UserController::class, 'update']);
    Route::put('/users/{id}', [UserController::class, 'update']);
    
    // プロフィール削除
    Route::delete('/users/{id}', [UserController::class, 'destroy']);
    
    // ユーザーネーム利用可能性チェック
    Route::post('/users/check-username', [UserController::class, 'checkUsernameAvailability']);
    
    // ユーザーネーム更新
    Route::put('/users/update-username', [UserController::class, 'updateUsername']);
    
    // 統合画像アップロードAPI
    Route::post('/images/upload', [App\Http\Controllers\UnifiedImageUploadController::class, 'upload']);
    Route::post('/images/upload-multiple', [App\Http\Controllers\UnifiedImageUploadController::class, 'uploadMultiple']);
    
    // 後方互換性のための既存エンドポイント
    Route::post('/upload-profile-image', [UserController::class, 'uploadProfileImage']);
    Route::post('/upload-cover-image', [UserController::class, 'uploadCoverImage']);
    Route::post('/upload-image', [ImageUploadController::class, 'store']);
    Route::post('/upload-images', [ImageUploadController::class, 'storeMultiple']);

    // 投稿の取得
    Route::get('/posts', [PostController::class, 'index']);

    // 投稿の作成
    Route::post('/posts', [PostController::class, 'store']);

    // 投稿の詳細取得
    Route::get('/posts/{post}', [PostController::class, 'show']);

    // 市町村別の投稿一覧
    Route::get('/posts/municipality/{name}', [PostController::class, 'indexByMunicipality']);

    // 投稿の更新
    Route::put('/posts/{post}', [PostController::class, 'update']);

    // 投稿の削除
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);

    // 特定ユーザーのストーリー一覧
    Route::get('/users/{user}/posts', [PostController::class, 'indexByUser']);

    // 特定お店の投稿一覧
    Route::get('/shops/{shopId}/posts', [PostController::class, 'indexByShop']);

    // Comment routes
    Route::get('/posts/{postId}/comments', [CommentController::class, 'index']);
    Route::post('/posts/{postId}/comments', [CommentController::class, 'store']);
    Route::delete('/comments/{commentId}', [CommentController::class, 'destroy']);

    // Like routes
    Route::post('/posts/{postId}/like', [LikeController::class, 'toggle']);
    Route::delete('/posts/{postId}/like', [LikeController::class, 'destroy']);
    Route::get('/user/liked-posts', [LikeController::class, 'likedPosts']);

    // Bookmark routes
    Route::post('/posts/{postId}/bookmark', [BookmarkController::class, 'toggle']);
    Route::delete('/posts/{postId}/bookmark', [BookmarkController::class, 'destroy']);
    Route::get('/user/bookmarked-posts', [BookmarkController::class, 'bookmarkedPosts']);

    // Favorite routes
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/toggle/{shop}', [FavoriteController::class, 'toggle']);
    Route::delete('/favorites/{favorite}', [FavoriteController::class, 'destroy']);
    Route::get('/favorites/stats', [FavoriteController::class, 'stats']);

    // 画像配信（認証不要）
    Route::get('/images/{path}', [ImageController::class, 'show'])->where('path', '.*');


    // 統合検索API
    Route::get('/search', [SearchController::class, 'search']);

    // AI Chat API
    Route::post('/ai/chat', [AIController::class, 'chat']);



    // Shop Proposal routes
    Route::get('/shop-proposals', [ShopProposalController::class, 'index']);
    Route::post('/shop-proposals', [ShopProposalController::class, 'store']);
    Route::get('/shop-proposals/{proposal}', [ShopProposalController::class, 'show']);
    Route::put('/shop-proposals/{proposal}', [ShopProposalController::class, 'update']);
    Route::delete('/shop-proposals/{proposal}', [ShopProposalController::class, 'destroy']);
    Route::get('/shop-proposals-status', [ShopProposalController::class, 'status']);



    // 管理者用お店管理API
    Route::prefix('admin')->group(function () {
        Route::get('/shops', [AdminShopController::class, 'index']);
        Route::post('/shops', [AdminShopController::class, 'store']);
        Route::get('/shops/{id}', [AdminShopController::class, 'show']);
        Route::put('/shops/{id}', [AdminShopController::class, 'update']);
        Route::delete('/shops/{id}', [AdminShopController::class, 'destroy']);
        
        // Admin shop proposal management
        Route::get('/shop-proposals', [ShopProposalController::class, 'adminIndex']);
        Route::post('/shop-proposals/{proposal}/approve', [ShopProposalController::class, 'approve']);
        Route::post('/shop-proposals/{proposal}/reject', [ShopProposalController::class, 'reject']);
    });
});
