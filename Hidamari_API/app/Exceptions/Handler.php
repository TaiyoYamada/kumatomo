<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * A list of exception types with their corresponding custom log levels.
     *
     * @var array<class-string<\Throwable>, \Psr\Log\LogLevel::*>
     */
    protected $levels = [
        //
    ];

    /**
     * A list of the exception types that are not reported.
     *
     * @var array<int, class-string<\Throwable>>
     */
    protected $dontReport = [
        //
    ];

    /**
     * A list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    protected function unauthenticated($request, AuthenticationException $exception)
    {
        return $request->expectsJson()
            ? $this->jsonErrorResponse('認証が必要です', 401, 'AUTHENTICATION_REQUIRED')
            : abort(401, 'Unauthenticated.');
    }

    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

    /**
     * Render an exception into an HTTP response.
     */
    public function render($request, Throwable $e)
    {
        if ($request->expectsJson()) {
            return $this->handleApiException($request, $e);
        }

        return parent::render($request, $e);
    }

    /**
     * Handle API exceptions with unified error response format
     */
    protected function handleApiException(Request $request, Throwable $e)
    {
        // Validation errors
        if ($e instanceof ValidationException) {
            return $this->jsonErrorResponse(
                '入力データに問題があります',
                422,
                'VALIDATION_ERROR',
                $e->errors()
            );
        }

        // Model not found
        if ($e instanceof ModelNotFoundException) {
            return $this->jsonErrorResponse(
                'リソースが見つかりません',
                404,
                'RESOURCE_NOT_FOUND'
            );
        }

        // Not found HTTP exception
        if ($e instanceof NotFoundHttpException) {
            return $this->jsonErrorResponse(
                'エンドポイントが見つかりません',
                404,
                'ENDPOINT_NOT_FOUND'
            );
        }

        // Access denied
        if ($e instanceof AccessDeniedHttpException) {
            return $this->jsonErrorResponse(
                'アクセス権限がありません',
                403,
                'ACCESS_DENIED'
            );
        }

        // HTTP exceptions
        if ($e instanceof HttpException) {
            return $this->jsonErrorResponse(
                $e->getMessage() ?: 'HTTPエラーが発生しました',
                $e->getStatusCode(),
                'HTTP_ERROR'
            );
        }

        // Database connection errors
        if ($this->isDatabaseConnectionError($e)) {
            return $this->jsonErrorResponse(
                'データベース接続エラーが発生しました',
                503,
                'DATABASE_CONNECTION_ERROR'
            );
        }

        // File upload errors
        if ($this->isFileUploadError($e)) {
            return $this->jsonErrorResponse(
                'ファイルアップロードエラーが発生しました',
                400,
                'FILE_UPLOAD_ERROR'
            );
        }

        // Generic server error
        return $this->jsonErrorResponse(
            app()->environment('production') 
                ? 'サーバーエラーが発生しました' 
                : $e->getMessage(),
            500,
            'INTERNAL_SERVER_ERROR'
        );
    }

    /**
     * Create a standardized JSON error response
     */
    protected function jsonErrorResponse(string $message, int $statusCode, string $errorCode, array $details = null)
    {
        $response = [
            'error' => [
                'code' => $errorCode,
                'message' => $message,
                'timestamp' => now()->toISOString(),
            ]
        ];

        if ($details) {
            $response['error']['details'] = $details;
        }

        if (!app()->environment('production')) {
            $response['error']['debug'] = [
                'file' => debug_backtrace()[1]['file'] ?? null,
                'line' => debug_backtrace()[1]['line'] ?? null,
            ];
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Check if the exception is a database connection error
     */
    protected function isDatabaseConnectionError(Throwable $e): bool
    {
        return str_contains($e->getMessage(), 'Connection refused') ||
               str_contains($e->getMessage(), 'SQLSTATE') ||
               str_contains($e->getMessage(), 'database connection');
    }

    /**
     * Check if the exception is a file upload error
     */
    protected function isFileUploadError(Throwable $e): bool
    {
        return str_contains($e->getMessage(), 'upload') ||
               str_contains($e->getMessage(), 'file size') ||
               str_contains($e->getMessage(), 'UPLOAD_ERR');
    }
}
