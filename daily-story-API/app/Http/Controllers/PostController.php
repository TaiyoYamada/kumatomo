<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::with('user')->latest()->get();
        return response()->json($posts);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'content' => 'required|string|max:200',
            'image_url' => 'nullable|url|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:20',
        ]);

        $post = $request->user()->stories()->create($validated);

        return response()->json($post->load('user'), 201);
    }

    /**
     * 特定のユーザーのストーリーを一覧取得
     *
     * @param  \App\Models\User $user
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function indexByUser(User $user)
    {
        return $user->posts()->with('user')->latest()->get();
    }
}
