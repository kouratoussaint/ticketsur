# ADR 0021 — Retrouver un titulaire à la porte ; journal de la structure

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (suite du lot 4 proposée le 20/11, « Continue »)

## Contexte

Un spectateur se présente sans son QR (téléphone éteint, image effacée). Jusqu'ici, le contrôleur ne pouvait rien faire : il ne lit pas les titulaires (RLS, PR #22). De son côté, le propriétaire d'une structure n'avait aucune vue sur ce que fait son équipe.

## Décision

1. **Nom au verdict** : `validate_scan` renvoie le nom du titulaire d'un ticket nominatif. C'est un champ facultatif du contrat v1 : les anciennes APK l'ignorent.
2. **Recherche à la porte** (`door_lookup`), avec ces garde-fous :
   - seulement pour un contrôleur affecté à cette porte, compte et structure actifs, **contrôle ouvert** ;
   - par nom (sans accents), téléphone (4 chiffres au moins) ou référence ; 3 caractères au moins ;
   - 10 résultats au plus, téléphone masqué (« •• 33 ») ;
   - 30 recherches par 10 minutes. Seule l'heure des recherches est gardée (`door_lookups`), jamais le texte cherché.
   Le contrôleur ne voit donc des titulaires que ticket par ticket, au moment du contrôle. Il n'accède jamais à la liste.
3. **Validation sans QR** (`validate_ticket_at_door`) : le serveur relit le QR du ticket choisi et appelle `validate_scan`. Les règles sont identiques : une seule entrée acceptée, en ligne, idempotence par `request_id`, refus détaillés. Le QR n'est jamais renvoyé à l'application. Journal `scan.manual` avec le résultat seulement.
4. **Journal de la structure** (`organization_audit_logs`, propriétaire seulement) :
   - filtres Événements, Tickets, Contrôle, Équipe, Structure ;
   - objet lisible (référence du ticket et titre de l'événement) ;
   - les actions de l'équipe Tikéo apparaissent sans nom d'administrateur ;
   - identifiants techniques (`ticket_ids`, `request_id`, `source`) jamais affichés.

## Conséquences

- Le nom du titulaire s'affiche désormais au contrôleur, au moment du scan. Le promoteur choisit de nommer ou non ses tickets.
- Une recherche abusive est freinée par la limite et visible au journal : chaque validation sans QR y apparaît avec le nom du contrôleur.
