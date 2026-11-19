# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versionnement sémantique à partir de la première APK pilote.

## [Non publié]

### Ajouté (lot 3a-1 : console d'administration dans l'app, ADR 0013)
- **Console Tikéo**, dans le Profil des seuls administrateurs de la plateforme. Le rôle est vérifié côté serveur et ne s'attribue qu'en SQL.
  - Vue d'ensemble : organisations, comptes, événements, tickets, contrôles des dernières 24 heures.
  - Organisations : recherche, suspension avec motif obligatoire, réactivation.
  - Catalogue public : retrait avec motif obligatoire, rétablissement.
  - Journal d'audit de toute la plateforme, filtré par famille d'actions, avec des libellés et des détails lisibles.
- **Organisateurs** : un événement retiré par Tikéo affiche le motif sur sa fiche. L'interrupteur « Visible par le public » est bloqué (`event_blocked`).
- **Base** : migration `1900`.
  - Colonnes `events.public_blocked_at` et `public_blocked_reason` ; `organizations.disabled_at` et `disabled_reason`.
  - Fonctions `is_platform_admin`, `admin_overview`, `admin_organizations`, `admin_set_organization_status`, `admin_public_events`, `admin_set_event_blocked` et `admin_audit_logs`.
  - `private.is_listed` exclut les événements retirés.
  - Journal `admin.*` sans motif ni donnée personnelle.
  - Tests SQL `99_console.sql`.

### Modifié (refonte Tikéo, étape D : ticket, PDF et rapports)
- **Ticket (fiche et image partagée)** :
  - logo Tikéo dans le bandeau bleu nuit ;
  - catégorie sur une pastille menthe ;
  - icônes menthe pour la date, le lieu (avec la ville) et le titulaire ;
  - ligne de découpe avec encoches.
  - Le QR est inchangé, noir sur blanc.
- **Invitations** : la mention et le filet passent de l'or à l'orange de la marque (`spark`). La couleur or est retirée.
- **PDF des tickets** :
  - logo et nouveau bleu nuit (l'ancien `#082D60` restait) ;
  - pastille de catégorie menthe ;
  - mention et filet orange pour les invitations ;
  - ligne de découpe ;
  - nom de l'organisation en menthe profonde.
  - Le logo n'est intégré qu'une fois par document, quel que soit le nombre de tickets.
- **Bilan PDF** : logo dans le bandeau, couleurs Tikéo (entrés en menthe profonde, passages en menthe, refus en rouge).
- Logo allégé `Tikeo_Logo_Clair_480.png` (10 Ko) pour le ticket et les PDF. Il est décodé avant le rendu de l'image partagée.

### Modifié (refonte Tikéo, étape C : écrans organisateur et contrôleur)
- **Accueil organisateur** :
  - « Bonjour <prénom> », organisation active (touchez pour changer) et avatar vers le Profil ;
  - actions rapides, la première en menthe ;
  - bandeau bleu nuit de l'événement du moment (en cours d'abord), avec entrés, émis, présence et une barre de progression ; lien « Suivre les entrées en direct » ;
  - liste « Mes événements » (trois au plus) avec pastilles de statut, « Tout voir » ;
  - tirer pour actualiser.
- Les chiffres de l'Accueil viennent du même fournisseur que le tableau de bord : l'ouvrir ne relance pas une lecture.
- **Tableau de bord** :
  - anneau de présence en menthe ;
  - ligne des invités dans le bandeau ;
  - barres des catégories aux couleurs de la marque, invitations en orange.
- **Écran du contrôleur** : icône du verdict dans un disque, détails (référence, catégorie, premier passage) regroupés dans un encart dont le contraste est vérifié par test. Les couleurs de verdict ne changent pas.

### Corrigé (étape C)
- Le bloc de date des cartes d'événement s'étirait sur toute la hauteur de la photo.

