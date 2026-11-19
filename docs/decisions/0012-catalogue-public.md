# ADR 0012 — Catalogue public dès l'ouverture

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint

## Contexte

Avec la refonte Tikéo, l'application doit montrer des événements dès l'ouverture, même sans compte, avec une barre de recherche et des filtres par catégorie d'événement. Certains événements sont privés (mariage, séminaire d'entreprise) et ne doivent jamais apparaître. La vente en ligne n'existe pas encore (lot 5).

## Décision

1. **Visibilité choisie par l'organisateur** : un interrupteur « Visible par le public » sur la fiche de l'événement (`events.is_public`, faux par défaut). Le catalogue ne liste que les événements publics, publiés ou en cours, non terminés, d'une organisation active.
2. **Lectures publiques limitées à la vitrine** : `public_events` (recherche sans casse ni accents, catégories, ville, période, entrée gratuite, pages de 50 au plus) et `public_event`, ouvertes au rôle `anon`. Elles renvoient le titre, la catégorie, les dates, le lieu, la ville, la photo, la description, le nom de l'organisation, son numéro public et les catégories avec prix indicatif. Elles ne renvoient jamais les tickets, les titulaires, les chiffres de vente ou d'entrée, ni les catégories d'invitations.
3. **« Obtenir un ticket »** ouvre WhatsApp (`wa.me`) vers le **numéro WhatsApp public de l'organisation**, avec un message prêt (événement et date). C'est un champ distinct du téléphone de la fiche, facultatif ; sans lui, la fiche affiche « Tickets auprès de l'organisateur ». Aucun coût, aucun prestataire.
4. **Prix indicatif** par catégorie, en FCFA, facultatif (`ticket_categories.indicative_price`, 0 = gratuit). Il est seulement affiché, et non encaissé.
5. **Villes** : le filtre propose les 49 communes urbaines du Burkina Faso (les 45 chefs-lieux de province, plus Bittou, Garango, Niangoloko et Pouytenga) et « Toutes les villes ». Un événement dans une autre localité reste visible avec « Toutes les villes » et par la recherche.
6. **Navigation** :
   - sans compte, l'application ouvre sur l'Explorer (`/decouvrir`), avec une barre de trois entrées : Explorer, Organiser (présentation), Compte (connexion) ;
   - connecté, l'Explorer devient le premier onglet (`/explorer`), et les onglets sont Explorer, Organiser (Accueil et liste des événements), Tickets, Équipe et Profil ; les contrôleurs ont Contrôle, Historique, Explorer et Profil.
   - L'Explorer sans compte est volontairement hors de la coque connectée : à la déconnexion, toute la coque et ses données sont libérées, comme avant.

## Conséquences

- Les journaux ne contiennent que les drapeaux (`public`, prix, numéro posé ou retiré), jamais le numéro.
- Le contenu public n'est pas modéré avant la console (lot 4) : c'est l'organisateur qui choisit de publier.
- La vente en ligne (lot 5) remplacera le lien WhatsApp par un vrai parcours d'achat.
