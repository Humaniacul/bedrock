import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Privacy Policy',
  description:
    'How Bedrock handles your data — what we collect, what we deliberately do not, and the control you have.',
};

const EFFECTIVE = 'June 18, 2026';

export default function Privacy() {
  return (
    <article className="legal">
      <h1 className="serif">Privacy Policy</h1>
      <p className="updated">Last updated: {EFFECTIVE}</p>

      <div className="callout">
        <p>
          Bedrock helps people recover from compulsive pornography use. We treat
          the fact that you use Bedrock — and everything connected to it — as
          deeply sensitive. This policy explains, in plain language, what we
          collect, what we deliberately don’t, and the control you keep.
        </p>
      </div>

      <h2>1. Who we are</h2>
      <p>
        Bedrock (“Bedrock,” “we,” “us”) is the provider of the Bedrock iOS
        application and this website. For privacy questions, or to exercise any
        of the rights below, contact us at{' '}
        <a href="mailto:support@thebedrock.app">support@thebedrock.app</a>. The
        data controller is <strong>[LEGAL ENTITY NAME], [ADDRESS]</strong>.
      </p>

      <h2>2. Our core principle: the blocking stays on your device</h2>
      <p>
        Bedrock’s content blocking runs entirely on your iPhone using Apple’s
        Screen Time frameworks (Family Controls, Managed Settings, Device
        Activity). Because of how Apple designed these frameworks,{' '}
        <strong>
          we cannot see — and never receive — the websites or apps you visit,
          the content you block, or your browsing history
        </strong>
        . That information stays on your device, protected by Apple.
      </p>

      <h2>3. What we collect</h2>
      <h3>Account &amp; identity</h3>
      <ul>
        <li>
          A random <strong>device identifier</strong> and an authentication token
          generated when you first open the app. These let your device talk to
          our server without you creating a username or password.
        </li>
        <li>
          If you choose <strong>Sign in with Apple</strong>: the anonymous
          identifier Apple gives us, your name (only if you share it), and your
          email (only if you share it, which may be Apple’s private relay
          address). This lets your membership and settings follow you to a new
          device.
        </li>
      </ul>

      <h3>Membership &amp; purchases</h3>
      <ul>
        <li>
          Subscriptions are processed by <strong>Apple</strong> and managed
          through <strong>RevenueCat</strong>, our subscription provider. We
          receive your subscription status (active, expired, trial) and product
          identifiers.{' '}
          <strong>
            We never see your card number, billing address, or full payment
            details
          </strong>{' '}
          — Apple handles payment.
        </li>
      </ul>

      <h3>Accountability features (only if you use them)</h3>
      <ul>
        <li>
          <strong>Partner links</strong> you create — the connection between you
          and a person you invite, and the status of that invitation.
        </li>
        <li>
          <strong>Check-in signals (“heartbeats”)</strong> — periodic pings that
          tell us your protection is still active. If your phone goes quiet when
          it shouldn’t (for example, the app is removed or Screen Time is turned
          off), we record that event and may notify your partner so they can
          reach out.
        </li>
        <li>
          A chosen <strong>display name</strong> shown to your partner, and the
          approval requests you send when you ask to change a locked setting.
        </li>
      </ul>

      <h3>Notifications</h3>
      <ul>
        <li>
          If you enable push notifications, Apple gives us a{' '}
          <strong>push token</strong> so we can deliver alerts (for example, to
          notify a partner). We use it only to send Bedrock notifications.
        </li>
      </ul>

      <h3>Technical</h3>
      <ul>
        <li>
          Basic, transient server logs (such as request timing and error
          information) needed to operate and secure the service. We do not build
          advertising profiles.
        </li>
      </ul>

      <h2>4. What we deliberately do not collect</h2>
      <ul>
        <li>The sites or apps you visit, block, or are blocked from.</li>
        <li>Your browsing history or the content of anything on your device.</li>
        <li>Your precise location.</li>
        <li>Your contacts, photos, or messages.</li>
        <li>Advertising identifiers. We do not run ads or sell or rent your data — ever.</li>
      </ul>

      <h2>5. How we use what we collect</h2>
      <ul>
        <li>To operate the app: keep you signed in, sync settings, and apply your protection across devices.</li>
        <li>To run the accountability features you turn on, including notifying a partner you’ve chosen.</li>
        <li>To manage your membership and provide support.</li>
        <li>To keep the service secure and detect abuse.</li>
        <li>To comply with legal obligations.</li>
      </ul>
      <p>
        Our legal bases (where GDPR applies) are <strong>performance of a
        contract</strong> (running the service you signed up for),{' '}
        <strong>consent</strong> (notifications and optional features), and our{' '}
        <strong>legitimate interests</strong> (security and reliability).
      </p>

      <h2>6. Sharing with your accountability partner</h2>
      <p>
        You decide whether to invite a partner. When you do, that person can see
        the limited status information needed for accountability — such as your
        chosen display name and whether your protection has lapsed. They do not
        see your browsing or any blocked content (we don’t have it). You can end
        a partner link at any time in the app.
      </p>

      <h2>7. Service providers (sub-processors)</h2>
      <p>We share data only with the providers that make Bedrock work:</p>
      <ul>
        <li><strong>Apple</strong> — Sign in with Apple, payments, and push delivery (APNs).</li>
        <li><strong>Supabase</strong> — our database, which stores the account and accountability data described above.</li>
        <li><strong>Railway</strong> — hosting for our application servers.</li>
        <li><strong>Upstash</strong> — a queue/cache used to run background checks.</li>
        <li><strong>RevenueCat</strong> — subscription management.</li>
      </ul>
      <p>
        Each processes data on our behalf under its own security and privacy
        commitments. Some may process data outside your country; where required,
        we rely on appropriate safeguards such as Standard Contractual Clauses.
      </p>

      <h2>8. Retention and your control</h2>
      <p>
        We keep your data only as long as your account is active or as needed to
        provide the service.{' '}
        <strong>
          You can delete your account and associated data at any time from
          Settings → Delete account in the app.
        </strong>{' '}
        Deletion removes your account record and the accountability data linked
        to it from our systems. Some information may persist briefly in encrypted
        backups, and Apple or RevenueCat may retain transaction records as
        required by law. You can also email{' '}
        <a href="mailto:support@thebedrock.app">support@thebedrock.app</a> to
        request deletion.
      </p>

      <h2>9. Security</h2>
      <p>
        Data is encrypted in transit. Your device identifier and authentication
        token are stored in the iOS Keychain. Your Screen Time passcode, when you
        choose the lock, is stored on your device — not on our servers. No system
        is perfectly secure, but we work to protect your information using
        industry-standard measures.
      </p>

      <h2>10. Children</h2>
      <p>
        Bedrock is intended for adults and is not directed to children. We do not
        knowingly collect data from anyone under the age required in their region
        (and at least 17). If you believe a minor has provided us data, contact
        us and we will remove it.
      </p>

      <h2>11. Your rights</h2>
      <p>
        Depending on where you live (including under the EU/UK GDPR and the
        California Consumer Privacy Act), you may have the right to access,
        correct, delete, or export your data, to object to or restrict certain
        processing, and to withdraw consent. We do not sell or “share” personal
        information as those terms are defined under California law. To exercise
        any right, email{' '}
        <a href="mailto:support@thebedrock.app">support@thebedrock.app</a>. You
        also have the right to lodge a complaint with your local data protection
        authority.
      </p>

      <h2>12. A note on sensitive information</h2>
      <p>
        Because Bedrock relates to sexual behavior and recovery, your use of it
        may itself be sensitive. We minimize what we collect, never use it for
        advertising, and never sell it. We ask for only what the features you
        choose require.
      </p>

      <h2>13. Changes to this policy</h2>
      <p>
        We may update this policy as the app evolves. We’ll change the “last
        updated” date above and, for material changes, provide a more prominent
        notice. Continued use after an update means you accept the revised
        policy.
      </p>

      <h2>14. Contact</h2>
      <p>
        Questions or requests:{' '}
        <a href="mailto:support@thebedrock.app">support@thebedrock.app</a>.
      </p>
    </article>
  );
}
