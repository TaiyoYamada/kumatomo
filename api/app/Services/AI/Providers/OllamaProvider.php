<?php

namespace App\Services\AI\Providers;

use App\Services\AI\AIProviderInterface;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class OllamaProvider implements AIProviderInterface
{
    private string $url;
    private string $model;
    private int $timeout;

    public function __construct()
    {
        $this->url = config('ai.ollama.url');
        $this->model = config('ai.ollama.model');
        $this->timeout = config('ai.ollama.timeout');
    }

    /**
     * Generate a response from Ollama
     *
     * @param string $message The user's message
     * @return string The AI's response
     * @throws Exception If Ollama fails to generate a response
     */
    public function generateResponse(string $message): string
    {
        try {
            $response = Http::timeout($this->timeout)
                ->post("{$this->url}/api/generate", [
                    'model' => $this->model,
                    'prompt' => $message,
                    'stream' => false,
                ]);

            if (!$response->successful()) {
                throw new Exception("Ollama API error: " . $response->body());
            }

            $data = $response->json();
            
            if (!isset($data['response'])) {
                throw new Exception("Invalid response format from Ollama");
            }

            return $data['response'];
        } catch (Exception $e) {
            Log::error('Ollama Provider Error', [
                'message' => $e->getMessage(),
                'url' => $this->url,
                'model' => $this->model,
            ]);
            
            throw new Exception("Failed to generate response from Ollama: " . $e->getMessage());
        }
    }

    /**
     * Check if Ollama is available
     *
     * @return bool True if Ollama is available, false otherwise
     */
    public function isAvailable(): bool
    {
        try {
            $response = Http::timeout(5)->get("{$this->url}/api/tags");
            return $response->successful();
        } catch (Exception $e) {
            Log::warning('Ollama availability check failed', [
                'error' => $e->getMessage(),
                'url' => $this->url,
            ]);
            return false;
        }
    }
}