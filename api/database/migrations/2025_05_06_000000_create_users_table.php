<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();

            // 認証関連
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->boolean('has_completed_setup')->default(false);


            // プロフィール情報
            $table->string('name')->nullable();
            $table->string('username')->nullable()->unique();
            $table->text('bio')->nullable();
            
            // Location
            $table->string('location')->nullable(); 

            $table->string('website')->nullable();
            $table->date('birthday')->nullable();
            $table->unsignedInteger('post_count')->default(0);
            
            $table->string('profile_image_url')->nullable(); 
            $table->string('cover_image_url')->nullable();

            // フォロー関連（初期値0）
            $table->unsignedInteger('followers_count')->default(0);
            $table->unsignedInteger('following_count')->default(0);


            // 管理用
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
