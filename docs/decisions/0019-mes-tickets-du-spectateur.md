# ADR 0019 — « Mes tickets » : le ticket entre dans un compte par son QR

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (« Mes tickets » pour le spectateur : oui, ADR 0018) ; mode d'ajout choisi par Claude, pour la sécurité

## Contexte

Le spectateur reçoit son ticket par WhatsApp, SMS ou e-mail (image ou PDF). Il veut le retrouver dans l'application. On pourrait rattacher les tickets nominatifs au compte dont l'adresse ou le téléphone correspond. Mais ni l'adresse (confirmation désactivée sur le staging) ni le téléphone du profil ne sont vérifiés. Quelqu'un pourrait alors créer un compte avec l'adresse d'un autre et recevoir son QR.

## Décision

1. **Preuve de possession** : un ticket entre dans un compte seulement si l'on présente son QR. Trois façons de le faire :
   - le scanner avec l'appareil photo ;
   - le lire dans une image de la galerie (celle reçue par WhatsApp) ;
   - coller le code `TS1.…`.
   Celui qui a le QR peut de toute façon entrer : on ne donne rien de plus.
2. **Un seul compte par ticket** : le premier compte qui l'ajoute le garde. Un autre compte reçoit « Ce ticket est déjà dans le compte d'une autre personne ». Le détenteur peut le retirer ; le ticket redevient alors ajoutable.
3. Un ticket annulé ne peut pas être ajouté. Un ticket utilisé ou annulé après l'ajout reste visible, sans QR.
4. **Base** (migration 2700) :
   - `tickets.holder_user_id` ;
   - `claim_ticket(qr)` cherche le ticket par l'empreinte HMAC existante, sans changer le format du QR ;
   - `my_tickets()` renvoie l'événement, la structure et le QR des seuls tickets valables ;
   - `release_ticket(id)` ;
   - journal `ticket.claimed` et `ticket.released`, sans aucune donnée.
5. **Application** :
   - onglet « Mes tickets » pour un compte classique (Explorer, Mes tickets, Favoris, Profil) ; entrée dans le Profil pour un membre de structure ;
   - liste « À venir » et « Passés » ; fiche avec le ticket et son QR ; retrait ;
   - la liste et les QR sont gardés sur l'appareil, pour être présentés sans réseau. La validation reste en ligne, au contrôle ;
   - ce cache est effacé à la déconnexion.

## Conséquences

- Le promoteur n'a rien à changer. Un message d'envoi pourra plus tard inviter le spectateur à ajouter son ticket dans l'application.
- Le cache de l'appareil contient les QR, comme la galerie qui a reçu l'image du ticket.
- Le transfert d'un ticket à une autre personne (lot 5) partira de ce rattachement.
