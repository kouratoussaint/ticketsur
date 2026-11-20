# ADR 0025 — Rappels avant l'événement, envois automatiques, bilan

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (« vas-y avec le prochain lot », lot 4-5 proposé sans coût)

## Contexte

Les notifications partaient seulement quand l'application appelait la fonction d'envoi juste après une action. Un message en échec restait en attente jusqu'à la prochaine action. Aucun rappel n'existait avant l'événement, et l'organisateur n'avait pas de bilan après coup.

## Décision

- **Rappels** aux détenteurs d'un ticket ajouté à « Mes tickets » (le seul lien sûr entre un ticket et un compte, ADR 0019) :
  - « Rappel » la veille (de 24 h à 3 h avant le début : « Demain » ou « Aujourd'hui à 21:00 · lieu ») ;
  - « Bientôt » 2 h avant (« Début à 21:00 · lieu ») ;
  - une seule fois par événement, par personne et par type (`private.event_reminders`), dans la langue du destinataire, pour les tickets valables d'un événement publié ou en cours ;
  - la notification ouvre le ticket (un seul) ou « Mes tickets » (plusieurs) ;
  - désactivables : Paramètres › Notifications › « Rappels avant l'événement » (`profiles.event_reminders`, `set_event_reminders`).
- **Envois automatiques** : tâche planifiée `pg_cron` (`tikeo-push-tick`, toutes les 5 minutes, `private.push_tick`). Elle prépare les rappels, puis, s'il reste des messages en attente, appelle la fonction `push-dispatch` par `pg_net`. Les messages en échec sont ainsi réessayés (5 essais au plus).
  - L'appel utilise la **clé publiable** du projet (publique, déjà dans l'APK), comme l'application : aucun nouveau secret. Le déploiement range l'adresse de la fonction et cette clé dans `private.app_settings` (jamais exposée par l'API).
  - Sans `pg_cron` ni `pg_net` (base locale, CI), rien n'est planifié. Le diagnostic `push-diagnostic` montre les dernières exécutions et réponses.
- **Bilan d'après-événement** (`event_summary`, propriétaires et gestionnaires) : présence, affluence par heure (heure de pointe), par jour, entrées des pass, première et dernière entrée, comparaison avec les 7 derniers événements commencés de la structure. Écran « Bilan » depuis le tableau de bord ; le rapport PDF reprend l'heure de pointe, les jours et la comparaison.

## Conséquences

- `pg_cron` et `pg_net` sont des extensions Supabase incluses : pas de coût ni de compte externe.
- Aucune donnée personnelle ajoutée au journal ; les messages de rappel contiennent le titre, l'heure et le lieu de l'événement, comme les autres notifications.
