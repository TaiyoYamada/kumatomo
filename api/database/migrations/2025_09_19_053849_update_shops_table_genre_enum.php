<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use App\Enums\ShopGenre;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            // Drop the existing genre column and recreate with enum constraint
            $table->dropColumn('genre');
        });

        Schema::table('shops', function (Blueprint $table) {
            // Add genre column with enum constraint
            $genreValues = ShopGenre::values();
            $enumString = "'" . implode("','", $genreValues) . "'";
            
            $table->enum('genre', $genreValues)->nullable()->after('business_hours');
            
            // Recreate the index
            $table->index('genre', 'idx_genre');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            // Drop the enum column
            $table->dropIndex('idx_genre');
            $table->dropColumn('genre');
        });

        Schema::table('shops', function (Blueprint $table) {
            // Restore the original string column
            $table->string('genre', 50)->nullable()->after('business_hours');
            $table->index('genre', 'idx_genre');
        });
    }
};
