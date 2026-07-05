import type { NextConfig } from 'next';
import path from 'node:path';

const nextConfig: NextConfig = {
  // Static-friendly marketing + legal site. No server data, no env needed.
  reactStrictMode: true,
  // Pin the trace root to this folder so Next doesn't pick up a parent lockfile
  // (the iOS repo lives one level up). Vercel should also set Root Directory =
  // "website" for this project.
  outputFileTracingRoot: path.join(__dirname),
};

export default nextConfig;
