<?php

namespace App\Providers;

use Aws\Ssm\SsmClient;
use Illuminate\Support\ServiceProvider;

/**
 * SSM Parameter Store Provider for Lambda/Bref
 * 
 * Fetches configuration from AWS SSM Parameter Store at runtime.
 * This replaces environment variables in serverless environments.
 */
class SsmServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Only run in production (Lambda)
        if (!$this->isLambdaEnvironment()) {
            return;
        }

        $this->loadSsmParameters();
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        //
    }

    /**
     * Check if running in Lambda environment
     */
    private function isLambdaEnvironment(): bool
    {
        return !empty($_ENV['AWS_LAMBDA_FUNCTION_NAME']) || !empty($_ENV['LAMBDA_TASK_ROOT']);
    }

    /**
     * Load parameters from SSM Parameter Store
     */
    private function loadSsmParameters(): void
    {
        $prefix = $_ENV['SSM_PREFIX'] ?? '/kumatomo/prod';
        $region = $_ENV['AWS_REGION'] ?? 'ap-northeast-1';

        try {
            $client = new SsmClient([
                'version' => 'latest',
                'region'  => $region,
            ]);

            $result = $client->getParametersByPath([
                'Path' => $prefix,
                'Recursive' => true,
                'WithDecryption' => true,
            ]);

            foreach ($result['Parameters'] as $param) {
                $name = $this->extractParameterName($param['Name'], $prefix);
                $value = $param['Value'];
                
                $this->setConfigValue($name, $value);
            }
        } catch (\Exception $e) {
            // Log error but don't fail - allow app to start
            logger()->error('Failed to load SSM parameters: ' . $e->getMessage());
        }
    }

    /**
     * Extract the parameter name from the full path
     */
    private function extractParameterName(string $fullPath, string $prefix): string
    {
        return ltrim(str_replace($prefix, '', $fullPath), '/');
    }

    /**
     * Set Laravel config based on parameter name
     */
    private function setConfigValue(string $name, string $value): void
    {
        $mappings = [
            'db_host'        => 'database.connections.mysql.host',
            'db_port'        => 'database.connections.mysql.port',
            'db_name'        => 'database.connections.mysql.database',
            'db_username'    => 'database.connections.mysql.username',
            'db_password'    => 'database.connections.mysql.password',
            'app_key'        => 'app.key',
            'app_env'        => 'app.env',
            's3_media_bucket'=> 'filesystems.disks.s3.bucket',
            'aws_region'     => 'filesystems.disks.s3.region',
        ];

        if (isset($mappings[$name])) {
            config([$mappings[$name] => $value]);
        }
    }
}
