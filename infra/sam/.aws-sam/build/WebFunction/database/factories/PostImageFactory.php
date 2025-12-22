<?php

namespace Database\Factories;

use App\Models\PostImage;
use App\Models\Post;
use Illuminate\Database\Eloquent\Factories\Factory;

class PostImageFactory extends Factory
{
    protected $model = PostImage::class;

    public function definition(): array
    {
        return [
            'post_id' => Post::factory(),
            'image_url' => $this->faker->imageUrl(800, 600),
            'display_order' => $this->faker->numberBetween(1, 5),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}