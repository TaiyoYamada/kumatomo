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
            'bio' => $this->bio,
            'city' => $this->city,
            'birthday' => $this->birthday?->toIso8601String(),
            'website' => $this->website,
            'profile_icon_image_url' => $this->profile_icon_image_url,
            'profile_image_url' => $this->profile_image_url,
            'post_count' => $this->stories_count ?? 0, // ストーリーの投稿数
            'following_count' => $this->following_count ?? 0,
            'followers_count' => $this->followers_count ?? 0,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
