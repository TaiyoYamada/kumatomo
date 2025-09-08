<?php

namespace Tests\Feature;

use App\Services\ErrorHandlingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\JsonResponse;
use Tests\TestCase;

class ErrorHandlingTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_creates_standardized_error_response()
    {
        $response = ErrorHandlingService::createErrorResponse(
            'SHOP_NOT_FOUND',
            'カスタムメッセージ',
            ['detail' => 'test'],
            404
        );

        $this->assertInstanceOf(JsonResponse::class, $response);
        $this->assertEquals(404, $response->getStatusCode());

        $data = $response->getData(true);
        $this->assertArrayHasKey('error', $data);
        $this->assertEquals('SHOP_NOT_FOUND', $data['error']['code']);
        $this->assertEquals('カスタムメッセージ', $data['error']['message']);
        $this->assertArrayHasKey('timestamp', $data['error']);
        $this->assertArrayHasKey('details', $data['error']);
    }

    /** @test */
    public function it_handles_validation_errors_properly()
    {
        $response = $this->postJson('/api/shops/search', [
            'q' => '', // Empty query should fail validation
        ]);

        $response->assertStatus(422);
        $response->assertJsonStructure([
            'error' => [
                'code',
                'message',
                'timestamp',
                'details'
            ]
        ]);

        $data = $response->json();
        $this->assertEquals('VALIDATION_ERROR', $data['error']['code']);
        $this->assertEquals('入力データに問題があります', $data['error']['message']);
    }

    /** @test */
    public function it_handles_not_found_errors()
    {
        $response = $this->getJson('/api/shops/99999');

        $response->assertStatus(404);
        $response->assertJsonStructure([
            'error' => [
                'code',
                'message',
                'timestamp'
            ]
        ]);

        $data = $response->json();
        $this->assertEquals('SHOP_NOT_FOUND', $data['error']['code']);
    }

    /** @test */
    public function it_handles_authentication_errors()
    {
        $response = $this->postJson('/api/posts', [
            'content' => 'Test post',
        ]);

        $response->assertStatus(401);
        $response->assertJsonStructure([
            'error' => [
                'code',
                'message',
                'timestamp'
            ]
        ]);

        $data = $response->json();
        $this->assertEquals('AUTHENTICATION_REQUIRED', $data['error']['code']);
        $this->assertEquals('認証が必要です', $data['error']['message']);
    }

    /** @test */
    public function it_identifies_retryable_errors()
    {
        $this->assertTrue(ErrorHandlingService::isRetryableError('DATABASE_CONNECTION_ERROR'));
        $this->assertTrue(ErrorHandlingService::isRetryableError('NETWORK_ERROR'));
        $this->assertTrue(ErrorHandlingService::isRetryableError('SERVICE_UNAVAILABLE'));
        
        $this->assertFalse(ErrorHandlingService::isRetryableError('VALIDATION_ERROR'));
        $this->assertFalse(ErrorHandlingService::isRetryableError('AUTHENTICATION_REQUIRED'));
        $this->assertFalse(ErrorHandlingService::isRetryableError('SHOP_NOT_FOUND'));
    }

    /** @test */
    public function it_provides_appropriate_retry_delays()
    {
        $this->assertEquals(5, ErrorHandlingService::getRetryDelay('DATABASE_CONNECTION_ERROR'));
        $this->assertEquals(3, ErrorHandlingService::getRetryDelay('NETWORK_ERROR'));
        $this->assertEquals(60, ErrorHandlingService::getRetryDelay('RATE_LIMIT_EXCEEDED'));
        $this->assertEquals(5, ErrorHandlingService::getRetryDelay('UNKNOWN_ERROR'));
    }

    /** @test */
    public function it_handles_endpoint_not_found()
    {
        $response = $this->getJson('/api/nonexistent-endpoint');

        $response->assertStatus(404);
        $response->assertJsonStructure([
            'error' => [
                'code',
                'message',
                'timestamp'
            ]
        ]);

        $data = $response->json();
        $this->assertEquals('ENDPOINT_NOT_FOUND', $data['error']['code']);
        $this->assertEquals('エンドポイントが見つかりません', $data['error']['message']);
    }

    /** @test */
    public function error_response_includes_recovery_suggestion()
    {
        $response = ErrorHandlingService::createErrorResponse('NETWORK_ERROR');
        $data = $response->getData(true);

        $this->assertArrayHasKey('recovery_suggestion', $data['error']);
        $this->assertEquals('ネットワーク接続を確認してください', $data['error']['recovery_suggestion']);
    }

    /** @test */
    public function error_response_excludes_debug_info_in_production()
    {
        // Temporarily set environment to production
        $originalEnv = app()->environment();
        app()->instance('env', 'production');

        $response = ErrorHandlingService::createErrorResponse('INTERNAL_SERVER_ERROR');
        $data = $response->getData(true);

        $this->assertArrayNotHasKey('debug', $data['error']);

        // Restore original environment
        app()->instance('env', $originalEnv);
    }

    /** @test */
    public function error_response_includes_debug_info_in_development()
    {
        // Ensure we're in a non-production environment
        app()->instance('env', 'local');

        $response = ErrorHandlingService::createErrorResponse('INTERNAL_SERVER_ERROR');
        $data = $response->getData(true);

        $this->assertArrayHasKey('debug', $data['error']);
    }
}