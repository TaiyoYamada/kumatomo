<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;

class PostSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 各ユーザーにサンプル投稿を作成
        $samplePosts = [
            [
                'content' => '今日は熊本城を散歩してきました！桜がとても綺麗でした🌸',
                'tags' => ['観光', '熊本城', '桜'],
            ],
            [
                'content' => '阿蘇の絶景を堪能中。自然は最高ですね！🏔️',
                'tags' => ['阿蘇', '自然', '絶景'],
            ],
            [
                'content' => '熊本ラーメンを食べにきました。やっぱり地元の味は最高です🍜',
                'tags' => ['グルメ', 'ラーメン', '熊本ラーメン'],
            ],
            [
                'content' => '馬刺しとからし蓮根で乾杯🍺熊本最高！',
                'tags' => ['グルメ', '馬刺し', '郷土料理'],
            ],
            [
                'content' => '黒川温泉で癒されてきました♨️温泉巡り楽しい！',
                'tags' => ['温泉', '黒川温泉', 'リラックス'],
            ],
            [
                'content' => 'くまモンに会えました！やっぱりかわいい🐻',
                'tags' => ['くまモン', '観光', '熊本'],
            ],
            [
                'content' => '天草でイルカウォッチングしてきました🐬最高の体験でした！',
                'tags' => ['天草', 'イルカ', '観光'],
            ],
            [
                'content' => '今日のカフェ☕️雰囲気良くてコーヒーも美味しかった',
                'tags' => ['カフェ', 'コーヒー', 'リラックス'],
            ],
        ];

        $users = User::all();

        if ($users->isEmpty()) {
            $this->command->warn('ユーザーが存在しません。先にUserSeederを実行してください。');
            return;
        }

        foreach ($users as $user) {
            // 各ユーザーに2-3件のランダムな投稿を作成
            $userPosts = collect($samplePosts)->random(rand(2, 3));

            foreach ($userPosts as $postData) {
                // 既存の投稿と重複しないよう、同じ内容がないか確認
                $existingPost = Post::where('user_id', $user->id)
                    ->where('content', $postData['content'])
                    ->exists();

                if (!$existingPost) {
                    Post::create([
                        'user_id' => $user->id,
                        'content' => $postData['content'],
                        'tags' => $postData['tags'],
                        'created_at' => now()->subDays(rand(0, 30))->subHours(rand(0, 23)),
                        'updated_at' => now(),
                    ]);
                }
            }
        }

        $this->command->info('投稿のシードが完了しました。');
    }
}
