import type { Metadata } from 'next';
import Link from 'next/link';
import './globals.css';

const SITE = 'https://thebedrock.app';

export const metadata: Metadata = {
  metadataBase: new URL(SITE),
  title: {
    default: 'Bedrock — the foundation that holds',
    template: '%s · Bedrock',
  },
  description:
    'Bedrock is a recovery tool that helps you break free from compulsive porn use — on-device blocking, an accountability partner, and a lock your weakest moment can’t undo.',
  applicationName: 'Bedrock',
  openGraph: {
    title: 'Bedrock — the foundation that holds',
    description:
      'On-device blocking, an accountability partner, and a lock your weakest moment can’t undo.',
    url: SITE,
    siteName: 'Bedrock',
    type: 'website',
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const year = new Date().getFullYear();
  return (
    <html lang="en">
      <body>
        <header className="site">
          <div className="row">
            <Link className="brand" href="/">
              <span className="mark" aria-hidden />
              <span>Bedrock</span>
            </Link>
            <nav className="site">
              <Link href="/privacy">Privacy</Link>
              <Link href="/terms">Terms</Link>
              <a href="mailto:support@thebedrock.app">Support</a>
            </nav>
          </div>
        </header>

        <main className="shell">{children}</main>

        <footer className="site">
          <div className="row">
            <span>© {year} Bedrock. All rights reserved.</span>
            <nav>
              <Link href="/privacy">Privacy</Link>
              <Link href="/terms">Terms</Link>
              <a href="mailto:support@thebedrock.app">support@thebedrock.app</a>
            </nav>
          </div>
        </footer>
      </body>
    </html>
  );
}
