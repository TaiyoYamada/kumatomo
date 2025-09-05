<?php

return [
    /*
    |--------------------------------------------------------------------------
    | AI Provider Configuration
    |--------------------------------------------------------------------------
    |
    | This configuration determines which AI provider to use based on the
    | environment. Supported providers: 'ollama', 'gemini'
    |
    */

    'provider' => env('AI_PROVIDER', 'ollama'),

    /*
    |--------------------------------------------------------------------------
    | Ollama Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for the Ollama provider (development environment)
    |
    */

    'ollama' => [
        'url' => env('OLLAMA_URL', 'http://ollama:11434'),
        'model' => env('OLLAMA_MODEL', 'llama2'),
        'timeout' => env('OLLAMA_TIMEOUT', 30), // seconds
    ],

    /*
    |--------------------------------------------------------------------------
    | Gemini Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for the Gemini API provider (production environment)
    |
    */

    'gemini' => [
        'api_key' => env('GEMINI_API_KEY'),
        'model' => env('GEMINI_MODEL', 'gemini-pro'),
        'api_url' => env('GEMINI_API_URL', 'https://generativelanguage.googleapis.com/v1beta'),
        'timeout' => env('GEMINI_TIMEOUT', 30), // seconds
    ],

    /*
    |--------------------------------------------------------------------------
    | General AI Configuration
    |--------------------------------------------------------------------------
    |
    | General settings that apply to all AI providers
    |
    */

    'max_message_length' => env('AI_MAX_MESSAGE_LENGTH', 1000),
    'rate_limit_per_minute' => env('AI_RATE_LIMIT_PER_MINUTE', 10),
];