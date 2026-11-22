# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versionnement sémantique à partir de la première APK pilote.

## [Non publié]

### Ajouté (côté promoteur, ADR 0048)
- **Accueil** : « Entrés » et « Émis » ouvrent l'onglet Tickets filtré, « Présence » le tableau de bord ; les tuiles « En cours », « À venir », « Brouillons » ouvrent la liste filtrée.
- **Fiche d'un membre de l'équipe** : entrées validées, dernière entrée, affectations à venir avec la porte, modification du rôle ou de l'accès.
- **Tuiles blanches** sur tous les formulaires et textes qui étaient posés sur le fond (profil, structure, formulaire d'événement, support, paiement, mentions légales, console…).
- Migration 5800 : `member_activity`.

### Corrigé
- Test base de données `95_deliveries` : ne dépend plus d'une référence de ticket aléatoire.

### Ajouté (structures : suivre, partager, présenter, ADR 0047)
- **Suivre une structure** depuis sa page : nombre d'abonnés, notification à la première mise au catalogue de chacun de ses événements, structures suivies dans les Favoris.
- **Partager la page d'une structure** : image (statut ou publication) et texte.
- **Présentation et réseaux** (Facebook, Instagram, TikTok) saisis dans « Modifier la structure », affichés sur sa page publique.
- Migration 5700.

### Ajouté (fiches touchables, ADR 0046)
- **Fiche publique** : la date ajoute l'événement à l'agenda du téléphone ; le lieu ouvre l'itinéraire dans Google Maps ; le type et la ville ouvrent l'Explorer filtré ; « Du même organisateur » en bas de la fiche.
- **Mon ticket** : « Voir la fiche de l'événement », « Organisé par … » (page de la structure), « Ajouter à mon agenda ».
- Migration 5600 : `my_tickets` renvoie `organization_id` et `event_listed`.

### Ajouté (page publique d'une structure, ADR 0045)
- **Fiche publique d'un événement** : « À propos » dans une tuile blanche ; le bloc « Organisé par » montre le logo de la structure et ouvre sa **page publique**.
- **Page publique d'une structure** (`/organisateur/:id`, avec ou sans compte) : logo, nom, ville, « Sur Tikéo depuis », événements à venir et déjà organisés, bouton « Contacter sur WhatsApp », liste des événements à venir.
- Migration 5500 : `public_organization(id)` (données publiques seulement) et `organization.id` dans `public_event`.

### Ajouté (structure fermée en consultation seule, ADR 0044)
- **Structure fermée consultable** par son propriétaire et ses gestionnaires : Profil › « Structures fermées » (visible seulement s'il y en a une). Bandeau « consultation seule », événements avec leurs chiffres (tickets, entrés, annulés), bilan PDF et liste des tickets en CSV de chaque événement, factures pour le propriétaire. Rien ne peut être modifié.
- Migration 5400 : fonctions de consultation dédiées ; `has_org_role` n'accepte une structure fermée que pendant une consultation (réglage local `tikeo.closed_read`), les écritures restent refusées.

### Ajouté (lot 4-10 — Explorer sans réseau, ADR 0043)
- **Explorer sans réseau** : les derniers résultats (4 dernières recherches) et « À la une » restent affichés, avec le bandeau « Hors ligne, mis à jour il y a … ». Les événements terminés sont écartés.
- **Mise à jour au retour du réseau** sans rien toucher : nouvel essai régulier (15 s, 30 s, 1 min, puis toutes les 2 min) et immédiat au retour dans l'app ; la liste est remplacée sans écran de chargement.

### Modifié (lot 4-9 PR C — Accessibilité et cohérence)
- **Texte à 200 %** : l'audit automatique vérifie désormais chaque écran jusqu'à 200 % de taille de texte (169 % avant). Débordements corrigés : titres de section avec « Tout voir », structure active du Profil (« Changer » passe dessous en très grand texte), barre d'étapes du formulaire d'événement, courbes et annonces de la console, récapitulatif des suppléments.
- **Une seule boîte de confirmation** (`confirmAction`) pour les 12 « Oui / Non » de l'app (texte qui défile s'il est long, bouton rouge pour les actions dangereuses).
- **Un seul champ de recherche** (`TikeoSearchBar`) partout : recherche du promoteur, recherche à la porte, listes et sélecteurs de la console.
- Échelle typographique documentée : `docs/design/echelle-typographique.md`.

### Interne (lot 4-9 PR B — Captures de référence)
- 24 captures de référence (12 écrans clés, clair et sombre, vraies polices) comparées à chaque PR : une différence visuelle non voulue fait échouer la vérification. Après un changement voulu : `flutter test --update-goldens test/goldens`.
- Données de démonstration communes à l'audit des contrastes et aux captures (`test/helpers/showcase.dart`).

### Interne (lot 4-9 PR A — Découpage des gros écrans)
- Tableau de bord de l'événement, formulaire d'événement, onglet Tickets, réglages et fiche de l'événement découpés en fichiers plus petits (`part`), sans aucun changement de comportement : le code déplacé est identique et les tests existants passent sans modification.

### Ajouté (lot 4-11d-2 — Maintenance, inscriptions, exports, ADR 0042)
- **Mode maintenance** (Console › Réglages) : bandeau « Maintenance en cours » pour tous, avec un message ; au besoin, modifications bloquées sauf pour les administrateurs. Le contrôle à l'entrée, « Mes tickets » et le support continuent.
- **Inscriptions ouvertes ou fermées** : fermées, un compte se crée seulement avec le code d'invitation d'une structure, ou depuis la console.
- **Exports pour Excel** (Console › Exports) : comptes, structures, événements, factures, journal, en CSV ; chaque export est inscrit au journal.
- La version minimale de l'app n'est pas incluse (décision de Toussaint).

### Ajouté (lot 4-11d-1 — Recherche globale, messages ciblés, journal filtrable, ADR 0041)
- **Recherche globale de la console** : un seul champ pour retrouver un compte, une structure, un événement ou un ticket.
- **Envoyer un message** depuis la fiche d'un compte (conversation dans « Support », la personne peut répondre), d'une structure (membres actifs) ou d'un événement (détenteurs qui ont ajouté leur ticket à « Mes tickets ») : notification et bandeau dans l'app pendant 1 à 30 jours.
- **Journal filtrable** par compte, structure, événement et administrateur ; bouton « Journal » sur chaque fiche.

### Ajouté (lot 4-11c — Événements et tickets depuis la console, ADR 0040)
- **Événements** (Console › Événements) : tous les événements de la plateforme, recherche et filtre par état ; fiche avec catégories, portes, tickets émis, valables, entrés et annulés, historique des actions.
- **Actions sur un événement**, avec un motif : modifier le titre, le lieu, la ville, l'adresse, l'accroche, la description, la capacité ; changer les dates ; rendre public ou privé ; changer l'état (publier, démarrer, clôturer, archiver, **annuler**, même en cours : tickets non entrés annulés et détenteurs prévenus) ; **déplacer** vers une autre structure ; mettre un brouillon sans ticket à la **corbeille**.
- **Tickets** (Console › Tickets) : recherche sur toute la plateforme par référence, nom ou téléphone ; fiche (événement, catégorie, entrée, envois, « Mes tickets »), sans QR ; **changer le titulaire**, **annuler le ticket**.
- **Émettre des tickets à la place d'un promoteur**, seulement si le réglage de la console est activé.
- La corbeille montre aussi les brouillons d'événements.

### Ajouté (lot 4-11b — Structures depuis la console, ADR 0039)
- **Fiche d'une structure** (Console › Structures › « Ouvrir la fiche ») : informations, propriétaire, membres, invitations en cours, derniers événements avec tickets et entrées, pack du propriétaire, factures, historique des actions de la console.
- **Créer une structure** pour un compte (depuis la liste des structures ou la fiche du compte), au pack de ce compte.
- **Modifier** une structure (nom, ville, téléphone, e-mail, WhatsApp public), **retirer son logo** ; **membres** : ajouter un compte, changer le rôle, retirer, transférer la propriété ; annuler une invitation.
- **Supprimer** (super administrateur, double authentification, nom à recopier) : une structure vide part à la **corbeille** (restaurable 30 jours, puis effacée automatiquement) ; une structure qui a servi est **fermée définitivement** : événements à venir annulés, tickets non entrés annulés et détenteurs prévenus, factures gardées. Les conséquences sont affichées avant de confirmer.
- **Corbeille** dans la console : restaurer, jours restants avant l'effacement.

### Ajouté (lot 4-11a — Rôles d'administration et comptes, ADR 0038)
- **Quatre rôles d'administration** : super administrateur, support, modération, finance ; chaque action de la console est réservée aux rôles concernés, contrôlé par le serveur. Le rôle s'affiche en tête de la console.
- **Fiche d'un compte** (Console › Comptes › « Ouvrir la fiche ») : identité, structures, tickets dans « Mes tickets », demandes au support, appareils connectés et historique des actions de la console avec leur motif.
- **Actions sur un compte**, toujours avec un motif : modifier le nom et le téléphone, changer l'adresse e-mail, donner un **mot de passe provisoire**, déconnecter partout, annuler une demande de suppression, **supprimer maintenant** (saisie de l'adresse e-mail), donner ou retirer un rôle d'administration, retirer la double authentification d'un administrateur.
- **Créer un compte** depuis la console, avec un mot de passe provisoire affiché une seule fois ; à sa première connexion, la personne choisit son mot de passe avant tout le reste.
- **Réglages et administrateurs** : « Prévenir la personne par défaut » et « Émettre des tickets à la place d'un promoteur » (désactivés par défaut), liste des administrateurs et de leur rôle.
- La double authentification est exigée pour créer ou supprimer un compte et pour changer un rôle.
- Correctif du déploiement : la permission de chaque fonction de la console est portée par `application_name` (Supabase refuse un paramètre personnalisé attaché à une fonction) ; test de garde ajouté.

