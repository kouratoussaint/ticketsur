# Échelle typographique de Tikéo

Référence pour tout nouvel écran (lot 4-9). Les valeurs viennent du code ; en cas d'écart, le code fait foi et ce document se corrige dans la même PR.

- **Nunito** pour les titres et les chiffres, **Inter** pour le texte courant et les libellés.
- Le poids est fixé à la fois par `fontWeight` et par l'axe variable `wght` (polices variables).
- Ne jamais écrire une taille en dur dans un écran : utiliser un style du thème (`Theme.of(context).textTheme…`) ou de `TikeoTextStyles`.

## Thème (`lib/design_system/ticketsur_theme.dart`)

| Style | Police | Taille | Poids | Interligne | Usage |
| --- | --- | --- | --- | --- | --- |
| `displaySmall` | Nunito | 32 | 900 | 1,1 | Très grands chiffres isolés |
| `headlineLarge` | Nunito | 28 | 900 | 1,15 | Rare (écrans de résultat) |
| `headlineMedium` | Nunito | 24 | 800 | 1,2 | Titre d'écran sans en-tête |
| `headlineSmall` | Nunito | 21 | 900 | 1,25 | Titre de bloc important |
| `titleLarge` | Nunito | 18 | 800 | 1,25 | Titre de section (`SectionHeader`) |
| `titleMedium` | Nunito | 16 | 800 | 1,3 | Titre de carte, de feuille |
| `titleSmall` | Inter | 13 | 700 | 1,4 | Titre de ligne de liste |
| `bodyLarge` | Inter | 14 | 400 | 1,5 | Texte courant, champs |
| `bodyMedium` | Inter | 13 | 400 | 1,45 | Texte secondaire |
| `bodySmall` | Inter | 12 | 500 | 1,4 | Détails, dates, aides |
| `labelLarge` | Inter | 15 | 700 | 1,25 | Boutons principaux |
| `labelMedium` | Inter | 13 | 600 | 1,25 | Boutons secondaires, libellés de champ ; libellé sur deux lignes dans une tuile étroite |
| `labelSmall` | Inter | 12 | 600 | 1,25 | Petits libellés |

Barre de navigation : Inter 13 (700 pour l'onglet choisi, 600 sinon), plafonnée à 115 % de taille de texte.

## Styles de la marque (`TikeoTextStyles`, `lib/design_system/tikeo_tokens.dart`)

| Style | Police | Taille | Poids | Usage |
| --- | --- | --- | --- | --- |
| `heroTitle` | Nunito | 24 | 800 | Titre d'en-tête Nuit |
| `heroSubtitle` | Inter | 14 | 400 (interligne 1,4) | Sous-titre d'en-tête |
| `heroCardTitle` | Nunito | 21 | 900 | Titre de carte héros |
| `bigNumber` | Nunito | 25 | 900, chiffres tabulaires | Grand chiffre |
| `tileNumber` | Nunito | 21 | 900, chiffres tabulaires | Chiffre de tuile |
| `ticketNumber` | Nunito | 28 | 900, chiffres tabulaires | « N° 000510 » |
| `overline` | Inter | 12 | 800, capitales, espacement 1 | Sur-titre (« CONCERT ») |
| `chip` | Inter | 13 | 700 | Pastille |
| `chipLarge` | Inter | 16 | 800 | Grande pastille |
| `avatarInitials` | Nunito | 20 | 800 | Initiales de l'avatar |

## Taille du texte

- Réglage de l'app (`TextSize`) : petite 90 %, normale, grande 115 %, très grande 130 %, multipliée par le réglage du téléphone.
- L'audit automatique (`test/design_system/contrast_audit_test.dart`) vérifie chaque écran jusqu'à **200 %** (très grande × téléphone à 154 %) : aucun débordement accepté.
- Règles de mise en page qui tiennent à 200 % :
  - dans une `Row`, un texte variable à droite (montant, compteur, pastille) va dans un `Flexible` avec `textAlign: end`, ou dans une boîte limitée à la moitié de la ligne quand le texte de gauche est `Expanded` ;
  - pastilles côte à côte dans un `Wrap` ;
  - une hauteur fixe qui contient du texte se calcule avec `MediaQuery.textScalerOf(context)` ;
  - un bouton à droite d'un bloc de texte peut passer dessous en très grand texte (`textScaler.scale(10) > 15`).

## Composants communs

- **Confirmation** : `confirmAction` (`lib/design_system/components/confirm.dart`) pour tout « Oui / Non » ; les formulaires (motif, code) gardent leur propre boîte.
- **Recherche** : `TikeoSearchBar` (`lib/design_system/components/controls.dart`) pour tout champ de recherche (loupe, bouton dans le champ, filtres, message d'erreur).
