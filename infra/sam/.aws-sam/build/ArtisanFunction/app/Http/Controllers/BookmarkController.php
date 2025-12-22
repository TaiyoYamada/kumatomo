<?php

namespace App\Http\Controllers;

use App\Models\Bookmark;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BookmarkController extends Controller
{
    /**
     * Toggle bookmark status for a post
     */
    public function toggle(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $user = $request->user();

        DB::beginTransaction();
        try {
            $existingBookmark = Bookmark::where('post_id', $post->id)
                ->where('user_id', $user->id)
                ->first();

            if ($existingBookmark) {
                // Remove bookmark
                $existingBookmark->delete();
                $isBookmarked = false;
            } else {
                // Add bookmark
                Bookmark::create([
                    'post_id' => $post->id,
                    'user_id' => $user->id,
                ]);
                $isBookmarked = true;
            }

            // Get updated bookmark count
            $bookmarkCount = $post->bookmarks()->count();

            DB::commit();

            return response()->json([
                'is_bookmarked' => $isBookmarked,
                'bookmark_count' => $bookmarkCount,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'code' => 'BOOKMARK_TOGGLE_FAILED',
                    'message' => 'ブックマークの処理に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * Get posts bookmarked by the current user
     */
    public function bookmarkedPosts(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:50',
        ]);

        $page = $validated['page'] ?? 1;
        $perPage = $validated['per_page'] ?? 10;

        try {
            $bookmarkedPosts = $user->bookmarkedPosts()
                ->with(['user:id,name,username,profile_image_url', 'images'])
                ->withPivot('created_at')
                ->orderByPivot('created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Add engagement data for each post
            $bookmarkedPosts->getCollection()->transform(function ($post) use ($user) {
                $engagementData = $post->getEngagementDataForUser($user->id);
                $post->like_count = $engagementData['like_count'];
                $post->bookmark_count = $engagementData['bookmark_count'];
                $post->comment_count = $engagementData['comment_count'];
                $post->is_liked_by_current_user = $engagementData['is_liked_by_current_user'];
                $post->is_bookmarked_by_current_user = $engagementData['is_bookmarked_by_current_user'];
                return $post;
            });

            return response()->json($bookmarkedPosts);
        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'BOOKMARKED_POSTS_FETCH_FAILED',
                    'message' => 'ブックマークした投稿の取得に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * Remove bookmark from a post
     */
    public function destroy(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $user = $request->user();

        DB::beginTransaction();
        try {
            $bookmark = Bookmark::where('post_id', $post->id)
                ->where('user_id', $user->id)
                ->first();

            if (!$bookmark) {
                return response()->json([
                    'error' => [
                        'code' => 'BOOKMARK_NOT_FOUND',
                        'message' => 'ブックマークが見つかりません'
                    ]
                ], 404);
            }

            $bookmark->delete();

            // Get updated bookmark count
            $bookmarkCount = $post->bookmarks()->count();

            DB::commit();

            return response()->json([
                'is_bookmarked' => false,
                'bookmark_count' => $bookmarkCount,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'code' => 'BOOKMARK_REMOVAL_FAILED',
                    'message' => 'ブックマークの削除に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }
}