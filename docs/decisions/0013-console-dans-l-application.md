# ADR 0013 — Console d'administration dans l'application Android

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint

## Contexte

Le plan d'évolution prévoyait une console d'administration (lot 3), avec une technologie à choisir (Flutter web recommandé) et un hébergement. Le catalogue public, ouvert sans compte depuis l'ADR 0012, demande une modération. La suppression définitive des comptes, demandée depuis le lot 1, attend aussi la console. Les packs et le paiement, eux, attendent des décisions de prix et d'agrégateur.

## Décision

1. **La console entière vit dans l'application Android** (choix de Toussaint, 19/11/2026). Il n'y a ni site web ni hébergement à prévoir. L'entrée « Console Tikéo » apparaît dans le Profil des seuls administrateurs de la plateforme, avec la route `/console` et ses sous-pages.
2. **Le rôle est vérifié côté serveur.**
   - Le drapeau `profiles.is_platform_admin`, présent depuis la migration 0100, ne s'attribue qu'en SQL, par le propriétaire de la base. Aucune fonction de l'application ne peut le poser.
   - Chaque fonction `admin_*` refuse un compte ordinaire (`forbidden`).
   - Un administrateur dont le compte est désactivé perd la console.
   - Aucune clé secrète n'entre dans l'application.
3. **La console est livrée avant les packs** : la console d'abord (lot 3a), puis les packs et le paiement (lot 3b), qui s'y brancheront.
4. **Le lot 3a-1 (migration 1900) contient :**
   - **Vue d'ensemble** : organisations, comptes, événements, tickets et contrôles des dernières 24 heures.
   - **Organisations** :
     - recherche ;
     - suspension avec motif obligatoire, ou réactivation ;
     - une organisation suspendue (`status = 'disabled'`) perd tous ses droits d'organisateur et de contrôleur, et ses événements quittent le catalogue.
   - **Modération du catalogue** :
     - retrait d'un événement avec motif obligatoire, ou rétablissement ;
     - l'organisateur voit le motif et ne peut plus republier (`event_blocked`) ;
     - un rétablissement ne republie rien automatiquement.
   - **Journal d'audit** de toute la plateforme, filtrable par famille d'actions, avec des libellés lisibles.
5. **Traçabilité** : chaque action de la console est journalisée (`admin.*`) avec son seul effet (`status`, `blocked`). Le motif libre reste sur la ligne concernée, jamais dans `audit_logs`.

## Conséquences

- Pour désigner un administrateur, sur le staging : `update public.profiles set is_platform_admin = true where id = (select id from auth.users where email = '…');`, exécuté dans le tableau de bord Supabase. L'adresse n'est jamais committée.
- La console s'utilise sur téléphone : listes paginées, recherche et feuilles de confirmation, pas de tableaux larges.
- Prochaines étapes du lot 3a :
  - comptes : liste, désactivation, suppression définitive après 30 jours ;
  - support et annonces.
- Lot 3b : les packs, puis le paiement.
