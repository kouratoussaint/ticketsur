---
title: "TicketSûr — Cahier des charges fonctionnel et technique"
subtitle: "Application Android-first de billetterie événementielle et de contrôle d’accès par QR code"
author: "Document de cadrage produit et technique"
date: "18 novembre 2026"
lang: fr-FR
---

> Marque renommée **Tikéo** le 19 novembre 2026 (ADR 0011) ; ce cahier des charges garde l'ancien nom.

![Identité de marque Tikéo](../../apps/mobile/assets/branding/Tikeo_Logo.png){width=5.9in}

# TICKETSÛR

**Cahier des charges fonctionnel, technique, UX/UI, sécurité et déploiement**  
**Signature officielle :** « Votre événement en un clic »  
**Version :** 1.0 — cadrage de référence  
**Plateforme prioritaire :** Android  
**Développement et collaboration :** Claude + GitHub  
**Statut :** document de conception à valider avant implémentation

\newpage

# Synthèse exécutive

**TicketSûr** est une application Android de création, distribution et vérification de tickets d’événements. Chaque billet dispose d’un QR code individuel à usage unique. Un contrôleur autorisé le scanne : le serveur vérifie l'événement, les droits du contrôleur et l'état du billet ; si les conditions sont réunies, la validation est inscrite dans une transaction atomique. Le QR est alors considéré comme utilisé. Toute tentative ultérieure est refusée avec indication de la date et de l'heure de la **première validation effective**, selon les permissions de consultation.

La plateforme a vocation à servir plusieurs organisations indépendantes. L'**organisateur** travaille dans son espace, crée ses événements, catégories, lots de tickets et équipes ; le **contrôleur** utilise un parcours de scan simplifié ; le **superadministrateur** supervise la plateforme sans exposer inutilement les données personnelles.

**Décisions de référence :**

| Domaine | Décision | Justification |
|---|---|---|
| Application principale | Flutter / Dart, Android d’abord | Une base mobile maintenable, extensible vers iOS |
| UI | Material 3 personnalisé TicketSûr | Cohérence, lisibilité et accessibilité |
| Services | Supabase Auth, PostgreSQL, Storage, fonctions de service | Accélération du MVP ; architecture évolutive |
| Contrôle d’entrée | Validation **côté serveur**, transaction PostgreSQL | Empêcher deux validations simultanées |
| QR code | Jeton opaque, aléatoire, à forte entropie ; aucune donnée personnelle | Réduction de la falsification et des divulgations |
| Connexion | **En ligne obligatoire** pour valider dans le MVP | Évite les incohérences multi-portes |
| Code source | Dépôt privé GitHub, pull requests, GitHub Actions | Traçabilité, qualité et automatisation |
| Distribution | APK signé pour tests ; AAB signé pour Google Play | Tester rapidement, publier proprement |
| Produit | Multi-organisations dès le modèle de données | Évite une refonte ultérieure du SaaS |

**Limite à communiquer honnêtement :** un QR unique n'empêche pas une copie photographique. Il garantit, avec le serveur transactionnel, qu'une seule copie sera acceptée. Une personne qui obtient frauduleusement le QR avant son propriétaire peut encore se présenter la première. Des contrôles complémentaires sont envisageables pour les événements sensibles.

# 1. Identité du projet

