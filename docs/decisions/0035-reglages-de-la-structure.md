# ADR 0035 — Réglages de la structure : message d'envoi et valeurs d'un nouvel événement

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-7 validé ; « un message par structure »)

## Contexte

Le texte accompagnant un ticket envoyé par WhatsApp, SMS ou e-mail était fixe. Chaque nouvel événement demandait de ressaisir le fuseau, la ville, le type, les mêmes catégories et les mêmes portes.

## Décisions

1. **Un réglage par structure**, côté serveur, lu par tous les téléphones de l'équipe : table `organization_settings` fermée à l'API (migration 4600). Lecture `organization_settings(structure)` et écriture `update_organization_settings(...)` réservées au propriétaire et aux gestionnaires ; un contrôleur ne voit ni la page ni le réglage.
2. **Message d'envoi** d'un ticket et d'une invitation (600 caractères au plus), avec des champs insérés par l'app : `{prenom}` (premier mot du nom du titulaire), `{evenement}`, `{date}`, `{lieu}`, `{categorie}`. Un champ vide est retiré proprement. **Aucun champ ne donne le jeton du QR** : le QR reste dans la pièce jointe. Message vide = message par défaut de Tikéo (« Revenir au message par défaut »). Si les réglages ne peuvent pas être lus (réseau), le message par défaut part.
3. **Nouvel événement** : fuseau, ville et type proposés dans le formulaire tant que rien n'a été saisi ; **catégories** (nom, quota, prix indicatif, invitation) et **portes** proposées (10 au plus chacune), ajoutées après la création si la case de l'aperçu reste cochée, par `apply_event_defaults(événement)` qui n'ajoute que les noms absents.
4. **Journal** : `organization.settings_updated` avec des indicateurs et des nombres seulement (message personnalisé oui/non, nombre de catégories et de portes), **jamais le texte du message** ; `event.defaults_applied` avec les nombres ajoutés.
5. Page « Réglages de la structure » ouverte depuis Profil › Structure active.

## Conséquences

- Aucun coût. Les anciennes APK continuent de fonctionner (fonctions et table ajoutées seulement) ; elles envoient le message par défaut.
- L'échec de l'ajout des propositions n'annule pas la création de l'événement : un message le signale et l'organisateur peut les ajouter à la main.
