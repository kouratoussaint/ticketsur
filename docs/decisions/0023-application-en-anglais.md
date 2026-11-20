# ADR 0023 — Application en anglais

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (lot 4-4b ; décisions consignées dans l'ADR 0022)

## Décision

- **Deux langues** : français (référence, `app_fr.arb`) et anglais (`app_en.arb`, 1 262 textes traduits par Claude). Un test fait échouer la CI s'il manque une traduction, s'il reste un texte anglais orphelin ou si les variables diffèrent.
- **Choix dans Paramètres › Langue** : langue du téléphone (par défaut), Français ou English.
  - Langue du téléphone : français ou anglais selon le premier des deux trouvé dans ses langues, français sinon.
  - Choix gardé sur l'appareil (`appearance.language`).
- **Tickets, PDF, rapports, messages d'envoi** dans la langue de l'application du promoteur. Les dates et nombres suivent la même langue (`appLocaleTag`).
- **Langue du compte** (`profiles.locale`, existante) tenue égale à celle de l'application. Le serveur écrit les notifications dans la langue du destinataire :
  - réponse du support ;
  - contrôle ouvert ;
  - notification de test.
  - Les annonces restent dans la langue où l'administrateur les écrit.
- **Mentions légales par langue** (migration 3300) :
  - version anglaise proposée, modifiable depuis la console (bouton Français / English) ;
  - sans version dans la langue demandée, la française est servie ;
  - les textes anglais précisent qu'en cas de différence, la version française prévaut.
- **Le serveur garde ses codes d'erreur** : l'application les traduit. Les textes `DETAIL` en français ne sont pas affichés.

## Conséquences

- Tout nouveau texte doit être ajouté aux deux fichiers ARB : la CI le vérifie.
- L'audit des contrastes passe aussi tous ses écrans en anglais. Un texte trop long y fait apparaître un débordement.
- Le modèle CSV d'import a des en-têtes dans la langue de l'application ; l'import reconnaît les en-têtes français et anglais.