### Ajouté (refonte Tikéo, étape B : catalogue public, ADR 0012)
- **Explorer sans compte** dès l'ouverture : barre de recherche (sans casse ni accents), puces de catégories, choix de la ville (les 49 communes urbaines du Burkina), filtres (catégories, aujourd'hui / ce week-end / cette semaine, entrée gratuite), événement « À la une », pages de 30 avec « Voir plus ».
- **Fiche publique** : photo, dates, lieu, description, catégories avec prix indicatif, organisateur ; bouton **« Obtenir un ticket »** vers WhatsApp (numéro public de l'organisation, message prêt) ; partage.
- **Organisateurs** :
  - interrupteur « Visible par le public » sur la fiche de l'événement (privé par défaut) ;
  - prix indicatif dans la fiche de catégorie ;
  - numéro WhatsApp public dans la fiche d'organisation.
- **Base** : migration `1800`.
  - Colonnes `events.is_public`, `organizations.public_phone` et `ticket_categories.indicative_price`.
  - Fonctions `set_event_public`, `set_organization_public_phone` et `set_category_price`, journalisées sans donnée personnelle.
  - `public_events` et `public_event`, ouvertes sans compte et limitées aux champs de vitrine.
  - Tests SQL `98_public_catalog.sql`.
- **Navigation** :
  - sans compte : Explorer, Organiser (présentation), Compte ;
  - connecté : Explorer, Organiser (Accueil, et la liste des événements via « Mes événements »), Tickets, Équipe, Profil.
  - La coque connectée est toujours libérée à la déconnexion.

### Corrigé
- Tests de contraste étendus à l'Explorer et à la fiche publique ; ils ont repéré un prix trop long dans une ligne de catégorie.

### Modifié (refonte Tikéo, étape A : marque)
- **Nouveau nom : Tikéo** (libellé Android, textes, PDF de tickets et de rapports, notes de version). Identifiant Android, dépôt et noms techniques inchangés (ADR 0011).
- **Logo et icône** : nouveau logo (version claire pour le thème sombre), icône Android adaptative et monochrome, écran de lancement.
- **Couleurs** : Nuit `#022445`, Menthe `#00C9A7` (boutons principaux, texte Nuit dessus), Menthe profonde `#006B5B` (texte), Étincelle `#FF6B3D`. Les couleurs des verdicts du contrôle ne changent pas.
- **Polices** : Nunito pour les titres (remplace Manrope), Inter pour le texte.
- **APK** : liens `Tikeo-arm64-v8a.apk` / `Tikeo-armeabi-v7a.apk` ; les anciens liens restent valables.

### Ajouté (lot 2 : thème sombre et finitions visuelles)
- **Choix du thème** dans Profil › Apparence : Système (par défaut), Clair ou Sombre. Le choix est propre à l'appareil et enregistré dans ses préférences.
- **Thème sombre complet** : tous les conteneurs Material 3 sont définis (bas, moyen, haut, plus haut), ainsi que les conteneurs secondaires et tertiaires, la surface inverse et les contours atténués, en clair comme en sombre. Les feuilles et boîtes de dialogue se détachent du fond.
- **Palette sémantique** `TicketSurPalette` (accent, réussite, avertissement, danger, secondaire, encadré d'avertissement), qui suit le thème. Elle remplace les couleurs fixes (bleu, ambre, rouge, ardoise) des textes et icônes posés sur les surfaces : statuts des tickets, sur-titres, encadrés « À compléter », fenêtre de contrôle, alertes d'import. Les pastilles de statut d'événement ont leur version sombre.
- **Audit automatique des contrastes** (`test/design_system/contrast_audit_test.dart`) : 11 écrans parcourus en entier, en clair et en sombre. Chaque texte visible est mesuré contre le fond réellement peint dessous (seuils WCAG AA). Plus 148 contrôles des paires de couleurs des deux thèmes.

### Corrigé
- Barre de navigation : libellés en 12 px (Material 3). « Événements » ne se coupe plus en deux lignes sur les écrans de 360 à 415 dp.
- Catégorie d'invitations : la mention « Invitations » débordait de la ligne de la catégorie. Elle est maintenant sous le nom.
- CI : l'installation du client PostgreSQL est sautée quand l'image en fournit déjà un (les miroirs Ubuntu renvoyaient 503).

### Ajouté (lot 2 : invitations)
- **Base** : migration `1700`, colonne `ticket_categories.is_invitation`.
  - `create_ticket_category` / `update_ticket_category` acceptent `p_is_invitation`. Par défaut `NULL` = inchangé, donc une APK plus ancienne qui modifie une catégorie d'invitations ne retire pas la marque.
  - La marque est renvoyée par `event_categories`, `issue_named_tickets`, `export_tickets`, `event_tickets` et `event_report_rows`.
  - `event_dashboard` compte les invitations à part (`invitations`, `invitations_admitted`).
  - Tests SQL `97_invitations.sql`.
- **Catégories** : interrupteur « Catégorie d'invitations » dans la fiche, et badge « Invitations » dans la liste.
- **Tickets des catégories d'invitations**, présentés comme des invitations :
  - carte et image avec la mention « INVITATION » et un filet doré ;
  - PDF avec « Invitation · catégorie » ;
  - message WhatsApp / SMS / e-mail rédigé comme une invitation (« vous êtes invité(e) à… »), avec l'objet « Votre invitation : … » ;
  - fichiers nommés `Invitation-…`.
  - Le contrôle à l'entrée ne change pas : même QR, mêmes règles, une seule entrée.
- **Tableau de bord et rapport** :
  - ligne « Invités : X entrés sur Y invitations » ;
  - catégories d'invitations signalées ;
  - colonne « Type » (Ticket / Invitation) dans la liste CSV.

### Modifié
- CI : l'installation du client PostgreSQL (db-tests, staging-tests) fait 3 essais, à cause des erreurs 503 des miroirs Ubuntu.

### Ajouté (lot 2 : rapports d'événement)
- **Base** : migration `1600`, fonction `event_report_rows` (organisateurs et gestionnaires seulement ; 50 000 lignes au plus). Chaque export est tracé dans `audit_logs` avec le seul nombre de lignes, sans donnée personnelle. Tests SQL `96_report.sql`.
- **Tableau de bord** : bouton « Rapport » avec deux choix, partagés comme les autres fichiers de l'app.
  - **Bilan PDF** (A4) : chiffres relus au moment de l'export, entrées par heure, catégories, points de contrôle, motifs de refus, contrôleurs, numéros de page.
  - **Liste des tickets (CSV)** pour Excel en français : `;`, BOM, CRLF, heures dans le fuseau de l'événement. Les téléphones sont écrits `00226 70 11 22 33` pour rester du texte, et les cellules commençant par `= + - @` sont neutralisées. Le fichier se relit avec l'import de l'app.

### Ajouté (livraison de l'APK de pilote)
- `android-build` publie, à chaque build sur `main` dont la signature stable est vérifiée, une GitHub Release `pilote-<build>`. Les APK y portent des noms fixes, d'où un lien direct permanent vers la dernière version, téléchargeable sans compte GitHub ni archive zip (`…/releases/latest/download/TicketSur-staging-arm64-v8a.apk`). Les empreintes SHA-256 sont dans les notes. Les 15 dernières versions sont gardées. Liens dans le README.

### Ajouté (lot 2 : envoi assisté des tickets, ADR 0010)
- **Base** : migration `1500`.
  - Journal `ticket_deliveries` (canal, auteur, heure du serveur ; aucune donnée personnelle), lisible des seuls organisateurs, sans écriture directe.
  - `record_ticket_delivery` : tickets valables seulement.
  - `event_tickets` renvoie le dernier envoi et accepte `p_undelivered` (tickets jamais envoyés).
  - Tests SQL `95_deliveries.sql`.
- **Android** : canal `ticketsur/send` dans `MainActivity` et `FileProvider` dédié.
  - WhatsApp (ou WhatsApp Business) s'ouvre sur la conversation du titulaire, avec l'image du ticket jointe.
  - SMS : MMS avec l'image si possible, sinon texte seul.
  - E-mail : avec le PDF.
- **Fiche du ticket** : carte « Envoyer au titulaire » avec un bouton par canal disponible et le dernier envoi. Au retour, l'app demande « Le ticket est-il parti ? », et seul un « oui » enregistre l'envoi.
- **Écran « Envoyer les tickets »** (onglet Tickets et fin d'import) : les tickets valables jamais envoyés, dans l'ordre d'émission, un par un, avec une progression et les compteurs envoyés / passés. Les jetons sont relus par paquets de 20.
- **Liste** : « Envoyé par WhatsApp le … » sur les tickets envoyés.
- **Image du ticket** rendue hors écran (même carte que le partage depuis la fiche).

### Modifié
- CI `android-build`, contre le refus de Maven Central (HTTP 429) :
  - la clé du cache Gradle suit aussi `pubspec.lock`. Une extension Android ajoutée (comme `file_picker`) laissait sinon l'ancien cache sans ses dépendances de build ;
  - un script d'initialisation Gradle, en CI seulement (`.github/gradle/maven-mirror.init.gradle`), fait passer tous les dépôts `mavenCentral()` (projet, Flutter, extensions) par le miroir officiel de Google.

### Ajouté (lot 2 : émission depuis une liste Excel ou CSV)
- Écran « Importer une liste », ouvert depuis l'onglet Tickets (bouton d'en-tête) et la feuille d'émission. Il émet un ticket nominatif par ligne, en un seul appel tout ou rien (`issue_named_tickets`, 500 lignes au plus).
- Lecture sur l'appareil :
  - Excel `.xlsx` : première feuille, textes partagés ou en ligne, texte enrichi, téléphones saisis comme nombres ;
  - CSV : séparateur `;`, `,` ou tabulation détecté, guillemets, UTF-8 ou Windows-1252 ;
  - un `.xls` reçoit un message clair, et un fichier de plus de 5 Mo est refusé.
- Colonnes reconnues par leur en-tête, même sous un titre : nom, ou prénom et nom, téléphone, e-mail, catégorie (synonymes français courants). Sans en-tête, les colonnes sont devinées d'après leur contenu.
- Aperçu avant l'envoi :
  - lignes prêtes, erreurs citées par leur numéro de ligne dans le tableur (nom manquant, téléphone ou e-mail invalide, catégorie inconnue) ;
  - doublons de téléphone ou d'e-mail signalés ;
  - répartition par catégorie, quotas et capacité vérifiés.
  L'envoi reste bloqué tant que les erreurs ne sont pas ignorées explicitement.
- Catégorie par défaut au choix pour les lignes sans catégorie ; modèle CSV à partager (avec BOM, pour qu'Excel affiche les accents).
- Après l'émission : partage de tous les tickets en PDF.
- Dépendances : `file_picker` (sélecteur Android) ; `archive` et `xml`, déjà présentes, deviennent directes.

### Ajouté (lot 2 : tickets nominatifs)
- Base : migration `1400`. Titulaire facultatif sur les tickets (nom, téléphone au format international, e-mail), lisible des seuls propriétaires et gestionnaires, jamais dans le QR ni dans le journal d'audit.
  - `issue_named_tickets` : de 1 à 500 lignes, catégories mélangées, tout ou rien, erreurs avec le numéro de ligne.
  - `set_ticket_holder` : modification réservée aux tickets valables, journalisée sans les valeurs.
  - `event_tickets` et `export_tickets` renvoient le titulaire, et la recherche porte aussi sur le nom, le téléphone et l'e-mail.
  - L'émission a désormais un cœur unique (`private.issue_ticket_rows`). Le contrat de `issue_tickets` est inchangé, et les quotas et la capacité restent vérifiés sous verrou.
  - Tests SQL `90_named_tickets.sql`.
- Application :
  - un ticket émis seul peut recevoir un titulaire (nom, téléphone, e-mail), vérifié avant l'envoi avec les mêmes règles que le serveur ;
  - le nom est imprimé sur l'image et le PDF (« Titulaire : … ») ;
  - la liste affiche le nom d'abord, et la recherche porte aussi sur le nom ;
  - la fiche du ticket permet d'ajouter, modifier ou effacer le titulaire tant que le ticket est valable.

### Ajouté (lot 2 : tableau de bord en direct)
- Base : migration `1300`, fonction `event_dashboard` (lecture seule, propriétaires et gestionnaires) : tickets émis, entrés, attendus, annulés et expirés ; tentatives, refus par motif, entrées des 15 dernières minutes ; détail par catégorie, par porte et par contrôleur ; chronologie des passages (48 tranches au plus, de 5 min à 1 jour, alignées sur le fuseau de l'événement). Aucun jeton ni référence de ticket dans la réponse. Tests SQL `80_dashboard.sql`, rejoués sur le staging.
- Application (DASH-01, S19) : écran « Tableau de bord » ouvert depuis la fiche événement et l'Accueil : anneau du taux d'entrée, indicateurs, histogramme des entrées et refus, motifs de refus, catégories, portes (fermées signalées), contrôleurs. Actualisation toutes les 15 s tant que l'écran est visible et l'application au premier plan, et à la demande (glisser ou bouton).
- Connexion (DASH-03) : état « En direct », « Contrôle fermé » ou « Non actualisé ». Un échec ne remplace jamais les chiffres : ils restent affichés avec l'heure serveur de leur calcul.

### Corrigé
- « Supprimer les animations » : les zones qui s'agrandissent (Accueil, sections de la fiche événement, équipe) déclenchaient une erreur de mise en page avec une animation de durée nulle. Nouveau composant `MotionSize`.

### Ajouté (lot 1 : profil et fiche d'organisation)
- Profil modifiable : migration `1200` (`my_profile`, `update_my_profile` avec téléphone normalisé au format international, `set_my_avatar`, `request_account_deletion`) ; bucket public `avatars` (dossier personnel seulement). Écrans : en-tête avec photo, nom, adresse et téléphone ; « Modifier le profil » (photo, nom, téléphone) ; Sécurité (changer le mot de passe après revérification de l'actuel, changer d'adresse par lien de confirmation, déconnecter tous les appareils) ; suppression du compte programmée à 30 jours avec confirmation par le mot SUPPRIMER et annulation possible.
- Fiche d'organisation : `update_organization` (nom, téléphone, e-mail de contact, ville) et `set_organization_logo` réservés aux propriétaires, bucket public `org-logos` ; `leave_organization` (affectations retirées, dernier propriétaire refusé : `org_last_owner`). Écrans : carte Organisation du profil (logo, rôle, ville, modifier, changer, quitter) et page « Fiche de l'organisation ».

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
