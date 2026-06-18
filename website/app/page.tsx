import Link from 'next/link';

export default function Home() {
  return (
    <>
      <section className="hero">
        <p className="eyebrow">Recovery, built to hold</p>
        <h1 className="serif">You stop building on sand.</h1>
        <p className="lede">
          Bedrock helps you break free from compulsive porn use — with on-device
          blocking, someone quietly in your corner, and a lock your weakest
          moment can’t undo.
        </p>
        <a className="btn" href="https://apps.apple.com/app/bedrock">
          Download for iPhone
        </a>
      </section>

      <section className="pillars">
        <div className="pillar">
          <h3>It blocks on your device</h3>
          <p>
            Bedrock uses Apple’s Screen Time controls to keep what pulls you in
            out of reach. The blocking runs on your phone — we never see what you
            browse.
          </p>
        </div>
        <div className="pillar">
          <h3>You hand off the key</h3>
          <p>
            Lock your settings behind a passcode your future self controls — so a
            weak moment can’t quietly undo a strong decision.
          </p>
        </div>
        <div className="pillar">
          <h3>Someone’s in your corner</h3>
          <p>
            Invite a trusted partner. If your phone goes dark when it shouldn’t,
            they get a gentle nudge to check in — never a report card.
          </p>
        </div>
        <div className="pillar">
          <h3>It learns your hardest hour</h3>
          <p>
            Bedrock notices your patterns and is ready before the moment
            arrives — support that shows up on time.
          </p>
        </div>
      </section>

      <section style={{ textAlign: 'center', margin: '24px 0 8px' }}>
        <p style={{ color: 'var(--ash)' }}>
          Questions? Read our{' '}
          <Link href="/privacy">Privacy Policy</Link> and{' '}
          <Link href="/terms">Terms of Service</Link>, or email{' '}
          <a href="mailto:support@thebedrock.app">support@thebedrock.app</a>.
        </p>
      </section>
    </>
  );
}
