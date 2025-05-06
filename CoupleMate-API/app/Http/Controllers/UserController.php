<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|min:6',
            'name' => 'required|string',
            'birthDate' => 'nullable|date',
            'profileImageURL' => 'nullable|string',
            'partnerId' => 'nullable|string',
            'pairId' => 'nullable|string',
            'relationshipStartDate' => 'nullable|date',
            'bio' => 'nullable|string',
            'interests' => 'nullable|array',
            'relationshipStatus' => 'nullable|string',
        ]);

        $user = User::create($validated);

        return response()->json($user, 201);
    }
}

