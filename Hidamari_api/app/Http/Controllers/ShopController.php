<?php

namespace App\Http\Controllers;

use App\Models\Shop;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class ShopController extends Controller
{
    /**
     * お店一覧を取得。
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Shop::query();

            // ジャンルでフィルタリング
            if ($request->has('genre') && $request->genre) {
                $query->byGenre($request->genre);
            }

            // 位置情報での検索
            if ($request->has('lat') && $request->has('lng')) {
                $latitude = $request->lat;
                $longitude = $request->lng;
                $radius = $request->get('radius', 10); // デフォルト10km

                $query->nearby($latitude, $longitude, $radius);
            }

            // キーワード検索
            if ($request->has('q') && $request->q) {
                $query->search($request->q);
            }

            $shops = $query->paginate($request->get('per_page', 10));

            return response()->json([
                'data' => $shops->items(),
                'pagination' => [
                    'current_page' => $shops->currentPage(),
                    'last_page' => $shops->lastPage(),
                    'per_page' => $shops->perPage(),
                    'total' => $shops->total(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'SHOP_FETCH_ERROR',
                    'message' => 'お店の取得に失敗しました',
                    'details' => config('app.debug') ? $e->getMessage() : null
                ]
            ], 500);
        }
    }

    /**
     * お店詳細を取得。
     */
    public function show(int $id): JsonResponse
    {
        try {
            $shop = Shop::with(['posts' => function ($query) {
                $query->with(['user', 'images'])
                      ->orderBy('created_at', 'desc');
            }])->find($id);

            if (!$shop) {
                return response()->json([
                    'error' => [
                        'code' => 'SHOP_NOT_FOUND',
                        'message' => 'お店が見つかりません'
                    ]
                ], 404);
            }

            return response()->json(['data' => $shop]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'SHOP_FETCH_ERROR',
                    'message' => 'お店の取得に失敗しました',
                    'details' => config('app.debug') ? $e->getMessage() : null
                ]
            ], 500);
        }
    }

    /**
     * 特定のお店の投稿一覧を取得。
     */
    public function posts(int $id, Request $request): JsonResponse
    {
        try {
            $shop = Shop::find($id);

            if (!$shop) {
                return response()->json([
                    'error' => [
                        'code' => 'SHOP_NOT_FOUND',
                        'message' => 'お店が見つかりません'
                    ]
                ], 404);
            }

            $posts = $shop->posts()
                          ->with(['user', 'images'])
                          ->orderBy('created_at', 'desc')
                          ->paginate($request->get('per_page', 10));

            return response()->json([
                'data' => $posts->items(),
                'pagination' => [
                    'current_page' => $posts->currentPage(),
                    'last_page' => $posts->lastPage(),
                    'per_page' => $posts->perPage(),
                    'total' => $posts->total(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'POST_FETCH_ERROR',
                    'message' => '投稿の取得に失敗しました',
                    'details' => config('app.debug') ? $e->getMessage() : null
                ]
            ], 500);
        }
    }

    /**
     * お店検索。
     */
    public function search(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'q' => 'required|string|min:1|max:100',
                'page' => 'integer|min:1',
                'per_page' => 'integer|min:1|max:50'
            ]);

            $shops = Shop::search($request->q)
                        ->paginate($request->get('per_page', 10));

            return response()->json([
                'data' => $shops->items(),
                'pagination' => [
                    'current_page' => $shops->currentPage(),
                    'last_page' => $shops->lastPage(),
                    'per_page' => $shops->perPage(),
                    'total' => $shops->total(),
                ]
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