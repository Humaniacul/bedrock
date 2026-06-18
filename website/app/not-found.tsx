import Link from 'next/link';

export default function NotFound() {
  return (
    <section className="hero">
      <p className="eyebrow">404</p>
      <h1 className="serif" style={{ fontSize: 'clamp(32px,6vw,48px)' }}>
        Nothing here.
      </h1>
      <p className="lede">That page doesn’t exist — but solid ground does.</p>
      <Link className="btn" href="/">
        Back to Bedrock
      </Link>
    </section>
  );
}
