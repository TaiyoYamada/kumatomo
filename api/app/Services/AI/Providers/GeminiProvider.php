<?php

namespace App\Services\AI\Providers;

use App\Services\AI\AIProviderInterface;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class GeminiProvider implements AIProviderInterface
{
    private string $apiKey;
    private string $model;
    private string $apiUrl;
    private int $timeout;

    public function __construct()
    {
        $apiKey = config('ai.gemini.api_key');
        
        if (empty($apiKey)) {
            throw new Exception('Gemini API key is not configured');
        }
        
        $this->apiKey = $apiKey;
        $this->model = config('ai.gemini.model');
        $this->apiUrl = config('ai.gemini.api_url');
        $this->timeout = config('ai.gemini.timeout');
    }

    /**
     * Generate a response from Gemini API
     *
     * @param string $message The user's message
     * @return string The AI's response
     * @throws Exception If Gemini fails to generate a response
     */
    public function generateResponse(string $message): string
    {
        try {
            $url = "{$this->apiUrl}/models/{$this->model}:generateContent?key={$this->apiKey}";
            
            $response = Http::timeout($this->timeout)
                ->withHeaders([
                    'Content-Type' => 'application/json',
                ])
                ->post($url, [
                    'contents' => [
                        [
                            'parts' => [
                                [
                                    'text' => $message
                                ]
                            ]
                        ]
                    ],
                    'generationConfig' => [
                        'temperature' => 0.7,
                        'topK' => 40,
                        'topP' => 0.95,
                        'maxOutputTokens' => 1024,
                    ]
                ]);

            if (!$response->successful()) {
                $errorBody = $response->json();
                $errorMessage = $errorBody['error']['message'] ?? $response->body();
                throw new Exception("Gemini API error: " . $errorMessage);
            }

            $data = $response->json();
            
            if (!isset($data['candidates'][0]['content']['parts'][0]['text'])) {
                throw new Exception("Invalid response format from Gemini API");
            }

            return $data['candidates'][0]['content']['parts'][0]['text'];
        } catch (Exception $e) {
            Log::error('Gemini Provider Error', [
                'message' => $e->getMessage(),
                'model' => $this->model,
                'api_url' => $this->apiUrl,
            ]);
            
            throw new Exception("Failed to generate response from Gemini: " . $e->getMessage());
        }
    }

    /**
     * Check if Gemini API is available
     *
     * @return bool True if Gemini is available, false otherwise
     */
    public function isAvailable(): bool
    {
        try {
            // Use a simple test request to check availability
            $url = "{$this->apiUrl}/models/{$this->model}:generateContent?key={$this->apiKey}";
            
            $response = Http::timeout(5)
                ->withHeaders([
                    'Content-Type' => 'application/json',
                ])
                ->post($url, [
                    'contents' => [
                        [
                            'parts' => [
                                [
                                    'text' => 'Hello'
                                ]
                            ]
                        ]
                    ]
                ]);

            return $response->successful();
        } catch (Exception $e) {
            Log::warning('Gemini availability check failed', [
                'error' => $e->getMessage(),
                'model' => $this->model,
                'api_url' => $this->apiUrl,
            ]);
            return false;
        }
    }
}