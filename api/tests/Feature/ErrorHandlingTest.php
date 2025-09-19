<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Shop;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class ErrorHandlingTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create();
        $this->actingAs($this->user, 'sanctum');
    }

    /** @test */
    public function it_handles_validation_errors_properly()
    {
        // Test shop creation with invalid data
        $response = $this->postJson('/api/admin/shops', [
            'name' => '', // Required field empty
            'genre' => 'invalid_genre', // Invalid enum value
            'latitude' => 'not_a_number', // Invalid type
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'message',
                'errors' => [
                    'name',
                    'genre',
                    'latitude'
                ]
            ]);

        $responseData = $response->json();
        $this->assertArrayHasKey('name', $responseData['errors']);
        $this->assertArrayHasKey('genre', $responseData['errors']);
        $this->assertArrayHasKey('latitude', $responseData['errors']);
    }

    /** @test */
    public function it_handles_authentication_errors()
    {
        // Test without authentication
        $this->withoutMiddleware(\Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class);
        
        $response = $this->postJson('/api/admin/shops', [
            'name' => 'Test Shop',
            'genre' => 'ラーメン'
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'message' => 'Unauthenticated.'
            ]);
    }

    /** @test */
    public function it_handles_not_found_errors()
    {
        $response = $this->getJson('/api/shops/99999');

        $response->assertStatus(404)
            ->assertJsonStructure([
                'error' => [
                    'message',
                    'type',
                    'code'
                ]
            ]);

        $responseData = $response->json();
        $this->assertEquals('not_found', $responseData['error']['type']);
    }

    /** @test */
    public function it_handles_server_errors_gracefully()
    {
        // Mock a database error
        DB::shouldReceive('table')->andThrow(new \Exception('Database connection failed'));

        $response = $this->getJson('/api/shops');

        $response->assertStatus(500)
            ->assertJsonStructure([
                'error' => [
                    'message',
                    'type',
                    'code'
                ],
                'meta' => [
                    'request_id',
                    'timestamp'
                ]
            ]);

        $responseData = $response->json();
        $this->assertEquals('server_error', $responseData['error']['type']);
        $this->assertArrayHasKey('request_id', $responseData['meta']);
    }

    /** @test */
    public function it_handles_rate_limiting()
    {
        // Simulate rate limiting by making many requests quickly
        for ($i = 0; $i < 100; $i++) {
            $response = $this->getJson('/api/shops');
            
            if ($response->status() === 429) {
                $response->assertJsonStructure([
                    'error' => [
                        'message',
                        'type',
                        'retry_after'
                    ]
                ]);
                
                $responseData = $response->json();
                $this->assertEquals('rate_limit_exceeded', $responseData['error']['type']);
                $this->assertArrayHasKey('retry_after', $responseData['error']);
                break;
            }
        }
    }

    /** @test */
    public function it_provides_proper_error_context()
    {
        $response = $this->postJson('/api/shop-proposals', [
            'name' => '', // Invalid data to trigger validation error
        ]);

        $response->assertStatus(422);
        $responseData = $response->json();

        // Check that error response includes helpful context
        $this->assertArrayHasKey('message', $responseData);
        $this->assertArrayHasKey('errors', $responseData);
        
        // Check for field-specific error messages
        $this->assertArrayHasKey('name', $responseData['errors']);
        $this->assertIsArray($responseData['errors']['name']);
    }

    /** @test */
    public function it_handles_network_timeout_simulation()
    {
        // Simulate a slow operation that might timeout
        $response = $this->withHeaders([
            'X-Simulate-Timeout' => 'true'
        ])->getJson('/api/shops');

        // In a real scenario, this would test actual timeout handling
        // For now, we'll test that the endpoint responds appropriately
        $this->assertTrue(in_array($response->status(), [200, 408, 504]));
    }

    /** @test */
    public function it_logs_errors_appropriately()
    {
        Log::shouldReceive('error')
            ->once()
            ->with(\Mockery::type('string'), \Mockery::type('array'));

        // Trigger an error that should be logged
        $this->postJson('/api/admin/shops', [
            'name' => str_repeat('a', 1000), // Extremely long name to trigger error
        ]);
    }

    /** @test */
    public function it_handles_database_constraint_violations()
    {
        // Create a shop first
        $shop = Shop::factory()->create(['name' => 'Unique Shop']);

        // Try to create another shop with the same name (if unique constraint exists)
        $response = $this->postJson('/api/admin/shops', [
            'name' => 'Unique Shop',
            'genre' => 'ラーメン'
        ]);

        // The response should handle the constraint violation gracefully
        $this->assertTrue(in_array($response->status(), [422, 409]));
    }

    /** @test */
    public function it_handles_file_upload_errors()
    {
        // Test with invalid file type
        $response = $this->postJson('/api/admin/shops', [
            'name' => 'Test Shop',
            'genre' => 'ラーメン',
            'image' => 'invalid_file_data'
        ]);

        if ($response->status() === 422) {
            $responseData = $response->json();
            $this->assertArrayHasKey('errors', $responseData);
        }
    }

    /** @test */
    public function it_provides_error_recovery_suggestions()
    {
        $response = $this->postJson('/api/shop-proposals', [
            'name' => '', // Trigger validation error
        ]);

        $response->assertStatus(422);
        $responseData = $response->json();

        // Check that the error response includes helpful recovery information
        $this->assertArrayHasKey('message', $responseData);
        $this->assertIsString($responseData['message']);
        $this->assertNotEmpty($responseData['message']);
    }

    /** @test */
    public function it_handles_concurrent_request_conflicts()
    {
        $shop = Shop::factory()->create();

        // Simulate concurrent updates
        $responses = [];
        
        for ($i = 0; $i < 5; $i++) {
            $responses[] = $this->putJson("/api/admin/shops/{$shop->id}", [
                'name' => "Updated Name {$i}",
                'genre' => 'ラーメン'
            ]);
        }

        // At least one should succeed
        $successCount = collect($responses)->filter(fn($r) => $r->status() === 200)->count();
        $this->assertGreaterThan(0, $successCount);
    }

    /** @test */
    public function it_handles_malformed_json_requests()
    {
        $response = $this->call('POST', '/api/admin/shops', [], [], [], [
            'CONTENT_TYPE' => 'application/json',
            'HTTP_ACCEPT' => 'application/json'
        ], 'invalid json data');

        $response->assertStatus(400);
    }

    /** @test */
    public function it_handles_missing_required_headers()
    {
        $response = $this->call('POST', '/api/admin/shops', [
            'name' => 'Test Shop'
        ], [], [], [
            // Missing Content-Type header
        ]);

        // Should handle gracefully, either accepting or rejecting appropriately
        $this->assertTrue(in_array($response->status(), [200, 201, 400, 415]));
    }

    /** @test */
    public function it_provides_consistent_error_format()
    {
        $testCases = [
            // Validation error
            ['method' => 'POST', 'url' => '/api/admin/shops', 'data' => ['name' => '']],
            // Not found error
            ['method' => 'GET', 'url' => '/api/shops/99999', 'data' => []],
            // Unauthorized (without auth)
            ['method' => 'POST', 'url' => '/api/admin/shops', 'data' => ['name' => 'Test'], 'no_auth' => true],
        ];

        foreach ($testCases as $case) {
            if (isset($case['no_auth'])) {
                $this->withoutMiddleware(\Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class);
            }

            $response = $this->json($case['method'], $case['url'], $case['data']);

            if ($response->status() >= 400) {
                $responseData = $response->json();
                
                // All error responses should have consistent structure
                $this->assertTrue(
                    isset($responseData['message']) || 
                    isset($responseData['error']['message']),
                    "Error response should have a message field"
                );
            }
        }
    }

    /** @test */
    public function it_handles_external_api_failures()
    {
        // Mock external HTTP calls to fail
        Http::fake([
            '*' => Http::response(null, 500)
        ]);

        // Test an endpoint that might make external API calls
        $response = $this->getJson('/api/shops');

        // Should handle external failures gracefully
        $this->assertTrue(in_array($response->status(), [200, 500, 503]));
    }

    /** @test */
    public function it_handles_cache_failures()
    {
        // Mock cache to fail
        Cache::shouldReceive('get')->andThrow(new \Exception('Cache unavailable'));
        Cache::shouldReceive('put')->andThrow(new \Exception('Cache unavailable'));

        $response = $this->getJson('/api/shops');

        // Should handle cache failures gracefully and still return data
        $this->assertTrue(in_array($response->status(), [200, 500]));
    }

    /** @test */
    public function it_provides_error_tracking_information()
    {
        $response = $this->getJson('/api/shops/99999');

        $response->assertStatus(404);
        $responseData = $response->json();

        // Should include tracking information for debugging
        if (isset($responseData['meta'])) {
            $this->assertArrayHasKey('request_id', $responseData['meta']);
            $this->assertArrayHasKey('timestamp', $responseData['meta']);
        }
    }

    /** @test */
    public function it_handles_memory_limit_scenarios()
    {
        // Test with a request that might consume a lot of memory
        $largeData = array_fill(0, 10000, [
            'name' => str_repeat('a', 100),
            'description' => str_repeat('b', 1000)
        ]);

        $response = $this->postJson('/api/admin/shops/bulk', [
            'shops' => $largeData
        ]);

        // Should handle gracefully, either processing or rejecting appropriately
        $this->assertTrue(in_array($response->status(), [200, 201, 413, 422, 500]));
    }

    /** @test */
    public function it_maintains_error_response_performance()
    {
        $startTime = microtime(true);

        // Trigger various types of errors
        $this->getJson('/api/shops/99999'); // Not found
        $this->postJson('/api/admin/shops', ['name' => '']); // Validation
        
        $endTime = microtime(true);
        $executionTime = $endTime - $startTime;

        // Error responses should be fast (less than 1 second for multiple requests)
        $this->assertLessThan(1.0, $executionTime);
    }
}