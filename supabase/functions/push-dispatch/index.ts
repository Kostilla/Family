// Supabase Edge Function base para FCM HTTP v1
// Requiere secrets:
// - FCM_PROJECT_ID
// - FCM_CLIENT_EMAIL
// - FCM_PRIVATE_KEY
//
// Invocación esperada:
// { "family_id": "...", "title": "...", "body": "...", "data": { "route": "/tasks" } }

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { encodeBase64 } from 'https://deno.land/std@0.224.0/encoding/base64.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

type PushBody = {
  family_id: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  user_id?: string | null;
};

function pemToDerBase64(pem: string) {
  return pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '')
    .replace(/\s+/g, '');
}

async function getAccessToken() {
  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')!;
  const privateKey = Deno.env.get('FCM_PRIVATE_KEY')!;
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();
  const h = encodeBase64(JSON.stringify(header)).replace(/=+$/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const p = encodeBase64(JSON.stringify(payload)).replace(/=+$/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const toSign = `${h}.${p}`;

  const keyData = Uint8Array.from(atob(pemToDerBase64(privateKey)), c => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, encoder.encode(toSign));
  const s = encodeBase64(new Uint8Array(signature)).replace(/=+$/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const assertion = `${toSign}.${s}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const json = await res.json();
  return json.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const body = (await req.json()) as PushBody;
  const projectId = Deno.env.get('FCM_PROJECT_ID')!;

  let query = supabase
    .from('device_tokens')
    .select('token,user_id');

  if (body.user_id) {
    query = query.eq('user_id', body.user_id);
  } else {
    const { data: members } = await supabase
      .from('family_members')
      .select('user_id')
      .eq('family_id', body.family_id);

    const ids = (members ?? []).map((m: { user_id: string }) => m.user_id);
    query = query.in('user_id', ids);
  }

  const { data: tokens, error } = await query;
  if (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }

  const accessToken = await getAccessToken();

  const results = [];
  for (const row of tokens ?? []) {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: row.token,
          notification: {
            title: body.title,
            body: body.body,
          },
          data: body.data ?? {},
        },
      }),
    });

    results.push({
      token: row.token,
      status: res.status,
      body: await res.text(),
    });
  }

  return Response.json({ ok: true, count: results.length, results });
});
