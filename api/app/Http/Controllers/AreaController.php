<?php

namespace App\Http\Controllers;

use App\Models\Area;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AreaController extends Controller
{
    /**
     * Display a listing of all areas.
     *
     * @return JsonResponse
     */
    public function index(): JsonResponse
    {
        try {
            $areas = Area::ordered()->get();
            
            return response()->json($areas);
        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'AREAS_FETCH_FAILED',
                    'message' => 'エリア一覧の取得に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * Display posts for a specific area with pagination.
     *
     * @param Request $request
     * @param int $id
     * @return JsonResponse
     */
    public function posts(Request $request, int $id): JsonResponse
    {
        try {
            // Validate area exists
            $area = Area::find($id);
            if (!$area) {
                return response()->json([
                    'error' => [
                        'code' => 'AREA_NOT_FOUND',
                        'message' => '指定されたエリアが見つかりません'
                    ]
                ], 404);
            }

            // Validate pagination parameters
            $validated = $request->validate([
                'page' => 'nullable|integer|min:1',
                'per_page' => 'nullable|integer|min:1|max:50',
            ]);

            $page = $validated['page'] ?? 1;
            $perPage = $validated['per_page'] ?? 10;

            // Get posts for this area with pagination
            $posts = $area->posts()
                ->with(['user', 'shop', 'images', 'areas'])
                ->latest()
                ->paginate($perPage, ['*'], 'page', $page);

            return response()->json($posts);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'バリデーションエラーが発生しました',
                    'details' => $e->errors()
                ]
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'code' => 'AREA_POSTS_FETCH_FAILED',
                    'message' => 'エリアの投稿取得に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }
}