<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use App\Http\Resources\UserResource;

class UserController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'fullName' => 'required|string|max:255',
            'birthDate' => 'nullable|date',
            'profileImageURL' => 'nullable|string',
            'partnerId' => 'nullable|string',
            'pairId' => 'nullable|string',
            'relationshipStartDate' => 'nullable|date',
            'bio' => 'nullable|string',
            'interests' => 'nullable|array',
            'relationshipStatus' => 'required|string',
        ]);
        

        $user = User::create($validated);
        return new UserResource($user);

    }
    
}
