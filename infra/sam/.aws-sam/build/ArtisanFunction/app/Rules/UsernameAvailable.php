<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use App\Models\User;

class UsernameAvailable implements ValidationRule
{
    protected $excludeUserId;

    /**
     * Create a new rule instance.
     *
     * @param int|null $excludeUserId User ID to exclude from uniqueness check
     */
    public function __construct(?int $excludeUserId = null)
    {
        $this->excludeUserId = $excludeUserId;
    }

    /**
     * Run the validation rule.
     *
     * @param  \Closure(string, ?string=): \Illuminate\Translation\PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (!User::isUsernameAvailable($value, $this->excludeUserId)) {
            $fail('このユーザーネームは既に使用されています。');
        }
    }
}
