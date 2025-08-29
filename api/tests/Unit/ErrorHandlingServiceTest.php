<?php

namespace Tests\Unit;

use App\Services\ErrorHandlingService;
use Illuminate\Http\JsonResponse;
use PHPUnit\Framework\TestCase;

class ErrorHandlingServiceTest extends TestCase
{
    public function test_creates_standardized_error_response()
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
        $this->assertEquals(['detail' => 'test'], $data['error']['details']);
    }

    public function test_uses_default_message_when_custom_message_is_null()
    {
        $response = ErrorHandlingService::createErrorResponse('SHOP_NOT_FOUND');
        $data = $response->getData(true);

        $this->assertEquals('お店が見つかりません', $data['error']['message']);
    }

    public function test_includes_recovery_suggestion()
    {
        $response = ErrorHandlingService::createErrorResponse('NETWORK_ERROR');
        $data = $response->getData(true);

        $this->assertArrayHasKey('recovery_suggestion', $data['error']);
        $this->assertEquals('ネットワーク接続を確認してください', $data['error']['recovery_suggestion']);
    }

    public function test_identifies_retryable_errors()
    {
        $this->assertTrue(ErrorHandlingService::isRetryableError('DATABASE_CONNECTION_ERROR'));
        $this->assertTrue(ErrorHandlingService::isRetryableError('NETWORK_ERROR'));
        $this->assertTrue(ErrorHandlingService::isRetryableError('SERVICE_UNAVAILABLE'));
        $this->assertTrue(ErrorHandlingService::isRetryableError('INTERNAL_SERVER_ERROR'));
        
        $this->assertFalse(ErrorHandlingService::isRetryableError('VALIDATION_ERROR'));
        $this->assertFalse(ErrorHandlingService::isRetryableError('AUTHENTICATION_REQUIRED'));
        $this->assertFalse(ErrorHandlingService::isRetryableError('SHOP_NOT_FOUND'));
        $this->assertFalse(ErrorHandlingService::isRetryableError('ACCESS_DENIED'));
    }

    public function test_provides_appropriate_retry_delays()
    {
        $this->assertEquals(5, ErrorHandlingService::getRetryDelay('DATABASE_CONNECTION_ERROR'));
        $this->assertEquals(3, ErrorHandlingService::getRetryDelay('NETWORK_ERROR'));
        $this->assertEquals(10, ErrorHandlingService::getRetryDelay('SERVICE_UNAVAILABLE'));
        $this->assertEquals(5, ErrorHandlingService::getRetryDelay('INTERNAL_SERVER_ERROR'));
        $this->assertEquals(60, ErrorHandlingService::getRetryDelay('RATE_LIMIT_EXCEEDED'));
        $this->assertEquals(5, ErrorHandlingService::getRetryDelay('UNKNOWN_ERROR'));
    }

    public function test_error_codes_are_defined()
    {
        $this->assertArrayHasKey('VALIDATION_ERROR', ErrorHandlingService::ERROR_CODES);
        $this->assertArrayHasKey('SHOP_NOT_FOUND', ErrorHandlingService::ERROR_CODES);
        $this->assertArrayHasKey('NETWORK_ERROR', ErrorHandlingService::ERROR_CODES);
        $this->assertArrayHasKey('AUTHENTICATION_REQUIRED', ErrorHandlingService::ERROR_CODES);
    }

    public function test_error_messages_are_defined()
    {
        $this->assertArrayHasKey('VALIDATION_ERROR', ErrorHandlingService::ERROR_MESSAGES);
        $this->assertArrayHasKey('SHOP_NOT_FOUND', ErrorHandlingService::ERROR_MESSAGES);
        $this->assertArrayHasKey('NETWORK_ERROR', ErrorHandlingService::ERROR_MESSAGES);
        $this->assertArrayHasKey('AUTHENTICATION_REQUIRED', ErrorHandlingService::ERROR_MESSAGES);
        
        $this->assertEquals('入力データに問題があります', ErrorHandlingService::ERROR_MESSAGES['VALIDATION_ERROR']);
        $this->assertEquals('お店が見つかりません', ErrorHandlingService::ERROR_MESSAGES['SHOP_NOT_FOUND']);
    }

    public function test_recovery_suggestions_are_defined()
    {
        $this->assertArrayHasKey('VALIDATION_ERROR', ErrorHandlingService::RECOVERY_SUGGESTIONS);
        $this->assertArrayHasKey('NETWORK_ERROR', ErrorHandlingService::RECOVERY_SUGGESTIONS);
        $this->assertArrayHasKey('AUTHENTICATION_REQUIRED', ErrorHandlingService::RECOVERY_SUGGESTIONS);
        
        $this->assertEquals('入力内容を確認して再試行してください', ErrorHandlingService::RECOVERY_SUGGESTIONS['VALIDATION_ERROR']);
        $this->assertEquals('ネットワーク接続を確認してください', ErrorHandlingService::RECOVERY_SUGGESTIONS['NETWORK_ERROR']);
    }

    public function test_response_includes_timestamp()
    {
        $response = ErrorHandlingService::createErrorResponse('SHOP_NOT_FOUND');
        $data = $response->getData(true);

        $this->assertArrayHasKey('timestamp', $data['error']);
        $this->assertNotEmpty($data['error']['timestamp']);
        
        // Verify timestamp is in ISO format
        $timestamp = $data['error']['timestamp'];
        $this->assertMatchesRegularExpression('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/', $timestamp);
    }

    public function test_handles_unknown_error_codes()
    {
        $response = ErrorHandlingService::createErrorResponse('UNKNOWN_ERROR_CODE');
        $data = $response->getData(true);

        $this->assertEquals('UNKNOWN_ERROR_CODE', $data['error']['code']);
        $this->assertEquals('エラーが発生しました', $data['error']['message']);
        $this->assertNull($data['error']['recovery_suggestion']);
    }
}