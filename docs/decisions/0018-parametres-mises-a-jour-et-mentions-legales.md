# ADR 0018 — Paramètres, mises à jour et mentions légales ; décisions du lot 3c

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint (réponses aux recommandations du 19/11)

## Contexte

Les recommandations du 19/11 (`claude/recommandations-tikeo.md` dans le projet) posaient cinq questions. Réponses de Toussaint :

1. Lot 3c « finitions pro » : **oui**, avant le lot 3b (packs et paiement), mis en pause.
2. Notifications push par Firebase Cloud Messaging : **oui** (lot 4). Le projet Firebase sera créé par Toussaint ; la clé serveur n'ira jamais dans l'application ni dans GitHub en clair.
3. Suivi des plantages (Sentry) : **pas pour le moment**.
4. Mentions légales : **Claude propose les textes, modifiables depuis la console**.
5. « Mes tickets » pour le spectateur : **oui** (lot 4).

## Décision

1. **Page Paramètres** (`/parametres`, ouverte à tous) : apparence, sons et vibrations, images enregistrées (taille, « Vider »), version, « Rechercher une mise à jour », mentions légales. Le Profil n'a plus qu'une entrée « Paramètres ».
2. **Mises à jour** :
   - le numéro de build est passé à l'application par la CI (`--dart-define=TIKEO_BUILD`) ;
   - l'application lit la dernière version pilote publiée sur GitHub (API publique, sans jeton), au plus toutes les 12 heures ;
   - si elle est plus récente, une carte « Nouvelle version disponible » s'affiche dans le Profil et les Paramètres, avec un point sur l'onglet Profil ; « Télécharger » ouvre le lien permanent de l'APK adaptée au processeur (64 ou 32 bits) ;
   - en développement (build 0), rien n'est vérifié.
3. **Mentions légales** :
   - table `legal_documents` (`terms`, `privacy`), sans accès direct ; lecture par `legal_document(slug)`, ouverte aux visiteurs sans compte ;
   - `admin_save_legal_document` publie une nouvelle version numérotée ; journal `admin.legal_updated` avec le document et le numéro, jamais le texte ;
   - textes proposés en version 1, fondés sur la loi n°001-2021/AN du 30 mars 2021 (protection des données) et la CIL ; les passages entre crochets (raison sociale, adresse, contact, ville, durée de conservation du support) sont à compléter depuis la console, qui les compte ;
   - affichées depuis les Paramètres et l'inscription (« En créant un compte, vous acceptez… »).

## Conséquences

- Les textes proposés ne remplacent pas l'avis d'un juriste.
- L'acceptation n'est pas encore enregistrée par compte (version acceptée) ; à ajouter si une nouvelle version doit être acceptée explicitement.
- La vérification passe par l'API GitHub, limitée à 60 requêtes par heure et par adresse IP : largement suffisant avec une vérification toutes les 12 heures.
