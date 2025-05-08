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

            // プロフィール情報
            $table->string('name')->nullable();
            $table->text('bio')->nullable();
            $table->string('website')->nullable();
            $table->string('profile_image_url')->nullable();

            // カップル関連
            $table->unsignedBigInteger('partner_id')->nullable(); // Userとのリレーション
            $table->unsignedBigInteger('pair_id')->nullable();    // Pairテーブルがある場合

            // フォロー関連（初期値0）
            $table->unsignedInteger('followers_count')->default(0);
            $table->unsignedInteger('following_count')->default(0);
            

            // 管理用
            $table->timestamps();
            $table->softDeletes();

            // 外部キー（必要に応じてON DELETEなど）
            // $table->foreign('partner_id')->references('id')->on('users')->nullOnDelete();
            // $table->foreign('pair_id')->references('id')->on('pairs')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