### Ajouté (lot 4-8b — Double authentification des administrateurs, ADR 0037)
- **Proposée, pas obligatoire** : Profil › Sécurité › « Double authentification » (administrateurs) ; activation par QR code ou clé dans une application d'authentification, puis code à 6 chiffres.
- Une fois activée, la **console demande le code** une fois par session ; le serveur refuse la console sans ce code.
- **8 codes de secours** affichés une seule fois ; un code retire la double authentification si le téléphone est perdu (5 essais par heure).

### Ajouté (lot 4-8a — Console pro, ADR 0036)
- **Annonces programmées** : « Programmer » avec date et heure de début ; état « Programmée » dans la liste ; modification tant que l'annonce n'a pas commencé ; la notification d'une annonce importante part à l'heure prévue (à 5 minutes près).
- **Réponses types du support** : gérées dans la console (titre et texte, 50 au plus) ; dans le fil d'une demande, le bouton « Réponses types » insère le texte, modifiable avant l'envoi.
- **30 derniers jours** sur la vue d'ensemble : comptes, structures, événements publiés, tickets émis et entrées, jour par jour.

### Corrigé (lot 4-8a)
- Journal de la structure : libellés des réglages de la structure et des propositions ajoutées à un événement.

### Ajouté (lot 4-7b — Réglages de la structure, ADR 0035)
- **Réglages de la structure** (Profil › Structure active, propriétaire et gestionnaires) :
  - **message d'envoi** d'un ticket et d'une invitation par WhatsApp, SMS ou e-mail, partagé par toute l'équipe, avec des champs à insérer (prénom, événement, date, lieu, catégorie), un aperçu et « Revenir au message par défaut » ; le QR code reste dans la pièce jointe, jamais dans le message ;
  - **valeurs d'un nouvel événement** : fuseau, ville, type, catégories proposées (nom, quota, prix indicatif, invitation) et portes proposées. À la création, une case de l'aperçu ajoute les catégories et portes proposées.
- Journal : la modification des réglages est consignée sans le texte du message.
### Ajouté (lot 4-7a — Gestes et mémoire)
- **Balayer pour agir** (vers la gauche, avec « Annuler ») : retirer un favori, retirer un membre de l'équipe d'un événement ; dans la console, balayer une demande du support la ferme.
- **Filtres retenus** : filtre de la liste des événements, événement, statut et type de l'onglet Tickets, filtres de la console (comptes, support) restent choisis d'une visite à l'autre, par compte et effacés à la déconnexion ; la ville de l'Explorer est retenue sur l'appareil.

### Corrigé (lot 4-7a)
- En mode sélection, les messages s'affichent **au-dessus** de la barre d'actions au lieu de la masquer.

