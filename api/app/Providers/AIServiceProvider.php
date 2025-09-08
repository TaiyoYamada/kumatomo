<?php

namespace App\Providers;

use App\Services\AI\AIService;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Validator;

class AIServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        $this->app->singleton(AIService::class, function ($app) {
            return new AIService();
        });
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Validate AI configuration on boot
        $this->validateAIConfiguration();
        
        // Add custom validation rules for AI messages
        Validator::extend('ai_message', function ($attribute, $value, $parameters, $validator) {
            $maxLength = config('ai.max_message_length', 1000);
            return is_string($value) && strlen(trim($value)) > 0 && strlen($value) <= $maxLength;
        });
        
        Validator::replacer('ai_message', function ($message, $attribute, $rule, $parameters) {
            $maxLength = config('ai.max_message_length', 1000);
            return str_replace(':max', $maxLength, 'The :attribute must be a non-empty string with maximum :max characters.');
        });
    }

    /**
     * Validate AI configuration
     */
    private function validateAIConfiguration(): void
    {
        $provider = config('ai.provider');
        
        if (!in_array($provider, ['ollama', 'gemini'])) {
            throw new \InvalidArgumentException("Invalid AI provider: {$provider}. Must be 'ollama' or 'gemini'.");
        }
        
        if ($provider === 'gemini' && empty(config('ai.gemini.api_key'))) {
            \Log::warning('Gemini API key is not configured. AI service may not work in production.');
        }
        
        if ($provider === 'ollama' && empty(config('ai.ollama.url'))) {
            \Log::warning('Ollama URL is not configured. AI service may not work in development.');
        }
    }
}