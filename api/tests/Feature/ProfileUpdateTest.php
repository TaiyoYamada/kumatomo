<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Carbon\Carbon;

class ProfileUpdateTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test successful profile update with all fields
     */
    public function test_can_update_profile_with_all_fields()
    {
        $user = User::factory()->create([
            'name' => 'Original Name',
            'email' => 'original@example.com',
            'username' => 'originaluser',
            'bio' => 'Original bio',
            'location' => 'Original City'
        ]);
        
        Sanctum::actingAs($user);

        $updateData = [
            'name' => 'Updated Name',
            'email' => 'updated@example.com',
            'username' => 'updateduser',
            'bio' => 'Updated bio',
            'location' => 'Updated City',
            'birthday' => '1995-05-15',
            'website' => 'https://updated-example.com'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'message',
                    'data' => [
                        'id',
                        'name',
                        'email',
                        'username',
                        'bio',
                        'location',
                        'birthday',
                        'website'
                    ]
                ])
                ->assertJson([
                    'message' => 'プロフィールが正常に更新されました。'
                ]);

        // Verify database was updated
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
            'email' => 'updated@example.com',
            'username' => 'updateduser',
            'bio' => 'Updated bio',
            'location' => 'Updated City',
            'birthday' => '1995-05-15',
            'website' => 'https://updated-example.com'
        ]);
    }

    /**
     * Test partial profile update (only some fields)
     */
    public function test_can_update_profile_partially()
    {
        $user = User::factory()->create([
            'name' => 'Original Name',
            'email' => 'original@example.com',
            'username' => 'originaluser',
            'bio' => 'Original bio'
        ]);
        
        Sanctum::actingAs($user);

        // Only update name and bio
        $updateData = [
            'name' => 'Partially Updated Name',
            'bio' => 'Partially updated bio'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200);

        // Verify only specified fields were updated
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Partially Updated Name',
            'email' => 'original@example.com', // Should remain unchanged
            'username' => 'originaluser', // Should remain unchanged
            'bio' => 'Partially updated bio'
        ]);
    }

    /**
     * Test profile update with location field (backward compatibility)
     */
    public function test_can_update_profile_with_location_field()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'location' => 'New Location'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200);

        // Verify location was saved
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'location' => 'New Location'
        ]);
    }

    /**
     * Test profile update with cover image URL (backward compatibility)
     */
    public function test_can_update_profile_with_cover_image_url()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'cover_image_url' => 'https://example.com/new-cover.jpg'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200);

        // Verify cover_image_url was saved
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'cover_image_url' => 'https://example.com/new-cover.jpg'
        ]);
    }

    /**
     * Test profile update using /user/update endpoint (without ID)
     */
    public function test_can_update_profile_using_user_update_endpoint()
    {
        $user = User::factory()->create(['name' => 'Original Name']);
        Sanctum::actingAs($user);

        $updateData = [
            'name' => 'Updated via user endpoint'
        ];

        $response = $this->putJson('/api/user/update', $updateData);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated via user endpoint'
        ]);
    }

    /**
     * Test profile update fails when user tries to update another user's profile
     */
    public function test_user_cannot_update_another_users_profile()
    {
        $user1 = User::factory()->create(['name' => 'User One']);
        $user2 = User::factory()->create(['name' => 'User Two']);
        
        Sanctum::actingAs($user1);

        $updateData = [
            'name' => 'Hacked Name'
        ];

        $response = $this->putJson("/api/users/{$user2->id}", $updateData);

        $response->assertStatus(403)
                ->assertJson([
                    'message' => 'このプロフィールを更新する権限がありません。',
                    'error' => 'Unauthorized'
                ]);

        // Verify user2's profile was not changed
        $this->assertDatabaseHas('users', [
            'id' => $user2->id,
            'name' => 'User Two'
        ]);
    }

    /**
     * Test profile update fails when user is not authenticated
     */
    public function test_unauthenticated_user_cannot_update_profile()
    {
        $user = User::factory()->create(['name' => 'Original Name']);

        $updateData = [
            'name' => 'Unauthorized Update'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(401);

        // Verify profile was not changed
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Original Name'
        ]);
    }

    /**
     * Test profile update fails for non-existent profile
     */
    public function test_profile_update_fails_for_non_existent_profile()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $nonExistentId = 99999;
        $updateData = [
            'name' => 'Non-existent Update'
        ];

        $response = $this->putJson("/api/users/{$nonExistentId}", $updateData);

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'プロフィールが見つかりません。',
                    'error' => 'Profile not found'
                ]);
    }

    /**
     * Test profile update fails with invalid email
     */
    public function test_profile_update_fails_with_invalid_email()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'email' => 'invalid-email-format'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'email'
                    ]
                ]);
    }

    /**
     * Test profile update fails with duplicate email
     */
    public function test_profile_update_fails_with_duplicate_email()
    {
        $user1 = User::factory()->create(['email' => 'user1@example.com']);
        $user2 = User::factory()->create(['email' => 'user2@example.com']);
        
        Sanctum::actingAs($user1);

        $updateData = [
            'email' => 'user2@example.com' // Try to use user2's email
        ];

        $response = $this->putJson("/api/users/{$user1->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'email'
                    ]
                ]);
    }

    /**
     * Test profile update fails with duplicate username
     */
    public function test_profile_update_fails_with_duplicate_username()
    {
        $user1 = User::factory()->create(['username' => 'user1']);
        $user2 = User::factory()->create(['username' => 'user2']);
        
        Sanctum::actingAs($user1);

        $updateData = [
            'username' => 'user2' // Try to use user2's username
        ];

        $response = $this->putJson("/api/users/{$user1->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'username'
                    ]
                ]);
    }

    /**
     * Test profile update fails with invalid username format
     */
    public function test_profile_update_fails_with_invalid_username()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'username' => 'ab' // Too short
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'username'
                    ]
                ]);
    }

    /**
     * Test profile update fails with invalid birthday
     */
    public function test_profile_update_fails_with_invalid_birthday()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'birthday' => Carbon::now()->addDays(1)->format('Y-m-d') // Future date
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'birthday'
                    ]
                ]);
    }

    /**
     * Test profile update fails with invalid website URL
     */
    public function test_profile_update_fails_with_invalid_website()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'website' => 'not-a-valid-url'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'website'
                    ]
                ]);
    }

    /**
     * Test profile update fails with bio too long
     */
    public function test_profile_update_fails_with_bio_too_long()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'bio' => str_repeat('a', 501) // Exceeds 500 character limit
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'bio'
                    ]
                ]);
    }

    /**
     * Test optimistic locking with concurrent updates
     */
    public function test_optimistic_locking_prevents_concurrent_updates()
    {
        $user = User::factory()->create(['name' => 'Original Name']);
        Sanctum::actingAs($user);

        // Simulate another session updating the user
        $user->update(['name' => 'Updated by another session']);
        $user->refresh();

        // Try to update with old timestamp
        $updateData = [
            'name' => 'My update',
            'updated_at' => Carbon::now()->subMinutes(5)->toISOString() // Old timestamp
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(409)
                ->assertJsonStructure([
                    'message',
                    'error',
                    'current_updated_at'
                ])
                ->assertJson([
                    'message' => 'プロフィールが他のセッションで更新されています。最新のデータを取得してから再試行してください。',
                    'error' => 'Conflict - Profile was updated by another session'
                ]);

        // Verify the name wasn't changed to "My update"
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated by another session'
        ]);
    }

    /**
     * Test successful update with correct timestamp
     */
    public function test_successful_update_with_correct_timestamp()
    {
        $user = User::factory()->create(['name' => 'Original Name']);
        Sanctum::actingAs($user);

        $updateData = [
            'name' => 'Updated Name',
            'updated_at' => $user->updated_at->toISOString()
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name'
        ]);
    }

    /**
     * Test profile update response format
     */
    public function test_profile_update_response_format()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'name' => 'Response Format Test'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'message',
                    'data' => [
                        'id',
                        'name',
                        'email',
                        'username'
                    ]
                ])
                ->assertJsonMissing(['password']); // Password should not be in response
    }

    /**
     * Test updating profile image URLs
     */
    public function test_can_update_profile_image_urls()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $updateData = [
            'profile_image_url' => 'https://example.com/profile.jpg',
            // 'profile_icon_image_url' => 'https://example.com/icon.jpg'
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'profile_image_url' => 'https://example.com/profile.jpg',
            // 'profile_icon_image_url' => 'https://example.com/icon.jpg'
        ]);
    }

    /**
     * Test updating has_completed_setup flag
     */
    public function test_can_update_has_completed_setup_flag()
    {
        $user = User::factory()->create(['has_completed_setup' => false]);
        Sanctum::actingAs($user);

        $updateData = [
            'has_completed_setup' => true
        ];

        $response = $this->putJson("/api/users/{$user->id}", $updateData);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'has_completed_setup' => true
        ]);
    }
}
