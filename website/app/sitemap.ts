import type { MetadataRoute } from 'next';

const SITE = 'https://thebedrock.app';

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  return [
    { url: `${SITE}/`, lastModified: now, priority: 1 },
    { url: `${SITE}/privacy`, lastModified: now, priority: 0.5 },
    { url: `${SITE}/terms`, lastModified: now, priority: 0.5 },
  ];
}
