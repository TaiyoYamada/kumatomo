<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 管理者ユーザー (admin@test.com / secret)
        if (!User::where('email', 'admin@test.com')->exists()) {
            User::create([
                'name' => 'Admin User',
                'email' => 'admin@test.com',
                'username' => 'adminuser',
                'password' => Hash::make('secret'),
                'email_verified_at' => now(),
                'is_admin' => true,
                'has_completed_setup' => true,
                'bio' => '管理者アカウントです',
            ]);
        }

        // テストユーザー (test@example.com)
        if (!User::where('email', 'test@example.com')->exists()) {
            User::create([
                'name' => 'テストユーザー',
                'email' => 'test@example.com',
                'username' => 'testuser',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
                'is_admin' => false,
                'has_completed_setup' => true,
                'bio' => 'テスト用のユーザーアカウントです',
            ]);
        }

        // 追加のテストユーザー
        $testUsers = [
            [
                'name' => '山田太郎',
                'email' => 'taro@example.com',
                'username' => 'taroyamada',
                'bio' => '熊本在住のグルメ好きです！',
                'location' => '熊本県熊本市',
            ],
            [
                'name' => '佐藤花子',
                'email' => 'hanako@example.com',
                'username' => 'hanakosato',
                'bio' => 'カフェ巡りが趣味です☕',
                'location' => '熊本県阿蘇市',
            ],
            [
                'name' => '鈴木一郎',
                'email' => 'ichiro@example.com',
                'username' => 'ichirosuzuki',
                'bio' => '熊本のラーメン情報を発信中🍜',
                'location' => '熊本県八代市',
            ],
        ];

        foreach ($testUsers as $userData) {
            if (!User::where('email', $userData['email'])->exists()) {
                User::create([
                    'name' => $userData['name'],
                    'email' => $userData['email'],
                    'username' => $userData['username'],
                    'password' => Hash::make('password'),
                    'email_verified_at' => now(),
                    'is_admin' => false,
                    'has_completed_setup' => true,
                    'bio' => $userData['bio'],
                    'location' => $userData['location'] ?? null,
                ]);
            }
        }
    }
}
