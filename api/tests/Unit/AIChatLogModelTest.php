<?php

namespace Tests\Unit;

use App\Models\AIChatLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Tests\TestCase;
use Mockery;
use Carbon\Carbon;

class AIChatLogModelTest extends TestCase
{
    public function test_ai_chat_log_has_correct_fillable_attributes()
    {
        $aiChatLog = new AIChatLog();
        
        $expectedFillable = [
            'user_id',
            'provider',
            'request_timestamp',
            'response_timestamp',
            'response_time_ms',
        ];
        
        $this->assertEquals($expectedFillable, $aiChatLog->getFillable());
    }

    public function test_ai_chat_log_has_correct_casts()
    {
        $aiChatLog = new AIChatLog();
        
        $casts = $aiChatLog->getCasts();
        
        $this->assertEquals('datetime', $casts['request_timestamp']);
        $this->assertEquals('datetime', $casts['response_timestamp']);
        $this->assertEquals('integer', $casts['response_time_ms']);
        $this->assertEquals('integer', $casts['user_id']);
    }

    public function test_ai_chat_log_belongs_to_user()
    {
        $aiChatLog = new AIChatLog();
        
        $relation = $aiChatLog->user();
        
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
        $this->assertEquals('user_id', $relation->getForeignKeyName());
        $this->assertEquals('id', $relation->getOwnerKeyName());
    }

    public function test_calculate_response_time_returns_correct_milliseconds()
    {
        $aiChatLog = new AIChatLog();
        
        $requestTime = Carbon::now();
        $responseTime = $requestTime->copy()->addSeconds(2); // 2 seconds later
        
        $aiChatLog->request_timestamp = $requestTime;
        $aiChatLog->response_timestamp = $responseTime;
        
        $result = $aiChatLog->calculateResponseTime();
        
        $this->assertEquals(2000, $result); // 2000 milliseconds (2 seconds)
    }

    public function test_calculate_response_time_returns_null_when_timestamps_missing()
    {
        $aiChatLog = new AIChatLog();
        
        // Test with no timestamps
        $this->assertNull($aiChatLog->calculateResponseTime());
        
        // Test with only request timestamp
        $aiChatLog->request_timestamp = Carbon::now();
        $this->assertNull($aiChatLog->calculateResponseTime());
        
        // Test with only response timestamp
        $aiChatLog->request_timestamp = null;
        $aiChatLog->response_timestamp = Carbon::now();
        $this->assertNull($aiChatLog->calculateResponseTime());
    }

    public function test_by_provider_scope_builds_correct_query()
    {
        $aiChatLog = new AIChatLog();
        $builder = Mockery::mock(Builder::class);
        
        $provider = 'ollama';
        
        $builder->shouldReceive('where')
                ->once()
                ->with('provider', $provider)
                ->andReturnSelf();
        
        $result = $aiChatLog->scopeByProvider($builder, $provider);
        
        $this->assertSame($builder, $result);
    }

    public function test_by_user_scope_builds_correct_query()
    {
        $aiChatLog = new AIChatLog();
        $builder = Mockery::mock(Builder::class);
        
        $userId = 123;
        
        $builder->shouldReceive('where')
                ->once()
                ->with('user_id', $userId)
                ->andReturnSelf();
        
        $result = $aiChatLog->scopeByUser($builder, $userId);
        
        $this->assertSame($builder, $result);
    }

    public function test_by_date_range_scope_builds_correct_query()
    {
        $aiChatLog = new AIChatLog();
        $builder = Mockery::mock(Builder::class);
        
        $startDate = '2025-01-01';
        $endDate = '2025-01-31';
        
        $builder->shouldReceive('whereBetween')
                ->once()
                ->with('request_timestamp', [$startDate, $endDate])
                ->andReturnSelf();
        
        $result = $aiChatLog->scopeByDateRange($builder, $startDate, $endDate);
        
        $this->assertSame($builder, $result);
    }

    public function test_table_name_is_correct()
    {
        $aiChatLog = new AIChatLog();
        
        $this->assertEquals('ai_chat_logs', $aiChatLog->getTable());
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}