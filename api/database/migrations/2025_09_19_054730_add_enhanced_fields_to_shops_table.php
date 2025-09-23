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
        Schema::table('shops', function (Blueprint $table) {
            $table->boolean('has_try_benefit')->default(false)->after('image_url');
            $table->integer('stamp_count')->default(0)->after('has_try_benefit');
            $table->boolean('is_approved')->default(true)->after('stamp_count');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropColumn(['has_try_benefit', 'stamp_count', 'is_approved']);
        });
    }
};
