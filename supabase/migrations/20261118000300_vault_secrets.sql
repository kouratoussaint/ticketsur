-- =============================================================================
-- TicketSûr — Migration 0300 : clés de sécurité des QR dans Supabase Vault
-- =============================================================================
-- Les deux clés sont générées ICI, par le serveur, au moment où la migration
-- s'applique : leur valeur n'apparaît jamais dans le dépôt, les journaux de
-- CI ni le chat. Chaque environnement (local, staging, production) reçoit ses
-- propres clés. Migration idempotente : une clé existante n'est jamais
-- remplacée (une rotation de la clé HMAC invaliderait tous les billets émis).
-- =============================================================================

do $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name = 'ticketsur_qr_hmac_key') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'ticketsur_qr_hmac_key',
      'TicketSûr : poivre HMAC-SHA256 des jetons QR (ne jamais faire tourner sans ré-émission)'
    );
  end if;

  if not exists (select 1 from vault.decrypted_secrets where name = 'ticketsur_qr_encryption_key') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'ticketsur_qr_encryption_key',
      'TicketSûr : clé de chiffrement des copies de jetons (re-téléchargement audité)'
    );
  end if;
end $$;
