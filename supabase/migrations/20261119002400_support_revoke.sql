-- =============================================================================
-- Tikéo — Migration 2400 : aucun droit direct sur les tables du support et
-- des annonces (correctif de la migration 2300, ADR 0017)
-- =============================================================================
-- Sur Supabase, les privilèges par défaut du schéma public accordent les
-- tables nouvelles à anon et authenticated. La RLS sans politique les fermait
-- déjà, mais le contrôle de configuration exige qu'anon n'ait aucun droit :
-- tout passe par les fonctions de la migration 2300.
-- =============================================================================

revoke all on public.support_requests from anon, authenticated;
revoke all on public.support_messages from anon, authenticated;
revoke all on public.announcements from anon, authenticated;
revoke all on sequence public.support_messages_seq_seq from anon, authenticated;
