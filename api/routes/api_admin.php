<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminShopController;
use App\Http\Controllers\ShopProposalController;
use App\Http\Controllers\UnifiedImageUploadController;

// Admin routes must be authenticated
Route::middleware('auth:sanctum')
    ->prefix('admin')
    ->group(function () {
        // Shop management
        Route::get('/shops', [AdminShopController::class, 'index']);
        Route::post('/shops', [AdminShopController::class, 'store']);
        Route::get('/shops/{id}', [AdminShopController::class, 'show']);
        Route::put('/shops/{id}', [AdminShopController::class, 'update']);
        Route::delete('/shops/{id}', [AdminShopController::class, 'destroy']);

        // Shop proposal management
        Route::get('/shop-proposals', [ShopProposalController::class, 'adminIndex']);
        Route::post('/shop-proposals/{proposal}/approve', [ShopProposalController::class, 'approve']);
        Route::post('/shop-proposals/{proposal}/reject', [ShopProposalController::class, 'reject']);

        // Admin shop image upload (reuses unified uploader)
        Route::post('/shops/upload-image', [UnifiedImageUploadController::class, 'upload']);
    });
