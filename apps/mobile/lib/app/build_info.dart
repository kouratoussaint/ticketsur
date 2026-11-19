/// Numéro de build de l'APK (`--dart-define=TIKEO_BUILD=<n>` dans la CI) ;
/// 0 en développement et dans les tests. Les versions pilotes publiées sur
/// GitHub s'appellent `pilote-<n>`.
const int appBuild = int.fromEnvironment('TIKEO_BUILD');
