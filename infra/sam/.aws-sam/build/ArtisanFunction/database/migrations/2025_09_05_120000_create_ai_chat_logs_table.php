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
        Schema::create('ai_chat_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('provider', 50);
            $table->timestamp('request_timestamp');
            $table->timestamp('response_timestamp')->nullable();
            $table->unsignedInteger('response_time_ms')->nullable();
            $table->timestamps();

            // Foreign key constraint
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');

            // Indexes for performance optimization
            $table->index('user_id', 'idx_user_id');
            $table->index('provider', 'idx_provider');
            $table->index('created_at', 'idx_created_at');
            $table->index('request_timestamp', 'idx_request_timestamp');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_chat_logs');
    }
};