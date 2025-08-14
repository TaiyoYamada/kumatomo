<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // HTTPS環境の検出とURL強制設定
        if ($this->app->environment('local')) {
            // 開発環境：Nginxプロキシ経由の場合
            if (request()->server('HTTPS') === 'on' || 
                request()->header('X-Forwarded-Proto') === 'https' ||
                request()->server('SERVER_PORT') == 443) {
                URL::forceScheme('https');
            }
        }
        
        if ($this->app->environment('production')) {
            // 本番環境：常にHTTPS
            URL::forceScheme('https');
        }
        
        // Laravel 12: 新機能対応
        // リアルタイムリンティングとエラーハンドリングでHTTPS前提の設定
        if ($this->app->environment('local') && request()->isSecure()) {
            config(['app.debug_show_exception_details' => true]);
        }
    }
}
