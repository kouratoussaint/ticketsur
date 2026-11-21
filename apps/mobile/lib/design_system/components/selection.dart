import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Barre du haut en mode sélection : quitter, nombre choisi, tout
/// sélectionner. Clés `selection-close` et `selection-all`.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const new({
    required this.count,
    required this.onClose,
    this.onSelectAll,
    this.actions = const [],
    this.primary = true,
    super.key,
  });

  /// Faux quand la barre est posée dans le corps d'une page (sous sa barre).
  final bool primary;

  final int count;
  final VoidCallback onClose;

  /// `null` : pas de bouton « Tout sélectionner ».
  final VoidCallback? onSelectAll;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppBar(
      primary: primary,
      leading: IconButton(
        key: const Key('selection-close'),
        tooltip: l10n.selectionClose,
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text(l10n.selectionCount(count)),
      actions: [
        if (onSelectAll case final selectAll?)
          IconButton(
            key: const Key('selection-all'),
            tooltip: l10n.selectionAll,
            onPressed: selectAll,
            icon: const Icon(Icons.select_all_rounded),
          ),
        ...actions,
      ],
    );
  }
}

/// Action de la barre du bas en mode sélection.
final class SelectionAction {
  const new({
    required this.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final Key key;
  final IconData icon;
  final String label;

  /// `null` : action indisponible (grisée).
  final VoidCallback? onPressed;

  /// Action destructrice (texte rouge).
  final bool danger;
}

/// Barre d'actions en bas de l'écran en mode sélection : une icône et un
/// libellé court par action, sur toute la largeur.
///
/// Tant qu'elle est affichée, les messages (`Toaster`) passent au-dessus.
class SelectionActionBar extends StatefulWidget {
  const new({required this.actions, this.busy = false, super.key});

  final List<SelectionAction> actions;

  /// Vrai pendant une action : tout est grisé, un fil de progression
  /// s'affiche en haut.
  final bool busy;

  @override
  State<SelectionActionBar> createState() => _SelectionActionBarState();
}

class _SelectionActionBarState extends State<SelectionActionBar> {
  double _registered = 0;

  void _measure() {
    if (!mounted) return;
    final height = context.size?.height ?? 0;
    if (height == _registered) return;
    _registered = height;
    Toaster.bottomClearance.value = height;
  }

  @override
  void dispose() {
    if (Toaster.bottomClearance.value == _registered) {
      Toaster.bottomClearance.value = 0;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final actions = widget.actions;
    final busy = widget.busy;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: theme.cardTheme.color ?? scheme.surfaceContainerLowest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 3,
              child: busy ? const LinearProgressIndicator() : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TikeoSizes.screenMargin / 2,
                vertical: 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final action in actions)
                    Expanded(
                      child: _ActionButton(action: action, busy: busy),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const new({required this.action, required this.busy});

  final SelectionAction action;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = !busy && action.onPressed != null;
    final color = !enabled
        ? scheme.onSurface.withValues(alpha: 0.6)
        : action.danger
        ? scheme.error
        : scheme.onSurface;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        key: action.key,
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? action.onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: color),
              const SizedBox(height: 4),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cadre d'une ligne sélectionnable : bordure de la couleur principale
/// quand la ligne est choisie.
class SelectableFrame extends StatelessWidget {
  const new({required this.selected, required this.child, super.key});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(TikeoRadii.button),
      border: selected
          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
          : null,
    ),
    child: child,
  );
}

/// Demande de confirmation d'une action groupée. Renvoie vrai si elle est
/// confirmée. Clés `bulk-confirm` et `bulk-cancel`.
Future<bool> confirmBulkAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool danger = false,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            key: const Key('bulk-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.bulkCancel),
          ),
          FilledButton(
            key: const Key('bulk-confirm'),
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
