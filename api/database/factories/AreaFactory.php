<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Area>
 */
class AreaFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $areas = [
            '渋谷区',
            '新宿区',
            '港区',
            '千代田区',
            '中央区',
            '品川区',
            '目黒区',
            '大田区',
            '世田谷区',
            '中野区',
            '杉並区',
            '練馬区',
            '板橋区',
            '豊島区',
            '北区',
            '荒川区',
            '足立区',
            '葛飾区',
            '江戸川区',
            '台東区',
            '墨田区',
            '江東区',
            '文京区'
        ];

        return [
            'name' => fake()->unique()->randomElement($areas),
        ];
    }
}