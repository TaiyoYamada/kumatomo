<?php

namespace Tests\Unit;

use App\Services\AI\Providers\OllamaProvider;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;
use Exception;

class OllamaProviderTest extends TestCase
{
    private OllamaProvider $provider;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Set up test configuration
        Config::set('ai.ollama.url', 'http://test-ollama:11434');
        Config::set('ai.ollama.model', 'test-model');
        Config::set('ai.ollama.timeout', 30);
        
        $this->provider = new OllamaProvider();
    }

    public function test_generate_response_success()
    {
        // Arrange
        $message = 'Hello, how are you?';
        $expectedResponse = 'I am doing well, thank you for asking!';
        
        Http::fake([
            'http://test-ollama:11434/api/generate' => Http::response([
                'response' => $expectedResponse,
                'done' => true,
            ], 200)
        ]);

        // Act
        $result = $this->provider->generateResponse($message);

        // Assert
        $this->assertEquals($expectedResponse, $result);
        
        Http::assertSent(function ($request) use ($message) {
            return $request->url() === 'http://test-ollama:11434/api/generate' &&
                   $request['model'] === 'test-model' &&
                   $request['prompt'] === $message &&
                   $request['stream'] === false;
        });
    }

    public function test_generate_response_http_error()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'http://test-ollama:11434/api/generate' => Http::response('Server Error', 500)
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Ollama');
        
        $this->provider->generateResponse($message);
    }

    public function test_generate_response_invalid_json_format()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'http://test-ollama:11434/api/generate' => Http::response([
                'invalid_field' => 'some data',
                'done' => true,
            ], 200)
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Ollama: Invalid response format from Ollama');
        
        $this->provider->generateResponse($message);
    }

    public function test_generate_response_network_timeout()
    {
        // Arrange
        $message = 'Hello';
        
        Http::fake([
            'http://test-ollama:11434/api/generate' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection timeout');
            }
        ]);

        // Act & Assert
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to generate response from Ollama');
        
        $this->provider->generateResponse($message);
    }

    public function test_is_available_success()
    {
        // Arrange
        Http::fake([
            'http://test-ollama:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'test-model']
                ]
            ], 200)
        ]);

        // Act
        $result = $this->provider->isAvailable();

        // Assert
        $this->assertTrue($result);
        
        Http::assertSent(function ($request) {
            return $request->url() === 'http://test-ollama:11434/api/tags';
        });
    }

    public function test_is_available_server_error()
    {
        // Arrange
        Http::fake([
            'http://test-ollama:11434/api/tags' => Http::response('Server Error', 500)
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
            'http://test-ollama:11434/api/tags' => function () {
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
            'http://test-ollama:11434/api/tags' => function () {
                // Simulate timeout by throwing a generic exception
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
        Config::set('ai.ollama.url', 'http://custom-ollama:8080');
        Config::set('ai.ollama.model', 'custom-model');
        Config::set('ai.ollama.timeout', 60);

        // Act
        $provider = new OllamaProvider();
        
        // We can't directly test private properties, but we can test behavior
        Http::fake([
            'http://custom-ollama:8080/api/generate' => Http::response([
                'response' => 'test response',
                'done' => true,
            ], 200)
        ]);

        $provider->generateResponse('test');

        // Assert
        Http::assertSent(function ($request) {
            return $request->url() === 'http://custom-ollama:8080/api/generate' &&
                   $request['model'] === 'custom-model';
        });
    }

    public function test_generate_response_with_empty_message()
    {
        // Arrange
        $message = '';
        
        Http::fake([
            'http://test-ollama:11434/api/generate' => Http::response([
                'response' => 'I received an empty message.',
                'done' => true,
            ], 200)
        ]);

        // Act
        $result = $this->provider->generateResponse($message);

        // Assert
        $this->assertEquals('I received an empty message.', $result);
        
        Http::assertSent(function ($request) use ($message) {
            return $request['prompt'] === $message;
        });
    }

    public function test_generate_response_with_long_message()
    {
        // Arrange
        $message = str_repeat('This is a very long message. ', 100);
        
        Http::fake([
            'http://test-ollama:11434/api/generate' => Http::response([
                'response' => 'I received a long message.',
                'done' => true,
            ], 200)
        ]);

        // Act
        $result = $this->provider->generateResponse($message);

        // Assert
        $this->assertEquals('I received a long message.', $result);
    }
}