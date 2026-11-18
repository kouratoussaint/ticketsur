# ADR 0003 — Secrets QR : HMAC pour la recherche, copie chiffrée pour le ré-export

- **Statut** : proposé (Phase 0) — **à arbitrer par le propriétaire du produit**
- **Date** : 2026-11-18

## Contexte

Le cahier demande de ne pas stocker le jeton QR en clair. Mais si la base ne garde qu'une empreinte, aucun organisateur ne pourra **re-télécharger** le PDF d'un billet déjà émis (participant qui a perdu son billet, renvoi par WhatsApp).

## Décision proposée

- **Jeton** : `TS1.` + 43 caractères base64url = 256 bits de `gen_random_bytes` (CSPRNG). Aucun nom, catégorie, montant ni identifiant séquentiel.
- **Recherche** : `HMAC-SHA256(jeton, ticketsur_qr_hmac_key)`, clé dans Supabase Vault. Une fuite de la table seule ne permet pas de retrouver ni de tester des jetons.
- **Ré-export** : copie chiffrée (`pgp_sym_encrypt`, AES-256, clé Vault **distincte**), stockée dans `private.ticket_secrets`, schéma non exposé à l'API. Seule une future fonction `export_ticket` (owner/manager, auditée) la déchiffrera.
- **Référence publique** imprimée : `TS-XXXX-XXXX` aléatoire (40 bits), distincte du secret, sans révéler le volume émis.

## Alternative

Pas de copie chiffrée : le ré-export devient « révoquer + émettre un nouveau billet ». Plus strict, mais chaque perte de billet invalide le QR déjà partagé.

## Conséquences

- La rotation de `ticketsur_qr_hmac_key` invaliderait tous les billets : elle est réservée aux incidents, avec ré-émission.
- Les deux clés doivent être créées dans Vault sur chaque projet (staging, production) avant la première émission.
