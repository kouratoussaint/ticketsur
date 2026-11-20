# ADR 0026 — Direction artistique « Nuit et Menthe »

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (direction artistique, 10 écrans principaux et 12 écrans de connexion validés le 20/11/2026)
- Références : docs du projet `claude/direction-artistique-tikeo.md` et `claude/direction-artistique-tikeo-complements.md` (le second l'emporte)

## Contexte

Toussaint a fourni des maquettes et validé une direction artistique. Elle garde l'identité de marque (ADR 0011 : Nuit `#022445`, Menthe `#00C9A7`, Menthe profonde `#006B5B`, Étincelle `#FF6B3D`, Nunito et Inter) et change le style des écrans : en-tête héros Nuit, cartes blanches très arrondies sur fond gris-bleu clair, une couleur par sens, grands chiffres, une action principale menthe par écran.

## Décision

1. **Règle de Toussaint : la direction artistique ne retire aucune fonctionnalité.** Elle peut en ajouter. Avant de restyler un écran, on liste ce qu'il permet ; tout reste accessible (menu « ⋮ », section repliée, bouton secondaire si une maquette ne le montre pas).
2. **Mise en œuvre en six PR** :
   - A, fondations ;
   - B, composants et illustrations ;
   - C, Accueil promoteur, Explorer et fiche publique (« Obtenir un ticket ») ;
   - D, Tickets, Équipe et Profil ;
   - E, connexion et compte (écrans A à L) ;
   - F, le reste et la relecture du thème sombre.

   Chaque PR liste les fonctions des écrans touchés et passe l'analyse, les tests, l'audit des contrastes et une relecture en image.
3. **PR A — Fondations** (cette PR) :
   - **Jetons** dans `lib/design_system/` :
     - `tikeo_tokens.dart` : surfaces claires et sombres, en-tête héros, Menthe vive, arrondis (pastille 999, champ 14, bouton 16, tuile 18, carte 20, héros 24, barre 28), ombres teintées de Nuit, tailles des éléments et des images, styles de texte (sur-titre, grands chiffres, numéro de ticket) ;
     - `tikeo_tints.dart` : teintes par sens (menthe, bleu, ambre, violet, rouge, saumon, vert, « en direct », gris, VIP, types d'événement) en clair et en sombre. En sombre, le fond est la couleur d'icône à 16 % et le texte une version claire.
   - **Thème** :
     - fond `#F4F7FB`, cartes blanches (arrondi 20, ombre douce), champs `#EEF2F7` bordés (focus Menthe profonde) ;
     - bouton principal menthe avec texte Nuit (56, arrondi 16), boutons secondaires à contour (52, arrondi 14), liens en Menthe profonde ;
     - puces arrondies (sélection menthe pâle), interrupteurs à piste menthe ;
     - barre de navigation Nuit aux coins arrondis, onglet actif en pastille menthe ;
     - échelle typographique de la section 4 de la direction artistique ;
     - thème sombre dérivé (fond `#061428`, carte `#0C1F3A`, champ `#13294A`).
   - **Statuts** : pastilles de 28 (icône 16, texte 14 / 700), toutes aux teintes des maquettes :
     - tickets : utilisé vert, valable bleu, annulé rouge, expiré gris ;
     - événements : en cours vert « en direct », à venir bleu, brouillon ambre, terminé gris, annulé rouge.
   - **Images** (`image_rules.dart`), réduites et compressées dans le téléphone avant l'envoi :

     | Image | Format conseillé | Poids maximal | Vignette |
     | --- | --- | --- | --- |
     | Couverture d'événement | 1600 × 900 | 400 Ko | 480 × 270 |
     | Logo de structure (transparence gardée) | 512 | 200 Ko | 128 |
     | Photo de profil | 400 | 150 Ko | 128 |

     - La vignette s'appelle `…_v.jpg`, à côté de l'image. Les listes et les petits avatars la chargent ; une image envoyée avant cette version n'a pas de vignette, et l'image complète est alors lue à sa place puis gardée sous l'adresse de la vignette.
     - Une image sous le minimum conseillé reste acceptée (aucune fonction retirée).
4. **Écarts assumés par rapport aux maquettes, au nom de la lisibilité (4,5:1)** :
   - texte « Utilisé » foncé en `#166534` ;
   - pastilles de type sur photo foncées pour le texte blanc : sport `#15803D`, culte `#0369A1`, mariage `#BE185D`, gala `#8A5A00` ;
   - menthe toujours avec du texte Nuit.

   Certaines icônes pâles des maquettes restent sous 3:1. Elles accompagnent toujours un texte lisible.
5. **Ce qu'on ne reprend pas des maquettes** : section 10 de la direction artistique (vocabulaire « ticket », rôles réels, pas de présence en ligne, pas de raccourci « Marquer comme utilisé », référence `TS-XXXX-XXXX`, logo officiel, défilement continu, tailles d'au moins 48).

## Conséquences

- Tous les écrans changent d'aspect sans changer de structure. Les composants (`TikeoHeroHeader`, `StatTile`, carte héros…) et les illustrations arrivent avec la PR B. Le dégradé et le halo du bouton principal en font partie : le thème Material ne sait pas les dessiner.
- Les tests vérifient les teintes (texte ≥ 4,5:1 en clair et en sombre), la compression, les vignettes et la lecture de l'image complète quand la vignette manque. L'audit des contrastes rejoue les écrans sur les nouvelles couleurs.
- Nouvelle dépendance directe : `image`, déjà présente par le paquet `pdf`.