### Corrigé (visionneuse de photo)
- **Photo en grand** : elle s'affichait toute petite en haut de l'écran noir. La visionneuse occupe maintenant tout l'écran et la photo y est entière et centrée (zoom à deux doigts inchangé).

### Corrigé (photo et écran Organiser)
- **Photo d'un événement en grand** : la sélection du texte n'enveloppe plus la photo ; un appui n'importe où sur la photo de la fiche (titre compris) l'ouvre, et un bouton « Voir la photo en grand » est visible sur la fiche du promoteur et la fiche publique.
- **Écran Organiser** : la carte de l'événement à venir montre la photo **entière** en haut (bords flous si ses proportions diffèrent) et le texte dessous, sans dégradé ni texte posé sur la photo.

### Ajouté (lots de tickets, ADR 0034)
- **Lots de génération** : chaque émission (rapide, nominative ou import) forme un lot numéroté ; bouton « Lots » dans l'onglet Tickets pour afficher un lot, **sélectionner tout le lot** ou imprimer directement sa **planche A4** ; numéro du lot sur chaque ticket. Les tickets déjà émis sont regroupés par émission d'origine.

### Modifié (lots de tickets)
- **1 000 tickets par lot** (au lieu de 500) pour l'émission rapide, nominative et l'import ; raccourcis 500 et 1 000.

### Ajouté (lot 4-6c — Sélection multiple, ADR 0033)
- **Événements** : appui long pour en choisir plusieurs, puis Rendre public, Rendre privé, Dupliquer (copies en brouillon une semaine plus tard) ou Archiver (clôturés ou annulés) ; confirmation, puis le nombre traité.
- **Mes favoris** : appui long pour en choisir plusieurs, « Retirer des favoris » avec « Annuler ».
- Barre d'actions en bas de l'écran en mode sélection.
- **Équipe d'un événement** : « Affecter » accepte plusieurs membres cochés pour la même porte ; les portes déjà attribuées sont indiquées.
- **Console** : appui long sur une structure, un compte ou une demande du support pour en choisir plusieurs ; suspendre ou réactiver des structures (motif commun), désactiver ou réactiver des comptes (jamais le sien), fermer des demandes.

### Ajouté (lot 4-6b — Recherche globale, ADR 0032)
- **Recherche** (loupe de l'Accueil, propriétaire et gestionnaires) : événements par titre, salle ou ville ; tickets de tous les événements par référence, nom du titulaire ou téléphone ; sans accents ni majuscules ; un appui ouvre la fiche. Le texte cherché n'est jamais journalisé.

### Ajouté (lot 4-6a — Sécurité des comptes, ADR 0031)
- **Appareils connectés** (Profil → Sécurité) : les téléphones où le compte est ouvert, l'appareil en cours d'abord, dernière activité ; **déconnecter un appareil** ou **tous les autres**. L'appareil déconnecté ferme sa session à son retour dans l'app et l'annonce.
- **Verrouiller par empreinte** (option, par appareil) : empreinte, visage ou code du téléphone au lancement et après 1 minute hors de l'app ; écran de déverrouillage avec « Se déconnecter ».

### Ajouté (améliorations du 20/11, PR 4 — Texte et console, ADR 0030)
- **Taille du texte** (Paramètres → Apparence) : Petite, Normale, Grande, Très grande, avec aperçu ; s'ajoute à la taille réglée sur le téléphone ; mémorisée.
- **Sélection du texte par appui long** (Copier) : fiche d'un événement (publique et promoteur), fiche d'un ticket, Mon ticket, fil du support, mentions légales, annonces, facture.
- **Console → Comptes → Attribuer une structure** : propriétaire (transfert, l'ancien propriétaire reste gestionnaire, quota de structures du pack vérifié), gestionnaire ou contrôleur ; motif obligatoire, journal, notification aux comptes concernés.

### Modifié (améliorations du 20/11, PR 4)
- **Polices réduites d'un cran** : titre d'en-tête 24, titre de section 18, texte 14, libellés 13 ; chiffres et boutons en proportion.
- Mise en page vérifiée à « Très grande » sur un téléphone déjà réglé à 130 % : montants, pastilles, légendes et lignes de chiffres passent à la ligne au lieu de déborder ; libellés de la barre du bas plafonnés à 115 %.

### Ajouté (améliorations du 20/11, PR 3 — Écrans, ADR 0029)
- **Imprimer des tickets** : l'icône ciseaux devient une icône d'impression ; feuille « Imprimer des tickets » avec **1 à 5 tickets par feuille A4**, aperçu de la feuille, nombre de feuilles et taille du QR (jamais sous 2 cm) ; « Générer le PDF ».
- **Détails d'une invitation** (Équipe) : rôle, état, **code masqué avec un œil pour l'afficher**, Copier, Partager, structure, créée par, dates, utilisations, personnes qui l'ont utilisée, Révoquer. Copie chiffrée du code côté serveur, affichage limité (30 par heure) et inscrit au journal ; invitations anciennes : « Code non récupérable ».
- **Mes favoris** : en-tête avec recherche et filtres, puces À venir / Passés / Tous avec compteurs, types, ville, tri (plus proches, plus récents), cartes d'Explorer, cœur rouge pour retirer avec « Annuler », état vide illustré.

### Modifié (améliorations du 20/11, PR 3 — Écrans)
- **Profil réorganisé** : carte du compte ; **Structure active** (logo, nom, rôle, pack, Changer ; informations, équipe et invitations, portes, facturation, journal selon le rôle) ; **Mes structures** (créer avec le quota du pack, rejoindre avec un code, quitter) ; **Mon compte** (informations personnelles, mes tickets, paramètres, aide et support, à propos) ; Sécurité ; Se déconnecter.

### Ajouté (améliorations du 20/11, PR 2 — Images et partage, ADR 0028)
- **À la une choisi par l'administrateur** (console → À la une) : liste ordonnée (monter, descendre, retirer), période de mise en avant, ajout d'un événement public à venir ; sans sélection, les 5 prochains événements publics.
- **Carte À la une** : photo entière (bords flous), plus de texte ni de dégradé dessus ; type, prix, titre, date, lieu et « Obtenir un ticket » dessous ; plusieurs cartes côte à côte.
- **Photo en grand** depuis la fiche d'un événement : zoom, partager, **télécharger dans la galerie**.
- **Partager l'événement en image** : Statut 9:16 ou Publication 4:5, aperçu, Enregistrer, Partager (avec le texte) ; le partage du texte seul reste possible.

### Corrigé (améliorations du 20/11, PR 1 — Corrections)
- **Réglages de paiement** (console) : l'enregistrement échouait sur Supabase (`UPDATE` sans `WHERE` refusé par l'extension `safeupdate`) ; fonction corrigée (migration 3900), test qui vérifie qu'aucune fonction ne contient d'`UPDATE` ou de `DELETE` sans `WHERE`, message lisible si l'enregistrement échoue quand même.
- **Retour sur la connexion et la création de compte** : Retour revient à l'écran d'où l'on vient (Explorer, Organiser…), jamais à une boucle Connexion ↔ Inscription ; Mot de passe oublié, Confirmer l'adresse et Nouveau mot de passe reviennent à la Connexion ; sans écran d'origine, Retour mène à Explorer au lieu de quitter l'app. Après connexion, la page demandée par un lien profond s'ouvre, pile vidée.
- **Déconnexion** (et « Déconnecter tous les appareils ») : Explorer, plus la page de connexion.
- **Organiser sans compte** : seulement la présentation de l'espace promoteur et Créer un compte, Se connecter, J'ai un code d'invitation (les événements se découvrent dans Explorer).
- **Centrage** des résumés du Contrôle (Ouverts, À venir, Portes), de l'Historique (Entrées, Refusés, Incertains) et de Mes tickets, à toute taille de texte.
- « Chargement de vos structures… » devient « Chargement… ».

### Modifié
- **Mise à jour** : vérifiée à chaque lancement (silencieuse sans réseau) ; fenêtre « Nouvelle version disponible » avec Télécharger.
- **Paramètres → Compte** : Changer le mot de passe, Changer d'adresse e-mail.
- **À propos** : page à part ouverte depuis le Profil (version, état de la mise à jour, « Vérifier maintenant », dernière vérification, conditions, confidentialité, aide et support) ; retirée des Paramètres.
- **Notification de test** : retirée des Paramètres, disponible dans la console pour les administrateurs.

### Ajouté (packs et facturation, PR 3b — Factures, limite atteinte, facturation d'un événement, ADR 0027)
- **Factures et reçus** : onglets Toutes, À payer, Payées ; **détail d'une facture à l'usage** : entrées réelles, entrées offertes, calcul par palier, suppléments, total, échéance, référence à indiquer, numéros Orange Money et Moov, **PDF** à partager.
- **Limite atteinte** : quand le pack bloque une action, une feuille explique la limite ; sur un événement à l'usage, **« Dépasser la limite »** ajoute le supplément à la facture de fin d'événement ; sinon suppléments, packs ou factures en retard.
- **Facturation d'un événement** (fiche de l'événement) : Comme la structure, Forfait ou À l'usage avec son pack ; figée dès le premier ticket ; **estimation en direct** et facture.
- **Essai gratuit** d'un pack forfait (jours d'essai réglés dans la console), une fois par compte.
- **Notifications** : pack activé ou demande refusée, rappel avant la fin du pack, facture émise, facture en retard.
- Envoi en série, import et planche A4 vérifient le pack de l'événement.
- Aucune fonctionnalité retirée.

