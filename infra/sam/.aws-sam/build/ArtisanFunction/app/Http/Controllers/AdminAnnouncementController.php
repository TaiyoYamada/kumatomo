<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use Illuminate\Http\Request;

class AdminAnnouncementController extends Controller
{
    // List announcements
    public function index(Request $request)
    {
        $query = Announcement::query();

        // Search functionality
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where('title', 'like', "%{$search}%")
                  ->orWhere('content', 'like', "%{$search}%");
        }

        // Sorting
        $sortColumn = $request->input('sort_by', 'created_at');
        $sortDirection = $request->input('sort_order', 'desc');
        $validSortColumns = ['id', 'title', 'published_at', 'is_active', 'priority', 'created_at'];

        if (in_array($sortColumn, $validSortColumns)) {
            $query->orderBy($sortColumn, $sortDirection);
        }

        $perPage = $request->input('per_page', 10);
        return $query->paginate($perPage);
    }

    // Show single announcement
    public function show($id)
    {
        return Announcement::findOrFail($id);
    }

    // Create announcement
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'published_at' => 'nullable|date',
            'is_active' => 'boolean',
            'priority' => 'integer',
        ]);

        $announcement = Announcement::create($validated);

        return response()->json($announcement, 201);
    }

    // Update announcement
    public function update(Request $request, $id)
    {
        $announcement = Announcement::findOrFail($id);

        $validated = $request->validate([
            'title' => 'string|max:255',
            'content' => 'string',
            'published_at' => 'nullable|date',
            'is_active' => 'boolean',
            'priority' => 'integer',
        ]);

        $announcement->update($validated);

        return response()->json($announcement);
    }

    // Delete announcement
    public function destroy($id)
    {
        $announcement = Announcement::findOrFail($id);
        $announcement->delete();

        return response()->json(['message' => 'Announcement deleted']);
    }

    // Dashboard stats
    public function stats()
    {
        $total = Announcement::count();
        $active = Announcement::where('is_active', true)->count();
        $scheduled = Announcement::where('published_at', '>', now())->count();

        return response()->json([
            'total_announcements' => $total,
            'active_announcements' => $active,
            'scheduled_announcements' => $scheduled,
        ]);
    }
}
