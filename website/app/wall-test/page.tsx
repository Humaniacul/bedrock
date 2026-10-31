import type { Metadata } from 'next';

// The page the app's S4 opens to prove the wall holds. Served at
// test.thebedrock.app (see next.config.ts). The app adds this domain to the
// Screen Time web filter on S3, so with the wall up this page never loads: iOS
// shows its own restriction page instead. The <title> is the marker the app's
// background check looks for — if it can read it, the page got through.
// Keep the title exactly “Bedrock wall test”.
export const metadata: Metadata = {
  title: { absolute: 'Bedrock wall test' },
  robots: { index: false, follow: false },
};

export default function WallTest() {
  return (
    <section className="join">
      <p className="eyebrow">Wall test</p>
      <h1 className="serif" style={{ fontSize: 'clamp(30px,6vw,46px)', margin: '0 0 14px' }}>
        This page got through.
      </h1>
      <p style={{ color: 'var(--ash)', maxWidth: 480, margin: '0 auto' }}>
        If you’re seeing this in Bedrock’s test, the wall isn’t holding on this
        iPhone yet. Go back to Bedrock and put it back up.
      </p>
    </section>
  );
}
