import http2 from 'node:http2';
import jwt from 'jsonwebtoken';

// Token-based APNs (HTTP/2 + ES256 JWT from a .p8 key). No native deps.
// If APNs isn't configured yet, sends are a no-op so the rest of the API works
// (deploy-ready). Supply APNS_KEY_P8 / APNS_KEY_ID / APNS_TEAM_ID to enable.

let cached: { token: string; iat: number } | null = null;

function providerToken(): string {
  const keyId = process.env.APNS_KEY_ID!;
  const teamId = process.env.APNS_TEAM_ID!;
  const key = (process.env.APNS_KEY_P8 ?? '').replace(/\\n/g, '\n');
  const now = Math.floor(Date.now() / 1000);
  if (cached && now - cached.iat < 3000) return cached.token;
  const token = jwt.sign({ iss: teamId, iat: now }, key, {
    algorithm: 'ES256',
    header: { alg: 'ES256', kid: keyId },
  });
  cached = { token, iat: now };
  return token;
}

export async function sendPush(apnsToken: string, title: string, body: string): Promise<void> {
  if (!process.env.APNS_KEY_P8 || !apnsToken) return; // not configured — no-op
  const host = process.env.APNS_HOST ?? 'https://api.push.apple.com';
  const topic = process.env.APNS_BUNDLE_ID ?? 'com.thebedrock.app';

  await new Promise<void>((resolve, reject) => {
    const conn = http2.connect(host);
    const payload = JSON.stringify({ aps: { alert: { title, body }, sound: 'default' } });
    const request = conn.request({
      ':method': 'POST',
      ':path': `/3/device/${apnsToken}`,
      authorization: `bearer ${providerToken()}`,
      'apns-topic': topic,
      'apns-push-type': 'alert',
    });
    request.setEncoding('utf8');
    request.on('end', () => {
      conn.close();
      resolve();
    });
    request.on('error', (e) => {
      conn.close();
      reject(e);
    });
    request.write(payload);
    request.end();
  });
}
