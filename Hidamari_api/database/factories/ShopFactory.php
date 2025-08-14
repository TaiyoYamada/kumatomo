<?php

namespace Database\Factories;

use App\Models\Shop;
use Illuminate\Database\Eloquent\Factories\Factory;

class ShopFactory extends Factory
{
    protected $model = Shop::class;

    public function definition(): array
    {
        return [
            'name' => $this->faker->company . '店',
            'description' => $this->faker->optional()->realText(300),
            'address' => $this->faker->address,
            'phone' => $this->faker->optional()->phoneNumber,
            'business_hours' => $this->faker->optional()->randomElement([
                '9:00-18:00',
                '11:00-22:00',
                '10:00-20:00',
                '24時間営業'
            ]),
            'genre' => $this->faker->randomElement([
                'レストラン',
                'カフェ',
                'ファストフード',
                '居酒屋',
                'ラーメン',
                '寿司',
                '焼肉',
                'イタリアン',
                'フレンチ',
                '中華'
            ]),
            'latitude' => $this->faker->latitude(35.5, 35.8), // 東京周辺
            'longitude' => $this->faker->longitude(139.5, 139.9), // 東京周辺
            'image_url' => $this->faker->optional()->imageUrl(),
            'created_at' => $this->faker->dateTimeBetween('-6 months', 'now'),
            'updated_at' => now(),
        ];
    }
}