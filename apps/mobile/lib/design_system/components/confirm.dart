import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Demande de confirmation commune à toute l'app (lot 4-9) : titre, texte
/// (qui défile s'il est long, utile en très grand texte), bouton d'annulation
/// et bouton de confirmation, rouge si l'action est [danger]euse. Renvoie
/// vrai seulement si la personne confirme.
///
/// Les formulaires (motif, code, saisie) gardent leurs propres boîtes ; tout
/// simple « Oui / Non » passe par ici.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  String? cancelLabel,
  IconData? icon,
  bool danger = false,
  Key confirmKey = const Key('confirm-action'),
  Key? cancelKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        key: const Key('confirm-dialog'),
        icon: icon == null ? null : Icon(icon),
        title: Text(title),
        content: body == null ? null : SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            key: cancelKey,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? context.l10n.bulkCancel),
          ),
          FilledButton(
            key: confirmKey,
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
