<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Resources\UserResource;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    /**
     * Create a new user profile
     */
    public function store(Request $request): JsonResponse
    {
        try {
            // Validate the request data using the User model validation rules
            $validated = $request->validate(
                User::getCreationRules(),
                User::getValidationMessages()
            );

            // Hash the password
            $validated['password'] = bcrypt($validated['password']);
            
            // Remove password confirmation as it's not needed for creation
            unset($validated['password_confirmation']);

            // Generate username if not provided
            if (empty($validated['username'])) {
                $usernameGenerator = new \App\Services\UsernameGeneratorService();
                $randomUsername = $usernameGenerator->generateUniqueUsername();
                
                if (!$randomUsername) {
                    return response()->json([
                        'message' => 'ユーザーネームの生成に失敗しました。しばらく時間をおいて再試行してください。'
                    ], 500);
                }
                
                $validated['username'] = $randomUsername;
                \Log::info("プロフィール作成時にusername自動生成: {$randomUsername}");
            }

            // Map location to city if provided (for backward compatibility)
            if (isset($validated['location'])) {
                $validated['city'] = $validated['location'];
                unset($validated['location']);
            }

            // Map cover_image_url to profile_image_url if provided
            if (isset($validated['cover_image_url'])) {
                $validated['profile_image_url'] = $validated['cover_image_url'];
                unset($validated['cover_image_url']);
            }

            // Create the user
            $user = User::create($validated);

            return response()->json([
                'message' => 'プロフィールが正常に作成されました。',
                'data' => new UserResource($user)
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'バリデーションエラーが発生しました。',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'プロフィールの作成中にエラーが発生しました。',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * 特定ユーザーのプロフィールを取得する
     */
    public function show(Request $request, $id): JsonResponse
    {
        $user = User::findOrFail($id);
        
        return response()->json([
            'data' => new UserResource($user)
        ]);
    }

    /**
     * 認証ユーザー自身のプロフィールを更新する
     */
    public function update(Request $request, $id = null): JsonResponse
    {
        try {
            // If ID is provided, use it; otherwise use authenticated user
            if ($id) {
                $user = User::findOrFail($id);
                // Ensure user can only update their own profile
                if ($user->id !== $request->user()->id) {
                    return response()->json([
                        'message' => 'このプロフィールを更新する権限がありません。',
                        'error' => 'Unauthorized'
                    ], 403);
                }
            } else {
                $user = $request->user();
            }

            // Store original data for optimistic locking check
            $originalUpdatedAt = $user->updated_at;
            
            // Check for optimistic locking if updated_at is provided
            if ($request->has('updated_at')) {
                $clientUpdatedAt = $request->input('updated_at');
                if ($originalUpdatedAt->toISOString() !== $clientUpdatedAt) {
                    return response()->json([
                        'message' => 'プロフィールが他のセッションで更新されています。最新のデータを取得してから再試行してください。',
                        'error' => 'Conflict - Profile was updated by another session',
                        'current_updated_at' => $originalUpdatedAt->toISOString()
                    ], 409);
                }
            }

            // Use enhanced validation rules for partial updates
            $validated = $request->validate(
                User::getPartialUpdateRules($user->id),
                User::getValidationMessages()
            );

            // Remove updated_at from validated data if present
            unset($validated['updated_at']);

            // Map location to city if provided (for backward compatibility)
            if (isset($validated['location'])) {
                $validated['city'] = $validated['location'];
                unset($validated['location']);
            }

            // Map cover_image_url to profile_image_url if provided
            if (isset($validated['cover_image_url'])) {
                $validated['profile_image_url'] = $validated['cover_image_url'];
                unset($validated['cover_image_url']);
            }

            // Update the user
            $user->update($validated);

            // Refresh the model to get updated timestamps
            $user->refresh();

            return response()->json([
                'message' => 'プロフィールが正常に更新されました。',
                'data' => new UserResource($user)
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'プロフィールが見つかりません。',
                'error' => 'Profile not found'
            ], 404);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'バリデーションエラーが発生しました。',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'プロフィールの更新中にエラーが発生しました。',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * 認証済みのユーザー情報を取得する
     */
    public function me(Request $request)
    {
        return response()->json([
            'data' => new UserResource($request->user())
        ]);
    }

    /**
     * ユーザーネームの利用可能性をチェックする
     */
    public function checkUsernameAvailability(Request $request): JsonResponse
    {
        $request->validate([
            'username' => [
                'required', 
                'string', 
                'min:6', 
                'max:15', 
                'regex:/^[a-zA-Z0-9]+$/',
                'not_regex:/^[0-9]+$/'
            ]
        ], [
            'username.required' => 'ユーザーネームは必須です。',
            'username.min' => 'ユーザーネームは6文字以上で入力してください。',
            'username.max' => 'ユーザーネームは15文字以内で入力してください。',
            'username.regex' => 'ユーザーネームは英数字のみ使用できます。',
            'username.not_regex' => 'ユーザーネームは数字のみにはできません。'
        ]);

        $username = $request->input('username');
        $currentUserId = $request->user()->id;

        // Check if username exists for other users
        $exists = User::where('username', $username)
                     ->where('id', '!=', $currentUserId)
                     ->exists();

        return response()->json([
            'available' => !$exists,
            'message' => $exists ? 'このユーザーネームは既に使用されています' : 'このユーザーネームは利用可能です'
        ]);
    }

    /**
     * ユーザーネームのみを更新する
     */
    public function updateUsername(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            // Validate username
            $validated = $request->validate([
                'username' => [
                    'required', 
                    'string', 
                    'min:6', 
                    'max:15', 
                    'regex:/^[a-zA-Z0-9]+$/',
                    'not_regex:/^[0-9]+$/',
                    Rule::unique('users')->ignore($user->id),
                    'not_in:admin,root,api,www,mail,support,help,info,contact,about,terms,privacy,login,register,logout,profile,settings,dashboard,home,index'
                ]
            ], [
                'username.required' => 'ユーザーネームは必須です。',
                'username.min' => 'ユーザーネームは6文字以上で入力してください。',
                'username.max' => 'ユーザーネームは15文字以内で入力してください。',
                'username.regex' => 'ユーザーネームは英数字のみ使用できます。',
                'username.not_regex' => 'ユーザーネームは数字のみにはできません。',
                'username.unique' => 'このユーザーネームは既に使用されています。',
                'username.not_in' => 'このユーザーネームは予約されているため使用できません。'
            ]);

            // Update only the username
            $user->update(['username' => $validated['username']]);

            \Log::info("ユーザーネーム更新: user_id={$user->id}, new_username={$validated['username']}");

            return response()->json([
                'message' => 'ユーザーネームが正常に更新されました。',
                'data' => new UserResource($user->fresh())
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'バリデーションエラーが発生しました。',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error("ユーザーネーム更新エラー: " . $e->getMessage());
            
            return response()->json([
                'message' => 'ユーザーネームの更新中にエラーが発生しました。',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * プロフィール画像をアップロードする
     */
    public function uploadProfileImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'image', 'mimes:jpeg,png,jpg,gif', 'max:2048']
        ]);

        try {
            $image = $request->file('image');
            $filename = 'profile_' . $request->user()->id . '_' . time() . '.' . $image->getClientOriginalExtension();
            
            // Store in public disk
            $path = $image->storeAs('profile_images', $filename, 'public');
            $url = Storage::url($path);

            return response()->json([
                'url' => $url,
                'message' => 'プロフィール画像がアップロードされました'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'プロフィール画像のアップロードに失敗しました',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * カバー画像をアップロードする
     */
    public function uploadCoverImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => ['required', 'image', 'mimes:jpeg,png,jpg,gif', 'max:2048']
        ]);

        try {
            $image = $request->file('image');
            $filename = 'cover_' . $request->user()->id . '_' . time() . '.' . $image->getClientOriginalExtension();
            
            // Store in public disk
            $path = $image->storeAs('cover_images', $filename, 'public');
            $url = Storage::url($path);

            return response()->json([
                'url' => $url,
                'message' => 'カバー画像がアップロードされました'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'カバー画像のアップロードに失敗しました',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a user profile (soft delete)
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        try {
            $user = User::findOrFail($id);
            
            // Authorization check: users can only delete their own profiles
            if ($user->id !== $request->user()->id) {
                return response()->json([
                    'message' => 'このプロフィールを削除する権限がありません。',
                    'error' => 'Unauthorized'
                ], 403);
            }

            // Perform soft delete
            $user->delete();

            // Additional cleanup can be added here if needed
            // For example: delete related posts, images, etc.
            
            return response()->json([
                'message' => 'プロフィールが正常に削除されました。'
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'プロフィールが見つかりません。',
                'error' => 'Profile not found'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'プロフィールの削除中にエラーが発生しました。',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
