<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Resources\UserResource;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * ユーザーのプロフィール情報を更新する
     *
     * @param Request $request
     * @param User $user ルートモデルバインディングにより自動的にユーザーが取得される
     * @return UserResource|\Illuminate\Http\JsonResponse
     */
    public function update(Request $request, User $user)
    {
        // 認可チェック: ログインしているユーザーが自分自身のプロフィールのみ更新可能にする
        if ($request->user()->id !== $user->id) {
            return response()->json(['message' => '権限がありません。'], 403);
        }

        // バリデーション
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            // emailはユニークだが、自分自身のメールアドレスは許可する
            'email' => ['sometimes', 'required', 'email', Rule::unique('users')->ignore($user->id)],
            'bio' => 'nullable|string',
            'website' => 'nullable|string|url',
            'profileImageURL' => 'nullable|string|url',
        ]);

        // ユーザー情報を更新して保存
        $user->update($validated);

        return new UserResource($user);
    }
}
