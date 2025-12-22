<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    // Public endpoint to get active announcements
    public function index()
    {
        // Get active and published announcements, ordered by priority and date
        $announcements = Announcement::active()->ordered()->take(20)->get();

        return response()->json($announcements);
    }
}
