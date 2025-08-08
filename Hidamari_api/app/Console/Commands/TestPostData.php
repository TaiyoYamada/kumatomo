<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Post;
use App\Models\PostImage;

class TestPostData extends Command
{
    protected $signature = 'test:post-data';
    protected $description = 'テスト用の投稿データを作成・確認';

    public function handle()
    {
        $this->info('=== 投稿データの確認 ===');
        
        // ユーザー数を確認
        $userCount = User::count();
        $this->info("ユーザー数: {$userCount}");
        
        // 投稿数を確認
        $postCount = Post::count();
        $this->info("投稿数: {$postCount}");
        
        // PostImage数を確認
        $imageCount = PostImage::count();
        $this->info("PostImage数: {$imageCount}");
        
        if ($userCount === 0) {
            $this->info('テストユーザーを作成中...');
            $user = User::create([
                'name' => 'テストユーザー',
                'email' => 'test@example.com',
                'password' => bcrypt('password'),
            ]);
            $this->info("ユーザー作成完了: ID {$user->id}");
        } else {
            $user = User::first();
            $this->info("既存ユーザーを使用: ID {$user->id}");
        }
        
        if ($postCount === 0) {
            $this->info('テスト投稿を作成中...');
            $post = Post::create([
                'user_id' => $user->id,
                'content' => 'テスト投稿です。画像付きの投稿をテストしています。',
            ]);
            $this->info("投稿作成完了: ID {$post->id}");
            
            // テスト画像を追加
            $this->info('テスト画像を追加中...');
            PostImage::create([
                'post_id' => $post->id,
                'image_url' => 'https://via.placeholder.com/300x200/0066cc/ffffff?text=Test+Image+1',
                'display_order' => 1,
            ]);
            
            PostImage::create([
                'post_id' => $post->id,
                'image_url' => 'https://via.placeholder.com/300x200/cc6600/ffffff?text=Test+Image+2',
                'display_order' => 2,
            ]);
            
            $this->info('テスト画像追加完了');
        }
        
        // 最新の投稿データを確認
        $this->info('=== 最新投稿データ ===');
        $latestPost = Post::with(['user', 'images'])->latest()->first();
        
        if ($latestPost) {
            $this->info("投稿ID: {$latestPost->id}");
            $this->info("ユーザー: {$latestPost->user->name}");
            $this->info("内容: {$latestPost->content}");
            $this->info("画像数: " . $latestPost->images->count());
            
            foreach ($latestPost->images as $index => $image) {
                $this->info("  画像" . ($index + 1) . ": {$image->image_url} (order: {$image->display_order})");
            }
            
            // JSONレスポンスを確認
            $this->info('=== JSON レスポンス ===');
            $this->line($latestPost->toJson(JSON_PRETTY_PRINT));
        } else {
            $this->error('投稿データが見つかりません');
        }
        
        return 0;
    }
}