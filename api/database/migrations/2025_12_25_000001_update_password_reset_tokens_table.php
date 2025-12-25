<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::dropIfExists('password_reset_tokens');
        
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('email')->index();
            $table->string('code', 6);              // 6桁OTPコード
            $table->string('token', 64)->nullable(); // 検証後に発行されるリセットトークン
            $table->boolean('verified')->default(false);
            $table->timestamp('expires_at');
            $table->timestamps();
            
            $table->index(['email', 'code']);
            $table->index('token');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('password_reset_tokens');
        
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->id();
            $table->timestamps();
        });
    }
};
