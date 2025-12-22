<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Str;

class UsernameGeneratorService
{
    /**
     * 最小文字数
     */
    private const MIN_LENGTH = 6;

    /**
     * 最大文字数
     */
    private const MAX_LENGTH = 15;

    /**
     * 使用可能な文字セット（混乱しやすい文字は除外）
     */
    private const CHARACTERS = 'abcdefghijkmnpqrstuvwxyz23456789';

    /**
     * 最大試行回数
     */
    private const MAX_ATTEMPTS = 10;

    /**
     * ランダムなusernameを生成
     *
     * @return string
     */
    public function generateRandomUsername(): string
    {
        $length = rand(self::MIN_LENGTH, self::MAX_LENGTH);
        $username = '';
        
        for ($i = 0; $i < $length; $i++) {
            $username .= self::CHARACTERS[rand(0, strlen(self::CHARACTERS) - 1)];
        }
        
        return $username;
    }

    /**
     * ユニークなusernameを生成
     *
     * @param int $maxAttempts 最大試行回数
     * @return string|null 生成されたusername、失敗時はnull
     */
    public function generateUniqueUsername(int $maxAttempts = self::MAX_ATTEMPTS): ?string
    {
        for ($attempt = 1; $attempt <= $maxAttempts; $attempt++) {
            $username = $this->generateRandomUsername();
            
            // 重複チェック
            if (User::isUsernameAvailable($username)) {
                \Log::info("ユニークなusername生成成功: {$username} (試行回数: {$attempt})");
                return $username;
            }
            
            \Log::info("username重複: {$username} (試行回数: {$attempt})");
        }
        
        \Log::error("ユニークなusername生成に失敗しました（最大試行回数: {$maxAttempts}）");
        return null;
    }

    /**
     * usernameの形式をバリデーション
     *
     * @param string $username
     * @return bool
     */
    public function validateUsernameFormat(string $username): bool
    {
        // 長さチェック
        if (strlen($username) < self::MIN_LENGTH || strlen($username) > self::MAX_LENGTH) {
            return false;
        }

        // 英数字のみチェック
        if (!preg_match('/^[a-zA-Z0-9]+$/', $username)) {
            return false;
        }

        // 数字のみは不可
        if (preg_match('/^[0-9]+$/', $username)) {
            return false;
        }

        return true;
    }

    /**
     * usernameの利用可能性をチェック
     *
     * @param string $username
     * @param int|null $excludeUserId 除外するユーザーID
     * @return bool
     */
    public function isUsernameAvailable(string $username, ?int $excludeUserId = null): bool
    {
        // 形式チェック
        if (!$this->validateUsernameFormat($username)) {
            return false;
        }

        // 重複チェック
        return User::isUsernameAvailable($username, $excludeUserId);
    }
}