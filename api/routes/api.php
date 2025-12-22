<?php

use Illuminate\Support\Facades\Route;

// Health check endpoint (for Lambda / SAM local testing)
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String(),
        'environment' => config('app.env'),
    ]);
});

// NOTE:
// Split routes into api_user.php and api_admin.php for clarity.
// This file only includes the two sub route files.

require __DIR__ . '/api_user.php';
require __DIR__ . '/api_admin.php';