### Ajouté (packs et facturation, PR 3a — Parcours d'achat, ADR 0027)
- **Profil › Mon pack** (propriétaire) : pack en cours, jauges de consommation (limite atteinte signalée), fonctions incluses, demande en attente, factures à payer, facturation par structure, factures et reçus.
- **Choisir un pack** : forfaits par durée (mensuel, trimestriel, etc.), pack mis en avant, offre Entreprise sur devis ; packs à l'usage avec « comment ça marche », paliers et **simulateur** du montant selon le nombre d'entrées ; « Utiliser pour ma structure ».
- **Suppléments** : tranches en plus (avec plafond) et fonctions en supplément, fonctions non incluses grisées avec le pack qui les propose, récapitulatif et total ; aussi en cours d'abonnement (estimation au prorata).
- **Paiement** : montant, référence à copier, numéros Orange Money et Moov à copier, opérateur, identifiant reçu par SMS, « J'ai payé », annuler la demande.
- **Demande en attente** : étapes (créée, paiement déclaré, vérification, activée), états activée, refusée, annulée ; retour à Mon pack, contacter le support.
- Aucune fonctionnalité retirée.

### Ajouté (packs et facturation, PR 2 — Console, ADR 0027)
- **Console › Facturation** : quatre nouvelles entrées, avec le nombre de paiements à vérifier.
- **Packs** (C1) : forfaits et packs à l'usage, filtres, publier, retirer, archiver, dupliquer.
- **Créer ou modifier un pack** (C2) : prix mensuel et prix de chaque durée (calculés, modifiables), jours d'essai ; prix par entrée, entrées offertes, paliers, délai de paiement ; options chiffrées (valeur incluse ou illimitée, supplément par tranche avec plafond) ; fonctions incluses, en supplément ou indisponibles ; aperçu, brouillon, publication.
- **À encaisser** (C3) : demandes d'activation et factures à l'usage, factures en retard, demandes traitées et factures payées.
- **Valider un paiement** (C4) : montant attendu, montant reçu (écart noté), Orange Money, Moov ou autre, identifiant de l'opérateur, date, note, dates de l'abonnement qui en découlent ; activer ou refuser ; marquer une facture payée.
- **Abonnements** (C5) : recherche, actifs / expirent bientôt / en grâce, prolonger, changer de pack, suppléments, résilier (motif obligatoire), activer un pack sans demande, changer la facturation d'un événement déjà figé.
- **Réglages de paiement** (C6) : numéros Orange Money et Moov, bénéficiaire, consigne, délais (paiement, émission de la facture, rappel, grâce).
- Serveur (migration 3700) : console en version 2 (e-mails, historique), prolonger, changer de pack, régler les suppléments, rechercher et changer la facturation d'un événement ; motif obligatoire, journal sans donnée personnelle.

