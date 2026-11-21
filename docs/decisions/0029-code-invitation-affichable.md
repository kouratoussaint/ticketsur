# ADR 0029 — Code d'invitation affichable

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (demande du 20/11/2026, #5, décision du 21/11)
- Référence : doc du projet `claude/ameliorations-2026-11-20.md`, section 5, PR 3 — Écrans

## Contexte

Jusqu'ici (`20261118000800_team.sql`), une invitation ne gardait que l'empreinte de son code (`code_hash`) et ses 4 derniers caractères (`code_hint`) : le code complet était montré une seule fois, à la création (« il ne sera plus jamais affiché »). Toussaint veut, depuis l'Équipe, ouvrir une invitation et réafficher son code avec une icône œil pour le renvoyer.

## Décisions

1. **Copie chiffrée** : nouvelle colonne `organization_invitations.code_ciphertext`, remplie par `create_invitation` avec la même méthode que la copie chiffrée des jetons QR (ADR 0003 : `pgp_sym_encrypt`, AES-256, clé `ticketsur_qr_encryption_key` dans Vault, jamais dans l'app). `code_hash` reste la seule chose utilisée pour vérifier un code à l'entrée.
2. **`invitation_details(id)`** : rôle, état (active, expirée, révoquée, épuisée), indice, code récupérable ou non, structure, créée par, créée le, valable jusqu'au, utilisations x / y, personnes qui l'ont utilisée (lues dans le journal `invitation.accepted`). Réservée à qui peut gérer ce rôle (propriétaire ; gestionnaire pour les contrôleurs).
3. **`reveal_invitation_code(id)`** : mêmes droits, invitation **active** seulement ; **30 affichages par heure** et par compte ; chaque affichage est inscrit au journal (`invitation.code_revealed`, sans le code ni donnée personnelle).
4. **App** : feuille « Invitation » à l'appui sur une ligne ; code masqué par défaut (`TSI-••••-••••-K7QP`) ; l'œil appelle la fonction et affiche le code ; Copier et Partager (même message qu'à la création). Le code n'est gardé qu'en mémoire le temps de la feuille, jamais en cache ni dans les journaux de l'app.
5. **Invitations créées avant ce changement** : pas de copie chiffrée → « Code non récupérable : créez une nouvelle invitation ».
6. Le texte de création devient « Partagez-le maintenant. Vous pourrez le retrouver dans les détails de l'invitation tant qu'elle est active. »

## Conséquences

- Compromis de sécurité accepté : un code d'invitation active peut être relu par un gestionnaire autorisé ; il reste chiffré dans la base, l'accès est limité et journalisé, et il disparaît de fait à l'expiration, à la révocation ou à l'épuisement.
- Aucun coût ni compte externe.
