import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Static export for S3 hosting
  output: 'export',

  // Allow images from any domain for the admin panel
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: 'localhost',
      },
    ],
    // Required for static export
    unoptimized: true,
  },
  // Empty turbopack config to silence the warning (using Turbopack by default in Next.js 16)
  turbopack: {},
};

export default nextConfig;
