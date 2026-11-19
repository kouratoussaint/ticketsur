# ADR 0010 — Envoi assisté des tickets (WhatsApp, SMS, e-mail)

- **Statut** : accepté le 2026-11-19 (choix de Toussaint : envoi assisté, sans fournisseur)

## Contexte

Le lot 2 prévoit l'envoi des tickets aux participants. Deux approches :

1. **Envoi automatique par le serveur** via des fournisseurs (WhatsApp Business API, passerelle SMS, service d'e-mail) : comptes à ouvrir, modèles de message WhatsApp à faire valider, coût par message, consentement à gérer. Le cahier des charges le classe en V1.1 (« Envoi automatisé de tickets… via fournisseurs autorisés », dépendances : consentements et coûts).
2. **Envoi assisté depuis le téléphone de l'organisateur** : l'application ouvre la bonne application, préremplie, et l'organisateur appuie sur « Envoyer ». Gratuit, immédiat, sans compte.

## Décision

Envoi assisté.

- **Canal Android** `ticketsur/send` (`MainActivity.kt`) :
  - WhatsApp : `ACTION_SEND` vers `com.whatsapp`, puis `com.whatsapp.w4b`, avec l'extra `jid` (conversation du numéro) et l'image du ticket jointe ;
  - SMS : application SMS par défaut, MMS avec l'image si possible, sinon texte seul ;
  - e-mail : applications d'e-mail seulement (sélecteur `mailto:`), PDF joint.
  - La pièce jointe est écrite dans `cache/envois/` (fichiers de plus d'une heure supprimés) et partagée par un `FileProvider` dédié (`EnvoisFileProvider`, autorité `com.ticketsur.fasosoft.envois`), en lecture seule et ponctuelle.
- **Image** : la carte du ticket (la même que celle partagée depuis sa fiche) rendue hors écran en PNG ; e-mail : le PDF A6 existant.
- **Message** : nom du titulaire, événement, date, lieu, consigne d'usage unique ; jamais le jeton en texte.
- **Jetons** relus par le ré-export audité existant (`export_tickets`), par paquets de 20 dans l'envoi en série.
- **Journal** `ticket_deliveries` (migration 1500) : l'application ne peut pas savoir si le message est parti. Elle demande donc à l'organisateur de confirmer, et seul un envoi confirmé est enregistré (canal, auteur, heure du serveur). Le journal ne contient aucune donnée personnelle, ni numéro, ni adresse, ni texte.
- **Envoi en série** : tickets valables jamais envoyés, joignables par le canal choisi, dans l'ordre d'émission ; « Envoyer », « Oui, envoyé · suivant », « Passer ».

## Conséquences

- Aucun coût ni compte externe ; fonctionne avec le WhatsApp personnel ou Business de l'organisateur.
- Une action par ticket : adapté à quelques centaines de tickets, pas à des milliers.
- Le comportement de l'extra `jid` dépend de WhatsApp (non documenté officiellement) ; il est à vérifier sur appareil. Si WhatsApp change, le repli est le partage Android classique depuis la fiche du ticket.
- L'envoi automatique par fournisseur reste possible plus tard : il réutilisera le message, le rendu de l'image et le journal `ticket_deliveries`, auquel il suffira d'ajouter un statut de remise.
