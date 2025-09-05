<?php

namespace App\Services\AI;

use App\Models\AIChatLog;
use App\Services\AI\Providers\OllamaProvider;
use App\Services\AI\Providers\GeminiProvider;
use Illuminate\Support\Facades\Log;
use Exception;

class AIService
{
    private ?AIProviderInterface $provider = null;

    public function __construct()
    {
        // Don't initialize provider in constructor to avoid dependency injection issues
        // Provider will be initialized lazily when needed
    }

    /**
     * Process a chat message and return AI response
     *
     * @param string $message The user's message
     * @param int $userId The user's ID
     * @return array Response data including message and metadata
     * @throws Exception If no provider is available or response generation fails
     */
    public function chat(string $message, int $userId): array
    {
        $startTime = microtime(true);
        $provider = $this->getProvider();
        $providerName = $this->getProviderName();
        
        // Log request metadata
        $chatLog = AIChatLog::create([
            'user_id' => $userId,
            'provider' => $providerName,
            'request_timestamp' => now(),
        ]);

        try {
            // Generate AI response
            $response = $provider->generateResponse($message);
            
            // Calculate response time
            $responseTime = (microtime(true) - $startTime) * 1000; // Convert to milliseconds
            
            // Update chat log with response metadata
            $chatLog->update([
                'response_timestamp' => now(),
                'response_time_ms' => round($responseTime),
            ]);

            return [
                'message' => $response,
                'timestamp' => now()->toISOString(),
                'provider' => $providerName,
                'response_time_ms' => round($responseTime),
            ];
        } catch (Exception $e) {
            // Log the error but don't update response timestamp for failed requests
            Log::error('AI Service Error', [
                'provider' => $providerName,
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'chat_log_id' => $chatLog->id,
            ]);
            
            throw $e;
        }
    }

    /**
     * Get the appropriate AI provider based on environment configuration
     *
     * @return AIProviderInterface
     * @throws Exception If no valid provider is configured or available
     */
    private function getProvider(): AIProviderInterface
    {
        $providerType = config('ai.provider', 'ollama');
        
        switch ($providerType) {
            case 'ollama':
                $provider = new OllamaProvider();
                break;
            case 'gemini':
                $provider = new GeminiProvider();
                break;
            default:
                throw new Exception("Unknown AI provider: {$providerType}");
        }

        // Check if the provider is available
        if (!$provider->isAvailable()) {
            throw new Exception("AI provider '{$providerType}' is not available");
        }

        return $provider;
    }

    /**
     * Get the name of the current provider
     *
     * @return string
     */
    private function getProviderName(): string
    {
        return config('ai.provider', 'ollama');
    }

    /**
     * Check if any AI provider is available
     *
     * @return bool
     */
    public function isServiceAvailable(): bool
    {
        try {
            $provider = $this->getProvider();
            return $provider->isAvailable();
        } catch (Exception $e) {
            return false;
        }
    }
}