### Modifié (direction artistique, PR F3 — Mes tickets, support, paramètres, console, ADR 0026)
- **Mes tickets** : en-tête illustré, lignes avec vignette, statut et catégorie (VIP dorée), trait de la couleur du statut ; **nouveau** : résumé (prochains, valables, terminés).
- **Mon ticket** : en-tête avec le titre de l'événement, bandeau d'état coloré, « Retirer de mes tickets » en bouton rouge. **Ajouter un ticket** : en-tête, choix en lignes de couleur, bouton principal.
- **Aide et support** : en-tête illustré, demandes en cartes avec une icône par catégorie ; nouvelle demande et fil avec barre Nuit, bulles menthe pour vos messages.
- **Paramètres** : en-tête illustré, sections avec icône.
- **Console** : en-tête illustré, chiffres de la plateforme en tuiles de couleur, modules en lignes de couleur ; toutes les pages de la console, le journal de la structure et les mentions légales ont la barre Nuit.
- Aucune fonctionnalité retirée.

### Modifié (direction artistique, PR F2 — Événements, ADR 0026)
- **Liste des événements** : en-tête illustré, filtres en pastilles posés dessus, sections avec icône, lignes avec vignette, date, type, lieu et statut.
- **Fiche événement** : type en pastille sur la photo, « Tableau de bord en direct » en bouton principal, « Contrôler les entrées » en bouton sombre, dates, lieu et capacité en lignes de couleur, statut, catégories (VIP dorée, invitations saumon), portes et équipe en cartes.
- **Créer ou modifier un événement** : en-tête Nuit avec les étapes en menthe, boutons « Suivant » et « Créer » au nouveau style.
- Les cartes posées sur l'en-tête (contrôle, historique, tableau de bord, bilan) reprennent la largeur prévue et restent touchables sur toute leur hauteur.
- Aucune fonctionnalité retirée.

### Modifié (direction artistique, PR F1 — Contrôle, scanner, tableau de bord, bilan, ADR 0026)
- **Contrôle des entrées** : en-tête illustré, résumé (contrôles ouverts, à venir, portes), événements en cartes avec l'état du contrôle en pastille, date et lieu, portes en boutons.
- **Scanner** : cadre de visée menthe sur voile Nuit, porte en pastille, boutons « Saisir le code » et « QR perdu ? Rechercher » côte à côte.
- **Nouveau sur le scanner** : nombre d'entrées acceptées et de refus depuis l'ouverture du poste.
- **Historique** : en-tête, lignes avec la couleur du verdict ; **nouveau** : résumé des 7 jours (acceptés, refusés, incertains).
- **Tableau de bord en direct** : en-tête avec le titre de l'événement, taux d'entrée dans une carte posée dessus, état « En direct » en pastille, chiffres en tuiles de couleur, sections en cartes.
- **Bilan** : en-tête, chiffres clés dans une carte posée dessus, barres aux couleurs de la marque.
- Couleurs des verdicts inchangées. Aucune fonctionnalité retirée.

### Modifié (direction artistique, PR E — Connexion et compte, ADR 0026)
- **Bienvenue** : en-tête « Découvrez les événements », aperçu des événements, carte « Organiser », et un espace Tikéo en bas (créer un compte, se connecter, code d'invitation, conditions et confidentialité).
- **Connexion**, **Inscription**, **Mot de passe oublié** et **Rejoindre une structure** : en-tête illustré, formulaire dans une carte posée dessus, champs avec leur intitulé, bouton principal en dégradé, erreurs en bandeau coloré.
- **Nouveau** : solidité du mot de passe affichée à l'inscription et au changement de mot de passe.
- **Nouveau** : après l'inscription, écran « Confirmez votre adresse » avec les étapes, « Ouvrir ma messagerie » et le renvoi de l'e-mail (après 60 s).
- **Nouveau** : « Mot de passe oublié » indique quoi faire si rien n'arrive, ouvre la messagerie et permet de renvoyer le lien.
- **Nouveau** : le lien de l'e-mail ouvre l'écran « Nouveau mot de passe » dans l'application (règles cochées au fil de la saisie).
- **Nouveau** : après avoir rejoint une structure, écran de bienvenue avec le rôle reçu.
- **Nouveau** : « J'ai un code d'invitation » sur l'écran de connexion.
- Aucune fonctionnalité retirée.

### Modifié (direction artistique, PR D — Tickets, Équipe, Profil, ADR 0026)
- **Tickets** redessinés : en-tête illustré, événement choisi avec sa photo, résumé « émis · entrés », filtres en pastilles, lignes avec la couleur du statut (Valable, Utilisé, Annulé, Expiré).
- **Fiche ticket** : ticket posé sur l'en-tête, bandeau d'état coloré, titulaire, boutons d'action plus visibles.
- **Émettre des tickets** : boutons principaux au nouveau style.
- **Équipe** : en-tête illustré, rôles en pastilles de couleur (Propriétaire, Gestionnaire, Contrôleur), invitations et membres en cartes.
- **Nouveau dans Équipe** : nombre de membres actifs, de gestionnaires et de contrôleurs.
- **Profil** : photo en grand avec un crayon pour la modifier, structure et ses actions, raccourcis, sécurité, suppression du compte et déconnexion.
- Aucune fonctionnalité retirée.

### Modifié (direction artistique, PR C — Accueil promoteur, Explorer, fiche publique, ADR 0026)
- **Accueil promoteur** redessiné : en-tête bleu nuit avec la salutation, structure active dans une carte posée dessus, actions rapides en tuiles, événement du moment en grande carte avec ses chiffres d'entrée et « Suivre les entrées en direct », lignes « Mes événements » avec photo.
- **Nouveau sur l'Accueil** : quatre tuiles (événements, en cours, à venir, brouillons) qui ouvrent la liste.
- **Explorer** redessiné : en-tête avec la ville, recherche et filtres posés dessus, types en tuiles avec icône, carte « À la une », lignes avec photo, type et prix.
- **Fiche publique** redessinée : type et prix en pastilles, date et lieu, catégories (VIP mise en avant), bouton « Obtenir un ticket ».
- **Nouveau sur la fiche publique** : bouton « Appeler le promoteur » à côté de « Obtenir un ticket ».
- Explorer sans réseau : le message et « Réessayer » s'affichent dès le premier échec, pendant les nouveaux essais automatiques.
- Aucune fonctionnalité retirée.

### Ajouté (packs et facturation, PR 1 — Base, ADR 0027)
- **Packs côté serveur** : forfait (mois, trimestre, semestre, année, un seul événement) ou à l'usage (prix par entrée réelle, entrées offertes, paliers), options chiffrées ou oui / non, suppléments.
- **Quotas et fonctions vérifiés par le serveur** : structures, événements actifs, tickets par événement et par période, membres, contrôleurs, envoi assisté, export, design importé, tickets nominatifs, tableau de bord en direct, catalogue public. Jamais à la porte.
- **Factures à l'usage** automatiques : entrées réelles (chaque entrée d'un pass, invitations comprises), émises à la clôture du contrôle ou après la fin ; estimation en direct.
- **Demandes d'activation** (référence `TK-XXXX`, Orange Money ou Moov), paiements reçus et réglages validés par l'administrateur ; abonnements offerts avec motif.
- **Pack Découverte** (gratuit, sans limite tant qu'aucune n'est réglée) et **pack Lancement** offert 3 mois aux comptes existants : aucune fonctionnalité retirée.
- Journal : actions de facturation lisibles.
- **Base** : migration `3600` ; tests SQL `99_billing.sql` et concurrence `run_billing_concurrency.sh`.

