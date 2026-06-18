import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Support someone on Bedrock',
  description:
    'You’ve been invited to stand in someone’s corner. Here’s how to accept.',
};

// The app shares links like thebedrock.app/join/ABC123. The invite is accepted
// inside the app by entering the code — this page just guides the recipient.
export default async function Join({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const clean = (code ?? '').toUpperCase().slice(0, 16);

  return (
    <section className="join">
      <p className="eyebrow">You’ve been asked to help</p>
      <h1 className="serif" style={{ fontSize: 'clamp(30px,6vw,46px)', margin: '0 0 14px' }}>
        Stand in someone’s corner.
      </h1>
      <p style={{ color: 'var(--ash)', maxWidth: 480, margin: '0 auto 8px' }}>
        Someone you know is doing hard, brave work — and they chose you to help
        them stay on solid ground. Here’s your invite code:
      </p>

      <div className="code-chip">{clean || '— — — — — —'}</div>

      <ol className="steps">
        <li>
          Download <strong>Bedrock</strong> from the App Store.
        </li>
        <li>
          Open the app and tap <strong>“Support someone”</strong>.
        </li>
        <li>
          Enter the code above to connect. That’s it — you’re in their corner.
        </li>
      </ol>

      <p style={{ marginTop: 32 }}>
        <a className="btn" href="https://apps.apple.com/app/bedrock">
          Get Bedrock
        </a>
      </p>

      <p style={{ color: 'var(--ash)', fontSize: 14, marginTop: 28 }}>
        Being a partner means showing up with kindness, not judgment. You won’t
        see anything they browse — only whether they need a nudge. Learn more in
        our <a href="/privacy">Privacy Policy</a>.
      </p>
    </section>
  );
}
