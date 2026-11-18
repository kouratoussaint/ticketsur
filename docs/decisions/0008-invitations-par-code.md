# ADR 0008 — Invitations d'équipe par code à partager

- **Statut** : accepté le 2026-11-18

## Contexte

ORG-02 demande d'inviter des gestionnaires et des contrôleurs. L'envoi d'e-mails par Supabase exige un serveur SMTP personnalisé (le service par défaut est limité et réservé aux tests), et une part importante des échanges des organisateurs passe par WhatsApp et SMS.

## Décision

L'invitation est un **code à partager** `TSI-XXXX-XXXX-XXXX`, créé par `create_invitation` (migration 0800) et transmis par le menu de partage Android ou copié. Le membre invité crée son compte, puis touche « Rejoindre avec un code ».

- 12 symboles parmi 32 (sans 0/O ni 1/I, pour la dictée), soit 60 bits aléatoires (`gen_random_bytes`).
- Le serveur ne conserve que l'**empreinte SHA-256** du code et ses 4 derniers caractères ; le code n'est affiché qu'une fois, à la création.
- Expiration (1 à 30 jours, 7 par défaut), nombre d'utilisations (1 à 100, 1 par défaut), révocation.
- Le propriétaire invite gestionnaires et contrôleurs ; un gestionnaire, des contrôleurs uniquement.
- Essais limités : 10 codes refusés par compte sur 15 minutes. `accept_invitation` renvoie un résultat au lieu de lever une exception, sans quoi l'essai raté serait annulé avec la transaction et ne serait jamais compté.
- Un ancien membre désactivé qui rejoint avec un nouveau code est réactivé avec le rôle de l'invitation.

## Conséquences

- Aucun service externe requis pour constituer une équipe.
- Les invitations par e-mail restent possibles plus tard (SMTP en production) ; elles réutiliseront la même table et la même fonction d'acceptation.
- ORG-03 : désactiver un membre (`update_member`) coupe ses scans dès l'appel suivant, `validate_scan` exigeant une adhésion active.
