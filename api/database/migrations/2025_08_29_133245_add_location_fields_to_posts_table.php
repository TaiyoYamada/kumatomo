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
            // Add location fields
            $table->string('place_name')->nullable()->after('content');
            $table->decimal('latitude', 10, 8)->nullable()->after('place_name');
            $table->decimal('longitude', 11, 8)->nullable()->after('latitude');
            
            // Update content column to support 200 characters
            $table->string('content', 200)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            // Remove location fields
            $table->dropColumn(['place_name', 'latitude', 'longitude']);
            
            // Revert content column back to 100 characters
            $table->string('content', 100)->change();
        });
    }
};
