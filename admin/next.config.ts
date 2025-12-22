import type { NextConfig } from "next";

const nextConfig: NextConfig = {
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
  },
  // Empty turbopack config to silence the warning (using Turbopack by default in Next.js 16)
  turbopack: {},
};

export default nextConfig;