### Ajouté (direction artistique, PR B — Composants et illustrations, ADR 0026)
- **Composants Tikéo** prêts pour les écrans :
  - en-tête bleu nuit à vague, carte qui le chevauche ;
  - tuiles de chiffres, actions rapides, carte d'événement mise en avant ;
  - lignes de liste et de réglage, bandeaux ;
  - bouton menthe en dégradé, champs, options, recherche et onglets ;
  - pastilles de type, de rôle et de prix ; point « en direct » ; cadre de QR.
- **17 illustrations** de marque : en-têtes (tickets, équipe, organiser, scanner, statistiques, Mes tickets, support, paramètres, console), connexion, états vides et succès.
- États vides des événements, des tickets et de Mes tickets, recherche sans résultat et erreur réseau de l'Explorer illustrés.
- Galerie de revue des composants (`/apercu/composants`).

### Modifié (direction artistique « Nuit et Menthe », PR A — Fondations, ADR 0026)
- **Nouvelles couleurs et formes** dans toute l'application : fond gris-bleu clair, cartes blanches très arrondies avec ombre douce, champs bordés, bouton principal menthe plus haut, liens en Menthe profonde, barre de navigation Nuit arrondie avec l'onglet actif en menthe ; thème sombre revu.
- **Pastilles de statut** aux couleurs des maquettes : ticket utilisé vert, valable bleu, annulé rouge, expiré gris ; événement en cours vert, à venir bleu, brouillon ambre, terminé gris.
- **Typographie** de la direction artistique (titres Nunito, texte Inter 15, petit texte 13).
- **Images plus légères** : couvertures, logos et photos de profil réduits et compressés avant l'envoi, avec une vignette pour les listes (moins de données mobiles).
- Aucune fonctionnalité retirée.

### Ajouté (lot 4-5 : rappels, envois automatiques, bilan, ADR 0025)
- **Rappels avant l'événement** pour les tickets ajoutés à « Mes tickets » : la veille et 2 h avant, dans la langue du compte ; la notification ouvre le ticket. Réglage dans Paramètres › Notifications.
- **Envois automatiques** : toutes les 5 minutes, la base prépare les rappels et relance les notifications en attente ou en échec.
- **Bilan d'après-événement** (tableau de bord › Bilan) : taux de présence, heures d'affluence et heure de pointe, détail par jour, entrées des pass, comparaison avec vos derniers événements. Repris dans le rapport PDF.
- **Base** : migration `3500` (`profiles.event_reminders`, `set_event_reminders`, `private.enqueue_event_reminders`, `private.push_tick`, tâche `pg_cron`, `event_summary`) ; tests SQL `99_reminders.sql`.

### Ajouté (lot 4-4c : pass à plusieurs entrées, ADR 0024)
- **Entrées par ticket**, réglées par catégorie : une seule (par défaut), une par jour (pass journalier) ou plusieurs au total (pass de 2 à 100 entrées). Règle figée dès la première entrée.
- **Contrôle** : « Entrée 2 sur 3 », « Pass journalier · jour d'entrée n° 2 », « Déjà entré aujourd'hui à 19:42 », « Pass épuisé ». Toujours en ligne, une entrée à la fois.
- **Tableau de bord** : personnes entrées et nombre total d'entrées.
- Le titulaire d'un pass ne change plus après sa première entrée.
- **Base** : migration `3400` (`entry_policy`, `max_entries`, `entries_used`, `set_category_entry_policy`, index « une acceptation par entrée ») ; tests SQL `99_entries.sql`.

