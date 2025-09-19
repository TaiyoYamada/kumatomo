<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ImageUploadController;
use App\Http\Controllers\ShopController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\ImageController;
use App\Http\Controllers\AIController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\LikeController;
use App\Http\Controllers\BookmarkController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\ShopProposalController;
use App\Http\Controllers\MunicipalityController;

// Public health/test endpoint
Route::get('/', function () {
    return response()->json([
        'message' => 'kumatomo API is working!',
        'version' => '1.0.0',
        'timestamp' => now()->toISOString()
    ]);
});

// Municipalities (public)
Route::get('/municipalities', [MunicipalityController::class, 'index']);

// Auth (public)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);


// Authenticated user endpoints
Route::middleware('auth:sanctum')->group(function () {
    // Current user
    Route::get('/user', [UserController::class, 'me']);

    // Users
    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::put('/user/update', [UserController::class, 'update']);
    Route::put('/users/{id}', [UserController::class, 'update']);
    Route::delete('/users/{id}', [UserController::class, 'destroy']);
    Route::post('/users/check-username', [UserController::class, 'checkUsernameAvailability']);
    Route::put('/users/update-username', [UserController::class, 'updateUsername']);

    // Unified image upload
    Route::post('/images/upload', [App\Http\Controllers\UnifiedImageUploadController::class, 'upload']);
    Route::post('/images/upload-multiple', [App\Http\Controllers\UnifiedImageUploadController::class, 'uploadMultiple']);
    // Backward compatibility
    Route::post('/upload-profile-image', [UserController::class, 'uploadProfileImage']);
    Route::post('/upload-cover-image', [UserController::class, 'uploadCoverImage']);
    Route::post('/upload-image', [ImageUploadController::class, 'store']);
    Route::post('/upload-images', [ImageUploadController::class, 'storeMultiple']);

    // Posts
    Route::get('/posts', [PostController::class, 'index']);
    Route::post('/posts', [PostController::class, 'store']);
    Route::get('/posts/{post}', [PostController::class, 'show']);
    Route::get('/posts/municipality/{name}', [PostController::class, 'indexByMunicipality']);
    Route::put('/posts/{post}', [PostController::class, 'update']);
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);
    Route::get('/users/{user}/posts', [PostController::class, 'indexByUser']);
    Route::get('/shops/{shopId}/posts', [PostController::class, 'indexByShop']);

    // Comments
    Route::get('/posts/{postId}/comments', [CommentController::class, 'index']);
    Route::post('/posts/{postId}/comments', [CommentController::class, 'store']);
    Route::delete('/comments/{commentId}', [CommentController::class, 'destroy']);

    // Likes
    Route::post('/posts/{postId}/like', [LikeController::class, 'toggle']);
    Route::delete('/posts/{postId}/like', [LikeController::class, 'destroy']);
    Route::get('/user/liked-posts', [LikeController::class, 'likedPosts']);

    // Bookmarks
    Route::post('/posts/{postId}/bookmark', [BookmarkController::class, 'toggle']);
    Route::delete('/posts/{postId}/bookmark', [BookmarkController::class, 'destroy']);
    Route::get('/user/bookmarked-posts', [BookmarkController::class, 'bookmarkedPosts']);

    // Favorites
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/toggle/{shop}', [FavoriteController::class, 'toggle']);
    Route::delete('/favorites/{favorite}', [FavoriteController::class, 'destroy']);
    Route::get('/favorites/stats', [FavoriteController::class, 'stats']);

    // Images delivery (public path)
    Route::get('/images/{path}', [ImageController::class, 'show'])->where('path', '.*');

    // Unified search
    Route::get('/search', [SearchController::class, 'search']);

    // AI Chat
    Route::post('/ai/chat', [AIController::class, 'chat']);

        // AI Health (public)
    Route::get('/ai/health', [AIController::class, 'health']);

    // Public profile creation (for onboarding)
    Route::post('/users', [UserController::class, 'store']);

    // Public shop endpoints
    Route::get('/shops', [ShopController::class, 'index']);
    Route::get('/shops/search', [ShopController::class, 'search']);
    Route::get('/shops/{id}', [ShopController::class, 'show']);
    Route::get('/shops/{id}/posts', [ShopController::class, 'posts']);

    // Public favorite check endpoint
    Route::get('/favorites/check/{shop}', [FavoriteController::class, 'check']);

    // Shop proposals (user)
    Route::get('/shop-proposals', [ShopProposalController::class, 'index']);
    Route::post('/shop-proposals', [ShopProposalController::class, 'store']);
    Route::get('/shop-proposals/{proposal}', [ShopProposalController::class, 'show']);
    Route::put('/shop-proposals/{proposal}', [ShopProposalController::class, 'update']);
    Route::delete('/shop-proposals/{proposal}', [ShopProposalController::class, 'destroy']);
    Route::get('/shop-proposals-status', [ShopProposalController::class, 'status']);
});
