# ADR 0028 — « À la une », photos en grand et image de partage

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (demandes du 20/11/2026, #1, #2, #3 et #18)
- Référence : doc du projet `claude/ameliorations-2026-11-20.md`, PR 2 — Images et partage

## Contexte

Le premier événement de la liste d'Explorer était mis « À la une » d'office, avec du texte et un dégradé posés sur la photo du promoteur (affiches illisibles, surtout verticales). Toussaint veut choisir lui-même les événements mis en avant, que la photo reste entière, qu'on puisse la voir en grand et l'enregistrer, et partager un événement en image (statut WhatsApp, publication).

## Décisions

1. **À la une choisi par l'administrateur** : table `featured_events` (événement unique, ordre, période, ajouté par), fermée à l'API ; fonctions `admin_featured_events`, `admin_add_featured_event` (événement public à venir seulement, fin par défaut = fin de l'événement), `admin_set_featured_period`, `admin_move_featured_event` (monter, descendre), `admin_remove_featured_event` ; journal `admin.featured_*` sans donnée personnelle. Lecture `public_featured_events` ouverte aux visiteurs : mises en avant en cours, dans l'ordre ; **sans sélection, les 5 prochains événements publics**. La liste d'Explorer reste complète (un événement à la une y figure aussi).
2. **Carte À la une** : image entière en haut (hauteur 210, `contain`), bords comblés par la même image floutée et assombrie ; type, prix, titre, date, lieu et « Obtenir un ticket » **sous** l'image. Plusieurs mises en avant : cartes côte à côte, défilement horizontal.
3. **Photo en grand** (fiche publique, fiche du promoteur) : fond noir, zoom par pincement, Fermer, Partager, **Télécharger dans la galerie** (paquet `gal`, licence BSD ; permission `WRITE_EXTERNAL_STORAGE` limitée à Android 10 et avant).
4. **Image de partage** : Statut 9:16 (1080 × 1920) ou Publication 4:5 (1080 × 1350), rendue dans l'app ; fond Nuit, photo entière, type et prix, titre, date, lieu, structure, bandeau « Obtenez votre ticket sur l'application Tikéo ». **Pas de QR** sur cette image (règle : pas de QR de lien ; ne pas la confondre avec un ticket). Texte joint : titre, date, lieu, prix, « Obtenez votre ticket sur Tikéo ». Le partage du texte seul reste possible.

## Conséquences

- Aucun coût ni compte externe.
- Tant que l'administrateur n'a rien choisi, Explorer montre les 5 prochains événements publics à la une.
- Un événement qui n'est plus public ou qui est terminé disparaît de la une ; la console le montre « Terminé » jusqu'à ce qu'on le retire.
