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
        // Build absolute URLs for images if paths are relative
        $makeAbsolute = function ($path) {
            if (!$path) return null;
            // If already absolute (http/https), return as-is
            if (preg_match('/^https?:\/\//i', $path)) {
                return $path;
            }
            // Assume storage path; use url() helper to make absolute
            return url($path);
        };

        return [
            'id' => $this->id,
            'email' => $this->email,
            'name' => $this->name,
            'username' => $this->username,
            'bio' => $this->bio,
            'location' => $this->location,
            'birthday' => $this->birthday,
            'website' => $this->website,
            'profileImageURL' => $makeAbsolute($this->profile_image_url),
            'coverImageURL' => $makeAbsolute($this->cover_image_url),
            'postCount' => $this->post_count ?? 0,
            'followingCount' => $this->following_count ?? 0,
            'followersCount' => $this->followers_count ?? 0,
            'hasCompletedSetup' => $this->has_completed_setup ?? false,
            'isAdmin' => $this->is_admin ?? false,
            'isVerified' => false,
            'joinedDate' => $this->created_at?->format('Y年m月d日'),
            'createdAt' => $this->created_at?->toIso8601String(),
        ];
    }
}
