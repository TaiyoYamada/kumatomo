<?php

namespace App\Http\Controllers;

use App\Models\Like;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LikeController extends Controller
{
    /**
     * Toggle like status for a post
     */
    public function toggle(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $user = $request->user();

        DB::beginTransaction();
        try {
            $existingLike = Like::where('post_id', $post->id)
                ->where('user_id', $user->id)
                ->first();

            if ($existingLike) {
                // Unlike the post
                $existingLike->delete();
                $isLiked = false;
            } else {
                // Like the post
                Like::create([
                    'post_id' => $post->id,
                    'user_id' => $user->id,
                ]);
                $isLiked = true;
            }

            // Get updated like count
            $likeCount = $post->likes()->count();

            DB::commit();

            return response()->json([
                'is_liked' => $isLiked,
                'like_count' => $likeCount,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'code' => 'LIKE_TOGGLE_FAILED',
                    'message' => 'いいねの処理に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * Get posts liked by the current user
     */
    public function likedPosts(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:50',
        ]);

        $page = $validated['page'] ?? 1;
        $perPage = $validated['per_page'] ?? 10;

        try {
            $likedPosts = $user->likedPosts()
                ->with(['user:id,name,username,profile_image_url', 'images'])
                ->withPivot('created_at')
                ->orderByPivot('created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Add engagement data for each post
            $likedPosts->getCollection()->transform(function ($post) use ($user) {
                $engagementData = $post->getEngagementDataForUser($user->id);
                $post->like_count = $engagementData['like_count'];
                $post->bookmark_count = $engagementData['bookmark_count'];
                $post->comment_count = $engagementData['comment_count'];
                $post->is_liked_by_current_user = $engagementData['is_liked_by_current_user'];
                $post->is_bookmarked_by_current_user = $engagementData['is_bookmarked_by_current_user'];
                return $post;
            });

            return response()->json($likedPosts);
        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'LIKED_POSTS_FETCH_FAILED',
                    'message' => 'いいねした投稿の取得に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * Remove like from a post
     */
    public function destroy(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $user = $request->user();

        $like = Like::where('post_id', $post->id)
            ->where('user_id', $user->id)
            ->first();

        if (!$like) {
            return response()->json([
                'error' => [
                    'code' => 'LIKE_NOT_FOUND',
                    'message' => 'いいねが見つかりません'
                ]
            ], 404);
        }

        DB::beginTransaction();
        try {
            $like->delete();

            // Get updated like count
            $likeCount = $post->likes()->count();

            DB::commit();

            return response()->json([
                'is_liked' => false,
                'like_count' => $likeCount,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'code' => 'LIKE_REMOVAL_FAILED',
                    'message' => 'いいねの削除に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }
}
