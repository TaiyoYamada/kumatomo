<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * 一括代入可能な属性
     */
    protected $fillable = [
        'email',
        'password',
        'name',
        'username',
        'bio',
        'city',
        'location', // Alias for city
        'birthday',
        'website',
        'post_count',
        'followers_count',
        'following_count',
        'profile_image_url', // カバー画像のURL
        'profile_icon_image_url', // プロフィールアイコンのURL
        'cover_image_url', // カバー画像のURL (alias for profile_image_url)
        'has_completed_setup',
        'created_at',
    ];

    /**
     * キャスト（自動型変換）
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'followers_count' => 'integer',
        'following_count' => 'integer',
        'has_completed_setup' => 'boolean',
        'password' => 'hashed',
    ];

    /**
     * 非表示にする属性（APIレスポンスに含めない）
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * ユーザーが投稿したストーリーを取得
     */
    public function stories()
    {
        return $this->hasMany(Post::class);
    }

    /**
     * ユーザーが投稿した投稿を取得（storiesのエイリアス）
     */
    public function posts()
    {
        return $this->hasMany(Post::class);
    }

    /**
     * ユーザーのAIチャットログを取得
     */
    public function aiChatLogs()
    {
        return $this->hasMany(AIChatLog::class);
    }

    /**
     * Get comprehensive validation rules for user profile
     * 
     * @param int|null $userId User ID to ignore for unique validation (for updates)
     * @param string $context Validation context ('create', 'update', 'partial')
     * @return array
     */
    public static function getValidationRules($userId = null, $context = 'update'): array
    {
        $rules = [
            'name' => ['required', 'string', 'min:1', 'max:255', 'regex:/^[\p{L}\p{M}\p{N}\s\-\'\.]+$/u', 'not_regex:/^[0-9]+$/'],
            'email' => [
                'required', 
                'email:rfc', 
                'max:255',
                Rule::unique('users')->ignore($userId)
            ],
            'username' => [
                'required', 
                'string', 
                'min:3', 
                'max:30', 
                'regex:/^[a-zA-Z0-9_\-\.]+$/',
                'not_regex:/^[0-9]+$/',
                'not_regex:/^[_\-\.]/',
                'not_regex:/[_\-\.]$/',
                'not_regex:/[_\-\.]{2,}/',
                Rule::unique('users')->ignore($userId),
                'not_in:admin,root,api,www,mail,support,help,info,contact,about,terms,privacy,login,register,logout,profile,settings,dashboard,home,index'
            ],
            'bio' => ['nullable', 'string', 'max:500'],
            'city' => ['nullable', 'string', 'max:255', 'regex:/^[\p{L}\p{M}\p{N}\s\-\'\.]+$/u'],
            'location' => ['nullable', 'string', 'max:255', 'regex:/^[\p{L}\p{M}\p{N}\s\-\'\.]+$/u'],
            'birthday' => [
                'nullable', 
                'date_format:Y-m-d', 
                'before:today',
                'after:' . Carbon::now()->subYears(120)->format('Y-m-d')
            ],
            'website' => ['nullable', 'url', 'max:255', 'regex:/^https?:\/\/.+/'],
            'profile_image_url' => ['nullable', 'string', 'max:500'],
            'profile_icon_image_url' => ['nullable', 'string', 'max:500'],
            'cover_image_url' => ['nullable', 'string', 'max:500'],
            'has_completed_setup' => ['sometimes', 'boolean'],
        ];

        // For creation context, password is required
        if ($context === 'create') {
            $rules['password'] = [
                'required', 
                'string', 
                'min:8', 
                'max:255',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/'
            ];
            $rules['password_confirmation'] = ['required', 'same:password'];
        }

        // For partial updates, make most fields optional
        if ($context === 'partial') {
            foreach ($rules as $field => &$fieldRules) {
                if ($field !== 'password' && $field !== 'password_confirmation') {
                    // Replace 'required' with 'sometimes' for partial updates
                    $key = array_search('required', $fieldRules);
                    if ($key !== false) {
                        $fieldRules[$key] = 'sometimes';
                    }
                }
            }
        }

        return $rules;
    }

    /**
     * Get validation rules for profile creation
     * 
     * @return array
     */
    public static function getCreationRules(): array
    {
        return self::getValidationRules(null, 'create');
    }

    /**
     * Get validation rules for profile updates
     * 
     * @param int $userId
     * @return array
     */
    public static function getUpdateRules($userId): array
    {
        return self::getValidationRules($userId, 'update');
    }

    /**
     * Get validation rules for partial profile updates
     * 
     * @param int $userId
     * @return array
     */
    public static function getPartialUpdateRules($userId): array
    {
        return self::getValidationRules($userId, 'partial');
    }

    /**
     * Custom validation messages
     * 
     * @return array
     */
    public static function getValidationMessages(): array
    {
        return [
            'name.required' => '名前は必須です。',
            'name.min' => '名前は1文字以上で入力してください。',
            'name.max' => '名前は255文字以内で入力してください。',
            'name.regex' => '名前に使用できない文字が含まれています。',
            
            'email.required' => 'メールアドレスは必須です。',
            'email.email' => '有効なメールアドレスを入力してください。',
            'email.unique' => 'このメールアドレスは既に使用されています。',
            'email.max' => 'メールアドレスは255文字以内で入力してください。',
            
            'username.required' => 'ユーザーネームは必須です。',
            'username.min' => 'ユーザーネームは3文字以上で入力してください。',
            'username.max' => 'ユーザーネームは30文字以内で入力してください。',
            'username.regex' => 'ユーザーネームは英数字、アンダースコア、ハイフン、ピリオドのみ使用できます。',
            'username.unique' => 'このユーザーネームは既に使用されています。',
            'username.not_in' => 'このユーザーネームは予約されているため使用できません。',
            
            'bio.max' => '自己紹介は500文字以内で入力してください。',
            
            'city.max' => '都市名は255文字以内で入力してください。',
            'city.regex' => '都市名に使用できない文字が含まれています。',
            
            'location.max' => '場所は255文字以内で入力してください。',
            'location.regex' => '場所に使用できない文字が含まれています。',
            
            'birthday.date_format' => '誕生日はYYYY-MM-DD形式で入力してください。',
            'birthday.before' => '誕生日は今日より前の日付を入力してください。',
            'birthday.after' => '誕生日は120年前より後の日付を入力してください。',
            
            'website.url' => '有効なURLを入力してください。',
            'website.max' => 'ウェブサイトURLは255文字以内で入力してください。',
            'website.regex' => 'ウェブサイトURLはhttp://またはhttps://で始まる必要があります。',
            
            'password.required' => 'パスワードは必須です。',
            'password.min' => 'パスワードは8文字以上で入力してください。',
            'password.regex' => 'パスワードは大文字、小文字、数字、特殊文字を含む必要があります。',
            'password_confirmation.required' => 'パスワード確認は必須です。',
            'password_confirmation.same' => 'パスワードが一致しません。',
            
            'profile_image_url.max' => 'プロフィール画像URLは500文字以内で入力してください。',
            'profile_icon_image_url.max' => 'プロフィールアイコン画像URLは500文字以内で入力してください。',
            'cover_image_url.max' => 'カバー画像URLは500文字以内で入力してください。',
        ];
    }

    /**
     * Check if username is available
     * 
     * @param string $username
     * @param int|null $excludeUserId
     * @return bool
     */
    public static function isUsernameAvailable(string $username, ?int $excludeUserId = null): bool
    {
        $query = self::where('username', $username);
        
        if ($excludeUserId) {
            $query->where('id', '!=', $excludeUserId);
        }
        
        return !$query->exists();
    }

    /**
     * Validate age from birthday
     * 
     * @param string $birthday
     * @param int $minAge
     * @return bool
     */
    public static function isValidAge(string $birthday, int $minAge = 13): bool
    {
        try {
            $birthDate = Carbon::createFromFormat('Y-m-d', $birthday);
            $age = $birthDate->diffInYears(Carbon::now());
            return $age >= $minAge;
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * Check if profile is complete
     * 
     * @return bool
     */
    public function isProfileComplete(): bool
    {
        $requiredFields = ['name', 'email', 'username'];
        
        foreach ($requiredFields as $field) {
            if (empty($this->$field)) {
                return false;
            }
        }
        
        return true;
    }

    /**
     * Get profile completion percentage
     * 
     * @return int
     */
    public function getProfileCompletionPercentage(): int
    {
        $fields = ['name', 'email', 'username', 'bio', 'city', 'birthday', 'website', 'profile_image_url'];
        $completedFields = 0;
        
        foreach ($fields as $field) {
            if (!empty($this->$field)) {
                $completedFields++;
            }
        }
        
        return (int) round(($completedFields / count($fields)) * 100);
    }
}
