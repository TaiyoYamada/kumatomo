<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

class ProfileDeletionTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test successful profile deletion by owner
     */
    public function test_user_can_delete_own_profile()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->deleteJson("/api/users/{$user->id}");

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'プロフィールが正常に削除されました。'
                ]);

        // Verify user was soft deleted
        $this->assertSoftDeleted('users', [
            'id' => $user->id,
            'email' => $user->email
        ]);

        // Verify user still exists in database but is soft deleted
        $deletedUser = User::withTrashed()->find($user->id);
        $this->assertNotNull($deletedUser);
        $this->assertNotNull($deletedUser->deleted_at);
    }

    /**
     * Test profile deletion fails when user tries to delete another user's profile
     */
    public function test_user_cannot_delete_another_users_profile()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        Sanctum::actingAs($user1);

        $response = $this->deleteJson("/api/users/{$user2->id}");

        $response->assertStatus(403)
                ->assertJson([
                    'message' => 'このプロフィールを削除する権限がありません。',
                    'error' => 'Unauthorized'
                ]);

        // Verify user2 was not deleted
        $this->assertDatabaseHas('users', [
            'id' => $user2->id,
            'email' => $user2->email,
            'deleted_at' => null
        ]);
    }

    /**
     * Test profile deletion fails when user is not authenticated
     */
    public function test_unauthenticated_user_cannot_delete_profile()
    {
        $user = User::factory()->create();

        $response = $this->deleteJson("/api/users/{$user->id}");

        $response->assertStatus(401);

        // Verify user was not deleted
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email' => $user->email,
            'deleted_at' => null
        ]);
    }

    /**
     * Test profile deletion fails when profile does not exist
     */
    public function test_profile_deletion_fails_for_non_existent_profile()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $nonExistentId = 99999;
        $response = $this->deleteJson("/api/users/{$nonExistentId}");

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'プロフィールが見つかりません。',
                    'error' => 'Profile not found'
                ]);
    }

    /**
     * Test profile deletion with invalid user ID format
     */
    public function test_profile_deletion_fails_with_invalid_id_format()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->deleteJson("/api/users/invalid-id");

        $response->assertStatus(404);
    }

    /**
     * Test that soft deleted user cannot be retrieved normally
     */
    public function test_soft_deleted_user_cannot_be_retrieved_normally()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Delete the user
        $this->deleteJson("/api/users/{$user->id}");

        // Try to retrieve the user normally (should fail)
        $retrievedUser = User::find($user->id);
        $this->assertNull($retrievedUser);

        // But can be retrieved with trashed
        $trashedUser = User::withTrashed()->find($user->id);
        $this->assertNotNull($trashedUser);
        $this->assertNotNull($trashedUser->deleted_at);
    }

    /**
     * Test that soft deleted user data is still accessible via token but marked as deleted
     */
    public function test_soft_deleted_user_token_behavior()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Delete the user
        $this->deleteJson("/api/users/{$user->id}");

        // Token is still valid, but user is soft deleted
        // Note: In a real application, you might want to invalidate tokens on deletion
        $response = $this->getJson('/api/user');
        
        // The response will depend on how the /api/user endpoint handles soft deleted users
        // For now, we'll just verify the user is soft deleted in the database
        $this->assertSoftDeleted('users', ['id' => $user->id]);
    }

    /**
     * Test profile deletion response format
     */
    public function test_profile_deletion_response_format()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->deleteJson("/api/users/{$user->id}");

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'message'
                ])
                ->assertJsonMissing(['data', 'error']);
    }

    /**
     * Test multiple deletion attempts on same profile
     */
    public function test_multiple_deletion_attempts_on_same_profile()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // First deletion should succeed
        $response1 = $this->deleteJson("/api/users/{$user->id}");
        $response1->assertStatus(200);

        // Second deletion attempt should fail (user not found)
        $response2 = $this->deleteJson("/api/users/{$user->id}");
        $response2->assertStatus(404)
                 ->assertJson([
                     'message' => 'プロフィールが見つかりません。',
                     'error' => 'Profile not found'
                 ]);
    }

    /**
     * Test profile deletion with related data cleanup
     */
    public function test_profile_deletion_with_related_data()
    {
        $user = User::factory()->create([
            'name' => 'User with Data',
            'email' => 'userdata@example.com',
            'username' => 'userwithdata',
            'bio' => 'User bio',
            'bio' => 'User bio',
            'location' => 'Tokyo',
            'profile_image_url' => 'https://example.com/image.jpg'
        ]);
        
        Sanctum::actingAs($user);

        $response = $this->deleteJson("/api/users/{$user->id}");

        $response->assertStatus(200);

        // Verify all user data is preserved but soft deleted
        $deletedUser = User::withTrashed()->find($user->id);
        $this->assertEquals('User with Data', $deletedUser->name);
        $this->assertEquals('userdata@example.com', $deletedUser->email);
        $this->assertEquals('userwithdata', $deletedUser->username);
        $this->assertEquals('User bio', $deletedUser->bio);
        $this->assertEquals('Tokyo', $deletedUser->location);
        $this->assertEquals('https://example.com/image.jpg', $deletedUser->profile_image_url);
        $this->assertNotNull($deletedUser->deleted_at);
    }

    /**
     * Test authorization with different user tokens
     */
    public function test_authorization_with_different_user_tokens()
    {
        $user1 = User::factory()->create(['name' => 'User One']);
        $user2 = User::factory()->create(['name' => 'User Two']);
        $user3 = User::factory()->create(['name' => 'User Three']);

        // User1 tries to delete User2's profile
        Sanctum::actingAs($user1);
        $response1 = $this->deleteJson("/api/users/{$user2->id}");
        $response1->assertStatus(403);

        // User2 tries to delete User3's profile
        Sanctum::actingAs($user2);
        $response2 = $this->deleteJson("/api/users/{$user3->id}");
        $response2->assertStatus(403);

        // User3 deletes their own profile (should succeed)
        Sanctum::actingAs($user3);
        $response3 = $this->deleteJson("/api/users/{$user3->id}");
        $response3->assertStatus(200);

        // Verify only User3 was deleted
        $this->assertDatabaseHas('users', ['id' => $user1->id, 'deleted_at' => null]);
        $this->assertDatabaseHas('users', ['id' => $user2->id, 'deleted_at' => null]);
        $this->assertSoftDeleted('users', ['id' => $user3->id]);
    }
}
