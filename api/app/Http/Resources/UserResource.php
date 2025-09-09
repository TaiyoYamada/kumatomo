<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'email' => $this->email,
            'name' => $this->name,
            'username' => $this->username,
            'bio' => $this->bio,
            'city' => $this->city,
            'location' => $this->city, // Alias for city
            'birthday' => $this->birthday,
            'website' => $this->website,
            'profileImageURL' => $this->profile_icon_image_url, // iOS expects camelCase
            'profileIconImageURL' => $this->profile_icon_image_url,
            'coverImageURL' => $this->profile_image_url, // Cover image
            'profile_icon_image_url' => $this->profile_icon_image_url, // Keep snake_case for backward compatibility
            'profile_image_url' => $this->profile_image_url,
            'postCount' => $this->post_count ?? 0,
            'post_count' => $this->post_count ?? 0, // Keep snake_case for backward compatibility
            'followingCount' => $this->following_count ?? 0,
            'following_count' => $this->following_count ?? 0,
            'followersCount' => $this->followers_count ?? 0,
            'followers_count' => $this->followers_count ?? 0,
            'hasCompletedSetup' => $this->has_completed_setup ?? false,
            'has_completed_setup' => $this->has_completed_setup ?? false,
            'isVerified' => false, // Add verification status
            'joinedDate' => $this->created_at?->format('Y年m月d日'),
            'createdAt' => $this->created_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
