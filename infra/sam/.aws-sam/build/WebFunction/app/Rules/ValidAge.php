<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Carbon\Carbon;
use App\Models\User;

class ValidAge implements ValidationRule
{
    protected $minAge;
    protected $maxAge;

    /**
     * Create a new rule instance.
     *
     * @param int $minAge Minimum age requirement
     * @param int $maxAge Maximum age limit
     */
    public function __construct(int $minAge = 6, int $maxAge = 120)
    {
        $this->minAge = $minAge;
        $this->maxAge = $maxAge;
    }

    /**
     * Run the validation rule.
     *
     * @param  \Closure(string, ?string=): \Illuminate\Translation\PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        try {
            $birthDate = Carbon::createFromFormat('Y-m-d', $value);
            $age = $birthDate->diffInYears(Carbon::now());

            if ($age < $this->minAge) {
                $fail("年齢は{$this->minAge}歳以上である必要があります。");
                return;
            }

            if ($age > $this->maxAge) {
                $fail("年齢は{$this->maxAge}歳以下である必要があります。");
                return;
            }

            // Additional check using the User model method
            if (!User::isValidAge($value, $this->minAge)) {
                $fail("有効な年齢を入力してください。");
                return;
            }

        } catch (\Exception $e) {
            $fail('有効な誕生日を入力してください（YYYY-MM-DD形式）。');
        }
    }
}
