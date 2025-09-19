<?php

namespace App\Http\Controllers;

use App\Models\ShopProposal;
use App\Models\Shop;
use App\Enums\ShopGenre;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ShopProposalController extends Controller
{
    /**
     * Display a listing of the user's shop proposals.
     */
    public function index(Request $request): JsonResponse
    {
        $proposals = $request->user()
            ->shopProposals()
            ->latest()
            ->paginate(20);

        return response()->json($proposals);
    }

    /**
     * Store a newly created shop proposal.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'address' => 'nullable|string|max:255',
            'genre' => ['nullable', Rule::in(ShopGenre::values())],
            'description' => 'nullable|string|max:1000',
        ]);

        // Rate limiting: Check if user has submitted too many proposals recently
        $recentProposals = $request->user()
            ->shopProposals()
            ->where('created_at', '>=', now()->subHour())
            ->count();

        if ($recentProposals >= 3) {
            return response()->json([
                'error' => [
                    'message' => '1時間に3件以上の提案はできません。しばらく時間をおいてから再度お試しください。',
                    'code' => 'RATE_LIMIT_EXCEEDED'
                ]
            ], 429);
        }

        // Check for duplicate proposals by the same user
        $existingProposal = $request->user()
            ->shopProposals()
            ->where('name', $validated['name'])
            ->where('status', ShopProposal::STATUS_PENDING)
            ->first();

        if ($existingProposal) {
            return response()->json([
                'error' => [
                    'message' => '同じ名前の店舗提案が既に承認待ちです。',
                    'code' => 'DUPLICATE_PROPOSAL'
                ]
            ], 422);
        }

        try {
            DB::beginTransaction();

            $proposal = $request->user()->shopProposals()->create([
                'name' => $validated['name'],
                'address' => $validated['address'] ?? null,
                'genre' => $validated['genre'] ?? null,
                'description' => $validated['description'] ?? null,
                'status' => ShopProposal::STATUS_PENDING,
            ]);

            DB::commit();

            return response()->json([
                'data' => $proposal,
                'message' => '店舗提案が正常に送信されました。管理者による承認をお待ちください。'
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'message' => '店舗提案の送信中にエラーが発生しました。もう一度お試しください。',
                    'code' => 'SUBMISSION_FAILED'
                ]
            ], 500);
        }
    }

    /**
     * Display the specified shop proposal.
     */
    public function show(Request $request, ShopProposal $proposal): JsonResponse
    {
        // Ensure user can only view their own proposals
        if ($proposal->user_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'message' => 'この提案にアクセスする権限がありません。',
                    'code' => 'UNAUTHORIZED'
                ]
            ], 403);
        }

        return response()->json(['data' => $proposal]);
    }

    /**
     * Update the specified shop proposal (only if pending).
     */
    public function update(Request $request, ShopProposal $proposal): JsonResponse
    {
        // Ensure user can only update their own proposals
        if ($proposal->user_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'message' => 'この提案を編集する権限がありません。',
                    'code' => 'UNAUTHORIZED'
                ]
            ], 403);
        }

        // Only allow updates to pending proposals
        if (!$proposal->isPending()) {
            return response()->json([
                'error' => [
                    'message' => '承認済みまたは却下された提案は編集できません。',
                    'code' => 'PROPOSAL_NOT_EDITABLE'
                ]
            ], 422);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'address' => 'nullable|string|max:255',
            'genre' => ['nullable', Rule::in(ShopGenre::values())],
            'description' => 'nullable|string|max:1000',
        ]);

        try {
            $proposal->update([
                'name' => $validated['name'],
                'address' => $validated['address'] ?? $proposal->address,
                'genre' => $validated['genre'] ?? $proposal->genre,
                'description' => $validated['description'] ?? $proposal->description,
            ]);

            return response()->json([
                'data' => $proposal->fresh(),
                'message' => '店舗提案が正常に更新されました。'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'message' => '店舗提案の更新中にエラーが発生しました。',
                    'code' => 'UPDATE_FAILED'
                ]
            ], 500);
        }
    }

    /**
     * Remove the specified shop proposal (only if pending).
     */
    public function destroy(Request $request, ShopProposal $proposal): JsonResponse
    {
        // Ensure user can only delete their own proposals
        if ($proposal->user_id !== $request->user()->id) {
            return response()->json([
                'error' => [
                    'message' => 'この提案を削除する権限がありません。',
                    'code' => 'UNAUTHORIZED'
                ]
            ], 403);
        }

        // Only allow deletion of pending proposals
        if (!$proposal->isPending()) {
            return response()->json([
                'error' => [
                    'message' => '承認済みまたは却下された提案は削除できません。',
                    'code' => 'PROPOSAL_NOT_DELETABLE'
                ]
            ], 422);
        }

        try {
            $proposal->delete();

            return response()->json([
                'message' => '店舗提案が正常に削除されました。'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'message' => '店舗提案の削除中にエラーが発生しました。',
                    'code' => 'DELETION_FAILED'
                ]
            ], 500);
        }
    }

    /**
     * Get proposal status for user feedback.
     */
    public function status(Request $request): JsonResponse
    {
        $proposals = $request->user()
            ->shopProposals()
            ->select(['id', 'name', 'status', 'admin_notes', 'created_at', 'updated_at'])
            ->latest()
            ->get();

        $statusCounts = [
            'pending' => $proposals->where('status', ShopProposal::STATUS_PENDING)->count(),
            'approved' => $proposals->where('status', ShopProposal::STATUS_APPROVED)->count(),
            'rejected' => $proposals->where('status', ShopProposal::STATUS_REJECTED)->count(),
        ];

        return response()->json([
            'data' => $proposals,
            'summary' => $statusCounts
        ]);
    }

    // MARK: - Admin Methods (for admin panel)

    /**
     * Get all proposals for admin review.
     */
    public function adminIndex(Request $request): JsonResponse
    {
        // This would typically have admin middleware
        $query = ShopProposal::with('user:id,username,email');

        // Filter by status if provided
        if ($request->has('status')) {
            $query->byStatus($request->status);
        }

        // Search by name if provided
        if ($request->has('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        $proposals = $query->latest()->paginate(20);

        return response()->json($proposals);
    }

    /**
     * Approve a shop proposal and convert to shop.
     */
    public function approve(Request $request, ShopProposal $proposal): JsonResponse
    {
        if (!$proposal->isPending()) {
            return response()->json([
                'error' => [
                    'message' => 'この提案は既に処理済みです。',
                    'code' => 'PROPOSAL_ALREADY_PROCESSED'
                ]
            ], 422);
        }

        $validated = $request->validate([
            'admin_notes' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'phone' => 'nullable|string|max:20',
            'business_hours' => 'nullable|string|max:255',
            'image_url' => 'nullable|url|max:255',
        ]);

        try {
            DB::beginTransaction();

            // Create the shop from the proposal
            $shop = Shop::create([
                'name' => $proposal->name,
                'address' => $proposal->address,
                'genre' => $proposal->genre,
                'description' => $proposal->description,
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
                'phone' => $validated['phone'] ?? null,
                'business_hours' => $validated['business_hours'] ?? null,
                'image_url' => $validated['image_url'] ?? null,
                'has_try_benefit' => false,
                'stamp_count' => 0,
                'is_approved' => true,
            ]);

            // Update proposal status
            $proposal->approve($validated['admin_notes'] ?? null);

            DB::commit();

            return response()->json([
                'data' => [
                    'shop' => $shop,
                    'proposal' => $proposal->fresh()
                ],
                'message' => '店舗提案が承認され、新しい店舗として追加されました。'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'error' => [
                    'message' => '提案の承認中にエラーが発生しました。',
                    'code' => 'APPROVAL_FAILED'
                ]
            ], 500);
        }
    }

    /**
     * Reject a shop proposal.
     */
    public function reject(Request $request, ShopProposal $proposal): JsonResponse
    {
        if (!$proposal->isPending()) {
            return response()->json([
                'error' => [
                    'message' => 'この提案は既に処理済みです。',
                    'code' => 'PROPOSAL_ALREADY_PROCESSED'
                ]
            ], 422);
        }

        $validated = $request->validate([
            'admin_notes' => 'required|string|max:500',
        ]);

        try {
            $proposal->reject($validated['admin_notes']);

            return response()->json([
                'data' => $proposal->fresh(),
                'message' => '店舗提案が却下されました。'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'message' => '提案の却下中にエラーが発生しました。',
                    'code' => 'REJECTION_FAILED'
                ]
            ], 500);
        }
    }
}