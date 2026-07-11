// Supabase Edge Function: notify-turf-hit
// Trigger via Database Webhook on INSERT to turf_hit_notifications,
// or call with service role. Prefers FCM HTTP v1 via FIREBASE_SERVICE_ACCOUNT
// (JSON). Falls back to legacy FCM_SERVER_KEY if set.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create, getNumericDate } from 'https://deno.land/x/djwt@v3.0.2/mod.ts'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

type ServiceAccount = {
  project_id: string
  client_email: string
  private_key: string
  token_uri?: string
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')
  const binary = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0))
  return crypto.subtle.importKey(
    'pkcs8',
    binary,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const key = await importPrivateKey(sa.private_key)
  const jwt = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: sa.client_email,
      sub: sa.client_email,
      aud: sa.token_uri ?? 'https://oauth2.googleapis.com/token',
      iat: getNumericDate(new Date()),
      exp: getNumericDate(3600),
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    },
    key,
  )

  const res = await fetch(sa.token_uri ?? 'https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  if (!res.ok) {
    throw new Error(`token exchange failed: ${res.status} ${await res.text()}`)
  }
  const json = await res.json()
  return json.access_token as string
}

async function sendFcmV1(
  sa: ServiceAccount,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ status: number; body: string }> {
  const accessToken = await getAccessToken(sa)
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: { priority: 'HIGH' },
          apns: {
            headers: { 'apns-priority': '10' },
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    },
  )
  return { status: res.status, body: await res.text() }
}

async function sendFcmLegacy(
  serverKey: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ status: number }> {
  const res = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      Authorization: `key=${serverKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      data,
      priority: 'high',
    }),
  })
  return { status: res.status }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }

  try {
    const payload = await req.json()
    const record = payload.record ?? payload
    const victimId = record.victim_user_id as string | undefined
    const area = Number(record.claimed_area_sq_meters ?? 0)
    if (!victimId) {
      return new Response(JSON.stringify({ ok: false, error: 'missing victim' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: tokens } = await supabase
      .from('push_tokens')
      .select('token')
      .eq('user_id', victimId)

    const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    const fcmKey = Deno.env.get('FCM_SERVER_KEY')
    if ((!saRaw && !fcmKey) || !tokens?.length) {
      return new Response(
        JSON.stringify({
          ok: true,
          skipped: !saRaw && !fcmKey ? 'no_fcm_credentials' : 'no_tokens',
          tokenCount: tokens?.length ?? 0,
        }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      )
    }

    const title = 'TURF HIT'
    const body =
      area > 0
        ? `You lost ${Math.round(area)} m² — reclaim within 24h`
        : 'Reclaim within 24h'
    const data = {
      type: 'turf_hit',
      route: '/territory',
      area_sqm: String(area),
    }

    const sa = saRaw ? (JSON.parse(saRaw) as ServiceAccount) : null
    const results = []
    for (const row of tokens) {
      if (sa) {
        results.push(await sendFcmV1(sa, row.token, title, body, data))
      } else if (fcmKey) {
        results.push(await sendFcmLegacy(fcmKey, row.token, title, body, data))
      }
    }

    return new Response(JSON.stringify({ ok: true, results }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  }
})
