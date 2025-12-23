<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class FollowController extends Controller
{
    /**
     * ユーザーをフォロー
     */
    public function follow(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $targetUser = User::findOrFail($id);

        // 自分自身をフォローできない
        if ($user->id === $targetUser->id) {
            return response()->json([
                'error' => [
                    'code' => 'CANNOT_FOLLOW_SELF',
                    'message' => '自分自身をフォローすることはできません'
                ]
            ], 400);
        }

        // 既にフォロー済みかチェック
        if ($user->isFollowing($targetUser)) {
            return response()->json([
                'is_following' => true,
                'followers_count' => $targetUser->followers_count,
                'message' => '既にフォロー済みです'
            ]);
        }

        DB::beginTransaction();
        try {
            $user->follow($targetUser);
            DB::commit();

            return response()->json([
                'is_following' => true,
                'followers_count' => $targetUser->fresh()->followers_count,
                'message' => 'フォローしました'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => [
                    'code' => 'FOLLOW_FAILED',
                    'message' => 'フォローに失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * フォロー解除
     */
    public function unfollow(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $targetUser = User::findOrFail($id);

        // フォローしていない場合
        if (!$user->isFollowing($targetUser)) {
            return response()->json([
                'is_following' => false,
                'followers_count' => $targetUser->followers_count,
                'message' => 'フォローしていません'
            ]);
        }

        DB::beginTransaction();
        try {
            $user->unfollow($targetUser);
            DB::commit();

            return response()->json([
                'is_following' => false,
                'followers_count' => $targetUser->fresh()->followers_count,
                'message' => 'フォロー解除しました'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => [
                    'code' => 'UNFOLLOW_FAILED',
                    'message' => 'フォロー解除に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * フォロワー一覧取得
     */
    public function followers(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'limit' => 'nullable|integer|min:1|max:50',
        ]);

        $page = (int)($validated['page'] ?? 1);
        $limit = (int)($validated['limit'] ?? 20);

        $user = User::findOrFail($id);
        $currentUser = $request->user();

        $followers = $user->followers()
            ->select('users.id', 'users.name', 'users.username', 'users.profile_image_url', 'users.bio')
            ->orderByPivot('created_at', 'desc')
            ->forPage($page, $limit)
            ->get();

        // 現在のユーザーがフォローしているかどうかを追加
        if ($currentUser) {
            $followingIds = $currentUser->following()->pluck('users.id')->toArray();
            $followers->transform(function ($follower) use ($followingIds, $currentUser) {
                $follower->is_following = in_array($follower->id, $followingIds);
                $follower->is_me = $follower->id === $currentUser->id;
                return $follower;
            });
        }

        return response()->json($followers);
    }

    /**
     * フォロー中ユーザー一覧取得
     */
    public function following(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'limit' => 'nullable|integer|min:1|max:50',
        ]);

        $page = (int)($validated['page'] ?? 1);
        $limit = (int)($validated['limit'] ?? 20);

        $user = User::findOrFail($id);
        $currentUser = $request->user();

        $following = $user->following()
            ->select('users.id', 'users.name', 'users.username', 'users.profile_image_url', 'users.bio')
            ->orderByPivot('created_at', 'desc')
            ->forPage($page, $limit)
            ->get();

        // 現在のユーザーがフォローしているかどうかを追加
        if ($currentUser) {
            $followingIds = $currentUser->following()->pluck('users.id')->toArray();
            $following->transform(function ($followedUser) use ($followingIds, $currentUser) {
                $followedUser->is_following = in_array($followedUser->id, $followingIds);
                $followedUser->is_me = $followedUser->id === $currentUser->id;
                return $followedUser;
            });
        }

        return response()->json($following);
    }

    /**
     * フォロー状態確認
     */
    public function checkStatus(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $targetUser = User::findOrFail($id);

        return response()->json([
            'is_following' => $user->isFollowing($targetUser),
            'is_followed_by' => $targetUser->isFollowing($user),
            'followers_count' => $targetUser->followers_count,
            'following_count' => $targetUser->following_count,
        ]);
    }
}
