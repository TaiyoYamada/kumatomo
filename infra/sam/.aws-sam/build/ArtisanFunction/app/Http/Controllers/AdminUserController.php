<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminUserController extends Controller
{
    /**
     * Display a listing of users.
     */
    public function index(Request $request)
    {
        $query = User::query();

        // Search
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        // Filter by is_admin
        if ($request->has('is_admin')) {
            $query->where('is_admin', $request->boolean('is_admin'));
        }

        // Sort
        $sortBy = $request->input('sort_by', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        // Pagination
        $perPage = min($request->input('per_page', 20), 100);
        $users = $query->paginate($perPage);

        return response()->json($users);
    }

    /**
     * Display the specified user.
     */
    public function show(int $id)
    {
        $user = User::withCount(['posts', 'comments', 'likes', 'bookmarks'])
            ->findOrFail($id);
        
        return response()->json($user);
    }

    /**
     * Update the specified user.
     */
    public function update(Request $request, int $id)
    {
        $user = User::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'username' => 'sometimes|string|min:6|max:15',
            'email' => 'sometimes|email|max:255',
            'bio' => 'nullable|string|max:500',
            'location' => 'nullable|string|max:255',
            'is_admin' => 'sometimes|boolean',
            'has_completed_setup' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user->update($validator->validated());

        return response()->json($user);
    }

    /**
     * Remove the specified user.
     */
    public function destroy(int $id)
    {
        $user = User::findOrFail($id);
        
        // Prevent deleting yourself
        if ($user->id === auth()->id()) {
            return response()->json([
                'message' => 'You cannot delete your own account from admin panel.'
            ], 403);
        }

        $user->delete();

        return response()->json(['message' => 'User deleted successfully']);
    }

    /**
     * Get dashboard statistics.
     */
    public function stats()
    {
        $stats = [
            'total_users' => User::count(),
            'admin_users' => User::where('is_admin', true)->count(),
            'new_users_today' => User::whereDate('created_at', today())->count(),
            'new_users_this_week' => User::whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])->count(),
            'new_users_this_month' => User::whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()])->count(),
        ];

        return response()->json($stats);
    }
}
