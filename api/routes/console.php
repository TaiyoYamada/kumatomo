<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use App\Console\Commands\TestKumamonAI;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Register Kumamon AI test command
Artisan::command('kumamon:test {message?}', function () {
    $message = $this->argument('message') ?? 'こんにちは！';
    $aiService = app(\App\Services\AI\AIService::class);
    
    $this->info("くまモンAIをテストします...");
    $this->info("メッセージ: {$message}");
    $this->info("---");
    
    try {
        if (!$aiService->isServiceAvailable()) {
            $this->error('AIサービスが利用できません。');
            return 1;
        }
        
        $response = $aiService->chat($message, 1);
        
        $this->info("くまモンの返答:");
        $this->line($response['message']);
        $this->info("---");
        $this->info("プロバイダー: {$response['provider']}");
        $this->info("応答時間: {$response['response_time_ms']}ms");
        
    } catch (\Exception $e) {
        $this->error("エラーが発生しました: " . $e->getMessage());
        return 1;
    }
    
    return 0;
})->purpose('Test Kumamon AI responses');
