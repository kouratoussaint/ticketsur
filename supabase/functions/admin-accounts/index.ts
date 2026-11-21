// =============================================================================
// Tikéo — Fonction Edge « admin-accounts » (lot 4-11a, ADR 0038)
// =============================================================================
// Opérations de la console qui touchent l'authentification Supabase et
// demandent la clé serveur : créer un compte, donner un mot de passe
// provisoire, changer l'adresse e-mail.
//
// 1. Contrôle avec le jeton de l'administrateur : `admin_account_guard`
//    (rôle, double authentification, compte visé).
// 2. Opération d'authentification avec la clé serveur (fournie par Supabase
//    aux fonctions : jamais dans l'app, GitHub ou le chat).
// 3. Enregistrement avec le jeton de l'administrateur (journal, motif,
//    mot de passe à changer, notification).
//
// Le mot de passe provisoire n'est renvoyé qu'une fois, dans la réponse ;
// il n'est jamais écrit dans les journaux. Réponses : { ok: true, … } ou
// { ok: false, code } avec un code stable (comme les erreurs SQL).
// =============================================================================

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

type Body = {
  action?: string;
  user_id?: string;
  email?: string;
  display_name?: string;
  phone?: string | null;
  reason?: string;
  notify?: boolean | null;
};

// Sans 0/O, 1/l/I : lisible au téléphone.
const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";

/** Mot de passe provisoire : 3 groupes de 4, ex. « Hq7m-2KzP-x9Rw ». */
export function temporaryPassword(): string {
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  const chars = Array.from(bytes, (b) => ALPHABET[b % ALPHABET.length]);
  return [chars.slice(0, 4), chars.slice(4, 8), chars.slice(8, 12)]
    .map((group) => group.join(""))
    .join("-");
}

function reply(status: number, payload: Record<string, unknown>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function failure(code: string, status = 400): Response {
  return reply(status, { ok: false, code });
}

/** Code stable d'une erreur PostgREST (MESSAGE de l'erreur SQL). */
function sqlCode(error: { message?: string } | null): string {
  return error?.message?.trim() || "unknown";
}

function authCode(error: { code?: string; status?: number } | null): string {
  if (!error) return "unknown";
  if (error.code === "email_exists" || error.code === "user_already_exists") {
    return "account_email_taken";
  }
  if (error.code === "email_address_invalid" || error.code === "validation_failed") {
    return "account_email_invalid";
  }
  if (error.code === "weak_password") return "password_weak";
  return "auth_failed";
}

function cleanEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const email = value.trim().toLowerCase();
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) && email.length <= 254 ? email : null;
}

async function create(caller: SupabaseClient, admin: SupabaseClient, body: Body) {
  const email = cleanEmail(body.email);
  const name = (body.display_name ?? "").trim().replace(/\s+/g, " ");
  if (!email) return failure("account_email_invalid");
  if (name.length < 2 || name.length > 60) return failure("profile_name_invalid");
  if ((body.reason ?? "").trim().length < 3) return failure("reason_required");

  const guard = await caller.rpc("admin_account_guard", {
    p_action: "create",
    p_user_id: null,
    p_phone: body.phone ?? null,
  });
  if (guard.error) return failure(sqlCode(guard.error), 403);

  const password = temporaryPassword();
  const created = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { display_name: name },
  });
  if (created.error || !created.data.user) return failure(authCode(created.error));
  const userId = created.data.user.id;

  const recorded = await caller.rpc("admin_record_account_created", {
    p_user_id: userId,
    p_phone: body.phone ?? null,
    p_reason: body.reason,
  });
  if (recorded.error) {
    // Rien d'enregistré : le compte d'authentification est retiré.
    await admin.auth.admin.deleteUser(userId);
    return failure(sqlCode(recorded.error));
  }
  return reply(200, { ok: true, user_id: userId, password });
}

async function resetPassword(caller: SupabaseClient, admin: SupabaseClient, body: Body) {
  if (!body.user_id) return failure("account_not_found");
  if ((body.reason ?? "").trim().length < 3) return failure("reason_required");
  const guard = await caller.rpc("admin_account_guard", {
    p_action: "password",
    p_user_id: body.user_id,
  });
  if (guard.error) return failure(sqlCode(guard.error), 403);

  const password = temporaryPassword();
  const updated = await admin.auth.admin.updateUserById(body.user_id, { password });
  if (updated.error) return failure(authCode(updated.error));

  const recorded = await caller.rpc("admin_record_password_reset", {
    p_user_id: body.user_id,
    p_reason: body.reason,
    p_notify: body.notify ?? null,
  });
  if (recorded.error) return failure(sqlCode(recorded.error));
  return reply(200, { ok: true, password });
}

async function changeEmail(caller: SupabaseClient, admin: SupabaseClient, body: Body) {
  const email = cleanEmail(body.email);
  if (!body.user_id) return failure("account_not_found");
  if (!email) return failure("account_email_invalid");
  if ((body.reason ?? "").trim().length < 3) return failure("reason_required");
  const guard = await caller.rpc("admin_account_guard", {
    p_action: "email",
    p_user_id: body.user_id,
  });
  if (guard.error) return failure(sqlCode(guard.error), 403);

  const updated = await admin.auth.admin.updateUserById(body.user_id, {
    email,
    email_confirm: true,
  });
  if (updated.error) return failure(authCode(updated.error));

  const recorded = await caller.rpc("admin_record_email_changed", {
    p_user_id: body.user_id,
    p_reason: body.reason,
    p_notify: body.notify ?? null,
  });
  if (recorded.error) return failure(sqlCode(recorded.error));
  return reply(200, { ok: true });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return failure("method_not_allowed", 405);
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return failure("forbidden", 401);

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anonKey || !serviceKey) return failure("not_configured", 500);

  let body: Body;
  try {
    body = await request.json();
  } catch {
    return failure("action_invalid");
  }

  const options = { auth: { persistSession: false, autoRefreshToken: false } };
  // Jeton de l'administrateur : contrôles et journal à son nom.
  const caller = createClient(url, anonKey, {
    ...options,
    global: { headers: { Authorization: authorization } },
  });
  const admin = createClient(url, serviceKey, options);

  try {
    switch (body.action) {
      case "create":
        return await create(caller, admin, body);
      case "password":
        return await resetPassword(caller, admin, body);
      case "email":
        return await changeEmail(caller, admin, body);
      default:
        return failure("action_invalid");
    }
  } catch (_error) {
    // Rien du corps de la requête dans les journaux (mot de passe, e-mail).
    console.error("admin-accounts: erreur inattendue");
    return failure("unknown", 500);
  }
});
