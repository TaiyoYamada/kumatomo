<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class UsernameFormat implements ValidationRule
{
    /**
     * Run the validation rule.
     *
     * @param  \Closure(string, ?string=): \Illuminate\Translation\PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        // Check minimum length
        if (strlen($value) < 3) {
            $fail('ユーザーネームは3文字以上で入力してください。');
            return;
        }

        // Check maximum length
        if (strlen($value) > 30) {
            $fail('ユーザーネームは30文字以内で入力してください。');
            return;
        }

        // Check allowed characters (alphanumeric, underscore, hyphen, period)
        if (!preg_match('/^[a-zA-Z0-9_\-\.]+$/', $value)) {
            $fail('ユーザーネームは英数字、アンダースコア、ハイフン、ピリオドのみ使用できます。');
            return;
        }

        // Check that it doesn't start or end with special characters
        if (preg_match('/^[_\-\.]|[_\-\.]$/', $value)) {
            $fail('ユーザーネームは特殊文字で始まったり終わったりできません。');
            return;
        }

        // Check for consecutive special characters
        if (preg_match('/[_\-\.]{2,}/', $value)) {
            $fail('ユーザーネームに連続する特殊文字は使用できません。');
            return;
        }

        // Check reserved usernames
        $reservedUsernames = [
            'admin', 'root', 'api', 'www', 'mail', 'support', 'help', 'info', 
            'contact', 'about', 'terms', 'privacy', 'login', 'register', 'logout', 
            'profile', 'settings', 'dashboard', 'home', 'index', 'user', 'users',
            'system', 'test', 'demo', 'guest', 'anonymous', 'null', 'undefined',
            'kumatomo', 'kumamon', 'moderator', 'staff'
        ];

        if (in_array(strtolower($value), $reservedUsernames)) {
            $fail('このユーザーネームは予約されているため使用できません。');
            return;
        }

        // Check for inappropriate patterns
        $inappropriatePatterns = [
            '/^[0-9]+$/',  // Only numbers
        ];

        foreach ($inappropriatePatterns as $pattern) {
            if (preg_match($pattern, $value)) {
                $fail('このユーザーネーム形式は使用できません。');
                return;
            }
        }
    }
}
