# ADR 0037 — Double authentification des administrateurs (proposée)

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (« seulement proposer », 21/11)

## Contexte

La console donne la main sur tous les comptes, structures et paiements. Un mot de passe seul la protège. Supabase Auth fournit sans frais des facteurs TOTP (code à 6 chiffres d'une application d'authentification).

## Décisions

1. **Proposée, pas obligatoire** : ligne « Double authentification » dans Profil › Sécurité, visible des seuls administrateurs. Activation : QR code (`otpauth://`) ou clé à saisir, puis code à 6 chiffres (`challengeAndVerify`) ; la session passe au niveau `aal2`.
2. **Côté serveur** (migration 4800) : `private.is_platform_admin()` et `private.require_platform_admin()` exigent une session `aal2` (claim `aal` du jeton) **dès que le compte a un facteur vérifié** (`auth.mfa_factors`) ; sinon `mfa_required`. Sans facteur, rien ne change. `public.is_platform_admin()` reste vrai à `aal1` pour afficher l'entrée « Console ».
3. **Console** : à l'ouverture, si `mfa_required`, une carte demande le code (une fois par session : la session garde `aal2` jusqu'à la déconnexion).
4. **Codes de secours** : 8 codes `XXXXX-XXXXX` générés après l'activation (`admin_generate_recovery_codes`, `aal2` exigé), affichés une seule fois, gardés en empreinte SHA-256. `admin_use_recovery_code` (à `aal1`) retire les facteurs du compte (la console se rouvre ; la double authentification est à réactiver) ; 5 essais par heure ; un code inconnu renvoie faux (l'essai reste compté).
5. **Désactivation** : depuis la page, à `aal2` seulement (`mfa.unenroll`).
6. Journal : `admin.mfa_codes_generated` `{count}` et `admin.mfa_recovered` `{}` ; jamais de code ni de clé.

## Conséquences

- Aucun coût (TOTP inclus dans Supabase Auth, activé par défaut sur les projets).
- À vérifier sur téléphone : activation avec Google Authenticator, ouverture de la console sur un second téléphone (code demandé), code de secours.
