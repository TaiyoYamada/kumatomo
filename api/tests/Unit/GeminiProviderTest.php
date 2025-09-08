<?php

namespace Tests\Unit;

use App\Services\AI\Providers\GeminiProvider;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;
use Exception;

class GeminiProviderTest extends TestCase
{
    private GeminiProvider $provider;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Set up test configuration
        Config::set('ai.gemini.api_key', 'test-api-key');
        Config::set('ai.gemini.model', 'gemini-pro');
        Config::set('ai.gemini.api_url', 'https://test-api.googleapis.com/v1beta');
        Config::set('ai.gemini.timeout', 30);
        
        $this->provider = new GeminiProvider();
    }

    public function test_generate_response_success()
    {
        // Arrange
        $message = 'Hello, how are you?';
        $expectedResponse = 'I am doing well, thank you for asking!';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => $expectedResponse
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        // Act
        $result = $this->provider->generateResponse($message);

        // Assert
        $this->assertEquals($expectedResponse, $result);
        
        Http::assertSent(function ($request) use ($message) {
            $url = 'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent?key=test-api-key';
            return $request->url() === $url &&
                   $request['contents'][0]['parts'][0]['text'] === $message &&
                   isset($request['generationConfig']);
        });
    }

    public function test_generate_response_http_error()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'error' => [
                    'message' => 'API quota exceeded'
                ]
            ], 429)
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Gemini');
        
        $this->provider->generateResponse($message);
    }

    public function test_generate_response_invalid_json_format()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'invalid_field' => 'some data',
            ], 200)
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Gemini: Invalid response format from Gemini API');
        
        $this->provider->generateResponse($message);
    }

    public function test_generate_response_network_timeout()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection timeout');
            }
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Gemini');
        
        $this->provider->generateResponse($message);
    }

    public function test_is_available_success()
    {
        // Arrange
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
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
        $result = $this->provider->isAvailable();

        // Assert
        $this->assertTrue($result);
        
        Http::assertSent(function ($request) {
            $url = 'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent?key=test-api-key';
            return $request->url() === $url &&
                   $request['contents'][0]['parts'][0]['text'] === 'Hello';
        });
    }

    public function test_is_available_server_error()
    {
        // Arrange
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'error' => [
                    'message' => 'Server Error'
                ]
            ], 500)
        ]);

        // Act
        $result = $this->provider->isAvailable();

        // Assert
        $this->assertFalse($result);
    }

    public function test_is_available_network_error()
    {
        // Arrange
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection refused');
            }
        ]);

        // Act
        $result = $this->provider->isAvailable();

        // Assert
        $this->assertFalse($result);
    }

    public function test_is_available_timeout()
    {
        // Arrange
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => function () {
                throw new Exception('Request timeout');
            }
        ]);

        // Act
        $result = $this->provider->isAvailable();

        // Assert
        $this->assertFalse($result);
    }

    public function test_constructor_uses_config_values()
    {
        // Arrange
        Config::set('ai.gemini.api_key', 'custom-api-key');
        Config::set('ai.gemini.model', 'gemini-pro-vision');
        Config::set('ai.gemini.api_url', 'https://custom-api.googleapis.com/v1beta');
        Config::set('ai.gemini.timeout', 60);

        // Act
        $provider = new GeminiProvider();
        
        Http::fake([
            'https://custom-api.googleapis.com/v1beta/models/gemini-pro-vision:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'test response'
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        $provider->generateResponse('test');

        // Assert
        Http::assertSent(function ($request) {
            $url = 'https://custom-api.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=custom-api-key';
            return $request->url() === $url;
        });
    }

    public function test_constructor_throws_exception_when_api_key_missing()
    {
        // Arrange
        Config::set('ai.gemini.api_key', '');

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Gemini API key is not configured');
        
        new GeminiProvider();
    }

    public function test_constructor_throws_exception_when_api_key_null()
    {
        // Arrange
        Config::set('ai.gemini.api_key', null);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Gemini API key is not configured');
        
        new GeminiProvider();
    }

    public function test_generate_response_with_empty_message()
    {
        // Arrange
        $message = '';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'I received an empty message.'
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        // Act
        $result = $this->provider->generateResponse($message);

        // Assert
        $this->assertEquals('I received an empty message.', $result);
        
        Http::assertSent(function ($request) use ($message) {
            return $request['contents'][0]['parts'][0]['text'] === $message;
        });
    }

    public function test_generate_response_with_long_message()
    {
        // Arrange
        $message = str_repeat('This is a very long message. ', 100);
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'I received a long message.'
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        // Act
        $result = $this->provider->generateResponse($message);

        // Assert
        $this->assertEquals('I received a long message.', $result);
    }

    public function test_generate_response_includes_generation_config()
    {
        // Arrange
        $message = 'Test message';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'Response'
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        // Act
        $this->provider->generateResponse($message);

        // Assert
        Http::assertSent(function ($request) {
            return isset($request['generationConfig']) &&
                   $request['generationConfig']['temperature'] === 0.7 &&
                   $request['generationConfig']['topK'] === 40 &&
                   $request['generationConfig']['topP'] === 0.95 &&
                   $request['generationConfig']['maxOutputTokens'] === 1024;
        });
    }

    public function test_generate_response_includes_api_key_in_query()
    {
        // Arrange
        $message = 'Test message';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'Response'
                                ]
                            ]
                        ]
                    ]
                ]
            ], 200)
        ]);

        // Act
        $this->provider->generateResponse($message);

        // Assert
        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'key=test-api-key');
        });
    }

    public function test_generate_response_handles_gemini_error_format()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'https://test-api.googleapis.com/v1beta/models/gemini-pro:generateContent*' => Http::response([
                'error' => [
                    'code' => 400,
                    'message' => 'Invalid request format',
                    'status' => 'INVALID_ARGUMENT'
                ]
            ], 400)
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Gemini: Gemini API error: Invalid request format');
        
        $this->provider->generateResponse($message);
    }
}