### Ajouté (lot 4-4b : application en anglais, ADR 0023)
- **Paramètres › Langue** : langue du téléphone, Français ou English. Toute l'application est traduite (1 262 textes).
- Tickets, PDF, rapports, messages d'envoi, dates et montants dans la langue choisie.
- **Notifications** dans la langue de leur destinataire (langue du compte tenue à jour par l'application).
- **Mentions légales en anglais**, modifiables depuis la console (bouton Français / English).
- **Base** : migration `3300` (notifications par langue, `legal_documents.locale`, `legal_document(slug, locale)`, `admin_save_legal_document(…, locale)`).
- Tests : traductions complètes et mêmes variables ; audit des contrastes aussi en anglais.

### Ajouté (lot 4-4a PR 2 : modèles de tickets, suite)
- **Nom du titulaire placé à part** sur un design importé.
- **Cadrer la photo** d'un thème (partie visible et zoom).
- **Utiliser ce modèle pour d'autres catégories**.
- **Planche A4 à imprimer** (sélection de tickets › ciseaux) : 3 tickets par page, traits de coupe.
- **Mes tickets** : le ticket dessiné avec son modèle et son numéro, et un QR en grand ; disponibles aussi sans réseau.
- **Dupliquer un événement** garde l'accroche et les modèles (designs importés compris).
- **Base** : migration `3200` (`holder_x/y`, `cover_x/y/zoom`, `event_ticket_templates` en JSON, `my_tickets` enrichi, `duplicate_event`).

### Ajouté (lot 4-4a : modèles de tickets, ADR 0022)
- **Modèles de tickets** : fiche de l'événement › Catégories › « Modèles des tickets ». Un modèle par catégorie : 12 thèmes Tikéo (Concert, Match, Théâtre, Soirée club…) ou votre propre design. Sans choix, le thème est proposé selon le type d'événement.
- **Design importé** : le QR est posé automatiquement dans la plus grande zone blanche (sinon sur son carré blanc, à droite), puis déplacé et redimensionné au doigt, jamais sous 35 % de la hauteur.
- **Image envoyée et PDF** au format du modèle (bande 2,4:1) : numéro d'ordre « N° 000123 », référence, titulaire, catégorie, logos de la structure et de Tikéo.
- **Accroche** de l'événement (60 caractères), imprimée sur le ticket.
- **Base** : migration `3100` (`events.tagline`, `tickets.event_number`, `ticket_category_templates`, `set_event_tagline`, `event_ticket_templates`, `set_ticket_template`, `ticket_art_info`) ; tests SQL `99_templates.sql`.

### Corrigé (notifications)
- Clé d'envoi Firebase d'un autre projet : chaque envoi refusé (`SENDER_ID_MISMATCH`). `deploy-staging` refuse désormais une clé d'un autre projet que l'APK ; workflow `push-diagnostic` ; codes d'erreur Firebase détaillés.
- Notifications application fermée : la configuration Firebase est aussi intégrée en ressources Android (`google_app_id`…), pour que Firebase démarre sans Flutter. Vérifiée dans l'APK par la CI.

### Ajouté
- Paramètres › Notifications : **Envoyer une notification de test** (vers les téléphones du compte, 5 par heure, migration `3000`). L'attente de 8 s se fait sur le serveur (`delay_seconds`, 10 s au plus) : en arrière-plan, le téléphone suspendait le minuteur de l'app.
- `push-diagnostic` : heures de création et d'envoi, empreintes courtes (md5, 6 caractères) des comptes et appareils.

### Ajouté (lot 4-3 : titulaire à la porte, journal de la structure, ADR 0021)
- **QR perdu ? Rechercher** sur le poste de scan : par nom, téléphone ou référence, puis « Valider l'entrée ». Mêmes règles que le scan : une seule entrée, en ligne. Recherche limitée à la porte du contrôleur, contrôle ouvert, 10 résultats, téléphone masqué.
- **Nom du titulaire** affiché au verdict d'un ticket nominatif.
- **Journal de la structure** (propriétaire, depuis le Profil) : qui a émis, annulé, validé ou modifié quoi, avec filtres.
- **Base** : migration `2900` (`validate_scan` avec `holder_name`, `door_lookup`, `validate_ticket_at_door`, `door_lookups`, `organization_audit_logs`) ; tests SQL `99_door.sql`.

### Ajouté (lot 4-2 : notifications push, ADR 0020)
- **Notifications** par Firebase Cloud Messaging : réponse du support (au demandeur), annonce importante (aux destinataires choisis, visiteurs compris), contrôle ouvert (aux contrôleurs affectés).
- Application ouverte : bandeau avec « Voir » ; notification touchée : la page s'ouvre (adresses internes connues seulement).
- **Paramètres › Notifications** : couper ou rétablir ; état affiché (actives, coupées, refusées par le téléphone, indisponibles).
- **Base** : migration `2800` (`push_devices`, `push_outbox`, déclencheurs, `register_push_device`, `unregister_push_device`, `push_take_batch` et `push_mark` réservées à la fonction d'envoi) ; tests SQL `99_push.sql`.
- **Fonction Edge** `push-dispatch` (API HTTP v1), déployée par `deploy-staging` avec le secret `FCM_SERVICE_ACCOUNT_B64` ; types vérifiés par Deno dans `db-tests`.
- **CI** : identifiants Firebase tirés du secret `TIKEO_GOOGLE_SERVICES_JSON` ; sans secret, APK sans notifications.

### Ajouté (lot 4-1 : Mes tickets, ADR 0019)
- **Mes tickets** pour le spectateur : onglet d'un compte classique (Explorer, Mes tickets, Favoris, Profil) ; entrée dans le Profil pour un membre d'une structure.
- **Ajouter un ticket** par son QR : appareil photo, image de la galerie ou code collé. Un ticket n'entre que dans un seul compte ; un ticket annulé est refusé.
- **Fiche du ticket** : carte Tikéo avec QR à présenter à l'entrée, état (valable, utilisé, annulé), retrait.
- **Sans réseau** : liste et QR lus sur l'appareil, avec la date de la dernière mise à jour ; effacés à la déconnexion.
- **Base** : migration `2700` (`tickets.holder_user_id`, `claim_ticket`, `my_tickets`, `release_ticket`) ; journal sans donnée ; tests SQL `99_wallet.sql`.

### Ajouté (lot 3c-C : sélection multiple, duplication, premiers pas)
- **Sélection multiple des tickets** : appui long pour sélectionner, « Tout sélectionner », partage en PDF des tickets valables, annulation groupée avec motif. Retour quitte d'abord la sélection.
- **Dupliquer un événement** : titre et début de la copie (une semaine plus tard par défaut, même durée) ; catégories (invitations, prix), portes et affectations de l'équipe recopiées, jamais les tickets ; photo recopiée dans un fichier distinct ; la copie s'ouvre en brouillon.
- **Premiers pas** sur l'accueil du promoteur : créer, publier, émettre, inviter un contrôleur, numéro WhatsApp public ; progression, raccourcis, « Masquer ».
- **Base** : migration `2600` (`revoke_tickets`, 500 tickets au plus, une ligne de journal par ticket ; `duplicate_event`) ; tests SQL `99_bulk_duplicate.sql`.

### Ajouté (lot 3c-B : Paramètres, mises à jour, mentions légales, ADR 0018)
- **Paramètres** : apparence, sons et vibrations, images enregistrées (taille, « Vider »), version, « Rechercher une mise à jour », mentions légales. Le Profil n'a plus qu'une entrée « Paramètres ».
- **Nouvelle version disponible** : comparaison avec la dernière version pilote sur GitHub (toutes les 12 heures au plus), carte dans le Profil et les Paramètres, point sur l'onglet Profil, téléchargement de l'APK adaptée au téléphone. Le point s'affiche aussi pour une réponse du support non lue.
- **Mentions légales** : conditions d'utilisation et politique de confidentialité proposées, lisibles sans compte, liées depuis l'inscription ; **Console › Mentions légales** pour les modifier avec aperçu, chaque publication crée une version numérotée.
- **Base** : migration `2500` (`legal_documents`, `legal_document`, `admin_save_legal_document`) ; tests SQL `99_legal.sql`.
- **CI** : le numéro de build est passé à l'application (`TIKEO_BUILD`).

### Modifié (lot 3c-A : finitions visuelles)
- **Icônes** : style arrondi partout ; contour réservé aux onglets inactifs de la barre de navigation. Un test empêche de mélanger les styles.
- **Chiffres à chasse fixe** sur les compteurs animés, les chiffres de l'accueil et de la console : un nombre qui change ne fait plus bouger le reste.
- **Composants communs** : `StatusChip` (pastilles d'état du support et de la console) et `EmptyState` avec une petite illustration de marque (`BrandSpot`) pour les écrans vides des événements, tickets, favoris, support et contrôle.
- **Écran de démarrage Android 12 et plus** : fond Nuit et repère Tikéo, en clair comme en sombre.
- **Images gardées sur le téléphone** (couvertures, photos de profil) : chargées une seule fois, décodées à la taille d'affichage, cache limité à 80 Mo et élagué au démarrage.

### Ajouté (lot 3a-3 : support et annonces, ADR 0017)
- **Aide et support** dans le Profil : nouvelle demande (catégorie, sujet, message), liste de mes demandes, fil de conversation, réponse, fermeture. Pastille quand l'équipe a répondu.
- **Console › Support** : demandes non lues d'abord, filtres (en attente, répondu, fermée, toutes), recherche, réponse sous le nom « Support Tikéo », compteur sur l'accueil de la console.
- **Console › Annonces** : publication avec destinataires cochés (visiteurs sans compte, comptes classiques, promoteurs, contrôleurs), importance et durée ; retrait d'une annonce.
- **Bandeau d'annonces** sur la présentation, l'Explorer, l'accueil du promoteur et l'écran Contrôle ; masquable, mémorisé sur l'appareil.
- Journal : libellés des réponses du support et des annonces (sans contenu).
- **Base** : migration `2300`.
  - Tables `support_requests`, `support_messages` et `announcements`, sans accès direct.
  - `create_support_request`, `my_support_requests`, `support_thread`, `reply_support_request`, `close_support_request`, `admin_support_requests`, `admin_support_counts`.
  - `my_announcements`, `admin_publish_announcement`, `admin_archive_announcement`, `admin_announcements`.
  - Tests SQL `99_support.sql`.
  - Migration `2400` : aucun droit direct d'`anon` ni d'`authenticated` sur ces tables (privilèges par défaut de Supabase retirés).

### Ajouté (lot 3a-2 : comptes dans la console, ADR 0016)
- **Console › Comptes** : recherche par nom ou adresse, filtres (désactivés, suppression demandée, à supprimer, supprimés), dernière connexion, structures.
- **Désactivation** avec motif obligatoire, puis réactivation. Le compte perd ses droits dans ses structures. On ne peut pas désactiver son propre compte.
- **Suppression définitive** 30 jours après la demande, compte par compte ou en une fois :
  - structures du propriétaire suspendues ;
  - profil anonymisé ;
  - connexion rendue impossible ;
  - tickets et journaux conservés.
- Vue d'ensemble : comptes « à supprimer ».
- Journal : libellés des actions sur les comptes.
- **Base** : migration `2200`.
  - `admin_accounts`, `admin_set_account_status`, `admin_purge_account` et `admin_purge_due_accounts`.
  - Colonnes `profiles.disabled_at`, `disabled_reason` et `deleted_at`.
  - Tests SQL `99_console_accounts.sql`.

### Ajouté / modifié (comptes, structures, favoris, Retour, ADR 0015)
- **Vocabulaire** : « structure » (entreprise) remplace « organisation », et « promoteur d'événement » remplace « organisateur », dans tous les écrans.
- **Création de compte** dans l'application.
  - Compte classique par défaut : Explorer, Favoris et Profil, avec « Créer ma structure » et « Rejoindre une équipe avec un code ».
  - « Je suis promoteur d'événement » : nom de la structure et numéro WhatsApp public, structure créée dès l'inscription.
  - Code d'invitation facultatif.
  - Plus d'écran de création imposé à la première connexion.
- **Présentation sans compte** : découverte d'événements et liens vers l'inscription, la connexion et le code d'invitation ; l'aperçu des écrans est retiré.
- **Logo Tikéo** sur la connexion, l'inscription, le mot de passe oublié, la création de structure, le code d'invitation et l'Explorer.
- **Favoris**, avec ou sans compte : cœur sur les cartes et la fiche, onglet Favoris (à venir, passés), gardés sur l'appareil.
- **Promoteur** :
  - événements publics par défaut ;
  - liste des événements en sections En cours, À venir, Brouillons, Passés ;
  - tickets regroupés par type.
- **Retour** : fiche et tableau de bord d'un événement, ticket, import, envoi, profil et structure s'empilent au-dessus des onglets ; Retour revient toujours à l'écran précédent.
- **Contrôleur** : redirigé vers Contrôle s'il vise une page du promoteur ; aucun onglet hors de son rôle n'est affiché, même une image. Compte classique : redirigé vers l'Explorer.
- **Suppression du compte d'un propriétaire** : ses structures seront suspendues à l'échéance (texte de confirmation mis à jour ; purge au lot 3a-2).
- **Base** : migration `2100` (`events.is_public` vrai par défaut, `event_tickets(..., p_category_id)`).

### Corrigé
- Accueil sans événement : le bouton « Créer un événement » débordait sur petit écran.

### Modifié (contrôle démarré et arrêté par l'organisateur, ADR 0014)
- **Fin de la fenêtre horaire** (3 h avant le début, 6 h après la fin). Le contrôle est possible dès que l'organisateur touche « Démarrer le contrôle », à toute heure. Il devient impossible dès qu'il touche « Arrêter le contrôle », et c'est définitif. Un événement seulement publié n'est plus contrôlable.
- **Fiche événement** : bouton « Arrêter le contrôle » quand le contrôle est en cours ; textes du cycle de vie revus.
- **Contrôleur** : « Le contrôle n'a pas encore démarré » ou « Contrôle arrêté » selon le statut, sans heure. Postes visibles tant que le contrôle est en cours, même après l'heure de fin.
- **Tableau de bord** : la chronologie part du démarrage réel ; « En direct » tant que le contrôle est en cours.
- **Base** : migration `2000`.
  - `events.control_started_at` et `control_stopped_at`, posés par `set_event_status`.
  - `validate_scan` n'accepte que le statut `in_progress`.
  - `my_scan_posts` sans limite d'heure.
  - `event_dashboard` renvoie `control_open`.
  - Tests SQL mis à jour (démarrage, arrêt, événement terminé encore contrôlable).

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
