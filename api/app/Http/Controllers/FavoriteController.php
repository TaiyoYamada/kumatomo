<?php

namespace App\Http\Controllers;

use App\Models\Favorite;
use App\Models\Shop;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class FavoriteController extends Controller
{
    /**
     * Get user's favorite shops with pagination
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json([
                    'error' => [
                        'message' => 'Unauthorized'
                    ]
                ], 401);
            }

            $perPage = min($request->get('per_page', 20), 50); // Max 50 items per page
            $page = $request->get('page', 1);

            $favorites = $user->favorites()
                ->with(['shop' => function ($query) {
                    $query->where('is_approved', true);
                }])
                ->latest()
                ->paginate($perPage, ['*'], 'page', $page);

            // Filter out favorites where shop is null (deleted shops)
            $filteredFavorites = $favorites->getCollection()->filter(function ($favorite) {
                return $favorite->shop !== null;
            })->values();

            // Update the collection with filtered results
            $favorites->setCollection($filteredFavorites);

            Log::info('Favorites fetched successfully', [
                'user_id' => $user->id,
                'count' => $filteredFavorites->count(),
                'page' => $page
            ]);

            return response()->json($favorites);

        } catch (\Exception $e) {
            Log::error('Failed to fetch favorites', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'error' => [
                    'message' => 'Failed to fetch favorites'
                ]
            ], 500);
        }
    }

    /**
     * Toggle favorite status for a shop
     *
     * @param Request $request
     * @param Shop $shop
     * @return JsonResponse
     */
    public function toggle(Request $request, Shop $shop): JsonResponse
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json([
                    'error' => [
                        'message' => 'Unauthorized'
                    ]
                ], 401);
            }

            // Check if shop is approved
            if (!$shop->is_approved) {
                return response()->json([
                    'error' => [
                        'message' => 'Shop is not available for favorites'
                    ]
                ], 403);
            }

            DB::beginTransaction();

            $favorite = $user->favorites()->where('shop_id', $shop->id)->first();

            if ($favorite) {
                // Remove from favorites
                $favorite->delete();
                $favorited = false;
                $message = 'Shop removed from favorites';
                
                Log::info('Shop removed from favorites', [
                    'user_id' => $user->id,
                    'shop_id' => $shop->id,
                    'shop_name' => $shop->name
                ]);
            } else {
                // Add to favorites
                $user->favorites()->create([
                    'shop_id' => $shop->id
                ]);
                $favorited = true;
                $message = 'Shop added to favorites';
                
                Log::info('Shop added to favorites', [
                    'user_id' => $user->id,
                    'shop_id' => $shop->id,
                    'shop_name' => $shop->name
                ]);
            }

            DB::commit();

            return response()->json([
                'favorited' => $favorited,
                'message' => $message
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('Failed to toggle favorite', [
                'user_id' => Auth::id(),
                'shop_id' => $shop->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'error' => [
                    'message' => 'Failed to toggle favorite status'
                ]
            ], 500);
        }
    }

    /**
     * Check if a shop is favorited by the current user
     *
     * @param Request $request
     * @param Shop $shop
     * @return JsonResponse
     */
    public function check(Request $request, Shop $shop): JsonResponse
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json([
                    'favorited' => false
                ]);
            }

            $favorited = $user->favorites()->where('shop_id', $shop->id)->exists();

            return response()->json([
                'favorited' => $favorited
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to check favorite status', [
                'user_id' => Auth::id(),
                'shop_id' => $shop->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'error' => [
                    'message' => 'Failed to check favorite status'
                ]
            ], 500);
        }
    }

    /**
     * Remove a specific favorite
     *
     * @param Request $request
     * @param Favorite $favorite
     * @return JsonResponse
     */
    public function destroy(Request $request, Favorite $favorite): JsonResponse
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json([
                    'error' => [
                        'message' => 'Unauthorized'
                    ]
                ], 401);
            }

            // Check if the favorite belongs to the current user
            if ($favorite->user_id !== $user->id) {
                return response()->json([
                    'error' => [
                        'message' => 'Forbidden'
                    ]
                ], 403);
            }

            $shopName = $favorite->shop ? $favorite->shop->name : 'Unknown Shop';
            $favorite->delete();

            Log::info('Favorite removed', [
                'user_id' => $user->id,
                'favorite_id' => $favorite->id,
                'shop_name' => $shopName
            ]);

            return response()->json([
                'message' => 'Favorite removed successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to remove favorite', [
                'user_id' => Auth::id(),
                'favorite_id' => $favorite->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'error' => [
                    'message' => 'Failed to remove favorite'
                ]
            ], 500);
        }
    }

    /**
     * Get favorite statistics for the current user
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function stats(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json([
                    'error' => [
                        'message' => 'Unauthorized'
                    ]
                ], 401);
            }

            $totalFavorites = $user->favorites()->count();
            $favoritesByGenre = $user->favorites()
                ->join('shops', 'favorites.shop_id', '=', 'shops.id')
                ->where('shops.is_approved', true)
                ->select('shops.genre', DB::raw('count(*) as count'))
                ->groupBy('shops.genre')
                ->get()
                ->pluck('count', 'genre');

            return response()->json([
                'total_favorites' => $totalFavorites,
                'favorites_by_genre' => $favoritesByGenre
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get favorite statistics', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'error' => [
                    'message' => 'Failed to get favorite statistics'
                ]
            ], 500);
        }
    }
}