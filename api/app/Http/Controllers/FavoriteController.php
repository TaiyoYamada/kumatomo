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
     * Get user's favorite shops with pagination and filtering
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

            // Validate request parameters
            $request->validate([
                'genres' => 'nullable|string',
                'lat' => 'nullable|numeric|between:-90,90',
                'lng' => 'nullable|numeric|between:-180,180',
                'radius' => 'nullable|numeric|min:0.1|max:100',
                'q' => 'nullable|string|max:100',
                'per_page' => 'nullable|integer|min:1|max:50',
                'page' => 'nullable|integer|min:1',
                'sort_by' => 'nullable|string|in:name,created_at,distance',
                'sort_order' => 'nullable|string|in:asc,desc'
            ]);

            $perPage = min($request->get('per_page', 20), 50);
            $page = $request->get('page', 1);

            // Build query for favorite shops
            $query = $user->favorites()
                ->join('shops', 'favorites.shop_id', '=', 'shops.id')
                ->where('shops.is_approved', true)
                ->select('favorites.*', 'shops.*', 'favorites.created_at as favorited_at');

            // Genre filtering
            if ($request->has('genres') && $request->genres) {
                $genres = array_filter(explode(',', $request->genres));
                if (!empty($genres)) {
                    $query->whereIn('shops.genre', $genres);
                }
            }

            // Location-based filtering
            if ($request->has('lat') && $request->has('lng')) {
                $latitude = (float) $request->lat;
                $longitude = (float) $request->lng;
                $radius = (float) $request->get('radius', 10);

                $query->selectRaw("
                    favorites.*,
                    shops.*,
                    favorites.created_at as favorited_at,
                    (6371 * acos(cos(radians(?)) 
                    * cos(radians(shops.latitude)) 
                    * cos(radians(shops.longitude) - radians(?)) 
                    + sin(radians(?)) 
                    * sin(radians(shops.latitude)))) AS distance
                ", [$latitude, $longitude, $latitude])
                ->having('distance', '<', $radius);
            }

            // Keyword search
            if ($request->has('q') && $request->q) {
                $keyword = $request->q;
                $query->where(function ($q) use ($keyword) {
                    $q->where('shops.name', 'LIKE', "%{$keyword}%")
                      ->orWhere('shops.description', 'LIKE', "%{$keyword}%")
                      ->orWhere('shops.address', 'LIKE', "%{$keyword}%");
                });
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'favorited_at');
            $sortOrder = $request->get('sort_order', 'desc');

            if ($sortBy === 'distance' && $request->has('lat') && $request->has('lng')) {
                $query->orderBy('distance', 'asc');
            } elseif ($sortBy === 'favorited_at') {
                $query->orderBy('favorites.created_at', $sortOrder);
            } else {
                $query->orderBy("shops.{$sortBy}", $sortOrder);
            }

            $favorites = $query->paginate($perPage, ['*'], 'page', $page);

            Log::info('Favorites fetched successfully', [
                'user_id' => $user->id,
                'count' => $favorites->count(),
                'page' => $page,
                'filters' => [
                    'genres' => $request->get('genres'),
                    'location' => $request->has('lat') && $request->has('lng'),
                    'search' => $request->get('q')
                ]
            ]);

            return response()->json([
                'data' => $favorites->items(),
                'pagination' => [
                    'current_page' => $favorites->currentPage(),
                    'last_page' => $favorites->lastPage(),
                    'per_page' => $favorites->perPage(),
                    'total' => $favorites->total(),
                    'from' => $favorites->firstItem(),
                    'to' => $favorites->lastItem(),
                    'has_more_pages' => $favorites->hasMorePages()
                ],
                'filters' => [
                    'genres' => $request->get('genres'),
                    'location' => $request->has('lat') && $request->has('lng') ? [
                        'lat' => $request->lat,
                        'lng' => $request->lng,
                        'radius' => $request->get('radius', 10)
                    ] : null,
                    'search' => $request->get('q'),
                    'sort_by' => $sortBy,
                    'sort_order' => $sortOrder
                ]
            ]);

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