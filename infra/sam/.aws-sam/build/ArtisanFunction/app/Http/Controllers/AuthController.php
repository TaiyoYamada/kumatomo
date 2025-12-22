<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Http\Resources\UserResource;
use Illuminate\Support\Facades\Hash;
use App\Services\UsernameGeneratorService;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        // バリデーション（メールとパスワードのチェック）
        $validatedData = $request->validate([
            'email' => 'required|email|unique:users,email', // メールアドレスがユニークであること
            'password' => 'required|min:6', // パスワードは6文字以上
        ]);

        try {
            // ランダムなusernameを生成
            $usernameGenerator = new UsernameGeneratorService();
            $randomUsername = $usernameGenerator->generateUniqueUsername();
            
            if (!$randomUsername) {
                return response()->json([
                    'message' => 'ユーザーネームの生成に失敗しました。しばらく時間をおいて再試行してください。'
                ], 500);
            }

            // ユーザーの作成
            $user = User::create([
                'email' => $validatedData['email'],
                'password' => Hash::make($validatedData['password']), // パスワードをハッシュ化して保存
                'username' => $randomUsername, // ランダムなusernameを設定
            ]);

            // 作成したユーザーのトークンを生成
            $token = $user->createToken('auth_token')->plainTextToken;

            \Log::info("新規ユーザー登録完了: email={$user->email}, username={$user->username}");

            // トークンを返す
            return response()->json([
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => new UserResource($user)
            ]);
            
        } catch (\Exception $e) {
            \Log::error("ユーザー登録エラー: " . $e->getMessage());
            
            return response()->json([
                'message' => 'ユーザー登録中にエラーが発生しました。',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function login(Request $request)
    {
        // バリデーション（メールとパスワードのチェック）
        $request->validate([
            'email' => 'required|email', // メールアドレスのチェック
            'password' => 'required', // パスワードのチェック
        ]);

        // ログイン試行
        if (!Auth::attempt($request->only('email', 'password'))) {
            // 認証に失敗した場合
            return response()->json(['message' => '認証に失敗しました'], 401);
        }

        // ログイン成功時、認証済みユーザーを取得
        $user = $request->user();

        // トークンを生成
        $token = $user->createToken('auth_token')->plainTextToken;

        // トークンを返す
        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user)
        ]);
    }
}
