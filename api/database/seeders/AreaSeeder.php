<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AreaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $areas = [
            ['name' => '渋谷区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '新宿区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '港区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '千代田区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '中央区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '品川区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '目黒区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '大田区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '世田谷区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '中野区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '杉並区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '練馬区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '板橋区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '豊島区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '北区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '荒川区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '足立区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '葛飾区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '江戸川区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '台東区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '墨田区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '江東区', 'created_at' => now(), 'updated_at' => now()],
            ['name' => '文京区', 'created_at' => now(), 'updated_at' => now()],
        ];

        DB::table('areas')->insert($areas);
    }
}
