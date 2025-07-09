<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Story;
use Illuminate\Http\Request;

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
            'title' => 'nullable|string|max:50',
            'content' => 'required|string|max:100',
            'image_url' => 'nullable|url|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:20',
        ]);

        $story = $request->user()->stories()->create($validated);

        return response()->json($story->load('user'), 201);
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
