<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Models\User;
use App\Http\Controllers\MemoryController;
use App\Http\Controllers\UserController;

Route::post('/users', function (Request $request) {
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users,email',
        'password' => 'required|string|min:6',
    ]);

    $user = User::create([
        'name' => $validated['name'],
        'email' => $validated['email'],
        'password' => Hash::make($validated['password']),
    ]);

    return response()->json($user, 201);
});

Route::post('/users', [UserController::class, 'store']);

Route::get('/memories', [MemoryController::class, 'index']);

Route::post('/memories', [MemoryController::class, 'store']);