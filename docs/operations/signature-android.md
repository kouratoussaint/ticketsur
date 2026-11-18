# Signature Android : une seule clé pour toutes les APK

Android n'installe une nouvelle APK par-dessus l'ancienne que si les deux sont
signées avec **la même clé**. Sans clé fournie, chaque build GitHub signe avec
une clé de débogage neuve : il faut alors désinstaller avant chaque mise à jour
(constaté : empreintes `9de367a9…` puis `73273f58…` sur deux builds successifs).

## Ce que fait le workflow `android-build`

1. Lit la clé depuis les **secrets du dépôt** (jamais depuis un fichier versionné) :

   | Secret | Contenu |
   | --- | --- |
   | `TICKETSUR_KEYSTORE_BASE64` | le fichier `.jks` encodé en base64 |
   | `TICKETSUR_KEYSTORE_PASSWORD` | mot de passe du keystore |
   | `TICKETSUR_KEY_PASSWORD` | mot de passe de la clé |

   L'alias de la clé est fixé en clair à `ticketsur` dans le workflow : ce
   n'est pas un secret, et un secret valant « ticketsur » ferait masquer le
   nom de l'application dans tous les journaux. Un ancien secret
   `TICKETSUR_KEY_ALIAS` peut être supprimé.

2. Écrit le keystore dans le dossier temporaire du runner (droits 600), signe,
   puis l'efface.
3. Si la **variable** de dépôt `TICKETSUR_SIGNING_CERT_SHA256` est définie,
   refuse toute APK dont l'empreinte du certificat diffère : impossible de
   publier par erreur une APK qui ne s'installerait pas par-dessus.
4. Sans secrets (PR venant d'un fork), repli sur la clé de débogage avec un
   avertissement visible dans le résumé du build.

## Créer la clé (une seule fois) — méthode recommandée, sans ordinateur

Le workflow `signing-key` génère la clé dans le runner GitHub et l'enregistre
lui-même dans les secrets ; elle n'est jamais affichée ni versionnée.

1. GitHub → photo de profil → Settings → Developer settings → Personal access
   tokens → **Fine-grained tokens** → Generate new token :
   expiration 1 jour, *Repository access* : seulement `ticketsur`,
   *Repository permissions* : **Secrets** = Read and write,
   **Variables** = Read and write. Copier le jeton.
2. Dépôt → Settings → Secrets and variables → Actions → New repository secret :
   nom `TICKETSUR_ADMIN_TOKEN`, valeur = le jeton.
3. Dépôt → Actions → **signing-key** → Run workflow (branche `main`).
4. Une fois le run vert : supprimer le secret `TICKETSUR_ADMIN_TOKEN` et
   révoquer le jeton.

Le workflow refuse de remplacer une clé existante sauf case
« replace_existing » cochée (remplacer la clé oblige à désinstaller toutes les
APK). Limite assumée : aucune copie de sauvegarde n'existe hors des secrets
GitHub (voir « Règles »).

## Créer la clé à la main (alternative)

Sur un ordinateur avec Java (JDK 17+) :

```bash
keytool -genkeypair -v -keystore ticketsur.jks -storetype PKCS12 \
  -keyalg RSA -keysize 4096 -validity 10000 -alias ticketsur \
  -dname "CN=TicketSur, O=FasoSoft, C=BF"
base64 -w0 ticketsur.jks > ticketsur.jks.b64   # macOS : base64 -i ticketsur.jks
keytool -list -v -keystore ticketsur.jks -alias ticketsur | grep SHA256
```

Puis dans GitHub → Settings → Secrets and variables → Actions :
- onglet **Secrets** : les trois secrets ci-dessus (coller le contenu de
  `ticketsur.jks.b64`, sans retour à la ligne) ;
- onglet **Variables** : `TICKETSUR_SIGNING_CERT_SHA256` = l'empreinte SHA256
  affichée, en minuscules et **sans les deux-points**.

## Règles

- Ne jamais committer le `.jks`, ni coller la clé ou ses mots de passe dans un
  chat, une issue ou une PR. Le `.gitignore` exclut `*.jks` et `*.keystore`.
- **Sauvegarder** `ticketsur.jks` et ses mots de passe hors de GitHub (les
  secrets GitHub sont en écriture seule : ils ne peuvent pas être relus).
- Pour Google Play, cette clé servira de **clé d'importation** (« upload key »)
  avec la signature d'application gérée par Google Play : en cas de perte, la
  clé d'importation peut être réinitialisée auprès de Google. Les APK de
  pilote déjà installées, elles, devront être désinstallées une fois.
- Le passage de la clé de débogage à la clé stable impose **une dernière
  désinstallation** sur les téléphones de test ; ensuite, chaque APK
  s'installe par-dessus la précédente.
