// =============================================================================
// Tikéo — Fonction Edge « push-dispatch » (lot 4-2, ADR 0020)
// =============================================================================
// Envoie les messages en attente de `push_outbox` par Firebase Cloud
// Messaging (API HTTP v1). Appelée par l'application juste après une action
// qui crée un message (réponse du support, annonce, contrôle démarré) ;
// sans entrée : un appel ne fait que vider la file, il est donc sans danger.
//
// Secret (Supabase, posé par le déploiement) :
//   FCM_SERVICE_ACCOUNT_B64 : clé du compte de service Firebase, en base64.
// Variables fournies par Supabase : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
// Ni le contenu des messages ni les jetons ne sont écrits dans les journaux.
// =============================================================================

import { createClient } from "npm:@supabase/supabase-js@2";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
};

type Pending = {
  id: number;
  tokens: string[] | null;
  topic_condition: string | null;
  title: string;
  body: string;
  route: string | null;
};

type Target = { token: string } | { condition: string };

const encoder = new TextEncoder();

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const der = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) der[i] = binary.charCodeAt(i);
  return der.buffer;
}

/** Jeton d'accès OAuth 2 (portée Firebase Messaging) du compte de service. */
async function accessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const tokenUri = account.token_uri ?? "https://oauth2.googleapis.com/token";
  const header = base64Url(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64Url(
    encoder.encode(
      JSON.stringify({
        iss: account.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: tokenUri,
        iat: now,
        exp: now + 3600,
      }),
    ),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const unsigned = `${header}.${claims}`;
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(unsigned)),
  );
  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64Url(signature)}`,
    }),
  });
  if (!response.ok) throw new Error(`oauth_${response.status}`);
  const json = await response.json();
  return json.access_token as string;
}

type SendResult = "sent" | "dead" | `retry:${string}`;

async function send(
  account: ServiceAccount,
  bearer: string,
  target: Target,
  message: Pending,
): Promise<SendResult> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: "POST",
      headers: { authorization: `Bearer ${bearer}`, "content-type": "application/json" },
      body: JSON.stringify({
        message: {
          ...target,
          notification: { title: message.title, body: message.body },
          data: message.route ? { route: message.route } : {},
          android: {
            priority: "high",
            notification: { color: "#00C9A7" },
          },
        },
      }),
    },
  );
  if (response.ok) return "sent";
  const text = await response.text();
  // Jeton expiré ou appli désinstallée : à oublier.
  if ("token" in target && (response.status === 404 || text.includes("UNREGISTERED"))) {
    return "dead";
  }
  // Code HTTP et statut Firebase (ex. « 403 PERMISSION_DENIED ») : jamais
  // le jeton ni le contenu.
  // Le détail Firebase (« SENDER_ID_MISMATCH », « THIRD_PARTY_AUTH_ERROR »…)
  // est plus précis que le statut général.
  const code = text.match(/"errorCode"\s*:\s*"([A-Z_]+)"/)?.[1] ??
    text.match(/"status"\s*:\s*"([A-Z_]+)"/)?.[1] ?? "";
  return `retry:fcm_${response.status}${code ? `_${code}` : ""}`;
}

Deno.serve(async (request: Request) => {
  const encoded = Deno.env.get("FCM_SERVICE_ACCOUNT_B64");
  if (!encoded) return Response.json({ skipped: "not_configured" });
  // Attente demandée (notification de test : le temps de mettre l'app en
  // arrière-plan, que le téléphone suspend). 10 s au plus.
  let delay = 0;
  try {
    const body = await request.json();
    delay = Math.min(10, Math.max(0, Number(body?.delay_seconds) || 0));
  } catch (_) {
    // Sans corps : envoi immédiat.
  }
  if (delay > 0) await new Promise((done) => setTimeout(done, delay * 1000));
  const account = JSON.parse(atob(encoded)) as ServiceAccount;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data, error } = await supabase.rpc("push_take_batch", { p_limit: 50 });
  if (error) return Response.json({ error: "take_failed" }, { status: 500 });
  const pending = (data ?? []) as Pending[];
  if (pending.length === 0) return Response.json({ sent: 0 });

  let bearer: string;
  try {
    bearer = await accessToken(account);
  } catch (e) {
    // Clé du compte de service refusée : on le note sur chaque message.
    const reason = `auth_${(e as Error)?.message ?? "unknown"}`.slice(0, 120);
    const failed = Object.fromEntries(pending.map((m) => [String(m.id), reason]));
    await supabase.rpc("push_mark", { p_sent: [], p_failed: failed, p_dead_tokens: [] });
    return Response.json({ error: reason }, { status: 502 });
  }
  const sent: number[] = [];
  const failed: Record<string, string> = {};
  const dead: string[] = [];

  for (const message of pending) {
    try {
      if (message.topic_condition) {
        const result = await send(account, bearer, { condition: message.topic_condition }, message);
        if (result === "sent") sent.push(message.id);
        else failed[String(message.id)] = result.replace(/^retry:/, "");
        continue;
      }
      const tokens = message.tokens ?? [];
      // Aucun appareil : rien à envoyer, le message est clos.
      let delivered = tokens.length === 0;
      let retry: string | null = null;
      for (const token of tokens) {
        const result = await send(account, bearer, { token }, message);
        if (result === "sent") delivered = true;
        else if (result === "dead") dead.push(token);
        else retry = result.replace(/^retry:/, "");
      }
      if (delivered || retry === null) sent.push(message.id);
      else failed[String(message.id)] = retry;
    } catch (e) {
      failed[String(message.id)] = `exception_${(e as Error)?.name ?? "unknown"}`;
    }
  }

  await supabase.rpc("push_mark", { p_sent: sent, p_failed: failed, p_dead_tokens: dead });
  return Response.json({ sent: sent.length, failed: Object.keys(failed).length });
});
