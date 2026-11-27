# ADR 0057 — Délai des doubles scans réglable depuis la console

- Statut : acceptée
- Date : 27 novembre 2026
- Décideur : Toussaint (27/11, 15 h 02 : « Réduire le délai à 15 secondes avec la ligne d'explication. Permettre le réglage depuis la console »)

## Contexte

L'ADR 0056 écartait des pertes évitées tout refus « déjà utilisé » arrivé moins d'une minute après l'entrée du même ticket (le scanner relit le QR resté devant la caméra). Sur un essai, 3 refus affichés dans « Motifs de refus » donnaient 0 FCFA de pertes évitées, sans explication.

## Décisions

- Délai par défaut : **15 secondes**, réglable dans Console › Réglages › « Doubles scans » : 0 (tout compte), 5, 10, 15, 30, 60, 120 ou 300 s. Permission « settings » (super administrateur). Journal `admin.double_scan_updated` avec le délai seulement.
- Migration 6800 : réglage `double_scan_seconds` (`private.console_settings`), `private.double_scan_seconds()`, `admin_save_double_scan_seconds(secondes)` (`double_scan_invalid` hors de 0 à 300), `admin_me` et `admin_console_settings` renvoient le délai ; `private.event_money` le lit et renvoie `double_scans` (refus écartés) et `double_scan_seconds`.
- Le délai s'applique à tous les événements et au calcul en cours (pas figé par événement) : changer le réglage change les montants affichés, bilans compris.
- Tableau de bord : sous les montants, « N refus non comptés : tickets repassés moins de N s après leur entrée (double scan). » quand il y en a.
