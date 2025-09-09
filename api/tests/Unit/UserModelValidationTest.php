<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class UserModelValidationTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test validation rules for user creation
     */
    public function test_user_creation_validation_rules()
    {
        $rules = User::getCreationRules();
        
        $this->assertArrayHasKey('name', $rules);
        $this->assertArrayHasKey('email', $rules);
        $this->assertArrayHasKey('username', $rules);
        $this->assertArrayHasKey('password', $rules);
        $this->assertArrayHasKey('password_confirmation', $rules);
        
        $this->assertContains('required', $rules['name']);
        $this->assertContains('required', $rules['email']);
        $this->assertContains('required', $rules['username']);
        $this->assertContains('required', $rules['password']);
    }

    /**
     * Test validation rules for user updates
     */
    public function test_user_update_validation_rules()
    {
        $user = User::factory()->create();
        $rules = User::getUpdateRules($user->id);
        
        $this->assertArrayHasKey('name', $rules);
        $this->assertArrayHasKey('email', $rules);
        $this->assertArrayHasKey('username', $rules);
        $this->assertArrayNotHasKey('password', $rules);
    }

    /**
     * Test validation rules for partial updates
     */
    public function test_user_partial_update_validation_rules()
    {
        $user = User::factory()->create();
        $rules = User::getPartialUpdateRules($user->id);
        
        // Check that required fields become 'sometimes'
        $this->assertContains('sometimes', $rules['name']);
        $this->assertContains('sometimes', $rules['email']);
        $this->assertContains('sometimes', $rules['username']);
    }

    /**
     * Test valid user data passes validation
     */
    public function test_valid_user_data_passes_validation()
    {
        $validData = [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'username' => 'testuser123',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'bio' => 'This is a test bio',
            'city' => 'Tokyo',
            'birthday' => '1990-01-01',
            'website' => 'https://example.com'
        ];

        $validator = Validator::make($validData, User::getCreationRules(), User::getValidationMessages());
        $this->assertTrue($validator->passes());
    }

    /**
     * Test invalid name validation
     */
    public function test_invalid_name_validation()
    {
        $invalidNames = [
            '', // Empty
            str_repeat('a', 256), // Too long
            '123', // Only numbers
            '<script>alert("xss")</script>', // XSS attempt
        ];

        foreach ($invalidNames as $name) {
            $data = ['name' => $name];
            $validator = Validator::make($data, ['name' => User::getCreationRules()['name']]);
            $this->assertTrue($validator->fails(), "Name '{$name}' should fail validation");
        }
    }

    /**
     * Test invalid email validation
     */
    public function test_invalid_email_validation()
    {
        $invalidEmails = [
            '', // Empty
            'invalid-email', // Invalid format
            'test@', // Incomplete
            '@example.com', // Missing local part
            str_repeat('a', 250) . '@example.com', // Too long
        ];

        foreach ($invalidEmails as $email) {
            $data = ['email' => $email];
            $validator = Validator::make($data, ['email' => User::getCreationRules()['email']]);
            $this->assertTrue($validator->fails(), "Email '{$email}' should fail validation");
        }
    }

    /**
     * Test invalid username validation
     */
    public function test_invalid_username_validation()
    {
        $invalidUsernames = [
            '', // Empty
            'ab', // Too short
            str_repeat('a', 31), // Too long
            'user name', // Contains space
            'user@name', // Contains @
            'admin', // Reserved
            'root', // Reserved
            '123', // Only numbers
            '_username', // Starts with underscore
            'username_', // Ends with underscore
            'user__name', // Consecutive underscores
        ];

        foreach ($invalidUsernames as $username) {
            $data = ['username' => $username];
            $validator = Validator::make($data, ['username' => User::getCreationRules()['username']]);
            $this->assertTrue($validator->fails(), "Username '{$username}' should fail validation");
        }
    }

    /**
     * Test valid username formats
     */
    public function test_valid_username_formats()
    {
        $validUsernames = [
            'testuser',
            'test123',
            'test_user',
            'test-user',
            'test.user',
            'user123test',
        ];

        foreach ($validUsernames as $username) {
            $data = ['username' => $username];
            $validator = Validator::make($data, ['username' => User::getCreationRules()['username']]);
            $this->assertTrue($validator->passes(), "Username '{$username}' should pass validation");
        }
    }

    /**
     * Test birthday validation
     */
    public function test_birthday_validation()
    {
        // Valid birthday
        $validBirthday = '1990-01-01';
        $data = ['birthday' => $validBirthday];
        $validator = Validator::make($data, ['birthday' => User::getCreationRules()['birthday']]);
        $this->assertTrue($validator->passes());

        // Invalid birthdays
        $invalidBirthdays = [
            Carbon::now()->addDays(1)->format('Y-m-d'), // Future date
            Carbon::now()->subYears(121)->format('Y-m-d'), // Too old
            'invalid-date', // Invalid format
            '1990/01/01', // Wrong format
        ];

        foreach ($invalidBirthdays as $birthday) {
            $data = ['birthday' => $birthday];
            $validator = Validator::make($data, ['birthday' => User::getCreationRules()['birthday']]);
            $this->assertTrue($validator->fails(), "Birthday '{$birthday}' should fail validation");
        }
    }

    /**
     * Test website URL validation
     */
    public function test_website_url_validation()
    {
        // Valid URLs
        $validUrls = [
            'https://example.com',
            'http://example.com',
            'https://www.example.com/path',
        ];

        foreach ($validUrls as $url) {
            $data = ['website' => $url];
            $validator = Validator::make($data, ['website' => User::getCreationRules()['website']]);
            $this->assertTrue($validator->passes(), "URL '{$url}' should pass validation");
        }

        // Invalid URLs
        $invalidUrls = [
            'example.com', // Missing protocol
            'ftp://example.com', // Wrong protocol
            'javascript:alert("xss")', // XSS attempt
        ];

        foreach ($invalidUrls as $url) {
            $data = ['website' => $url];
            $validator = Validator::make($data, ['website' => User::getCreationRules()['website']]);
            $this->assertTrue($validator->fails(), "URL '{$url}' should fail validation");
        }
    }

    /**
     * Test username availability check
     */
    public function test_username_availability_check()
    {
        $existingUser = User::factory()->create(['username' => 'existinguser']);
        
        // Username should not be available
        $this->assertFalse(User::isUsernameAvailable('existinguser'));
        
        // Username should be available
        $this->assertTrue(User::isUsernameAvailable('newuser'));
        
        // Username should be available when excluding the existing user
        $this->assertTrue(User::isUsernameAvailable('existinguser', $existingUser->id));
    }

    /**
     * Test age validation
     */
    public function test_age_validation()
    {
        // Valid age (20 years old)
        $validBirthday = Carbon::now()->subYears(20)->format('Y-m-d');
        $this->assertTrue(User::isValidAge($validBirthday, 13));
        
        // Invalid age (too young)
        $invalidBirthday = Carbon::now()->subYears(10)->format('Y-m-d');
        $this->assertFalse(User::isValidAge($invalidBirthday, 13));
        
        // Invalid date format
        $this->assertFalse(User::isValidAge('invalid-date', 13));
    }

    /**
     * Test profile completion check
     */
    public function test_profile_completion_check()
    {
        // Complete profile
        $completeUser = User::factory()->create([
            'name' => 'Test User',
            'email' => 'complete@example.com',
            'username' => 'testuser'
        ]);
        $this->assertTrue($completeUser->isProfileComplete());
        
        // Incomplete profile (missing username)
        $incompleteUser = User::factory()->create([
            'name' => 'Test User',
            'email' => 'incomplete@example.com',
            'username' => null
        ]);
        $this->assertFalse($incompleteUser->isProfileComplete());
    }

    /**
     * Test profile completion percentage
     */
    public function test_profile_completion_percentage()
    {
        $user = User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'username' => 'testuser',
            'bio' => 'Test bio',
            'city' => null,
            'birthday' => null,
            'website' => null,
            'profile_image_url' => null
        ]);
        
        // Should have 4 out of 8 fields completed = 50%
        $this->assertEquals(50, $user->getProfileCompletionPercentage());
    }

    /**
     * Test password validation
     */
    public function test_password_validation()
    {
        // Valid password
        $validPassword = 'Password123!';
        $data = ['password' => $validPassword, 'password_confirmation' => $validPassword];
        $validator = Validator::make($data, [
            'password' => User::getCreationRules()['password'],
            'password_confirmation' => User::getCreationRules()['password_confirmation']
        ]);
        $this->assertTrue($validator->passes());

        // Invalid passwords
        $invalidPasswords = [
            'password', // No uppercase, numbers, or special chars
            'PASSWORD', // No lowercase, numbers, or special chars
            'Password', // No numbers or special chars
            'Pass12!', // Too short (7 chars)
            'password123', // No uppercase or special chars
        ];

        foreach ($invalidPasswords as $password) {
            $data = ['password' => $password, 'password_confirmation' => $password];
            $validator = Validator::make($data, [
                'password' => User::getCreationRules()['password'],
                'password_confirmation' => User::getCreationRules()['password_confirmation']
            ]);
            $this->assertTrue($validator->fails(), "Password '{$password}' should fail validation");
        }
    }

    /**
     * Test bio length validation
     */
    public function test_bio_length_validation()
    {
        // Valid bio
        $validBio = 'This is a valid bio that is under 500 characters.';
        $data = ['bio' => $validBio];
        $validator = Validator::make($data, ['bio' => User::getCreationRules()['bio']]);
        $this->assertTrue($validator->passes());

        // Invalid bio (too long)
        $invalidBio = str_repeat('a', 501);
        $data = ['bio' => $invalidBio];
        $validator = Validator::make($data, ['bio' => User::getCreationRules()['bio']]);
        $this->assertTrue($validator->fails());
    }
}
