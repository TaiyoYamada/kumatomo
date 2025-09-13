<?php

namespace App\Http\Controllers;

use App\Models\Comment;
use App\Models\Post;
use App\Services\ImageService;
use App\Http\Requests\StoreCommentRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommentController extends Controller
{
    protected $imageService;

    public function __construct(ImageService $imageService)
    {
        $this->imageService = $imageService;
    }

    /**
     * Get comments for a specific post
     */
    public function index(Request $request, $postId)
    {
        $post = Post::findOrFail($postId);
        
        $comments = $post->comments()
            ->with('user:id,name,username,profile_image_url')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($comments);
    }

    /**
     * Create a new comment
     */
    public function store(StoreCommentRequest $request, $postId)
    {
        $post = Post::findOrFail($postId);
        $validated = $request->validated();

        DB::beginTransaction();
        try {
            $commentData = [
                'post_id' => $post->id,
                'user_id' => $request->user()->id,
                'content' => trim($validated['content']),
            ];

            // Handle image upload if present
            if ($request->hasFile('image')) {
                $imageResult = $this->imageService->uploadImage($request->file('image'));
                $commentData['image_url'] = $imageResult['medium'] ?? $imageResult;
            } elseif (!empty($validated['image_url'])) {
                $commentData['image_url'] = $validated['image_url'];
            }

            $comment = Comment::create($commentData);

            // Load the comment with user relationship
            $comment->load('user:id,name,username,profile_image_url');

            DB::commit();

            return response()->json($comment, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'code' => 'COMMENT_CREATION_FAILED',
                    'message' => 'コメントの作成に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }

    /**
     * Delete a comment
     */
    public function destroy(Request $request, $commentId)
    {
        $comment = Comment::findOrFail($commentId);

        // Check if user owns the comment or the post
        $user = $request->user();
        if ($comment->user_id !== $user->id && $comment->post->user_id !== $user->id) {
            return response()->json([
                'error' => [
                    'code' => 'FORBIDDEN',
                    'message' => 'このコメントを削除する権限がありません'
                ]
            ], 403);
        }

        DB::beginTransaction();
        try {
            // Delete associated image if exists
            if ($comment->image_url) {
                $this->imageService->deleteImage($comment->image_url);
            }

            $comment->delete();

            DB::commit();

            return response()->json([
                'message' => 'コメントが削除されました'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'code' => 'COMMENT_DELETION_FAILED',
                    'message' => 'コメントの削除に失敗しました',
                    'details' => $e->getMessage()
                ]
            ], 500);
        }
    }
}