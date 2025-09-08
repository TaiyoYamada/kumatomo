<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Resources\UserResource;
use Illuminate\Validation\Rule;

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

    /**
     * 認証済みのユーザー情報を取得する
     *
     * @param \Illuminate\Http\Request $request
     * @return \App\Http\Resources\UserResource
     */
    public function me(Request $request)
    {
        return new UserResource($request->user());
    }
}
