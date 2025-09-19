<?php

namespace Database\Factories;

use App\Models\ShopProposal;
use App\Models\User;
use App\Enums\ShopGenre;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\ShopProposal>
 */
class ShopProposalFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var string
     */
    protected $model = ShopProposal::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => $this->faker->company . '店',
            'address' => $this->faker->address,
            'genre' => $this->faker->randomElement(ShopGenre::values()),
            'description' => $this->faker->optional(0.7)->paragraph,
            'status' => ShopProposal::STATUS_PENDING,
            'admin_notes' => null,
        ];
    }

    /**
     * Indicate that the proposal is pending.
     */
    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => ShopProposal::STATUS_PENDING,
            'admin_notes' => null,
        ]);
    }

    /**
     * Indicate that the proposal is approved.
     */
    public function approved(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => ShopProposal::STATUS_APPROVED,
            'admin_notes' => $this->faker->optional(0.5)->sentence,
        ]);
    }

    /**
     * Indicate that the proposal is rejected.
     */
    public function rejected(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => ShopProposal::STATUS_REJECTED,
            'admin_notes' => $this->faker->sentence,
        ]);
    }

    /**
     * Create a proposal for a specific user.
     */
    public function forUser(User $user): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => $user->id,
        ]);
    }

    /**
     * Create a proposal with minimal data.
     */
    public function minimal(): static
    {
        return $this->state(fn (array $attributes) => [
            'address' => null,
            'genre' => null,
            'description' => null,
        ]);
    }

    /**
     * Create a proposal with specific genre.
     */
    public function withGenre(ShopGenre $genre): static
    {
        return $this->state(fn (array $attributes) => [
            'genre' => $genre->value,
        ]);
    }

    /**
     * Create a proposal with specific name.
     */
    public function withName(string $name): static
    {
        return $this->state(fn (array $attributes) => [
            'name' => $name,
        ]);
    }
}