<?php

namespace App\Http\Controllers;

use App\Models\Story; // Storyモデルをインポート
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StoryController extends Controller
{
    // 投稿されたストーリーを取得（新着順）
    public function index()
    {
        return Story::with('user')->latest()->get();
    }

    // 投稿
    public function store(Request $request)
    {
        $validated = $request->validate([
            'body' => 'required|string|max:100',
        ]);

        // 認証済みユーザーのリレーションを利用してストーリーを作成
        // これにより、user_idが自動的に設定されます
        $story = $request->user()->stories()->create($validated);

        // 作成されたストーリーにユーザー情報を含めて返す
        // indexメソッドのレスポンスと形式を合わせるため
        return response()->json($story->load('user'), 201);
    }
}
