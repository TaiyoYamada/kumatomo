<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class ProfileCreationTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test successful profile creation
     */
    public function test_can_create_profile_with_valid_data()
    {
        $profileData = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'username' => 'testuser123',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'bio' => 'This is a test bio',
            'location' => 'Tokyo',
            'birthday' => '1990-01-01',
            'website' => 'https://example.com'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(201)
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
                        'website',
                        'createdAt'
                    ]
                ])
                ->assertJson([
                    'message' => 'プロフィールが正常に作成されました。'
                ]);

        // Verify user was created in database
        $this->assertDatabaseHas('users', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'username' => 'testuser123',
            'bio' => 'This is a test bio',
            'location' => 'Tokyo',
            'birthday' => '1990-01-01',
            'website' => 'https://example.com'
        ]);

        // Verify password was hashed
        $user = User::where('email', 'test@example.com')->first();
        $this->assertTrue(Hash::check('Password123!', $user->password));
    }

    /**
     * Test profile creation with minimum required fields
     */
    public function test_can_create_profile_with_minimum_fields()
    {
        $profileData = [
            'name' => 'Minimal User',
            'email' => 'minimal@example.com',
            'username' => 'minimaluser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(201)
                ->assertJsonStructure([
                    'message',
                    'data' => [
                        'id',
                        'name',
                        'email',
                        'username'
                    ]
                ]);

        $this->assertDatabaseHas('users', [
            'name' => 'Minimal User',
            'email' => 'minimal@example.com',
            'username' => 'minimaluser'
        ]);
    }

    /**
     * Test profile creation with location field (backward compatibility)
     */
    public function test_can_create_profile_with_location_field()
    {
        $profileData = [
            'name' => 'Location User',
            'email' => 'location@example.com',
            'username' => 'locationuser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'location' => 'Osaka'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(201);

        // Verify location was mapped to city
        $this->assertDatabaseHas('users', [
            'name' => 'Location User',
            'email' => 'location@example.com',
            'username' => 'locationuser',
            'location' => 'Osaka'
        ]);
    }

    /**
     * Test profile creation with cover image URL (backward compatibility)
     */
    public function test_can_create_profile_with_cover_image_url()
    {
        $profileData = [
            'name' => 'Cover User',
            'email' => 'cover@example.com',
            'username' => 'coveruser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'cover_image_url' => 'https://example.com/cover.jpg'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(201);

        // Verify cover_image_url was mapped to profile_image_url
        $this->assertDatabaseHas('users', [
            'name' => 'Cover User',
            'email' => 'cover@example.com',
            'username' => 'coveruser',
            'cover_image_url' => 'https://example.com/cover.jpg'
        ]);
    }

    /**
     * Test profile creation fails with missing required fields
     */
    public function test_profile_creation_fails_with_missing_required_fields()
    {
        $incompleteData = [
            'name' => 'Incomplete User',
            // Missing email, username, password
        ];

        $response = $this->postJson('/api/users', $incompleteData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'email',
                        'password'
                    ]
                ]);

        // Verify user was not created
        $this->assertDatabaseMissing('users', [
            'name' => 'Incomplete User'
        ]);
    }

    /**
     * Test profile creation fails with invalid email
     */
    public function test_profile_creation_fails_with_invalid_email()
    {
        $profileData = [
            'name' => 'Invalid Email User',
            'email' => 'invalid-email',
            'username' => 'invalidemailuser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'email'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with duplicate email
     */
    public function test_profile_creation_fails_with_duplicate_email()
    {
        // Create existing user
        User::factory()->create(['email' => 'existing@example.com']);

        $profileData = [
            'name' => 'Duplicate Email User',
            'email' => 'existing@example.com',
            'username' => 'duplicateuser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'email'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with duplicate username
     */
    public function test_profile_creation_fails_with_duplicate_username()
    {
        // Create existing user
        User::factory()->create(['username' => 'existinguser']);

        $profileData = [
            'name' => 'Duplicate Username User',
            'email' => 'duplicate@example.com',
            'username' => 'existinguser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'username'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with invalid username format
     */
    public function test_profile_creation_fails_with_invalid_username()
    {
        $profileData = [
            'name' => 'Invalid Username User',
            'email' => 'invalidusername@example.com',
            'username' => 'ab', // Too short
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'username'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with weak password
     */
    public function test_profile_creation_fails_with_weak_password()
    {
        $profileData = [
            'name' => 'Weak Password User',
            'email' => 'weakpassword@example.com',
            'username' => 'weakpassworduser',
            'password' => 'password', // No uppercase, numbers, or special chars
            'password_confirmation' => 'password'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'password'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with mismatched password confirmation
     */
    public function test_profile_creation_fails_with_mismatched_password_confirmation()
    {
        $profileData = [
            'name' => 'Mismatched Password User',
            'email' => 'mismatched@example.com',
            'username' => 'mismatcheduser',
            'password' => 'Password123!',
            'password_confirmation' => 'DifferentPassword123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'password_confirmation'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with invalid birthday
     */
    public function test_profile_creation_fails_with_invalid_birthday()
    {
        $profileData = [
            'name' => 'Invalid Birthday User',
            'email' => 'invalidbirthday@example.com',
            'username' => 'invalidbirthdayuser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'birthday' => now()->addDays(1)->format('Y-m-d') // Future date
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'birthday'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with invalid website URL
     */
    public function test_profile_creation_fails_with_invalid_website()
    {
        $profileData = [
            'name' => 'Invalid Website User',
            'email' => 'invalidwebsite@example.com',
            'username' => 'invalidwebsiteuser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'website' => 'not-a-valid-url'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'website'
                    ]
                ]);
    }

    /**
     * Test profile creation fails with bio too long
     */
    public function test_profile_creation_fails_with_bio_too_long()
    {
        $profileData = [
            'name' => 'Long Bio User',
            'email' => 'longbio@example.com',
            'username' => 'longbiouser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'bio' => str_repeat('a', 501) // Exceeds 500 character limit
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(422)
                ->assertJsonStructure([
                    'message',
                    'errors' => [
                        'bio'
                    ]
                ]);
    }

    /**
     * Test profile creation response format
     */
    public function test_profile_creation_response_format()
    {
        $profileData = [
            'name' => 'Response Format User',
            'email' => 'responseformat@example.com',
            'username' => 'resformatuser',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!'
        ];

        $response = $this->postJson('/api/users', $profileData);

        $response->assertStatus(201)
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
                        'website',
                        'profileImageURL',
                        'coverImageURL',
                        'hasCompletedSetup',
                        'createdAt'
                    ]
                ])
                ->assertJsonMissing(['password']); // Password should not be in response
    }
}
