<?php

namespace App\Services\AI;

interface AIProviderInterface
{
    /**
     * Generate a response from the AI provider
     *
     * @param string $message The user's message
     * @return string The AI's response
     * @throws \Exception If the provider fails to generate a response
     */
    public function generateResponse(string $message): string;

    /**
     * Check if the AI provider is available
     *
     * @return bool True if the provider is available, false otherwise
     */
    public function isAvailable(): bool;
}