# ADR 0053 — Promoteur prévenu des changements d'abonnement ; accusés de réception

- Statut : acceptée
- Date : 23 novembre 2026
- Décideur : Toussaint (« Je veux une notification au promoteur du changement. Les notifs de l'application semblent ne même pas fonctionner », 23/11 à 16 h 14)

## Contexte

Un changement d'abonnement fait depuis la console n'était pas signalé au promoteur. Par ailleurs, Toussaint ne reçoit pas les notifications. Le diagnostic du 23/11 (`push-diagnostic`, 16 h 15) montre que le serveur et Firebase fonctionnent : les messages sont acceptés par Firebase pour les 3 téléphones enregistrés (dernier envoi le 23/11 à 13 h 50, `{"sent":1,"failed":0}`), la tâche planifiée tourne toutes les 5 minutes. Firebase dit seulement qu'il a accepté le message, pas que le téléphone l'a reçu : impossible de savoir où le message se perd.

## Décisions

1. **Abonnement changé par la console** : le promoteur reçoit une notification (page « Mon pack ») quand le pack change (« Votre pack est maintenant B (au lieu de A). Vos dates ne changent pas. »), quand la date de fin change, et quand ses suppléments changent. Rien si la valeur ne change pas. Toujours envoyée (pas de réglage), dans la langue du compte. Migration 6300 : `admin_change_subscription_pack`, `admin_extend_subscription`, `admin_set_subscription_addons` recréées, permission `billing` reposée.
2. **Envoi immédiat** : après une activation, un refus, un changement de pack, de date ou de suppléments, la console envoie la file tout de suite (au lieu d'attendre la tâche des 5 minutes).
3. **Accusés de réception** : chaque message porte son numéro (`outbox_id`). Le téléphone confirme sa réception au serveur, tout de suite au premier plan, à la prochaine ouverture s'il l'a reçu en arrière-plan (gestionnaire Firebase d'arrière-plan). Table `push_receipts` (message, empreinte md5 du jeton de l'appareil, heure), fonction `push_ack` (migration 6400) ; colonne `recu_par` dans le diagnostic.
4. **Paramètres › Notifications** : « Dernière notification reçue sur ce téléphone : … » ou « Aucune notification reçue sur ce téléphone pour l'instant. »

## Conséquences

- Le diagnostic distingue maintenant « accepté par Firebase mais jamais arrivé » (réglages du téléphone : autorisation, économie de batterie, app fermée de force) de « arrivé ».
- Aucun coût ni compte externe ; aucune donnée personnelle nouvelle.
