<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Rules\UsernameFormat;
use App\Rules\UsernameAvailable;
use App\Rules\ValidAge;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class CustomValidationRulesTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test UsernameFormat rule with valid usernames
     */
    public function test_username_format_rule_passes_valid_usernames()
    {
        $validUsernames = [
            'testuser',
            'test123',
            'test_user',
            'test-user',
            'test.user',
            'user123test',
            'a1b2c3',
        ];

        $rule = new UsernameFormat();

        foreach ($validUsernames as $username) {
            $validator = Validator::make(['username' => $username], ['username' => $rule]);
            $this->assertTrue($validator->passes(), "Username '{$username}' should pass UsernameFormat validation");
        }
    }

    /**
     * Test UsernameFormat rule with invalid usernames
     */
    public function test_username_format_rule_fails_invalid_usernames()
    {
        $invalidUsernames = [
            'ab', // Too short
            str_repeat('a', 31), // Too long
            'user name', // Contains space
            'user@name', // Contains @
            'user#name', // Contains #
            'user$name', // Contains $
            '_username', // Starts with underscore
            'username_', // Ends with underscore
            '-username', // Starts with hyphen
            'username-', // Ends with hyphen
            '.username', // Starts with period
            'username.', // Ends with period
            'user__name', // Consecutive underscores
            'user--name', // Consecutive hyphens
            'user..name', // Consecutive periods
            'admin', // Reserved
            'root', // Reserved
            'api', // Reserved
            '123456', // Only numbers
        ];

        $rule = new UsernameFormat();

        foreach ($invalidUsernames as $username) {
            $validator = Validator::make(['username' => $username], ['username' => $rule]);
            $this->assertTrue($validator->fails(), "Username '{$username}' should fail UsernameFormat validation");
        }
    }

    /**
     * Test UsernameAvailable rule with available username
     */
    public function test_username_available_rule_passes_available_username()
    {
        $rule = new UsernameAvailable();
        $validator = Validator::make(['username' => 'availableuser'], ['username' => $rule]);
        $this->assertTrue($validator->passes());
    }

    /**
     * Test UsernameAvailable rule with taken username
     */
    public function test_username_available_rule_fails_taken_username()
    {
        $existingUser = User::factory()->create(['username' => 'takenuser']);
        
        $rule = new UsernameAvailable();
        $validator = Validator::make(['username' => 'takenuser'], ['username' => $rule]);
        $this->assertTrue($validator->fails());
    }

    /**
     * Test UsernameAvailable rule with excluded user ID
     */
    public function test_username_available_rule_passes_with_excluded_user_id()
    {
        $existingUser = User::factory()->create(['username' => 'existinguser']);
        
        $rule = new UsernameAvailable($existingUser->id);
        $validator = Validator::make(['username' => 'existinguser'], ['username' => $rule]);
        $this->assertTrue($validator->passes());
    }

    /**
     * Test ValidAge rule with valid ages
     */
    public function test_valid_age_rule_passes_valid_ages()
    {
        $validBirthdays = [
            Carbon::now()->subYears(13)->format('Y-m-d'), // Exactly 13 years old
            Carbon::now()->subYears(20)->format('Y-m-d'), // 20 years old
            Carbon::now()->subYears(50)->format('Y-m-d'), // 50 years old
            Carbon::now()->subYears(80)->format('Y-m-d'), // 80 years old
        ];

        $rule = new ValidAge(13, 120);

        foreach ($validBirthdays as $birthday) {
            $validator = Validator::make(['birthday' => $birthday], ['birthday' => $rule]);
            $this->assertTrue($validator->passes(), "Birthday '{$birthday}' should pass ValidAge validation");
        }
    }

    /**
     * Test ValidAge rule with invalid ages
     */
    public function test_valid_age_rule_fails_invalid_ages()
    {
        $invalidBirthdays = [
            Carbon::now()->subYears(12)->format('Y-m-d'), // Too young (12 years old)
            Carbon::now()->subYears(121)->format('Y-m-d'), // Too old (121 years old)
            Carbon::now()->addYears(1)->format('Y-m-d'), // Future date
            'invalid-date', // Invalid format
            '1990/01/01', // Wrong format
            '90-01-01', // Wrong format
        ];

        $rule = new ValidAge(13, 120);

        foreach ($invalidBirthdays as $birthday) {
            $validator = Validator::make(['birthday' => $birthday], ['birthday' => $rule]);
            $this->assertTrue($validator->fails(), "Birthday '{$birthday}' should fail ValidAge validation");
        }
    }

    /**
     * Test ValidAge rule with custom age limits
     */
    public function test_valid_age_rule_with_custom_limits()
    {
        // Test with 18+ requirement
        $rule = new ValidAge(18, 65);
        
        // Should pass for 25 year old
        $validBirthday = Carbon::now()->subYears(25)->format('Y-m-d');
        $validator = Validator::make(['birthday' => $validBirthday], ['birthday' => $rule]);
        $this->assertTrue($validator->passes());
        
        // Should fail for 16 year old
        $invalidBirthday = Carbon::now()->subYears(16)->format('Y-m-d');
        $validator = Validator::make(['birthday' => $invalidBirthday], ['birthday' => $rule]);
        $this->assertTrue($validator->fails());
        
        // Should fail for 70 year old
        $invalidBirthday = Carbon::now()->subYears(70)->format('Y-m-d');
        $validator = Validator::make(['birthday' => $invalidBirthday], ['birthday' => $rule]);
        $this->assertTrue($validator->fails());
    }

    /**
     * Test all custom rules together in a complete validation
     */
    public function test_all_custom_rules_together()
    {
        $data = [
            'username' => 'testuser123',
            'birthday' => Carbon::now()->subYears(25)->format('Y-m-d'),
        ];

        $rules = [
            'username' => [new UsernameFormat(), new UsernameAvailable()],
            'birthday' => [new ValidAge(13, 120)],
        ];

        $validator = Validator::make($data, $rules);
        $this->assertTrue($validator->passes());
    }

    /**
     * Test custom rules with existing user data
     */
    public function test_custom_rules_with_existing_user()
    {
        $existingUser = User::factory()->create([
            'username' => 'existinguser',
            'birthday' => Carbon::now()->subYears(30)->format('Y-m-d'),
        ]);

        // Test updating with same username (should pass)
        $data = [
            'username' => 'existinguser',
            'birthday' => Carbon::now()->subYears(25)->format('Y-m-d'),
        ];

        $rules = [
            'username' => [new UsernameFormat(), new UsernameAvailable($existingUser->id)],
            'birthday' => [new ValidAge(13, 120)],
        ];

        $validator = Validator::make($data, $rules);
        $this->assertTrue($validator->passes());

        // Test updating with different username (should pass if available)
        $data['username'] = 'newusername';
        $validator = Validator::make($data, $rules);
        $this->assertTrue($validator->passes());
    }

    /**
     * Test error messages from custom rules
     */
    public function test_custom_rule_error_messages()
    {
        // Test UsernameFormat error message
        $rule = new UsernameFormat();
        $validator = Validator::make(['username' => 'ab'], ['username' => $rule]);
        $this->assertTrue($validator->fails());
        $errors = $validator->errors()->get('username');
        $this->assertContains('ユーザーネームは3文字以上で入力してください。', $errors);

        // Test UsernameAvailable error message
        $existingUser = User::factory()->create(['username' => 'takenuser']);
        $rule = new UsernameAvailable();
        $validator = Validator::make(['username' => 'takenuser'], ['username' => $rule]);
        $this->assertTrue($validator->fails());
        $errors = $validator->errors()->get('username');
        $this->assertContains('このユーザーネームは既に使用されています。', $errors);

        // Test ValidAge error message
        $rule = new ValidAge(13, 120);
        $youngBirthday = Carbon::now()->subYears(10)->format('Y-m-d');
        $validator = Validator::make(['birthday' => $youngBirthday], ['birthday' => $rule]);
        $this->assertTrue($validator->fails());
        $errors = $validator->errors()->get('birthday');
        $this->assertContains('年齢は13歳以上である必要があります。', $errors);
    }
}
