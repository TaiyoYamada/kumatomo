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
            'fullName' => $this->fullName,
            'birthDate' => $this->birthDate?->toDateString(),
            'profileImageURL' => $this->profileImageURL,
            'partnerId' => $this->partnerId,
            'pairId' => $this->pairId,
            'relationshipStartDate' => $this->relationshipStartDate?->toDateString(),
            'bio' => $this->bio,
            'interests' => $this->interests ?? [],
            'relationshipStatus' => $this->relationshipStatus,
            'createdAt' => $this->created_at?->toIso8601String(),
            'updatedAt' => $this->updated_at?->toIso8601String(),
        ];
    }
}
