<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
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
            'profile_image_url' => $this->profileImageURL,
            'bio' => $this->bio,
            'website' => $this->website,
            'following_count' => $this->following_count ?? 0,
            'followers_count' => $this->followers_count ?? 0,
            'partner_id' => $this->partnerId,
            'pair_id' => $this->pairId,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
