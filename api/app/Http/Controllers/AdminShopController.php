<?php

namespace App\Http\Controllers;

use App\Models\Shop;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Storage;

class AdminShopController extends Controller
{
    /**
     * 管理者用お店一覧を取得。
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Shop::query();

            // キーワード検索
            // 'q' と 'search' の両方をサポート
            $keyword = $request->get('q') ?? $request->get('search');
            if (!empty($keyword)) {
                $query->search($keyword);
            }

            // ジャンルでフィルタリング
            if ($request->has('genre') && $request->genre) {
                $query->byGenre($request->genre);
            }

            $shops = $query->withCount('posts')
                          ->orderBy('created_at', 'desc')
                          ->paginate($request->get('per_page', 20));

            return response()->json([
                'data' => $shops->items(),
                'pagination' => [
                    'current_page' => $shops->currentPage(),
                    'last_page' => $shops->lastPage(),
                    'per_page' => $shops->perPage(),
                    'total' => $shops->total(),
                    'from' => $shops->firstItem(),
                    'to' => $shops->lastItem(),
                    'has_more_pages' => $shops->hasMorePages(),
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
     * お店を作成。
     */
    public function store(Request $request): JsonResponse
    {
        try {
            // Accept both snake_case and camelCase from clients
            if ($request->has('imageUrl') && !$request->has('image_url')) {
                $request->merge(['image_url' => $request->input('imageUrl')]);
            }

            $validatedData = $request->validate([
                'name' => 'required|string|max:100',
                'description' => 'nullable|string|max:1000',
                'address' => 'nullable|string|max:255',
                'phone' => 'nullable|string|max:20',
                'business_hours' => 'nullable|string|max:500',
                'genre' => 'nullable|string|max:50',
                'latitude' => 'nullable|numeric|between:-90,90',
                'longitude' => 'nullable|numeric|between:-180,180',
                // URL指定での登録も許可（DB仕様に合わせて最大2048文字）
                'image_url' => 'nullable|url|max:2048',
                // 画像ファイルアップロード（任意）
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                // 管理系フィールド
                'has_try_benefit' => 'nullable|boolean',
                'stamp_count' => 'nullable|integer|min:0',
                'is_approved' => 'nullable|boolean',
            ]);

            // 画像アップロード処理
            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('shops', 'public');
                $validatedData['image_url'] = Storage::url($imagePath);
            }

            $shop = Shop::create($validatedData);

            return response()->json([
                'data' => $shop,
                'message' => 'お店を登録しました'
            ], 201);

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
                    'code' => 'SHOP_CREATE_ERROR',
                    'message' => 'お店の登録に失敗しました',
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
            $shop = Shop::withCount('posts')->find($id);

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
     * お店を更新。
     */
    public function update(Request $request, int $id): JsonResponse
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

            // Accept both snake_case and camelCase from clients
            if ($request->has('imageUrl') && !$request->has('image_url')) {
                $request->merge(['image_url' => $request->input('imageUrl')]);
            }

            $validatedData = $request->validate([
                'name' => 'required|string|max:100',
                'description' => 'nullable|string|max:1000',
                'address' => 'nullable|string|max:255',
                'phone' => 'nullable|string|max:20',
                'business_hours' => 'nullable|string|max:500',
                'genre' => 'nullable|string|max:50',
                'latitude' => 'nullable|numeric|between:-90,90',
                'longitude' => 'nullable|numeric|between:-180,180',
                // URL指定での更新も許可（DB仕様に合わせて最大2048文字）
                'image_url' => 'nullable|url|max:2048',
                // 画像ファイルアップロード（任意）
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                // 管理系フィールド
                'has_try_benefit' => 'nullable|boolean',
                'stamp_count' => 'nullable|integer|min:0',
                'is_approved' => 'nullable|boolean',
            ]);

            // 画像アップロード処理
            if ($request->hasFile('image')) {
                // 古い画像を削除
                if ($shop->image_url) {
                    $oldImagePath = str_replace('/storage/', '', $shop->image_url);
                    Storage::disk('public')->delete($oldImagePath);
                }

                $imagePath = $request->file('image')->store('shops', 'public');
                $validatedData['image_url'] = Storage::url($imagePath);
            }

            $shop->update($validatedData);

            return response()->json([
                'data' => $shop->fresh(),
                'message' => 'お店情報を更新しました'
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
                    'code' => 'SHOP_UPDATE_ERROR',
                    'message' => 'お店の更新に失敗しました',
                    'details' => config('app.debug') ? $e->getMessage() : null
                ]
            ], 500);
        }
    }

    /**
     * お店を削除。
     */
    public function destroy(int $id): JsonResponse
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

            // 関連する投稿がある場合の確認
            $postsCount = $shop->posts()->count();
            if ($postsCount > 0) {
                return response()->json([
                    'error' => [
                        'code' => 'SHOP_HAS_POSTS',
                        'message' => 'このお店には投稿が関連付けられているため削除できません',
                        'details' => ['posts_count' => $postsCount]
                    ]
                ], 409);
            }

            // 画像ファイルを削除
            if ($shop->image_url) {
                $imagePath = str_replace('/storage/', '', $shop->image_url);
                Storage::disk('public')->delete($imagePath);
            }

            $shop->delete();

            return response()->json([
                'message' => 'お店を削除しました'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'SHOP_DELETE_ERROR',
                    'message' => 'お店の削除に失敗しました',
                    'details' => config('app.debug') ? $e->getMessage() : null
                ]
            ], 500);
        }
    }
}
