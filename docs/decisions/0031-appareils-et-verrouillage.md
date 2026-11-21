# ADR 0031 — Appareils connectés, déconnexion à distance et verrouillage par empreinte

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-6, sécurité des comptes)
- Référence : doc du projet `claude/recommandations-tikeo.md`, lot 4-6 sans coût

## Contexte

Un promoteur ou un contrôleur prête son téléphone, en change ou le perd. Il doit voir où son compte est ouvert, fermer une session à distance, et pouvoir protéger l'app d'un regard indiscret.

## Décisions

1. **Un appareil = une session Supabase Auth** (claim `session_id` du jeton). Table `account_devices` (session, compte, nom de l'appareil, système, version de l'app, dates), fermée à l'API. Le nom vient de `device_info_plus` (marque et modèle) : **aucun identifiant matériel, aucune adresse IP** n'est lu ni gardé.
2. **Fonctions** (migration 4300) : `register_device` (inscription à l'ouverture et au retour au premier plan, au plus une fois par minute ; `session_revoked` si la session n'existe plus), `my_devices` (sessions du compte, l'appareil en cours d'abord, les sessions non inscrites comprises), `revoke_device` (un autre appareil ; jamais celui en cours), `revoke_other_devices`. Journal `account.device_revoked` / `account.devices_revoked` sans donnée personnelle.
3. **Déconnexion à distance** : la session supprimée ne peut plus se renouveler ; l'appareil visé le constate à sa prochaine inscription (ouverture ou retour au premier plan), ferme sa session locale, revient à Explorer et l'annonce. Le jeton d'accès déjà émis reste techniquement valable jusqu'à son expiration (1 h au plus) s'il n'y a pas de retour au premier plan.
4. **Verrouillage par empreinte** (option par appareil, désactivée par défaut) : paquet `local_auth` (BSD) ; empreinte, visage ou code du téléphone. L'activer demande d'abord une empreinte réussie. Verrouillé au lancement avec une session ouverte, puis au retour après **1 minute** hors de l'app ; écran « Tikéo est verrouillé » avec Déverrouiller et Se déconnecter.
5. **Android** : `MainActivity` hérite de `FlutterFragmentActivity` ; permission `USE_BIOMETRIC` ; thèmes de démarrage AppCompat avant Android 12 (exigence de `local_auth` sur Android 8 et avant), dépendance `androidx.appcompat`.

## Conséquences

- Aucun coût ni compte externe.
- Les APK antérieures à cette version n'inscrivent pas leur appareil : leurs sessions apparaissent « Appareil non identifié » et peuvent quand même être déconnectées.
