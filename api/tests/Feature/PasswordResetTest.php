<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\PasswordResetToken;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        // テスト用ユーザーを作成
        $this->user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('oldpassword'),
        ]);
    }

    // ==========================================
    // forgot-password のテスト
    // ==========================================

    public function test_user_can_request_password_reset_code(): void
    {
        $response = $this->postJson('/api/forgot-password', [
            'email' => 'test@example.com',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'expires_in_minutes',
            ]);

        // データベースにトークンが作成されていることを確認
        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'test@example.com',
            'verified' => false,
        ]);
    }

    public function test_forgot_password_fails_with_invalid_email(): void
    {
        $response = $this->postJson('/api/forgot-password', [
            'email' => 'invalid-email',
        ]);

        $response->assertStatus(422);
    }

    public function test_forgot_password_fails_with_nonexistent_email(): void
    {
        $response = $this->postJson('/api/forgot-password', [
            'email' => 'nonexistent@example.com',
        ]);

        $response->assertStatus(422);
    }

    // ==========================================
    // verify-reset-code のテスト
    // ==========================================

    public function test_user_can_verify_reset_code(): void
    {
        // トークンを作成
        $token = PasswordResetToken::create([
            'email' => 'test@example.com',
            'code' => '123456',
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/verify-reset-code', [
            'email' => 'test@example.com',
            'code' => '123456',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'reset_token',
            ]);

        // トークンが検証済みになっていることを確認
        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'test@example.com',
            'verified' => true,
        ]);
    }

    public function test_verify_code_fails_with_wrong_code(): void
    {
        // トークンを作成
        PasswordResetToken::create([
            'email' => 'test@example.com',
            'code' => '123456',
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/verify-reset-code', [
            'email' => 'test@example.com',
            'code' => '654321',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'message' => '無効な認証コードです',
            ]);
    }

    public function test_verify_code_fails_when_expired(): void
    {
        // 期限切れのトークンを作成
        PasswordResetToken::create([
            'email' => 'test@example.com',
            'code' => '123456',
            'expires_at' => now()->subMinutes(1), // 1分前に期限切れ
        ]);

        $response = $this->postJson('/api/verify-reset-code', [
            'email' => 'test@example.com',
            'code' => '123456',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'message' => '認証コードの有効期限が切れています。再度リセットをリクエストしてください',
            ]);
    }

    // ==========================================
    // reset-password のテスト
    // ==========================================

    public function test_user_can_reset_password(): void
    {
        // 検証済みのトークンを作成
        $resetToken = PasswordResetToken::create([
            'email' => 'test@example.com',
            'code' => '123456',
            'token' => str_repeat('a', 64),
            'verified' => true,
            'expires_at' => now()->addMinutes(30),
        ]);

        $response = $this->postJson('/api/reset-password', [
            'token' => str_repeat('a', 64),
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'パスワードが正常にリセットされました',
            ]);

        // パスワードが更新されていることを確認
        $this->user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $this->user->password));

        // トークンが削除されていることを確認
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'test@example.com',
        ]);
    }

    public function test_reset_password_fails_with_invalid_token(): void
    {
        $response = $this->postJson('/api/reset-password', [
            'token' => str_repeat('x', 64),
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'message' => '無効なリセットトークンです',
            ]);
    }

    public function test_reset_password_fails_when_token_expired(): void
    {
        // 期限切れの検証済みトークンを作成
        PasswordResetToken::create([
            'email' => 'test@example.com',
            'code' => '123456',
            'token' => str_repeat('b', 64),
            'verified' => true,
            'expires_at' => now()->subMinutes(1), // 1分前に期限切れ
        ]);

        $response = $this->postJson('/api/reset-password', [
            'token' => str_repeat('b', 64),
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'message' => 'リセットトークンの有効期限が切れています。再度リセットをリクエストしてください',
            ]);
    }

    public function test_reset_password_fails_with_mismatched_confirmation(): void
    {
        // 検証済みのトークンを作成
        PasswordResetToken::create([
            'email' => 'test@example.com',
            'code' => '123456',
            'token' => str_repeat('c', 64),
            'verified' => true,
            'expires_at' => now()->addMinutes(30),
        ]);

        $response = $this->postJson('/api/reset-password', [
            'token' => str_repeat('c', 64),
            'password' => 'newpassword123',
            'password_confirmation' => 'differentpassword',
        ]);

        $response->assertStatus(422); // バリデーションエラー
    }
}
