<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

class AIControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_ai_chat_requires_authentication()
    {
        $response = $this->postJson('/api/ai/chat', [
            'message' => 'Hello AI'
        ]);

        $response->assertStatus(401);
    }

    public function test_ai_chat_validates_message_required()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/ai/chat', []);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'error',
                    'message',
                    'code',
                    'details',
                    'timestamp'
                ])
                ->assertJson([
                    'error' => true,
                    'code' => 'VALIDATION_ERROR'
                ]);
    }

    public function test_ai_chat_validates_message_not_empty()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/ai/chat', [
            'message' => ''
        ]);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'error',
                    'message',
                    'code',
                    'details',
                    'timestamp'
                ]);
    }

    public function test_ai_chat_validates_message_max_length()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $longMessage = str_repeat('a', 1001); // Exceeds 1000 character limit

        $response = $this->postJson('/api/ai/chat', [
            'message' => $longMessage
        ]);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'error',
                    'message',
                    'code',
                    'details',
                    'timestamp'
                ]);
    }

    public function test_ai_chat_returns_service_unavailable_when_provider_not_available()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Since no AI provider is configured in test environment, 
        // this should return service unavailable
        $response = $this->postJson('/api/ai/chat', [
            'message' => 'Hello AI'
        ]);

        $response->assertStatus(503)
                ->assertJsonStructure([
                    'error',
                    'message',
                    'code',
                    'timestamp'
                ])
                ->assertJson([
                    'error' => true,
                    'code' => 'AI_SERVICE_UNAVAILABLE'
                ]);
    }
}