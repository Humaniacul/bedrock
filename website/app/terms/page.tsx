import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Terms of Service',
  description:
    'The agreement between you and Bedrock — what the app is, what it isn’t, and the rules for using it.',
};

const EFFECTIVE = 'June 18, 2026';

export default function Terms() {
  return (
    <article className="legal">
      <h1 className="serif">Terms of Service</h1>
      <p className="updated">Last updated: {EFFECTIVE}</p>

      <p>
        These Terms of Service (“Terms”) govern your use of the Bedrock app and
        website (“Bedrock,” “we,” “us”). By downloading or using Bedrock, you
        agree to these Terms. If you don’t agree, please don’t use Bedrock.
      </p>

      <h2>1. Who can use Bedrock</h2>
      <p>
        You must be at least 17 years old (or the age of majority where you live,
        if higher) to use Bedrock. By using it, you confirm that you meet this
        requirement.
      </p>

      <h2>2. What Bedrock is — and what it is not</h2>
      <p>
        Bedrock is a self-help and accountability tool to support people working
        to reduce or stop compulsive pornography use. It uses Apple’s Screen Time
        controls and optional partner accountability to make relapse harder.
      </p>
      <div className="callout">
        <p>
          <strong>
            Bedrock is not medical care, therapy, counseling, or a medical
            device.
          </strong>{' '}
          It does not diagnose or treat any condition and is not a substitute for
          professional help. If you are struggling, please consider reaching out
          to a qualified professional. If you are in crisis or thinking about
          harming yourself, contact your local emergency services or a crisis
          line immediately.
        </p>
      </div>

      <h2>3. The blocking feature is best-effort</h2>
      <p>
        Bedrock applies restrictions through Apple’s frameworks and is designed
        to make bypassing difficult — including an optional lock you hand to your
        future self. However,{' '}
        <strong>
          no blocking technology is perfect, and we cannot guarantee that
          restrictions can never be bypassed, disabled, or circumvented
        </strong>
        . Effectiveness depends on your device, iOS version, settings, and your
        own choices. You remain responsible for your behavior and your device.
      </p>

      <h2>4. Your account and responsibilities</h2>
      <ul>
        <li>Keep your device secure; your account is tied to it (and, if you sign in, to your Apple ID).</li>
        <li>Provide accurate information and use Bedrock only for yourself.</li>
        <li>You are responsible for activity that occurs through your account.</li>
      </ul>

      <h2>5. Accountability partners</h2>
      <p>
        If you invite a partner, you authorize Bedrock to share limited status
        information with them as described in our{' '}
        <a href="/privacy">Privacy Policy</a>. Only invite people who consent to
        the role. If you act as a partner for someone else, you agree to treat
        their information respectfully and not to misuse it. Either person can end
        the link at any time.
      </p>

      <h2>6. Subscriptions, billing, and cancellation</h2>
      <ul>
        <li>
          Some features require a paid subscription. Purchases are billed through
          your <strong>Apple App Store</strong> account.
        </li>
        <li>
          Subscriptions <strong>auto-renew</strong> unless cancelled at least 24
          hours before the end of the current period. Your account is charged for
          renewal within 24 hours of the period’s end.
        </li>
        <li>
          You can manage or cancel anytime in{' '}
          <strong>App Store → your account → Subscriptions</strong>. Cancelling
          stops future renewals; it does not retroactively refund the current
          period.
        </li>
        <li>
          Refunds are handled by Apple under the App Store terms. Prices and
          plans may change; we’ll give notice as required.
        </li>
      </ul>

      <h2>7. Acceptable use</h2>
      <p>You agree not to:</p>
      <ul>
        <li>Use Bedrock for any unlawful purpose or to harm or harass another person.</li>
        <li>Attempt to access another user’s account or data.</li>
        <li>Reverse engineer, disrupt, or overload the service, except where such restriction is prohibited by law.</li>
        <li>Misuse the accountability features to surveil or coerce someone without their genuine consent.</li>
      </ul>

      <h2>8. Intellectual property</h2>
      <p>
        Bedrock, its name, design, and content are owned by us and protected by
        intellectual-property laws. We grant you a personal, non-transferable,
        revocable license to use the app for its intended purpose. You may not
        copy, resell, or create derivative works without our permission.
      </p>

      <h2>9. Disclaimers</h2>
      <p>
        Bedrock is provided “as is” and “as available,” without warranties of any
        kind, whether express or implied, including fitness for a particular
        purpose and non-infringement. We do not warrant that the service will be
        uninterrupted, error-free, or that it will prevent any particular
        outcome.
      </p>

      <h2>10. Limitation of liability</h2>
      <p>
        To the fullest extent permitted by law, Bedrock and its team will not be
        liable for any indirect, incidental, special, consequential, or punitive
        damages, or for any loss arising from your use of (or inability to use)
        the app, including any relapse or its consequences. Our total liability
        for any claim will not exceed the amount you paid us in the 12 months
        before the claim. Some jurisdictions don’t allow certain limitations, so
        some of these may not apply to you.
      </p>

      <h2>11. Termination</h2>
      <p>
        You can stop using Bedrock and delete your account at any time from
        Settings. We may suspend or end access if you violate these Terms or to
        protect the service or other users.
      </p>

      <h2>12. Governing law</h2>
      <p>
        These Terms are governed by the laws of{' '}
        <strong>[JURISDICTION]</strong>, without regard to its conflict-of-laws
        rules. Any disputes will be handled in the courts located there, unless
        applicable law gives you the right to bring a claim elsewhere.
      </p>

      <h2>13. Changes to these Terms</h2>
      <p>
        We may update these Terms as Bedrock evolves. We’ll update the date above
        and, for material changes, provide a more prominent notice. Continued use
        after an update means you accept the revised Terms.
      </p>

      <h2>14. Contact</h2>
      <p>
        Questions about these Terms:{' '}
        <a href="mailto:support@thebedrock.app">support@thebedrock.app</a>.
      </p>
    </article>
  );
}
