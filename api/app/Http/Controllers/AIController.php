<?php

namespace App\Http\Controllers;

use App\Services\AI\AIService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Exception;

class AIController extends Controller
{
    protected AIService $aiService;

    public function __construct(AIService $aiService)
    {
        $this->aiService = $aiService;
    }

    /**
     * Health check endpoint for AI service
     *
     * @return JsonResponse
     */
    public function health(): JsonResponse
    {
        try {
            $isAvailable = $this->aiService->isServiceAvailable();
            
            if ($isAvailable) {
                return response()->json([
                    'status' => 'healthy',
                    'service' => 'available',
                    'timestamp' => now()->toISOString()
                ], 200);
            } else {
                return response()->json([
                    'status' => 'unhealthy',
                    'service' => 'unavailable',
                    'timestamp' => now()->toISOString()
                ], 503);
            }
        } catch (Exception $e) {
            return response()->json([
                'status' => 'unhealthy',
                'service' => 'error',
                'message' => $e->getMessage(),
                'timestamp' => now()->toISOString()
            ], 503);
        }
    }

    /**
     * Handle AI chat requests
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function chat(Request $request): JsonResponse
    {
        try {
            // Validate the request
            $validated = $request->validate([
                'message' => 'required|string|max:1000|min:1',
            ]);

            // Get the authenticated user
            $user = $request->user();
            
            // Check if AI service is available
            if (!$this->aiService->isServiceAvailable()) {
                return response()->json([
                    'error' => true,
                    'message' => 'AI service is currently unavailable. Please try again later.',
                    'code' => 'AI_SERVICE_UNAVAILABLE',
                    'timestamp' => now()->toISOString()
                ], 503);
            }

            // Process the chat message
            $response = $this->aiService->chat($validated['message'], $user->id);

            // Return successful response in the format expected by the iOS app
            return response()->json([
                'message' => $response['message'],
                'timestamp' => $response['timestamp'],
                'provider' => $response['provider'],
                'success' => true
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            // Handle validation errors
            return response()->json([
                'error' => true,
                'message' => 'Invalid request data',
                'code' => 'VALIDATION_ERROR',
                'details' => $e->errors(),
                'timestamp' => now()->toISOString()
            ], 422);

        } catch (Exception $e) {
            // Log the error for debugging
            Log::error('AI Controller Error', [
                'user_id' => $request->user()?->id,
                'message' => $validated['message'] ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            // Determine appropriate error response based on exception type
            if (str_contains($e->getMessage(), 'not available') || 
                str_contains($e->getMessage(), 'unavailable')) {
                return response()->json([
                    'error' => true,
                    'message' => 'AI service is currently unavailable. Please try again later.',
                    'code' => 'AI_SERVICE_UNAVAILABLE',
                    'timestamp' => now()->toISOString()
                ], 503);
            }

            if (str_contains($e->getMessage(), 'timeout') || 
                str_contains($e->getMessage(), 'connection')) {
                return response()->json([
                    'error' => true,
                    'message' => 'Request timeout. Please try again.',
                    'code' => 'REQUEST_TIMEOUT',
                    'timestamp' => now()->toISOString()
                ], 408);
            }

            // Generic server error for unexpected exceptions
            return response()->json([
                'error' => true,
                'message' => 'An unexpected error occurred. Please try again later.',
                'code' => 'INTERNAL_SERVER_ERROR',
                'timestamp' => now()->toISOString()
            ], 500);
        }
    }
}