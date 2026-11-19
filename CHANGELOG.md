# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versionnement sémantique à partir de la première APK pilote.

## [Non publié]

### Ajouté (lot 1 : événements enrichis)
- Événements : photo de couverture, ville, type (concert, conférence, culte, sport, mariage, formation, gala, autre), description, adresse ; migration `1100` et ADR 0009 (bucket public `event-covers`, chemin imposé, dépôt réservé aux gestionnaires, `set_event_cover`). La publication exige une photo et une ville (`event_incomplete`).
- Assistant de création en 4 étapes (infos, date et lieu, photo, aperçu) avec barre de progression, suggestions des villes du Burkina Faso, choix de la photo (galerie ou appareil photo, réduite avant l'envoi), aperçu de la carte et liste de ce qui manque pour publier ; en modification, chaque étape est accessible et « Enregistrer » reste disponible.
- Liste des événements en cartes visuelles (photo, date, statut, type, lieu et ville, mention « À compléter avant publication ») ; fiche avec grande couverture repliable, changement de photo, carte des éléments manquants avec raccourcis, description.

### Ajouté (phase 5)
- Scanner caméra (S22) : `mobile_scanner` 7.5 (ML Kit embarqué, fonctionne sans Google Play Services), QR seulement, lecture limitée au cadre, cadre de visée animé (coins, ligne de balayage), lampe torche, réarmement de 2,5 s contre la double lecture, verdict par-dessus la caméra restée allumée, saisie manuelle en secours, états « permission refusée » et « caméra indisponible ».
- Accueil organisateur : actions rapides (nouvel événement, émettre des tickets, inviter l'équipe) à la place des étapes annoncées, désormais livrées.

### Modifié
- Vocabulaire : « ticket » remplace « billet » dans toute l'application (onglet « Tickets », textes, PDF, noms des fichiers partagés, adresses internes `/tickets`).

### Ajouté
- Sons et retours : 6 sons originaux synthétisés (`tools/sounds/generate_sounds.py` : clic, réussite, erreur, entrée autorisée, refusée, à confirmer), lecteur basse latence sans prise du focus audio, vibrations ; réglages « Sons et vibrations » dans le Profil (sons du contrôle, de l'interface, vibrations, écoute des verdicts), mémorisés sur l'appareil.
- Animations : messages stylés avec icône animée, son et vibration ; cartes qui s'enfoncent au toucher ; silhouettes scintillantes pendant les chargements ; compteurs qui défilent ; éclat de réussite (émission de tickets, code d'invitation) ; clic et vibration au changement d'onglet. Toutes respectent « réduire les animations ».
- Contrôle des entrées (phase 4, S20 à S27) : migration `1000` (`my_scan_posts`, `my_recent_scans`) ; barre de navigation selon le rôle (contrôleur : Contrôle / Historique / Profil) ; choix de l'événement et de la porte, poste de scan avec saisie ou collage du code, verdicts plein écran, rejeu idempotent avec le même `request_id` (jamais de vert sans réponse serveur complète), réarmement explicite contre la double lecture, retour haptique ; historique personnel sur 7 jours ; accès organisateur depuis l'Accueil et la fiche événement.
- Billets (phase 3, S11 à S15) : migration `0900` (`event_tickets` paginé et filtré sans secret, `export_tickets` : ré-export audité des jetons, 200 au plus, billets annulés exclus) ; onglet Billets (événement, compteurs, filtres, recherche), émission par lots jusqu'à 500, fiche billet avec QR (affiché d'office seulement dans la session d'émission, sinon sur demande journalisée), partage en image PNG ou en PDF A6 (un billet par page), annulation avec motif. QR vérifiés avec un lecteur indépendant (zbar) sur l'image et le PDF.
- Équipe (ORG-02, ORG-03, S16, S17) : migration `0800` et ADR 0008 — invitations par code à partager (empreinte seule côté serveur, expiration, utilisations, révocation, essais limités), rôle et activation des membres (désactivation immédiate des scans), affectations aux événements et aux portes ; onglet Équipe, « Rejoindre avec un code », section « Contrôleurs affectés » de la fiche événement.
- Catégories de billets et portes (EVT-03, EVT-04) : migration `0700` (`create/update/delete_ticket_category`, `event_categories` avec compteurs émis/entrés, `create_checkpoint`, `update_checkpoint`) ; configuration figée une fois l'événement clôturé, annulé ou archivé ; fiche événement avec quotas animés, feuilles de saisie, désactivation de porte confirmée.
- Émission : capacité de l'événement respectée toutes catégories confondues (verrou de l'événement, prouvé par deux tests de concurrence réelle) ; plus d'émission tant que l'événement est en brouillon.
- Événements (EVT-01, EVT-02) : migration `0600` (`create_event`, `update_event`, `set_event_status`), cycle de vie contrôlé côté serveur sous verrou (brouillon → publié → en cours → clôturé → archivé, annulation), fuseau IANA validé, audit de chaque écriture ; onglet Événements (filtres, fiche, formulaire avec dates et heures dans le fuseau de l'événement), prochain événement sur l'Accueil.
- Signature Android stable : clé unique dans les secrets du dépôt (workflow `signing-key`), empreinte vérifiée à chaque build.
- Organisations en libre-service (ADR 0007) : `create_organization` (5 au plus par propriétaire), `my_organizations` ; création à la première connexion, organisation active mémorisée, changement d'organisation (S05).
- Navigation de l'espace connecté (Accueil, Événements, Billets, Équipe, Profil), transitions de pages Material 3, apparitions animées, double appui sur Retour pour quitter ; respect du réglage « supprimer les animations ».
- Plateforme Android (`com.ticketsur.fasosoft`, API 24 à 36), icônes adaptatives, écran de lancement, workflow `android-build` produisant l'APK de pilote.
- Connexion (S03), mot de passe oublié (S04), redirections de session ; test de bout en bout avec un vrai compte sur le staging.

### Corrigé
- Retour revient à l'écran précédent (historique des onglets) au lieu de toujours ramener à l'Accueil ; une page empilée se ferme d'abord.
- Onglets : l'onglet quitté restait affiché par-dessus en revenant vers la gauche (fondu figé). Touche Retour : l'application se déclare toujours responsable de Retour auprès d'Android (13+, 16 par défaut), au lieu d'être fermée par le système.
- Migration `0400` : profil créé à l'inscription. Sans lui, `validate_scan` échouait (HTTP 409) pour un compte neuf au lieu de répondre « unauthorized ». Un profil désactivé est désormais refusé sans écriture.

### Ajouté (Phase 0)
- Phase 0 : ADR 0001 à 0006, documentation du moteur de scan, backlog.
- Migrations `0100` (schéma multi-organisations, RLS de lecture) et `0200` (émission, révocation, validation atomique des scans avec idempotence).
- Tests base de données : 47 assertions (acceptation, concurrence 2 et 50 scans, rejeux idempotents simultanés, 10 000 billets).
- Workflows GitHub Actions `db-tests`, `security` et `deploy-staging` (Supabase CLI 3.2.0).
- Migration `0300` : clés Vault des QR générées côté serveur, idempotente.
- `supabase/config.toml` (Supabase CLI) et procédure `docs/operations/deploiement-supabase.md`.
- Actifs de marque officiels (logo, icône Android).
