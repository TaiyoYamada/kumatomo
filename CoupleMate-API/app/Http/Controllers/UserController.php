<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Resources\UserResource;

class UserController extends Controller
{
    public function store(Request $request)
    {
        // 入力バリデーション
        $validated = $request->validate([
            'email' => 'required|email',
            'name' => 'required|string',
            'bio' => 'nullable|string',
            'website' => 'nullable|string',
            'profileImageURL' => 'nullable|string',
            'partnerId' => 'nullable|string',
            'pairId' => 'nullable|string',
        ]);

        // ユーザーを作成
        $user = User::create($validated);

        // JSON形式でユーザー情報を返却（UserResourceで整形も可能）
        return response()->json(['data' => $user], 201);
        // または：return new UserResource($user);
    }
}
