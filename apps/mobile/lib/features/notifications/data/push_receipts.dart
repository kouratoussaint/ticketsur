import 'package:shared_preferences/shared_preferences.dart';

/// Accusés de réception des notifications (ADR 0053) : numéros des messages
/// reçus pas encore confirmés au serveur, et heure de la dernière réception
/// sur ce téléphone. Écrits aussi par le gestionnaire d'arrière-plan
/// (autre isolat) : relire les préférences avant de lire.
const String pushReceiptsPreference = 'push.received';
const String pushLastReceivedPreference = 'push.last_received';

/// Note la réception d'un message (`outbox_id` des données Firebase).
Future<void> notePushReceived(
  SharedPreferences prefs,
  String? outboxId,
  DateTime at,
) async {
  await prefs.setString(
    pushLastReceivedPreference,
    at.toUtc().toIso8601String(),
  );
  final id = int.tryParse(outboxId ?? '');
  if (id == null) return;
  final others = [
    for (final e
        in prefs.getStringList(pushReceiptsPreference) ?? const <String>[])
      if (e != '$id') e,
  ];
  await prefs.setStringList(pushReceiptsPreference, [
    ...others.skip(others.length > 49 ? others.length - 49 : 0),
    '$id',
  ]);
}

/// Messages reçus à confirmer.
List<int> pendingPushReceipts(SharedPreferences prefs) => [
  for (final raw
      in prefs.getStringList(pushReceiptsPreference) ?? const <String>[])
    ?int.tryParse(raw),
];

/// Retire les messages confirmés.
Future<void> clearPushReceipts(SharedPreferences prefs, List<int> sent) async {
  final rest = [
    for (final id in pendingPushReceipts(prefs))
      if (!sent.contains(id)) '$id',
  ];
  await prefs.setStringList(pushReceiptsPreference, rest);
}

/// Dernière notification reçue sur ce téléphone, ou `null`.
DateTime? lastPushReceived(SharedPreferences prefs) =>
    DateTime.tryParse(prefs.getString(pushLastReceivedPreference) ?? '')
        ?.toLocal();
