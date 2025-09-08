<?php

namespace Tests\Unit;

use App\Services\AI\AIService;
use App\Services\AI\Providers\GeminiProvider;
use App\Services\AI\Providers\OllamaProvider;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;
use Exception;
use ReflectionClass;

class AIServiceProviderSelectionTest extends TestCase
{
    public function test_ai_service_selects_gemini_provider_when_configured()
    {
        // Arrange
        Config::set('ai.provider', 'gemini');
        Config::set('ai.gemini.api_key', 'test-api-key');
        Config::set('ai.gemini.model', 'gemini-2.0-flash-lite');
        Config::set('ai.gemini.api_url', 'https://test-api.googleapis.com/v1beta');
        Config::set('ai.gemini.timeout', 30);

        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'Hello!'
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        // Act
        $aiService = new AIService();

        // Assert - Use reflection to check the provider type
        $reflection = new ReflectionClass($aiService);
        $providerProperty = $reflection->getProperty('provider');
        $providerProperty->setAccessible(true);
        $provider = $providerProperty->getValue($aiService);

        $this->assertInstanceOf(GeminiProvider::class, $provider);
    }

    public function test_ai_service_selects_ollama_provider_when_configured()
    {
        // Arrange
        Config::set('ai.provider', 'ollama');
        Config::set('ai.ollama.url', 'http://test-ollama:11434');
        Config::set('ai.ollama.model', 'test-model');
        Config::set('ai.ollama.timeout', 30);

        Http::fake([
            'http://test-ollama:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'test-model']
                ]
            ], 200)
        ]);

        // Act
        $aiService = new AIService();

        // Assert - Use reflection to check the provider type
        $reflection = new ReflectionClass($aiService);
        $providerProperty = $reflection->getProperty('provider');
        $providerProperty->setAccessible(true);
        $provider = $providerProperty->getValue($aiService);

        $this->assertInstanceOf(OllamaProvider::class, $provider);
    }

    public function test_ai_service_throws_exception_for_unknown_provider()
    {
        // Arrange
        Config::set('ai.provider', 'unknown-provider');

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Unknown AI provider: unknown-provider');

        new AIService();
    }

    public function test_ai_service_throws_exception_when_gemini_api_key_missing()
    {
        // Arrange
        Config::set('ai.provider', 'gemini');
        Config::set('ai.gemini.api_key', '');

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Gemini API key is not configured');

        new AIService();
    }
}