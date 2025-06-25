<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('memories', function (Blueprint $table) {
            $table->id();
            $table->string('author_id'); // Firebase UIDなど
            $table->string('title');
            $table->date('date');
            $table->string('location');
            $table->text('notes')->nullable();
            $table->json('photos')->nullable(); // JSON配列で保存
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('memories');
    }
};
