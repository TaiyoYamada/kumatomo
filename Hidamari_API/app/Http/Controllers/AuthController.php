<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Http\Resources\UserResource;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        // バリデーション（メールとパスワードのチェック）
        $validatedData = $request->validate([ // nameが必須の場合、ここを有効にする
            'email' => 'required|email|unique:users,email', // メールアドレスがユニークであること
            'password' => 'required|min:6', // パスワードは6文字以上
        ]);

        // ユーザーの作成
        $user = User::create([ // $validatedDataを直接渡す
            'email' => $validatedData['email'],
            'password' => Hash::make($validatedData['password']), // パスワードをハッシュ化して保存
        ]);

        // 作成したユーザーのトークンを生成
        $token = $user->createToken('auth_token')->plainTextToken;

        // トークンを返す
        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user)
        ]);
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
