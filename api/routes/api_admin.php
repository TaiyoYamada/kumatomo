<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\AdminPostController;
use App\Http\Controllers\PortalSlideController;
use App\Http\Controllers\UnifiedImageUploadController;

// Admin routes - requires auth:sanctum and EnsureAdmin middleware
Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureAdmin::class])
    ->prefix('admin')
    ->group(function () {
        // Dashboard stats
        Route::get('/stats/users', [AdminUserController::class, 'stats']);
        Route::get('/stats/posts', [AdminPostController::class, 'stats']);

        // User management
        Route::get('/users', [AdminUserController::class, 'index']);
        Route::get('/users/{id}', [AdminUserController::class, 'show']);
        Route::put('/users/{id}', [AdminUserController::class, 'update']);
        Route::delete('/users/{id}', [AdminUserController::class, 'destroy']);

        // Post management
        Route::get('/posts', [AdminPostController::class, 'index']);
        Route::get('/posts/{id}', [AdminPostController::class, 'show']);
        Route::delete('/posts/{id}', [AdminPostController::class, 'destroy']);

        // Portal slides management
        Route::get('/portal-slides', [PortalSlideController::class, 'index']);
        Route::post('/portal-slides', [PortalSlideController::class, 'store']);
        Route::get('/portal-slides/{id}', [PortalSlideController::class, 'show']);
        Route::put('/portal-slides/{id}', [PortalSlideController::class, 'update']);
        Route::delete('/portal-slides/{id}', [PortalSlideController::class, 'destroy']);
        Route::post('/portal-slides/reorder', [PortalSlideController::class, 'reorder']);

        // Image upload (reuses unified uploader)
        Route::post('/upload-image', [UnifiedImageUploadController::class, 'upload']);
    });

// Public portal slides endpoint (for iOS app)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/portal-slides', [PortalSlideController::class, 'publicIndex']);
});
