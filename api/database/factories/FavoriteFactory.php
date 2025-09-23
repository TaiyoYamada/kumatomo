<?php

namespace Database\Factories;

use App\Models\Favorite;
use App\Models\User;
use App\Models\Shop;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Favorite>
 */
class FavoriteFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = Favorite::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'shop_id' => Shop::factory(),
        ];
    }

    /**
     * Create a favorite for a specific user and shop.
     */
    public function forUserAndShop(User $user, Shop $shop): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => $user->id,
            'shop_id' => $shop->id,
        ]);
    }

    /**
     * Create a favorite for a specific user.
     */
    public function forUser(User $user): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => $user->id,
        ]);
    }

    /**
     * Create a favorite for a specific shop.
     */
    public function forShop(Shop $shop): static
    {
        return $this->state(fn (array $attributes) => [
            'shop_id' => $shop->id,
        ]);
    }
}