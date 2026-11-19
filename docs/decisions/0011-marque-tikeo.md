# ADR 0011 — Nouvelle marque : Tikéo

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint

## Contexte

L'application change de nom, de logo et de couleurs. Toussaint a fourni le logo (ticket QR menthe posé sur un repère bleu nuit, étincelles menthe et orange) et le nom **Tikéo**. Une proposition de refonte complète (catalogue public dès l'ouverture, nouveaux écrans) a été validée ; elle est découpée en quatre étapes A à D.

## Décision

1. **Nom affiché : « Tikéo »** (libellé Android, textes de l'app, PDF, notes de version). Le slogan « Votre événement en un clic » est conservé.
2. **Rien ne change sous le capot** : dépôt `ticketsur`, identifiant Android `com.ticketsur.fasosoft`, paquet Dart `ticketsur`, noms de classes (`TicketSur…`), schéma de la base. Changer l'identifiant Android créerait une autre application : les téléphones ne recevraient plus les mises à jour par-dessus l'APK installée (règle « même signature, même application »).
3. **Couleurs** tirées du logo :
   - Nuit `#022445` (texte, en-têtes) ;
   - Menthe `#00C9A7` (boutons principaux, sélection ; toujours avec du texte Nuit, jamais blanc) ;
   - Menthe profonde `#006B5B` (texte et liens menthe sur fond clair) ;
   - Étincelle `#FF6B3D` (accent rare).
   - Les couleurs des verdicts du contrôle (vert, rouge, ambre) restent distinctes de la marque.
4. **Polices** : Nunito (titres, terminaisons arrondies proches du logo) et Inter (texte). Manrope est retirée. Toutes deux sous licence SIL OFL, embarquées.
5. **APK** : publiées sous les noms `Tikeo-arm64-v8a.apk` et `Tikeo-armeabi-v7a.apk`. Les anciens noms `TicketSur-staging-…` restent publiés (même fichier) pour ne pas casser les liens déjà partagés.
6. **Nom de marque** : avant toute publication sur le Play Store, Toussaint fait vérifier le nom auprès de l'OAPI. Des noms proches existent dans la sous-région (Tikerama, TikePass).

## Conséquences

- Les contrastes de la nouvelle palette sont vérifiés par les tests existants (`theme_test.dart`, audit automatique des contrastes sur 11 écrans en clair et en sombre).
- Le ticket, son image et son PDF gardent leur mise en page actuelle avec la nouvelle couleur Nuit ; leur refonte est l'étape D. Le format du QR ne change pas.
