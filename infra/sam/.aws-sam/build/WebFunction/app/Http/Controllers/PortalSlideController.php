<?php

namespace App\Http\Controllers;

use App\Models\PortalSlide;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class PortalSlideController extends Controller
{
    /**
     * Display a listing of portal slides (admin).
     */
    public function index()
    {
        $slides = PortalSlide::ordered()->get();
        return response()->json($slides);
    }

    /**
     * Display a listing of active portal slides (public/iOS).
     */
    public function publicIndex()
    {
        $slides = PortalSlide::active()->ordered()->get();
        return response()->json($slides);
    }

    /**
     * Store a newly created portal slide.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image_url' => 'required|string|max:500',
            'title' => 'nullable|string|max:255',
            'link_url' => 'nullable|url|max:500',
            'sort_order' => 'nullable|integer',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $data = $validator->validated();
        
        // Set default sort_order to max + 1
        if (!isset($data['sort_order'])) {
            $maxOrder = PortalSlide::max('sort_order') ?? 0;
            $data['sort_order'] = $maxOrder + 1;
        }

        $slide = PortalSlide::create($data);

        return response()->json($slide, 201);
    }

    /**
     * Display the specified portal slide.
     */
    public function show(int $id)
    {
        $slide = PortalSlide::findOrFail($id);
        return response()->json($slide);
    }

    /**
     * Update the specified portal slide.
     */
    public function update(Request $request, int $id)
    {
        $slide = PortalSlide::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'image_url' => 'sometimes|string|max:500',
            'title' => 'nullable|string|max:255',
            'link_url' => 'nullable|url|max:500',
            'sort_order' => 'nullable|integer',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $slide->update($validator->validated());

        return response()->json($slide);
    }

    /**
     * Remove the specified portal slide.
     */
    public function destroy(int $id)
    {
        $slide = PortalSlide::findOrFail($id);
        $slide->delete();

        return response()->json(['message' => 'Slide deleted successfully']);
    }

    /**
     * Reorder portal slides.
     */
    public function reorder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order' => 'required|array',
            'order.*' => 'required|integer|exists:portal_slides,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        foreach ($request->order as $index => $slideId) {
            PortalSlide::where('id', $slideId)->update(['sort_order' => $index]);
        }

        return response()->json(['message' => 'Slides reordered successfully']);
    }
}
