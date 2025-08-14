<?php

namespace Database\Factories;

use App\Models\Post;
use App\Models\User;
use App\Models\Shop;
use Illuminate\Database\Eloquent\Factories\Factory;

class PostFactory extends Factory
{
    protected $model = Post::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'shop_id' => null,
            'content' => $this->faker->realText(200),
            'image_url' => $this->faker->optional()->imageUrl(),
            'tags' => $this->faker->optional()->randomElements(['グルメ', 'カフェ', 'ランチ', 'ディナー', 'デザート'], 2),
            'created_at' => $this->faker->dateTimeBetween('-1 month', 'now'),
            'updated_at' => now(),
        ];
    }

    public function withShop(): static
    {
        return $this->state(fn (array $attributes) => [
            'shop_id' => Shop::factory(),
        ]);
    }
}