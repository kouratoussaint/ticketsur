# ADR 0022 — Modèles de tickets ; décisions du lot 4-4

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (spécification « Modèles de tickets » validée le 20/11 ; réponses du 20/11 sur le lot 4-4)

## Décisions de Toussaint pour le lot 4-4

1. **Ordre** : modèles de tickets (4-4a), puis application en anglais (4-4b), puis pass à plusieurs entrées (4-4c).
2. **Pass à plusieurs entrées : oui, les deux formules.** Une entrée par jour, et N entrées au total, au choix du promoteur par catégorie. C'est une exception explicite à la règle « au plus une validation acceptée par ticket ». Elle ne vaut que pour les catégories ainsi réglées ; les autres gardent une seule entrée. Validation toujours en ligne et atomique. Un ADR dédié sera écrit avec le lot 4-4c.
3. **Langue des tickets** (image, PDF, rapport) : celle de l'application du promoteur.
4. **Mentions légales en anglais** : traduction proposée par Claude, modifiable depuis la console.

## Modèles de tickets (lot 4-4a, PR 1)

- **Un modèle par catégorie** (`ticket_category_templates`) :
  - soit l'un des 12 thèmes intégrés ;
  - soit un design importé (JPG ou PNG, bande horizontale de proportions 1,5 à 4).
  - Sans choix : thème proposé selon le type d'événement.
- **Le modèle n'est qu'un fond.** Le format du QR (`TS1.` + 43 caractères), la validation à la porte et les règles d'émission ne changent pas.
- **QR** :
  - toujours noir sur blanc, marge de 4 modules ajoutée par Tikéo ;
  - au moins 35 % de la hauteur du ticket, vérifié par l'application et par le serveur (`template_qr_too_small`) ;
  - jamais hors du ticket (`template_invalid`).
- **Placement automatique sur un design importé** : le plus grand carré clair d'une version réduite de l'image (calcul dans le téléphone), sinon un carré blanc dans le dernier quart à droite. Le promoteur déplace et redimensionne ensuite.
- **Images importées** : bucket `event-covers`, dossier de l'événement, mêmes droits que la photo de couverture, 2 Mo au plus. Elles sont publiques comme les couvertures : un modèle ne contient ni QR ni donnée personnelle.
- **Numéro d'ordre** (`tickets.event_number`, « N° 000123 ») : attribué à l'insertion, sous le verrou de l'événement, unique par événement. Les tickets existants sont numérotés dans l'ordre d'émission.
- **Accroche** (`events.tagline`, 60 caractères), enregistrée par `set_event_tagline`.
- **Rendu** :
  - image envoyée (WhatsApp, SMS) et partagée : 2160 px de large ;
  - PDF : une page par ticket au format du modèle, fond de chaque catégorie rendu une seule fois en image, QR et textes en vecteurs.
  - La fiche du ticket garde la carte verticale à l'écran (QR en grand).
- **Polices ajoutées** : Yellowtail (manuscrite, licence Apache 2.0) et Bebas Neue (condensée, OFL).
- **Écart à la spécification** : pastille du thème 10 en `#0369A1` au lieu de `#0284C7`. Le texte blanc n'atteignait que 4,1:1 ; l'audit des contrastes exige 4,5:1.
- **Journal** : `ticket_template.updated` avec le type de modèle seulement ; `event.updated` avec `fields: [tagline]`.

## PR 2 (migration 3200)

- **Titulaire placé à part sur un design importé** (`holder_x`, `holder_y`) : les deux coordonnées ou aucune. Sinon, le nom reste sous la référence.
- **Cadrage de la photo** d'un thème intégré : point gardé visible (`cover_x`, `cover_y`), zoom de 1 à 3 (`cover_zoom`).
- **« Mes tickets »** : `my_tickets` renvoie aussi le numéro, l'accroche, le logo de la structure et le modèle de la catégorie. Le titulaire voit son ticket dessiné comme le promoteur l'a choisi, plus un QR en grand. Le tout est gardé dans le cache de l'appareil.
- **Planche A4 à imprimer** : 3 thèmes intégrés par page, traits de coupe en pointillés.
- **Copie d'un modèle** vers d'autres catégories du même événement (une seule image envoyée).
- **Duplication d'un événement** : l'accroche et les thèmes intégrés sont recopiés par le serveur. Les designs importés sont recopiés par l'application (image copiée dans le dossier de la copie) ; en cas d'échec, la copie garde le modèle proposé.
