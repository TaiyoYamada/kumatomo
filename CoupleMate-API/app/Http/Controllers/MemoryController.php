<?php

namespace App\Http\Controllers;

use App\Models\Memory;
use Illuminate\Http\Request;
use App\Http\Resources\MemoryResource;

class MemoryController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return MemoryResource::collection(Memory::all());
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */

    public function store(Request $request)
    {
        $validated = $request->validate([
            'author_id' => 'required|string',
            'title' => 'required|string|max:255',
            'date' => 'required|date',
            'location' => 'required|string',
            'notes' => 'nullable|string',
            'photos' => 'nullable|array',
        ]);
    
        $memory = Memory::create([
            'author_id' => $validated['author_id'],
            'title' => $validated['title'],
            'date' => $validated['date'],
            'location' => $validated['location'],
            'notes' => $validated['notes'] ?? '',
            'photos' => $validated['photos'] ?? [],
        ]);
    
        return response()->json($memory, 201);
        }

    /**
     * Display the specified resource.
     */
    public function show(Memory $memory)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Memory $memory)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Memory $memory)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Memory $memory)
    {
        //
    }
}
