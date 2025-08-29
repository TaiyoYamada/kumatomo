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
        Schema::create('post_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')
                ->constrained('posts')
                ->onUpdate('cascade')
                ->onDelete('cascade');
            $table->string('image_url', 2048);
            $table->tinyInteger('display_order')->unsigned()->default(1);
            $table->timestamps();

            // インデックスの最適化
            $table->index('post_id', 'idx_post_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('post_images');
    }
};