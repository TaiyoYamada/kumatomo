<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Http\Resources\UserResource;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MemoryController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PairController;

// ✅ 新規ユーザー登録（登録時にパスワード含む）
Route::post('/register', [AuthController::class, 'register']);

// ✅ ログイン
Route::post('/login', [AuthController::class, 'login']);

// ✅ 新規プロフィール作成（認証なしで使うならここで）
Route::post('/users', [UserController::class, 'store']);

// ✅ 認証が必要なAPI（Sanctum）
Route::middleware('auth:sanctum')->group(function () {
    
    // 自分のユーザー情報取得
    Route::get('/user', function (Request $request) {
        return new UserResource($request->user());
    });

    // プロフィール更新
    Route::put('/users/{id}', [UserController::class, 'update']);

    // メモリー（思い出）投稿／取得（ログイン必須にしたいならここ）
    Route::get('/memories', [MemoryController::class, 'index']);
    Route::post('/memories', [MemoryController::class, 'store']);

    // カップル機能など
    Route::post('/pairing', [PairController::class, 'store']);
});
