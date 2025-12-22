<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class AdminPostController extends Controller
{
    /**
     * Display a listing of posts.
     */
    public function index(Request $request)
    {
        $query = Post::with(['user:id,name,username,profile_image_url']);

        // Search
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where('content', 'like', "%{$search}%");
        }

        // Filter by user
        if ($request->has('user_id')) {
            $query->where('user_id', $request->input('user_id'));
        }

        // Sort
        $sortBy = $request->input('sort_by', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        // Pagination
        $perPage = min($request->input('per_page', 20), 100);
        $posts = $query->withCount(['comments', 'likes', 'bookmarks'])->paginate($perPage);

        return response()->json($posts);
    }

    /**
     * Display the specified post.
     */
    public function show(int $id)
    {
        $post = Post::with(['user:id,name,username,profile_image_url', 'images'])
            ->withCount(['comments', 'likes', 'bookmarks'])
            ->findOrFail($id);

        return response()->json($post);
    }

    /**
     * Remove the specified post.
     */
    public function destroy(int $id)
    {
        $post = Post::findOrFail($id);
        $post->delete();

        return response()->json(['message' => 'Post deleted successfully']);
    }

    /**
     * Get dashboard statistics for posts.
     */
    public function stats()
    {
        $stats = [
            'total_posts' => Post::count(),
            'new_posts_today' => Post::whereDate('created_at', today())->count(),
            'new_posts_this_week' => Post::whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])->count(),
            'new_posts_this_month' => Post::whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()])->count(),
        ];

        return response()->json($stats);
    }
}
