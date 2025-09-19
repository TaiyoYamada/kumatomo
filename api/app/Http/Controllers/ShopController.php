<?php

namespace App\Http\Controllers;

use App\Models\Shop;
use App\Services\ErrorHandlingService;
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
            $query = Shop::query()->where('is_approved', true);

            // Multi-genre filtering (new feature)
            if ($request->has('genres') && $request->genres) {
                $genres = array_filter(explode(',', $request->genres));
                if (!empty($genres)) {
                    $query->whereIn('genre', $genres);
                }
            }
            // Single genre filtering (backward compatibility)
            elseif ($request->has('genre') && $request->genre) {
                $query->byGenre($request->genre);
            }

            // Location-based filtering with radius parameter
            if ($request->has('lat') && $request->has('lng')) {
                $latitude = (float) $request->lat;
                $longitude = (float) $request->lng;
                $radius = (float) $request->get('radius', 10); // Default 10km

                $query->nearby($latitude, $longitude, $radius);
            }

            // Keyword search
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

        } catch (ValidationException $e) {
            return ErrorHandlingService::createErrorResponse(
                'VALIDATION_ERROR',
                null,
                $e->errors(),
                422
            );
        } catch (\Exception $e) {
            return ErrorHandlingService::handleShopError($e, 'fetch shops list');
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
                return ErrorHandlingService::createErrorResponse(
                    'SHOP_NOT_FOUND',
                    null,
                    null,
                    404
                );
            }

            return response()->json(['data' => $shop]);

        } catch (\Exception $e) {
            return ErrorHandlingService::handleShopError($e, "fetch shop details (ID: {$id})");
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
                return ErrorHandlingService::createErrorResponse(
                    'SHOP_NOT_FOUND',
                    null,
                    null,
                    404
                );
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
            return ErrorHandlingService::handlePostError($e, "fetch posts for shop (ID: {$id})");
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
            return ErrorHandlingService::createErrorResponse(
                'VALIDATION_ERROR',
                null,
                $e->errors(),
                422
            );
        } catch (\Exception $e) {
            return ErrorHandlingService::handleShopError($e, "search shops with query: {$request->q}");
        }
    }
}