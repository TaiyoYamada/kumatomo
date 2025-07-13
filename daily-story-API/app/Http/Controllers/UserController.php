<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Resources\UserResource;
use Illuminate\Validation\Rule;

// class UserController extends Controller
// {
//     /**
//      * ユーザーのプロフィール情報を更新する
//      *
//      * @param Request $request
//      * @param User $user ルートモデルバインディングにより自動的にユーザーが取得される
//      * @return UserResource|\Illuminate\Http\JsonResponse
//      */
//     public function update(Request $request, User $user)
//     {
//         // 認可チェック: ログインしているユーザーが自分自身のプロフィールのみ更新可能にする
//         if ($request->user()->id !== $user->id) {
//             return response()->json(['message' => '権限がありません。'], 403);
//         }

//         // バリデーション
//         $validated = $request->validate([
//             'city' => 'nullable|string|max:255',
//             'birthday' => 'nullable|date_format:Y-m-d',
//             'name' => 'sometimes|required|string|max:255',
//             // emailはユニークだが、自分自身のメールアドレスは許可する
//             'email' => ['sometimes', 'required', 'email', Rule::unique('users')->ignore($user->id)],
//             'bio' => 'nullable|string',
//             'website' => 'nullable|string|url',
//             'profileImageURL' => 'nullable|string|url',
//         ]);

//         // ユーザー情報を更新して保存
//         $user->update($validated);

//         return new UserResource($user);
//     }
// }

class UserController extends Controller
{
    /**
     * 認証ユーザー自身のプロフィールを更新する
     */
    public function update(Request $request)
    {
        $user = $request->user(); // 認証トークンから取得

        // バリデーション
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => ['sometimes', 'required', 'email', Rule::unique('users')->ignore($user->id)],
            'bio' => ['nullable', 'string'],
            'city' => ['nullable', 'string', 'max:255'],
            'birthday' => ['nullable', 'date_format:Y-m-d'],
            'website' => ['nullable', 'url'],
            'profile_image_url' => ['nullable', 'url'], 
            'has_completed_setup' => ['sometimes', 'boolean'],
        ]);

        // データを更新
        $user->update($validated);

        return new UserResource($user); // 更新後のユーザー情報を返す
    }
}
