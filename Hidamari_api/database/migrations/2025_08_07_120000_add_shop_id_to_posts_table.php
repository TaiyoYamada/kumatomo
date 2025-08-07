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
        Schema::table('posts', function (Blueprint $table) {
            $table->foreignId('shop_id')
                ->nullable()
                ->after('user_id')
                ->constrained('shops')
                ->onUpdate('cascade')
                ->onDelete('set null');

            // インデックスの最適化
            $table->index('shop_id', 'idx_shop_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropForeign(['shop_id']);
            $table->dropIndex('idx_shop_id');
            $table->dropColumn('shop_id');
        });
    }
};