| Élément | Spécification |
|---|---|
| Nom de marque | **TicketSûr** (accent circonflexe obligatoire dans l'interface) |
| Slogan | **Votre événement en un clic** |
| Nom technique | `ticketsur` |
| Domaine fonctionnel | Billetterie événementielle et contrôle d'accès |
| Public principal | Organisateurs, gestionnaires, contrôleurs d'accès |
| Zone de lancement visée | Burkina Faso ; internationalisation possible |
| Langue initiale | Français ; architecture prête pour traductions |
| Appareils cibles | Smartphones Android, y compris appareils modestes |
| Mode de vente initial | Hors périmètre du MVP : pas de paiement intégré |
| Date du cadrage | 18 novembre 2026 |

## 1.1 Problématique

Les billets imprimés ou partagés par messagerie peuvent être copiés, modifiés ou présentés plusieurs fois. Les contrôles purement visuels ne suffisent pas à distinguer l'original d'une copie. Les outils complexes ralentissent l'entrée et obligent parfois les organisateurs à employer plusieurs systèmes indépendants.

## 1.2 Proposition de valeur

- Pour l'organisateur : création, suivi et contrôle depuis une même application Android.
- Pour le contrôleur : scan sans menu superflu, réponse explicite et historique contextualisé.
- Pour le participant : ticket simple à conserver au format image ou PDF, sans compte obligatoire au MVP.
- Pour le gestionnaire de plateforme : séparation stricte des organisations et visibilité sur l'exploitation.

## 1.3 Objectifs

1. Empêcher la **double validation** d'un même billet à usage unique.
2. Réduire le temps de contrôle à l'entrée, sans sacrifier la sûreté.
3. Disposer d'une traçabilité exploitable des validations et refus.
4. Permettre à plusieurs contrôleurs et portes d'opérer en parallèle.
5. Créer une base de produit commercial multi-organisateurs.

## 1.4 Indicateurs de succès proposés

| Indicateur | Cible de recette initiale (à mesurer, non garantie) |
|---|---|
| Double acceptation d'un même billet | **0** sur les tests de concurrence définis |
| Exactitude des statuts de scan | 100 % des scénarios de recette validés |
| Latence de validation, connexion stable | P95 inférieur à 2 s dans l'environnement de test retenu |
| Démarrage du scanner à chaud | Objectif inférieur à 1,5 s sur appareil de référence |
| Tickets générés dans un lot test | 10 000 sans collision d'identifiant |
| Contrôleurs simultanés en test | 20, ajustable selon plan de charge |
| Messages d'erreur expliqués | 100 % des états critiques couverts |
| Accessibilité | Contrastes vérifiés ; couleurs jamais seuls signaux |

# 2. Périmètre et versions

## 2.1 MVP — inclus

- Comptes, connexion, récupération du mot de passe et gestion des sessions.
- Organisations, membres et rôles ; cloisonnement multi-organisateurs.
- Création, publication, modification contrôlée et clôture d'événements.
- Catégories de tickets ; création unitaire et en lots.
- QR opaque à forte entropie ; génération et téléchargement PDF/image.
- Partage natif d'un ticket et export de lots, sous règles d'accès.
- Points d'entrée et affectation des contrôleurs.
- Scanner Android ; retour visuel, haptique et sonore paramétrable.
- Validation atomique et irréversible en usage normal.
- Détection des tickets déjà utilisés, révoqués, inconnus ou hors événement.
- Historique des scans, liste de tickets, recherche et filtres.
- Statistiques simples en temps réel ou quasi réel, avec rafraîchissement manuel.
- Journal d'audit des actions d'administration ; suivi des erreurs techniques.
- Déploiement de préproduction, builds Android et pipeline GitHub.

## 2.2 Post-MVP — priorités futures

| Évolution | Priorité envisagée | Dépendance |
|---|---|---|
| Back-office web responsive | V1.1 | API et permissions stabilisées |
| Envoi automatisé de tickets par email/WhatsApp via fournisseurs autorisés | V1.1 | Consentements et coûts |
| Invitations nominatives et contrôle d'identité optionnel | V1.1 | Réglementation et vie privée |
| Billets multi-entrées / réadmission / pass par zone | V2 | Nouveau moteur de règles d'accès |
| Paiements mobile money et achats en ligne | V2 | Fournisseurs, conformité et rapprochement |
| Impression thermique et badges | V2 | Matériel et pilotes |
| Mode hors ligne coordonné | Étude préalable | Risque de double entrée multi-appareils |
| iOS et PWA grand public | V2 | Demande et ressources |
| Webhooks, API partenaires, facturation SaaS | V2 | Gestion des contrats et sécurité |

## 2.3 Exclus du MVP

Vente de billets, portefeuille de paiement, remboursement financier, géolocalisation des participants, reconnaissance faciale, contrôle biométrique, scanner hors ligne permettant une acceptation définitive et place de marché publique d'événements.

# 3. Parties prenantes, rôles et droits

## 3.1 Rôles

**Superadministrateur plateforme :** gère la disponibilité et les organisations, traite les incidents, sans accès libre par défaut aux données nominatives des participants.

**Propriétaire d'organisation :** crée l'espace, gère les administrateurs et les paramètres, consulte les statistiques de ses événements.

**Gestionnaire / organisateur :** crée et gère les événements, catégories, tickets et affectations selon ses habilitations.

**Contrôleur :** voit uniquement les événements et points d'accès qui lui sont attribués ; effectue des scans ; lit les informations strictement utiles au contrôle.

**Participant :** ne requiert pas de compte dans le MVP ; reçoit son ticket par un canal choisi par l'organisateur.

## 3.2 Matrice simplifiée des permissions

| Action | Superadmin | Propriétaire | Gestionnaire | Contrôleur |
|---|---|---|---|---|
| Gérer organisations de la plateforme | Oui | Non | Non | Non |
| Gérer son organisation | Encadré | Oui | Selon droit | Non |
| Créer / modifier un événement | Non par défaut | Oui | Oui | Non |
| Créer / révoquer un ticket | Non par défaut | Oui | Oui | Non |
| Gérer les contrôleurs | Non par défaut | Oui | Selon droit | Non |
| Effectuer un scan | Seulement si affecté | Si affecté | Si affecté | Oui si affecté |
| Consulter historique de l'événement | Support restreint | Oui | Oui | Limité |
| Exporter données personnelles | Sous procédure | Selon rôle | Selon rôle | Non |

**Règle fondamentale :** ne jamais déduire les droits d'un simple champ de rôle côté mobile ; chaque requête est autorisée côté serveur en tenant compte de l'organisation, de l'événement, du point d'entrée, de l'état du compte et du jeton de session.

# 4. Parcours fonctionnels

## 4.1 Parcours organisateur

1. Ouvre TicketSûr et se connecte.
2. Crée ou rejoint une organisation.
3. Crée un événement : titre, lieu, fuseau, dates, capacité et visuel.
4. Ajoute les catégories (Standard, VIP, Invitation, etc.).
5. Génère des billets par unité ou par lots, dans la limite des quotas configurés.
6. Distribue le PDF ou l'image du billet au participant.
7. Ajoute des contrôleurs et leurs points d'entrée.
8. Suit les validations et les refus pendant l'événement.
9. Exporte le bilan et clôture l'événement.

## 4.2 Parcours contrôleur

1. Se connecte sur un téléphone autorisé.
2. Sélectionne l'événement auquel il a accès.
3. Choisit son point de contrôle, si plusieurs affectations existent.
4. Ouvre la caméra et scanne un QR.
5. Attend le verdict **serveur**. Aucun écran vert anticipé.
6. Voit une réponse pleine page : valide, déjà utilisé, refusé ou indéterminé.
7. Le scanner se réarme selon une règle UX évitant les scans répétés involontaires.
8. En cas d'erreur réseau, l'agent ne laisse pas entrer sur la base de l'application seule.

## 4.3 Parcours participant

Le participant reçoit un ticket lisible, le conserve ou l'imprime, puis présente son QR à un contrôleur. La création d'un compte participant n'est pas requise. Les instructions accompagnant le billet précisent qu'une copie du QR pourrait être utilisée avant le détenteur légitime : il faut donc éviter de le publier publiquement.

# 5. Exigences fonctionnelles détaillées

## 5.1 Comptes et organisations

| ID | Exigence | Priorité | Critère d'acceptation |
|---|---|---|---|
| AUTH-01 | Connexion email/mot de passe | P0 | Session chiffrée, erreurs génériques |
| AUTH-02 | Réinitialisation du mot de passe | P0 | Flux vérifié, jetons expirables |
| AUTH-03 | Déconnexion et révocation des sessions | P0 | Accès refusé après révocation |
| ORG-01 | Création et isolation d'organisation | P0 | Aucune lecture inter-organisations |
| ORG-02 | Invitation des gestionnaires et contrôleurs | P0 | Invitation à usage défini, rôles assignés |
| ORG-03 | Désactivation immédiate d'un contrôleur | P0 | Scan refusé au prochain appel serveur |
| ORG-04 | Paramètres du profil et préférences | P1 | Données limitées au périmètre autorisé |

## 5.2 Événements et tickets

| ID | Exigence | Priorité | Critère d'acceptation |
|---|---|---|---|
| EVT-01 | Créer, éditer, publier, clôturer | P0 | Transitions contrôlées côté serveur |
| EVT-02 | Fuseau horaire par événement | P0 | Enregistrement UTC, affichage local cohérent |
| EVT-03 | Catégories et capacités | P0 | Compteurs et limites transactionnels |
| EVT-04 | Points de contrôle | P0 | Affectations vérifiées au scan |
| TIC-01 | Ticket individuel et lot | P0 | Aucun jeton dupliqué |
| TIC-02 | QR opaque sans donnée personnelle | P0 | Décodage QR n'expose que le jeton/adresse contrôlée |
| TIC-03 | Export PDF/image | P0 | QR réellement lisible par scanner |
| TIC-04 | Révocation d'un ticket | P0 | Toute tentative suivante est refusée |
| TIC-05 | Recherche par référence publique | P1 | Aucun accès au secret du ticket |
| TIC-06 | Import CSV facultatif | P1 | Contrôle des doublons et erreurs de format |
| TIC-07 | Annulation / régénération contrôlée | P1 | Ancien QR révoqué, opération auditée |

## 5.3 Scan, tableaux de bord et historiques

| ID | Exigence | Priorité | Critère d'acceptation |
|---|---|---|---|
| SCN-01 | Scanner caméra Android | P0 | Permissions contextualisées, mise au point |
| SCN-02 | Premier scan accepté au serveur | P0 | Ticket consommé une fois, en transaction |
| SCN-03 | Second scan : refus + horodatage | P0 | Date et heure initiales correctes |
| SCN-04 | Simultanéité multi-appareils | P0 | Une seule validation gagnante |
| SCN-05 | Indisponibilité du réseau = indéterminé | P0 | Aucun faux message de validité |
| SCN-06 | Événement, affectation et point d'entrée | P0 | Rejet si périmètre non autorisé |
| SCN-07 | Anti double-déclenchement caméra | P0 | Un scan en vol à la fois par appareil |
| SCN-08 | Tentative horodatée et tracée | P0 | Historique explicite même en refus |
| SCN-09 | Retentative idempotente | P0 | Pas de second passage après timeout |
| DASH-01 | KPIs événement | P0 | Total, validés, restants, refus |
| DASH-02 | Filtres et exports historiques | P1 | Respect droits + pagination |
| DASH-03 | Indicateur réseau et synchronisation | P0 | État fidèle, pas de fausse assurance |

# 6. Règles métier et cycle de vie

## 6.1 Événement

États proposés : `draft` → `published` → `in_progress` → `closed` → `archived`, avec annulation exceptionnelle `cancelled`. Les règles de changement doivent être explicites : pas de scan accepté sur un événement brouillon, annulé ou clôturé ; fenêtre de validation configurable pour un événement en cours. La transition peut être manuelle ou déterminée par les heures, mais **le serveur est l'autorité**.

## 6.2 Ticket

États canoniques : `issued`, `redeemed`, `revoked` et `expired` (expiration peut être calculée en fonction des règles de l'événement). Le QR d'un billet `issued` peut être validé une fois. Seul un processus administratif exceptionnel, enregistré et soumis à droits renforcés, peut créer un **nouveau** billet en remplacement ; il ne réactive pas silencieusement le précédent.

## 6.3 Principe « première validation »

Le **premier scan reçu** n'est pas nécessairement une entrée. Le ticket n'est considéré utilisé que si la transaction serveur a effectivement été validée et enregistrée. Un scan échoué (mauvais événement, agent non autorisé, QR inconnu, panne réseau) ne consomme pas le billet.

## 6.4 Réadmission

Un billet MVP est à entrée unique. Les sorties et réentrées, les places à passages multiples, les événements multi-jours et la gestion des zones sont **hors MVP** et nécessiteront un moteur de droits plus élaboré.

# 7. Spécification du moteur de vérification

## 7.1 Composition du QR

Le QR contient un jeton aléatoire opaque (par exemple 256 bits issus d'une source cryptographiquement sûre) ou une URL contenant ce jeton, sans nom de personne, catégorie VIP, montant ou identifiant séquentiel. Sa représentation doit respecter les règles des lecteurs QR, la marge silencieuse et des dimensions suffisantes pour l'impression. L'illustration de QR dans le **logo** est décorative ; les billets doivent recevoir de **vrais** QR générés par une bibliothèque.

Le serveur conserve une **empreinte cryptographique** du jeton plutôt que le secret en clair dans les tables métier, si ce schéma est retenu. Le jeton doit être traité comme un secret au porteur et ne doit pas apparaître dans les journaux, événements analytiques ou captures de diagnostic. L'utilisation d'un HMAC côté serveur peut être envisagée, avec secret conservé dans un environnement sécurisé.

## 7.2 Séquence d'une validation

1. La caméra lit le QR et suspend les nouveaux scans.
2. Le mobile forme une requête avec jeton, `event_id`, `checkpoint_id`, identifiant unique de requête (`request_id`) et session authentifiée.
3. Le serveur authentifie l'utilisateur, vérifie son affectation active, les droits et le périmètre.
4. Le serveur dérive l'empreinte du jeton et recherche le billet du bon événement.
5. Il vérifie l'état, la période autorisée, les règles d'entrée et les interdictions.
6. Une **transaction atomique** effectue le passage de `issued` à `redeemed` sous condition, enregistre l'instant UTC serveur et le premier contrôleur, puis écrit l'essai de scan cohérent.
7. Le serveur retourne un verdict versionné et un identifiant de validation.
8. Le mobile montre le résultat et, après confirmation, réarme la lecture.

**Invariant non négociable :** pour tout billet à usage unique, le nombre de validations confirmées est inférieur ou égal à 1, même avec un grand nombre d'appels simultanés.

## 7.3 Gestion de la concurrence

La logique `SELECT statut → UPDATE statut` séparée côté mobile est interdite. Utiliser une transaction côté PostgreSQL : mise à jour conditionnelle avec `WHERE status = 'issued' RETURNING ...`, ou une fonction transactionnelle équivalente, complétée par les contraintes, les droits d'accès et les écritures d'audit. Une validation gagnante et un refus `already_used` pour les requêtes concurrentes doivent être prouvés par tests réels.

## 7.4 Idempotence et réponses perdues

Un timeout **n'implique pas** que la transaction a échoué. Le mobile utilise un `request_id` stable pour rejouer exactement la même demande. Le serveur stocke son résultat selon un mécanisme d'idempotence soumis à une contrainte d'unicité `(scanner_actor_id, request_id)` ou équivalente. Une requête répétée doit renvoyer le **même résultat** sans créer de deuxième droit d'entrée. En cas de résultat encore inconnu, afficher « Vérification en cours » ou « État à confirmer », jamais « Valide » par supposition. La vérification de statut peut être faite via une route autorisée, sans exposer le secret QR à d'autres agents.

## 7.5 Verdicts normalisés

| Code interne | Message français | Conséquence |
|---|---|---|
| `accepted` | Ticket valide — entrée autorisée | Autoriser **une** entrée |
| `already_used` | Ticket déjà utilisé | Refuser, montrer date/heure initiales |
| `revoked` | Ticket annulé | Refuser |
| `expired` | Ticket expiré | Refuser |
| `not_found` | Ticket introuvable | Refuser |
| `wrong_event` | Billet non valable pour cet événement | Refuser |
| `unauthorized` | Contrôle non autorisé | Refuser, alerter l'agent |
| `event_inactive` | Contrôle indisponible pour cet événement | Refuser |
| `rate_limited` | Trop de tentatives, réessayez | Ne pas donner de verdict positif |
| `unavailable` | Vérification impossible — connexion requise | **Indéterminé** ; pas d'admission automatisée |
| `pending` | Confirmation de validation en cours | Indéterminé ; résoudre l'idempotence |

La couleur est un renfort, pas le seul signal. Pour `already_used`, l'app peut afficher la date du premier passage **si l'agent a le droit de la consulter** ; ne pas exposer inutilement l'identité de l'agent précédent.

# 8. Modèle de données conceptuel

Chaque table métier contient au minimum un identifiant, des horodatages et un lien vers l'organisation, directement ou via une relation tenant vérifiable. Les noms exacts seront arrêtés en migration versionnée.

| Table | Champs essentiels | Règles importantes |
|---|---|---|
| `profiles` | `id`, `display_name`, `status`, `created_at` | Référence Auth ; données minimales |
| `organizations` | `id`, `name`, `slug`, `status`, `owner_id` | Slug unique, périmètre tenant |
| `organization_members` | `organization_id`, `user_id`, `role`, `active` | Unicité membre/organisation |
| `events` | `id`, `organization_id`, `title`, `venue`, `timezone`, `starts_at`, `ends_at`, `status` | Dates valides, index par tenant |
| `ticket_categories` | `id`, `event_id`, `name`, `capacity`, `quota` | Compteurs cohérents, unique par événement |
| `tickets` | `id`, `event_id`, `category_id`, `public_reference`, `qr_token_hash`, `status`, `issued_at`, `redeemed_at`, `redeemed_by`, `checkpoint_id` | Hash unique ; pas de jeton en clair |
| `ticket_batches` | `id`, `event_id`, `created_by`, `quantity`, `status` | Génération suivie, partielle gérée |
| `checkpoints` | `id`, `event_id`, `name`, `active` | Porte active et nom unique par événement |
| `event_assignments` | `event_id`, `user_id`, `checkpoint_id`, `role`, `active` | Contrôleur lié au bon événement |
| `scan_requests` | `id`, `actor_id`, `request_id`, `event_id`, `received_at`, `result_code`, `ticket_id` | Idempotence et conservation du résultat |
| `scan_attempts` | `id`, `ticket_id?`, `actor_id`, `event_id`, `checkpoint_id`, `outcome`, `server_time` | Journal append-only autorisé |
| `audit_logs` | `id`, `organization_id`, `actor_id`, `action`, `resource_type`, `resource_id`, `created_at` | Actions sensibles sans secrets |
| `invites` | `id`, `organization_id`, `email`, `role`, `expires_at`, `status` | Invitation limitée dans le temps |
| `device_sessions` | `id`, `user_id`, `device_label`, `last_seen_at`, `revoked_at` | Gestion des sessions/terminaux |

## 8.1 Contraintes et index

- `tickets.qr_token_hash` unique ; `tickets.public_reference` unique dans le périmètre défini.
- `organization_members(organization_id,user_id)` unique ; `event_assignments` selon la cardinalité retenue.
- `scan_requests(actor_id,request_id)` unique ; index sur `event_id`, `received_at`.
- Index pour `tickets(event_id,status)`, `scan_attempts(event_id,server_time)` et recherches paginées.
- Clés étrangères tenant/event strictes, contraintes `CHECK` sur états et fenêtres temporelles.
- Réconciliation des compteurs via les données de tickets plutôt que compteurs manuels non fiables.

## 8.2 Migration et données de démonstration

Toutes les tables, fonctions, RLS, index et données de démonstration **non sensibles** doivent être définis dans des migrations Supabase versionnées dans GitHub. Les données de test seront distinctes de la production.

# 9. Contrats API recommandés

Le service peut utiliser une Supabase Edge Function ou une API sécurisée qui invoque une fonction PostgreSQL transactionnelle. L'option exacte est à justifier en conception ; la transaction de validation doit résider du côté serveur et de la base. Voici un contrat **indicatif**, à finaliser sans exposer les jetons dans les logs.

## 9.1 Requête de scan

```json
POST /v1/scans/validate
Authorization: Bearer <access_token>
{
  "request_id": "uuid-v4-ou-v7",
  "event_id": "uuid",
  "checkpoint_id": "uuid",
  "qr_token": "secret_opaque_du_billet"
}
```

## 9.2 Réponse `accepted`

```json
{
  "request_id": "uuid",
  "result": "accepted",
  "validation_id": "uuid",
  "ticket": {"public_reference": "TS-2026-000123", "category": "Standard"},
  "first_validated_at": "2026-11-18T19:42:00Z",
  "checkpoint_label": "Entrée principale",
  "server_time": "2026-11-18T19:42:01Z"
}
```

## 9.3 Réponse `already_used`

```json
{
  "request_id": "uuid",
  "result": "already_used",
  "ticket": {"public_reference": "TS-2026-000123"},
  "first_validated_at": "2026-11-18T19:42:00Z",
  "checkpoint_label": "Entrée principale",
  "server_time": "2026-11-18T19:47:11Z"
}
```

Les messages locaux affichent les dates converties avec le fuseau de l'événement ou du terminal selon la politique UX explicitée. Les champs non nécessaires ne sont jamais renvoyés à un contrôleur.

# 10. Sécurité et modèle de menace

## 10.1 Menaces prévues

| Risque | Mesure fondamentale | Limite résiduelle |
|---|---|---|
| Copie/photo de QR | Usage unique atomique | La première copie présentée peut gagner |
| QR inventé par fraudeur | Jeton opaque aléatoire fort | Gestion rigoureuse des secrets nécessaire |
| Deux scans simultanés | Transaction SQL et test de concurrence | L'UX doit éviter ambiguïté en timeout |
| Contrôleur non habilité | Auth serveur + affectations | Appareil volé : révocation et sessions |
| Lecture des billets d'une autre organisation | RLS + contrôles serveur | Audit des politiques à maintenir |
| Fuite de clé de service | Jamais dans mobile / repo | Gestion de secrets hébergeur |
| Abus de l'API de scan | Limitation de débit et surveillance | Faux positifs à ajuster |
| Billets révoqués encore partagés | Contrôle état serveur au scan | Aucun usage hors ligne au MVP |
| Fuite de journaux | Masquage tokens et PII | Politique de rétention |
| Envoi d'un faux « valide » depuis l'interface | Aucun verdict local de confiance | Un agent doit utiliser l'app officielle |

## 10.2 Contrôles techniques obligatoires

- HTTPS/TLS, validation des paramètres, limitation de débit par utilisateur/appareil.
- Supabase Auth ; gestion de session et renouvellement des jetons ; révocation.
- Row Level Security sur les tables exposées ; principe du moindre privilège.
- Aucune clé `service_role` ni secret privé dans le binaire Flutter ou GitHub public.
- Les fonctions `SECURITY DEFINER`, si indispensables, nécessitent une revue de sécurité, un `search_path` verrouillé, des schémas qualifiés et des droits `EXECUTE` minimaux.
- Journalisation des décisions sans enregistrer le QR brut ; corrélation par ID non secret.
- Validation transactionnelle serveur avec contraintes DB ; aucun update direct de `tickets.status` depuis le mobile.
- Analyse de dépendances, revue de code, CI bloquante, sauvegardes et tests de restauration.
- Protections de l'export ; billets partageables uniquement par une action explicitement autorisée.
- Politiques d'accès aux historiques, suppression/anonymisation et revue réglementaire avant commercialisation.

## 10.3 Protection de la vie privée

Le modèle MVP doit fonctionner sans créer de compte participant. Ne collecter nom, téléphone, email ou pièce d'identité que s'ils sont réellement requis pour un événement et clairement annoncés. Prévoir notice de confidentialité, droits d'accès, export/suppression selon obligations applicables et durée de conservation configurable. Une revue juridique locale doit valider les mesures avant mise en production au Burkina Faso.

# 11. Résilience, réseau et gestion des erreurs

- Prioriser des payloads courts et une consommation limitée de données mobiles.
- Utiliser une file **locale d'interface**, non une file de validations acceptées hors ligne : une opération en cours peut être reprise par `request_id` après reconnexion.
- Définir des timeouts explicites, une politique de retentative bornée et l'affichage d'un état indéterminé.
- Déconnecté : le scan peut décoder localement un QR, mais **ne peut pas autoriser l'entrée**.
- Serveur répond 500 : afficher « Service momentanément indisponible » sans autoriser.
- Caméra refusée : explication et lien vers réglages Android.
- QR illisible : message utile, lampe torche, guide de cadrage, pas de lecture défectueuse présumée.
- Horloge du téléphone erronée : timestamps de référence créés par le serveur.
- Double scan accidentel : délai de réarmement et verrouillage de la requête en cours.
- Reprise de session et reconnexion : l'agent retrouve l'événement/porte sans perte de sécurité.

# 12. Expérience Android et architecture UI

## 12.1 Principes

Design Material 3 personnalisé TicketSûr, mode clair d'abord, mode sombre pris en charge, accessibilité dynamique et usage à une main. Contraste fort au soleil, typographie lisible, zones tactiles d'au moins 48 dp, indicateur sonore/haptique optionnel, aucune animation ralentissant le scan. Prévoir états `loading`, `empty`, `error`, `offline`, `success`, `permission_denied` et `session_expired`.

## 12.2 Architecture de navigation

**Organisateur :** Accueil / Événements / Tickets / Équipe / Profil. Le scanner reste accessible via une action flottante ou un accès direct contextualisé. **Contrôleur :** événement actif / scanner / historique personnel / profil, sans modules administratifs superflus.

## 12.3 Inventaire des écrans

| ID | Écran | Rôle | Éléments essentiels |
|---|---|---|---|
| S01 | Splash et vérification session | Tous | Logo, état de connexion |
| S02 | Accueil / onboarding court | Tous | Valeur produit, connexion |
| S03 | Connexion | Tous | Email, mot de passe, erreurs |
| S04 | Mot de passe oublié | Tous | Email et confirmation |
| S05 | Choix de l'organisation | Multi-membres | Liste des espaces autorisés |
| S06 | Accueil organisateur | Organisateur | KPIs, événements, actions rapides |
| S07 | Liste des événements | Organisateur | Recherche, filtres, statuts |
| S08 | Créer un événement | Organisateur | Détails, date, lieu, capacité |
| S09 | Détail événement | Organisateur | Synthèse, billets, équipe, stats |
| S10 | Catégories de billets | Organisateur | Quotas et noms |
| S11 | Créer un ticket | Organisateur | Catégorie et génération |
| S12 | Génération en lot | Organisateur | Quantité, progression, erreurs |
| S13 | Aperçu d'un ticket | Organisateur | QR, référence, export |
| S14 | Liste des billets | Organisateur | États et filtres |
| S15 | Détail et annulation ticket | Organisateur | Statut, journal, confirmation |
| S16 | Liste des agents | Organisateur | Invitation, activité |
| S17 | Affectation agents/portes | Organisateur | Matrice événement et porte |
| S18 | Historique des scans | Organisateur | Résultats, dates, filtres |
| S19 | Statistiques d'événement | Organisateur | Graphes et compteurs |
| S20 | Sélection d'événement | Contrôleur | Événements autorisés |
| S21 | Sélection de porte | Contrôleur | Porte attribuée et active |
| S22 | Scanner plein écran | Contrôleur | Caméra, lampe, état réseau |
| S23 | Scan accepté | Contrôleur | Fond vert, confirmation, catégorie |
| S24 | Ticket déjà utilisé | Contrôleur | Refus, date/heure initiales |
| S25 | Refus / ticket inconnu | Contrôleur | Cause neutre et explicite |
| S26 | Vérification impossible | Contrôleur | Reconnexion et idempotence |
| S27 | Mes scans récents | Contrôleur | Historique limité |
| S28 | Profil et paramètres | Tous | Compte, sons, thème, session |
| S29 | Centre d'aide / procédures | Tous | Assistance, FAQ, sécurité |
| S30 | Paramètres de l'organisation | Propriétaire | Membres, informations, règles |

## 12.4 Spécification de l'écran scanner

- Zone caméra occupant la majorité de l'écran ; cadre de visée lisible, sans effet visuel excessif.
- Bandeau événement/porte permanent pour éviter de contrôler le mauvais événement.
- Indicateur réseau et délai de réponse non trompeurs.
- Au décodage : affichage « Vérification… », blocage temporaire de la lecture et retour haptique discret.
- En cas d'acceptation : surface très lisible « ENTRÉE AUTORISÉE », référence/catégorie, bouton « Scanner suivant ».
- En cas de refus : libellé « ENTRÉE REFUSÉE », raison, date/heure du premier scan si pertinente.
- En cas d'incertitude : écran distinct (orange/gris), aucune couleur de succès.
- Paramètres pour couper sons/vibrations et lampe manuelle.

# 13. Identité visuelle et actifs de marque

**Nom officiel : TicketSûr. Slogan officiel : Votre événement en un clic.** Le concept graphique sélectionné est **le logo Option B**, caractérisé par un billet / QR blanc sur fond bleu nuit, un accent bleu électrique et une coche de validation verte. Conserver l'accent circonflexe du nom dans tous les textes visibles. Le nom technique `ticketsur` reste sans accent pour les chemins et identifiants.

**Actifs fournis au projet :**
- `Tikeo_Logo.png` / `Tikeo_Logo_Clair.png` : logo horizontal transparent (fond clair / fond sombre).
- `Tikeo_Icone.png` : icône carrée, base des variantes Android ; `Tikeo_Symbole.png` : ticket et repère seuls.

## 13.1 Palette initiale de travail

| Jeton | Couleur | Usage |
|---|---|---|
| `brand.navy` | `#082D60` | Titres, navigation, identité |
| `brand.blue` | `#079EF4` | Actions et focus |
| `status.success` | `#17BE35` | Validation uniquement |
| `status.error` | `#DC3545` | Refus et erreurs critiques |
| `status.warning` | `#F59E0B` | Indéterminé et avertissement |
| `surface.light` | `#F7F9FC` | Surfaces claires |
| `surface.dark` | À définir et auditer | Mode sombre |

Ces codes sont **des valeurs de départ** : les couleurs finales sont à échantillonner sur le logo retenu et à vérifier selon WCAG pour chaque paire texte/fond. Éviter le vert vif comme couleur de texte sur fond blanc si le contraste est insuffisant.

## 13.2 Typographies et composants

- **Nunito** (depuis l'ADR 0011, à la place de Manrope) : marque, titres. Si indisponible, police équivalente libre validée.
- **Inter** : corps d'interface, chiffres, tableaux, champs.
- Icônes cohérentes Material Symbols / bibliothèque compatible ; pas de pictogrammes hétérogènes.
- Tokens : échelle d'espacement 4/8/12/16/24/32, rayons 12–20, élévation modérée, contrastes testés.
- Générer les variantes d'icône adaptative Android, splash, favicon futur, logo monochrome, et consignes d'espace libre.
- Ne jamais utiliser le QR décoratif du logo comme QR d'accès réel.

# 14. Architecture technique cible

## 14.1 Composants

1. **Flutter Android** : présentation, caméra/QR, gestion d'état, cache non sensible, clients sécurisés.
2. **Supabase Auth** : comptes et identités, sessions.
3. **PostgreSQL** : organisations, événements, tickets, affectations, transactions et historiques.
4. **Fonction transactionnelle** : seule autorité d'acceptation des billets.
5. **Edge Function/API sécurisée** : validation de la forme des requêtes, télémétrie contrôlée, appels transactionnels.
6. **Supabase Storage** : visuels d'événement et exports avec règles d'accès appropriées.
7. **GitHub** : code, documentation, issues, PR, automatisations CI/CD, releases.
8. **Distribution Android** : APK signé pour pilote, puis AAB signé pour Play Store.

**Précision essentielle :** GitHub héberge le code et orchestre les builds/déploiements ; **l'application backend s'exécute chez un hébergeur** tel que Supabase. GitHub n'est pas, à lui seul, un serveur PostgreSQL de production.

## 14.2 Structure monorepo suggérée

```text
ticketsur/
  .github/
    ISSUE_TEMPLATE/
    workflows/
      ci.yml
      android-build.yml
      security.yml
      deploy-staging.yml
      deploy-production.yml
    pull_request_template.md
    CODEOWNERS
  apps/
    mobile/
      android/
      lib/
        core/
        design_system/
        features/
          auth/
          organizations/
          events/
          tickets/
          scanner/
          history/
          dashboard/
          settings/
      test/
      integration_test/
      assets/branding/
  supabase/
    migrations/
    functions/
    tests/
    seed.sql
    config.toml
  docs/
    product/
    architecture/
    api/
    security/
    ux/
    operations/
    decisions/
  scripts/
  .env.example
  .gitignore
  LICENSE
  README.md
  CONTRIBUTING.md
  SECURITY.md
  CHANGELOG.md
```

## 14.3 Architecture Flutter

Séparation `presentation` / `application` / `domain` / `data` par fonctionnalité ; injection des dépendances ; sérialisation typée des réponses ; localisation `fr` et extension multilingue. Riverpod (ou alternative justifiée) pour l'état, GoRouter pour la navigation, package de scan caméra maintenu et vérifié au moment du développement. Éviter de sur-ingénier le MVP : adapter Clean Architecture au poids réel de chaque module.

## 14.4 Compatibilité Android

Cibler **Android API 24+** comme base selon la documentation Flutter consultée en novembre 2026, puis vérifier les exigences du SDK au moment de l'implémentation. Tester prioritairement des appareils ARM64 de gamme intermédiaire et des modèles plus modestes ; portrait d'abord ; permissions de caméra au bon moment ; pas de permission de géolocalisation par défaut.

# 15. GitHub : gouvernance, développement et déploiement

## 15.1 Organisation du dépôt

- Dépôt GitHub privé au lancement ; droits limités aux collaborateurs nécessaires.
- Branche `main` protégée et déployable ; branches `feature/*`, `fix/*`, `docs/*` à durée courte ; `develop` **facultative** et uniquement si elle apporte une valeur à l'équipe.
- Toute modification applicative passe par PR, revue, checks CI et critères d'acceptation.
- Étiquettes `P0`, `P1`, `P2`, `bug`, `security`, `flutter`, `backend`, `ux` ; jalons alignés sur les incréments.
- Issues petites, liées à une exigence et un test ; ADR pour décisions majeures.

## 15.2 CI/CD GitHub Actions

| Pipeline | Déclencheur | Travail attendu |
|---|---|---|
| `ci.yml` | PR / push | Format, analyse statique, tests Flutter |
| `db-tests.yml` | PR / push ciblé | Migrations, tests SQL, politiques RLS, concurrence |
| `security.yml` | PR / périodique | Dépendances, secrets accidentels, alertes |
| `android-build.yml` | PR / tag | Build debug de vérification, APK signé sur release contrôlée |
| `deploy-staging.yml` | Merge autorisé | Migrations et fonctions de préproduction |
| `deploy-production.yml` | Approbation/release | Déploiement encadré, sauvegarde, vérifications |

Stocker les clés de signature Android et secrets d'infrastructure dans les **secrets/environnements protégés GitHub**, jamais dans le dépôt. Conserver les clés de production de manière sécurisée, prévoir rotation et récupération ; ne pas exposer le mot de passe de signature dans les logs. Vérifier les restrictions offertes par le plan GitHub utilisé.

## 15.3 Stratégie de livraison

1. Environnement `development` / local.
2. Environnement `staging` Supabase distinct, données factices.
3. Production Supabase distincte ; migrations versionnées et revues.
4. Release candidate APK signée diffusée à une équipe pilote.
5. AAB signé pour tests internes Google Play et publication éventuelle.
6. Surveillance de l'incidentologie et procédure de retour arrière documentée (attention aux migrations irréversibles).

## 15.4 Collaboration avec Claude

Claude doit travailler **sur des branches/PR explicites**, fournir le diff, expliquer les modifications, exécuter ou indiquer les commandes de tests, et ne jamais affirmer avoir poussé sur GitHub ou déployé tant que l'opération n'a pas été réalisée avec des accès autorisés. Chaque étape produit fichiers, tests, documentation et note de validation. Aucune clé privée ne doit être fournie dans le chat ni committée.

# 16. Exigences non fonctionnelles

| Dimension | Cible / règle |
|---|---|
| Sécurité | Un seul scan accepté ; aucun accès inter-organisations |
| Performance | P95 < 2 s **sur réseau stable de recette** ; budget à mesurer |
| Robustesse | Résultat « indéterminé » pour pannes et timeouts |
| Scalabilité | Tests 10 000 tickets / 20 contrôleurs, puis montée en charge |
| Disponibilité | Plan de continuité et statut serveur ; SLA à définir contractuellement |
| Accessibilité | Contraste WCAG visé, libellés explicites, taille texte adaptable |
| Confidentialité | Minimisation, journalisation sans secret, rétention définie |
| Exploitabilité | Logs structurés, métriques, alertes, tableaux de bord opérationnels |
| Compatibilité | Android API 24+ à confirmer avec SDK et dépendances retenues |
| Localisation | Français initial ; dates UTC stockées, affichage local clair |
| Documentation | Installation, architecture, règles métier, sécurité, exploitation |
| Sauvegardes | Plan restaurable documenté et testé |

# 17. Plan de tests et scénarios d'acceptation

## 17.1 Tests fonctionnels obligatoires

| Test | Entrée / situation | Résultat attendu |
|---|---|---|
| AT-01 | Ticket non utilisé, agent autorisé | `accepted`, statut `redeemed` |
| AT-02 | Même ticket immédiatement rescanné | `already_used`, date initiale |
| AT-03 | Deux agents même QR simultanément | **Un accepté, un refusé** |
| AT-04 | 50 appels concurrents même QR | **Un seul accepté** |
| AT-05 | QR aléatoire inexistant | `not_found` |
| AT-06 | Ticket d'un autre événement | `wrong_event` |
| AT-07 | Ticket révoqué | `revoked` |
| AT-08 | Événement clôturé | `event_inactive` |
| AT-09 | Contrôleur sans affectation | `unauthorized` |
| AT-10 | Agent désactivé après connexion | Refus au prochain scan |
| AT-11 | Téléphone hors ligne | Aucun écran « Valide » |
| AT-12 | Serveur timeout après commit | Retry même `request_id` = même verdict |
| AT-13 | Retry avec autre `request_id` sur ticket déjà consommé | `already_used` |
| AT-14 | Deux organisations distinctes | Aucune fuite croisée |
| AT-15 | Billet généré en PDF imprimé | QR lisible sur appareil basique |
| AT-16 | Caméra refusée | Explication et récupération |
| AT-17 | Horloge téléphone décalée | Heure du serveur utilisée |
| AT-18 | Grande police / TalkBack | Affichage et commandes utilisables |
| AT-19 | Fuite de requête dans logs | QR brut absent des logs |
| AT-20 | Migration et retour incident | Sauvegarde/restore documentés |
| AT-21 | Lot de 10 000 billets | Identifiants uniques, cohérence totale |
| AT-22 | Déconnexion ou révocation de session | Plus d'accès au scan sécurisé |

## 17.2 Tests complémentaires

- Unitaires : règles des statuts, validations de formulaire, formatage des dates, composants.
- Widgets Flutter : succès, refus, états vides, erreurs, permission caméra, session expirée.
- Intégration : authentification, création, export, scan, historique.
- PostgreSQL : transactions concurrentes, contraintes, idempotence, RLS et privilèges RPC.
- E2E sur appareils physiques Android : luminosité, faible connexion, appareil ancien, caméra moyenne.
- Sécurité : rôle forgé côté client, appels API hors affectation, exports non autorisés, journaux.
- Charge : tickets multiples, pointes d'entrée, latences, échecs réseau, reprise.

# 18. Observabilité et exploitation

Métriques sans secrets : volume de validations par minute, taux de refus, doublons détectés, latence P50/P95/P99, erreurs API, erreurs de base, endpoints en échec, versions d'app, incidents de signature et crashs. Séparer **fraude potentielle** et **simple duplication accidentelle** dans les libellés : un second scan n'établit pas à lui seul une intention malveillante. Les logs horodatés doivent être corrélés par identifiants techniques. Un runbook couvre : indisponibilité Supabase, panne réseau à une porte, sessions volées, génération bloquée, restauration et incident de données.

# 19. Gouvernance des données et conformité

- Classer les données : publiques événement, privées organisation, privées participant éventuelles, secrets QR, logs techniques.
- Définir un responsable du traitement, accès, export et rétention selon le cadre applicable.
- Période de conservation des scans : à décider et paramétrer ; éviter la conservation illimitée par défaut.
- Encadrer suppression, anonymisation, sauvegardes et rétention légale.
- Prévoir clauses de service, confidentialité, conditions d'utilisation et consentements lorsque nécessaires.
- Audit juridique avant traitement de données nominatives et avant ajout de paiements.

# 20. Livrables à remettre par Claude

| Lot | Livrable | Preuve attendue |
|---|---|---|
| 0 | Analyse du cahier, questions bloquantes, décisions techniques | Document ADR + backlog priorisé |
| 1 | Design system, navigation et maquettes des 30 écrans | Composants et états documentés |
| 2 | Monorepo GitHub, outils, CI, environnements | PR, tests, README |
| 3 | Schéma SQL, migrations, RLS, auth, organisations | Tests d'isolation multi-tenants |
| 4 | Événements, catégories, contrôleurs | Tests API et Flutter |
| 5 | Tickets, génération QR, PDF et lots | Tests d'unicité et lecture QR |
| 6 | Moteur atomique de scan et idempotence | Preuve concurrence 50 appels |
| 7 | Scanner Android, états et retour UX | Tests sur appareils réels |
| 8 | Historiques, statistiques, export | Captures et tests d'accès |
| 9 | Durcissement, tests de charge et observabilité | Rapport de recette |
| 10 | APK signé de pilote et AAB de distribution | Artifacts GitHub, checklist release |
| 11 | Dossier d'exploitation et guide utilisateur | Documentation vérifiée |

## 20.1 Définition de « terminé » (Definition of Done)

Une fonctionnalité n'est terminée que si : critères d'acceptation satisfaits, tests ajoutés et verts, gestion des erreurs et états UX couverts, permissions et RLS testées, secrets exclus des logs, documentation à jour, PR revue et liée au backlog, et démonstration sur appareil Android pour les flux critiques.

# 21. Roadmap de réalisation (séquencée, sans durée promise)

| Phase | Objectif | Sortie de phase |
|---|---|---|
| 0 — Fondations | Revue cahier, ADR, design system, repo | Architecture validée |
| 1 — Identité / accès | Auth, orgs, rôles, RLS | Deux orgs isolées |
| 2 — Événementiel | Événements, quotas, agents, portes | Événement test prêt |
| 3 — Tickets | Génération, visuel, PDF, révocation | Tickets de test exploitables |
| 4 — Scan sûr | Transaction, idempotence, caméra | Invariant 1 entrée prouvé |
| 5 — Pilotage | Historique, stats, exports | Bilan d'événement possible |
| 6 — Durcissement | Performance, accessibilité, sécurité | Recette interne validée |
| 7 — Pilote | Test réel encadré, correction | APK candidate |
| 8 — Distribution | Version, signature, AAB, monitoring | Publication contrôlée |

# 22. Risques, arbitrages et atténuations

| Risque | Gravité | Plan proposé |
|---|---|---|
| Récupération d'un QR avant le propriétaire | Élevée | Usage unique + option identité pour événements sensibles |
| Panne d'Internet pendant l'événement | Élevée | Réseau secondaire, affichage indéterminé, procédure terrain |
| Bug de concurrence | Critique | Validation SQL et tests parallèles obligatoires |
| Mauvais paramétrage RLS | Critique | Tests inter-organisations et revue des fonctions |
| Dépendance fournisseur backend | Moyenne | Migrations SQL, couche de services, plan d'export |
| Instabilité caméra sur appareil bas de gamme | Élevée | Tests appareils réels, package maintenu, repli ergonomique |
| Fuite du QR par export ou journal | Élevée | Masquage, contrôle de partage, durée de vie des exports |
| Publication Android sans clé de signature récupérable | Élevée | Play App Signing, coffre de clés, responsable désigné |
| Coût des pics de charge | Moyenne | Mesures, quotas, alerte et calcul de capacité avant événements |

# 23. Hypothèses et décisions à confirmer avant développement

Les choix structurants ont été fixés pour permettre de travailler sans nouvelle réunion de cadrage : Android Flutter, Supabase PostgreSQL, en ligne obligatoire, multi-organisations et identité visuelle Option B. Les paramètres restants peuvent avoir des **valeurs par défaut proposées par Claude** et être configurables : capacité maximale par lot, durée de fenêtre de scan, durée de rétention, autorisation d'afficher les noms des participants, granularité des points de contrôle, résolution d'un timeout, formats PDF/impression, politique de réémission, support technique et mode de tarification futur. Les décisions affectant sécurité ou conformité exigent une revue humaine avant mise en production.

# 24. Critères de réception du MVP

La version MVP n'est **pas** acceptable si : un QR peut être validé deux fois ; le mobile seul peut marquer un billet valide ; un contrôleur sans droits valide un billet ; un tenant peut consulter les données d'un autre ; le QR apparaît en clair dans les journaux ; un timeout est affiché comme un succès ; l'historique ne restitue pas la première validation ; un ticket révoqué est accepté ; les builds Android ne sont pas reproductibles depuis GitHub ; ou aucun test de charge et de restauration n'a été exécuté.

Elle est réceptionnable lorsqu'un organisateur peut créer un événement complet, générer/distribuer un lot, affecter une équipe, tenir une session de contrôle multi-portes sur Android, consulter les résultats, exporter son bilan et relancer la session après un incident, le tout avec des preuves de tests et des livrables versionnés.

# 25. Sources techniques de référence

Documentation officielle consultée pour le cadrage du 18 novembre 2026 :

1. Flutter — Build and release an Android app : https://docs.flutter.dev/deployment/android
2. Flutter — Supported deployment platforms : https://docs.flutter.dev/reference/supported-platforms
3. Supabase — Use Supabase with Flutter : https://supabase.com/docs/guides/getting-started/quickstarts/flutter
4. Supabase — Row Level Security : https://supabase.com/docs/guides/database/postgres/row-level-security
5. Supabase — Database functions : https://supabase.com/docs/guides/database/functions
6. PostgreSQL — UPDATE / RETURNING : https://www.postgresql.org/docs/current/sql-update.html
7. PostgreSQL — Explicit locking : https://www.postgresql.org/docs/current/explicit-locking.html
8. GitHub Docs — Managing environments for deployment : https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments

**Note de révision :** les packages, API, quotas, versions et exigences Android/Google Play devront être revérifiés par Claude au début de l'implémentation. Les valeurs chiffrées de performance de ce document sont des **cibles de recette**, pas des mesures réalisées ni des garanties contractuelles.
