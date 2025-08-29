<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Post;
use App\Models\PostImage;
use App\Services\ImageService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PostController extends Controller
{
    protected $imageService;

    public function __construct(ImageService $imageService)
    {
        $this->imageService = $imageService;
    }

    public function index()
    {
        $posts = Post::with(['user', 'shop', 'images', 'areas'])->latest()->get();
        
        // デバッグ用：レスポンスをログに出力
        \Log::info('投稿一覧レスポンス', ['posts_count' => $posts->count()]);
        
        if ($posts->count() > 0) {
            $firstPost = $posts->first();
            \Log::info('最初の投稿詳細', [
                'post_id' => $firstPost->id,
                'images_count' => $firstPost->images ? $firstPost->images->count() : 0,
                'first_image' => $firstPost->images && $firstPost->images->count() > 0 ? $firstPost->images->first()->toArray() : null
            ]);
            
            // 実際のJSONレスポンスをログ出力
            \Log::info('実際のJSONレスポンス', ['json' => $posts->toJson()]);
        }
        
        return response()->json($posts);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'content' => 'required|string|max:200', // Updated to 200 characters
            'area_ids' => 'required|array|min:1|max:5', // Required area selection, max 5
            'area_ids.*' => 'integer|exists:areas,id',
            'place_name' => 'nullable|string|max:255', // Location name
            'latitude' => 'nullable|numeric|between:-90,90', // Location latitude
            'longitude' => 'nullable|numeric|between:-180,180', // Location longitude
            'shop_id' => 'nullable|integer|exists:shops,id',
            'images' => 'nullable|array|max:4', // Updated to max 4 images
            'images.*' => 'sometimes|image|mimes:jpeg,png,jpg,gif|max:5120', // 画像ファイルの場合
            'image_urls' => 'nullable|array|max:4', // Updated to max 4 image URLs
            'image_urls.*' => 'url|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:20',
            // 後方互換性のため
            'image_url' => 'nullable|url|max:2048',
        ]);

        DB::beginTransaction();
        try {
            // 投稿を作成
            $postData = [
                'user_id' => $request->user()->id,
                'content' => $validated['content'],
                'shop_id' => $validated['shop_id'] ?? null,
                'place_name' => $validated['place_name'] ?? null,
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
                'image_url' => $validated['image_url'] ?? null, // Legacy support
                'tags' => $validated['tags'] ?? null,
            ];

            $post = Post::create($postData);
            
            if (!$post || !$post->id) {
                throw new \Exception('投稿の作成に失敗しました');
            }
            
            \Log::info('投稿作成成功', ['post_id' => $post->id, 'user_id' => $post->user_id]);

            // エリアとの関連付け
            if (isset($validated['area_ids']) && !empty($validated['area_ids'])) {
                // 最大5つのエリアまで許可
                $limitedAreaIds = array_slice($validated['area_ids'], 0, 5);
                $post->areas()->sync($limitedAreaIds);
                \Log::info('エリア関連付け完了', [
                    'post_id' => $post->id, 
                    'area_ids' => $limitedAreaIds
                ]);
            }

            // 複数画像の処理
            if (isset($validated['images']) && !empty($validated['images'])) {
                // 画像ファイルがアップロードされた場合
                $imageResults = $this->imageService->uploadMultipleImages($validated['images']);
                
                foreach ($imageResults as $index => $imageResult) {
                    // 中サイズの画像URLを使用（存在しない場合はオリジナル）
                    $imageUrl = $imageResult['medium'] ?? $imageResult['original'];
                    
                    PostImage::create([
                        'post_id' => $post->id,
                        'image_url' => $imageUrl,
                        'display_order' => $index + 1,
                    ]);
                }
            } elseif (isset($validated['image_urls']) && !empty($validated['image_urls'])) {
                // 画像URLが送信された場合（事前にアップロード済み）
                \Log::info('画像URL処理開始', ['post_id' => $post->id, 'image_urls' => $validated['image_urls']]);
                
                foreach ($validated['image_urls'] as $index => $imageUrl) {
                    $postImageData = [
                        'post_id' => $post->id,
                        'image_url' => $imageUrl,
                        'display_order' => $index + 1,
                    ];
                    
                    \Log::info('PostImage作成', $postImageData);
                    
                    try {
                        $postImage = PostImage::create($postImageData);
                        \Log::info('PostImage作成成功', ['post_image_id' => $postImage->id]);
                    } catch (\Exception $e) {
                        \Log::error('PostImage作成失敗', [
                            'error' => $e->getMessage(),
                            'data' => $postImageData
                        ]);
                        throw $e;
                    }
                }
                
                \Log::info('画像URL処理完了');
            }

            DB::commit();

            // 作成後のPostオブジェクトをリロードしてログ出力
            $createdPost = $post->load(['user', 'shop', 'images', 'areas']);
            
            \Log::info('作成された投稿の詳細', [
                'post_id' => $createdPost->id,
                'images_count' => $createdPost->images ? $createdPost->images->count() : 0,
                'images_data' => $createdPost->images ? $createdPost->images->toArray() : []
            ]);

            return response()->json($createdPost, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('投稿作成エラー', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'request_data' => $request->all()
            ]);
            
            return response()->json([
                'error' => [
                    'code' => 'POST_CREATION_FAILED',
                    'message' => '投稿の作成に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    public function show(Post $post)
    {
        return response()->json($post->load(['user', 'shop', 'images', 'areas']));
    }

    public function update(Request $request, Post $post)
    {
        // 投稿の所有者チェック
        if ($post->user_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'この投稿を編集する権限がありません'
                ]
            ], 403);
        }

        $validated = $request->validate([
            'content' => 'required|string|max:500',
            'shop_id' => 'nullable|integer|exists:shops,id',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:20',
        ]);

        $post->update($validated);

        return response()->json($post->load(['user', 'shop', 'images', 'areas']));
    }

    public function destroy(Request $request, Post $post)
    {
        // 投稿の所有者チェック
        if ($post->user_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'この投稿を削除する権限がありません'
                ]
            ], 403);
        }

        DB::beginTransaction();
        try {
            // 関連する画像ファイルを削除
            $imageUrls = $post->images->pluck('image_url')->toArray();
            if (!empty($imageUrls)) {
                $this->imageService->deleteMultipleImages($imageUrls);
            }

            // 後方互換性: 古い形式の画像URLも削除
            if ($post->image_url) {
                $this->imageService->deleteImage($post->image_url);
            }

            // 投稿を削除（PostImageは外部キー制約でカスケード削除される）
            $post->delete();

            DB::commit();

            return response()->json(['message' => '投稿が削除されました']);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'error' => [
                    'code' => 'POST_DELETION_FAILED',
                    'message' => '投稿の削除に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * 特定のユーザーの投稿を一覧取得
     *
     * @param  \Illuminate\Http\Request $request
     * @param  \App\Models\User $user
     * @return \Illuminate\Http\JsonResponse
     */
    public function indexByUser(Request $request, User $user)
    {
        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:50',
        ]);

        $page = $validated['page'] ?? 1;
        $perPage = $validated['per_page'] ?? 10;

        $posts = $user->posts()
            ->with(['user', 'shop', 'images', 'areas'])
            ->latest()
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json($posts);
    }

    /**
     * 特定のお店の投稿を一覧取得
     *
     * @param  \Illuminate\Http\Request $request
     * @param  int $shopId
     * @return \Illuminate\Http\JsonResponse
     */
    public function indexByShop(Request $request, int $shopId)
    {
        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:50',
        ]);

        $page = $validated['page'] ?? 1;
        $perPage = $validated['per_page'] ?? 10;

        $posts = Post::where('shop_id', $shopId)
            ->with(['user', 'shop', 'images', 'areas'])
            ->latest()
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json($posts);
    }
}
