import type { NextConfig } from 'next';
import path from 'node:path';

const nextConfig: NextConfig = {
  // Static-friendly marketing + legal site. No server data, no env needed.
  reactStrictMode: true,
  // Pin the trace root to this folder so Next doesn't pick up a parent lockfile
  // (the iOS repo lives one level up). Vercel should also set Root Directory =
  // "website" for this project.
  outputFileTracingRoot: path.join(__dirname),

  // test.thebedrock.app serves only the wall-test page (the app's S4).
  async rewrites() {
    return {
      beforeFiles: [
        {
          source: '/:path*',
          has: [{ type: 'host', value: 'test.thebedrock.app' }],
          destination: '/wall-test',
        },
      ],
    };
  },

  // Universal links: iOS fetches this without an extension and needs JSON.
  async headers() {
    return [
      {
        source: '/.well-known/apple-app-site-association',
        headers: [{ key: 'Content-Type', value: 'application/json' }],
      },
    ];
  },
};

export default nextConfig;
