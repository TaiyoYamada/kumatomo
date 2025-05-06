<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('name')->nullable();
            $table->date('birthDate')->nullable();
            $table->string('profileImageURL')->nullable();
            $table->string('partnerId')->nullable();
            $table->string('pairId')->nullable();
            $table->date('relationshipStartDate')->nullable();
            $table->text('bio')->nullable();
            $table->json('interests')->nullable();
            $table->string('relationshipStatus')->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
