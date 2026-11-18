# Politique de sécurité — TicketSûr

## Signaler une vulnérabilité

Ne publiez pas de détail dans une issue publique. Utilisez l'onglet **Security → Report a vulnerability** du dépôt GitHub (signalement privé) ou contactez directement le mainteneur. Nous accusons réception sous 72 heures.

## Règles non négociables du projet

1. **Un seul passage par billet.** Toute modification touchant `public.validate_scan`, `public.tickets` ou `public.scan_attempts` doit garder verts les tests de concurrence (`supabase/tests/concurrency/`).
2. **Le mobile ne décide jamais.** Aucun écran « valide » sans réponse `accepted` du serveur ; aucun droit d'écriture direct des clients sur les billets et les scans.
3. **Aucun secret dans le dépôt ni dans l'APK.** Clé `service_role`, clés Vault, keystore Android : uniquement dans Supabase Vault et les environnements protégés GitHub.
4. **Le jeton QR est un secret au porteur.** Il n'apparaît ni dans les journaux, ni dans les événements analytiques, ni dans les rapports de crash. Les RPC qui le reçoivent sont appelées en `POST`, jamais en `GET`.
5. **Fonctions `security definer`** : `search_path = ''`, objets qualifiés par schéma, `EXECUTE` révoqué pour `public`/`anon` et accordé explicitement.
6. **Isolation des organisations** : RLS sur toutes les tables exposées, testée à chaque PR.

## Limites connues (modèle de menace)

- Un QR copié avant l'arrivée de son détenteur légitime peut être présenté en premier. Atténuation : consignes au participant, contrôle d'identité optionnel pour les événements sensibles (V1.1).
- Un téléphone de contrôle volé avec session ouverte peut scanner jusqu'à la désactivation du compte ; la désactivation prend effet au scan suivant.
