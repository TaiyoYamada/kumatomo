<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class SearchController extends Controller
{
    /**
     * 統合検索（投稿を検索）
     */
    public function search(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'q' => 'required|string|min:1|max:100',
                'type' => 'nullable|string|in:posts,all',
                'page' => 'integer|min:1',
                'per_page' => 'integer|min:1|max:50'
            ]);

            $query = $request->q;
            $type = $request->get('type', 'all');
            $perPage = $request->get('per_page', 10);
            $page = $request->get('page', 1);

            $results = [
                'posts' => [],
                'pagination' => [
                    'current_page' => $page,
                    'per_page' => $perPage
                ]
            ];

            // 投稿を検索
            if ($type === 'all' || $type === 'posts') {
                $posts = Post::with(['user', 'images'])
                    ->where('content', 'LIKE', "%{$query}%")
                    ->orderBy('created_at', 'desc')
                    ->paginate($perPage, ['*'], 'posts_page', $page);

                $results['posts'] = $posts->items();
                $results['pagination']['posts'] = [
                    'current_page' => $posts->currentPage(),
                    'last_page' => $posts->lastPage(),
                    'per_page' => $posts->perPage(),
                    'total' => $posts->total(),
                ];
            }

            return response()->json([
                'data' => $results,
                'query' => $query,
                'type' => $type
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => '入力データに問題があります',
                    'details' => $e->errors()
                ]
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'SEARCH_ERROR',
                    'message' => '検索に失敗しました',
                    'details' => config('app.debug') ? $e->getMessage() : null
                ]
            ], 500);
        }
    }
}