<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    /**
     * Test the health check endpoint.
     */
    public function test_health_check_endpoint_returns_ok(): void
    {
        dump('DB Connection: ' . config('database.default'));
        dump('DB Database: ' . config('database.connections.'.config('database.default').'.database'));
        
        $response = $this->get('/api/health');

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'ok',
            ]);
    }
}
