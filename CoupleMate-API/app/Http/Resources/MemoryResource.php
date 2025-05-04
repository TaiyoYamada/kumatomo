<?php
// app/Http/Resources/MemoryResource.php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class MemoryResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'author_id' => $this->author_id,
            'title' => $this->title,
            'date' => $this->date,
            'location' => $this->location,
            'notes' => $this->notes,
            'photos' => json_decode($this->photos, true),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
