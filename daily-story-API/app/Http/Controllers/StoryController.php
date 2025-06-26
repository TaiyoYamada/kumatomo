<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Story; // Storyモデルをインポート
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StoryController extends Controller
{
    public function index()
    {
        $stories = Story::with('user')->latest()->get();
        return response()->json($stories);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|exists:users,id',
            'content' => 'required|string|max:100',
        ]);

        $story = Story::create([
            'user_id' => $validated['user_id'],
            'content' => $validated['content'],
        ]);

        $story = $request->user()->stories()->create($validated);

        return response()->json($story->load('user'), 201);
    }
    public function userStories($userId)
    {
        return Story::where('user_id', $userId)
            ->with('user')
            ->latest()
            ->get();
    }

    /**
     * 特定のユーザーのストーリーを一覧取得
     *
     * @param  \App\Models\User $user
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function indexByUser(User $user)
    {
        return $user->stories()->with('user')->latest()->get();
    }
}
