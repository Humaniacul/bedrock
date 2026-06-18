import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Support someone on Bedrock',
};

// Fallback when someone lands on /join without a code.
export default function JoinIndex() {
  return (
    <section className="join">
      <p className="eyebrow">Support someone</p>
      <h1 className="serif" style={{ fontSize: 'clamp(30px,6vw,46px)', margin: '0 0 14px' }}>
        You need an invite code.
      </h1>
      <p style={{ color: 'var(--ash)', maxWidth: 460, margin: '0 auto 28px' }}>
        Ask the person who invited you for their Bedrock link or code, then open
        the app, tap <strong>“Support someone”</strong>, and enter it.
      </p>
      <a className="btn" href="https://apps.apple.com/app/bedrock">
        Get Bedrock
      </a>
    </section>
  );
}
