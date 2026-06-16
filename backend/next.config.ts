import type { NextConfig } from 'next';

// API-only Next.js app (route handlers under src/app/api). Deployed on Railway
// with `next start`; the BullMQ worker (src/worker) runs as a second service.
const config: NextConfig = {
  serverExternalPackages: ['bullmq', 'ioredis', 'jsonwebtoken'],
};

export default config;
