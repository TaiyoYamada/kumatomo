<?php

namespace App\Http\Controllers;

use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\VerifyResetCodeRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Models\PasswordResetToken;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class PasswordResetController extends Controller
{
    /**
     * OTPコードの有効期限（分）
     */
    private const CODE_EXPIRY_MINUTES = 10;

    /**
     * パスワードリセット用のOTPコードを送信
     */
    public function forgotPassword(ForgotPasswordRequest $request)
    {
        $email = $request->validated()['email'];

        // 既存の未使用トークンを削除
        PasswordResetToken::where('email', $email)
            ->where('verified', false)
            ->delete();

        // 6桁のランダムコードを生成
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // データベースに保存
        PasswordResetToken::create([
            'email' => $email,
            'code' => $code,
            'expires_at' => now()->addMinutes(self::CODE_EXPIRY_MINUTES),
        ]);

        // メール送信
        $this->sendResetCodeEmail($email, $code);

        \Log::info("パスワードリセットコード送信: email={$email}");

        return response()->json([
            'message' => 'パスワードリセット用のコードをメールで送信しました',
            'expires_in_minutes' => self::CODE_EXPIRY_MINUTES,
        ]);
    }

    /**
     * OTPコードを検証し、リセットトークンを発行
     */
    public function verifyCode(VerifyResetCodeRequest $request)
    {
        $validated = $request->validated();
        $email = $validated['email'];
        $code = $validated['code'];

        // 該当するトークンを検索
        $resetToken = PasswordResetToken::where('email', $email)
            ->where('code', $code)
            ->where('verified', false)
            ->first();

        if (!$resetToken) {
            return response()->json([
                'message' => '無効な認証コードです',
            ], 400);
        }

        // 有効期限チェック
        if ($resetToken->isExpired()) {
            $resetToken->delete();
            return response()->json([
                'message' => '認証コードの有効期限が切れています。再度リセットをリクエストしてください',
            ], 400);
        }

        // リセットトークンを生成して保存
        $token = Str::random(64);
        $resetToken->update([
            'token' => $token,
            'verified' => true,
            'expires_at' => now()->addMinutes(30), // トークンは30分有効
        ]);

        \Log::info("パスワードリセットコード検証成功: email={$email}");

        return response()->json([
            'message' => '認証コードが確認されました',
            'reset_token' => $token,
        ]);
    }

    /**
     * 新しいパスワードを設定
     */
    public function resetPassword(ResetPasswordRequest $request)
    {
        $validated = $request->validated();
        $token = $validated['token'];
        $password = $validated['password'];

        // トークンを検索
        $resetToken = PasswordResetToken::where('token', $token)
            ->where('verified', true)
            ->first();

        if (!$resetToken) {
            return response()->json([
                'message' => '無効なリセットトークンです',
            ], 400);
        }

        // 有効期限チェック
        if ($resetToken->isExpired()) {
            $resetToken->delete();
            return response()->json([
                'message' => 'リセットトークンの有効期限が切れています。再度リセットをリクエストしてください',
            ], 400);
        }

        // ユーザーのパスワードを更新
        $user = User::where('email', $resetToken->email)->first();
        if (!$user) {
            return response()->json([
                'message' => 'ユーザーが見つかりません',
            ], 404);
        }

        $user->update([
            'password' => Hash::make($password),
        ]);

        // 使用済みトークンを削除
        $resetToken->delete();

        // そのユーザーの他のリセットトークンも削除
        PasswordResetToken::where('email', $resetToken->email)->delete();

        \Log::info("パスワードリセット完了: email={$resetToken->email}");

        return response()->json([
            'message' => 'パスワードが正常にリセットされました',
        ]);
    }

    /**
     * リセットコードをメールで送信
     */
    private function sendResetCodeEmail(string $email, string $code): void
    {
        $subject = '【kumatomo】パスワードリセットのご案内';
        $body = <<<EOT
kumatomoをご利用いただきありがとうございます。

パスワードリセットのリクエストを受け付けました。
以下の認証コードをアプリに入力してください。

認証コード: {$code}

このコードは10分間有効です。

このメールに心当たりがない場合は、無視してください。
パスワードは変更されません。

---
kumatomo サポートチーム
EOT;

        Mail::raw($body, function ($message) use ($email, $subject) {
            $message->to($email)
                ->subject($subject);
        });
    }
}
