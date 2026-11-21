import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';

/// Ligne qu'on balaie vers la gauche pour une action courante (retirer,
/// fermer). Le geste a toujours un équivalent par bouton ailleurs sur la
/// ligne ou l'écran (accessibilité).
///
/// [confirm] fait l'action quand elle dépend du serveur : `true` si elle a
/// abouti (la ligne part), `false` sinon (la ligne revient). [onSwiped] est
/// appelé une fois la ligne partie : la liste doit la retirer tout de suite.
class SwipeToAct extends StatelessWidget {
  const new({
    required this.swipeKey,
    required this.icon,
    required this.label,
    required this.child,
    this.onSwiped,
    this.confirm,
    this.danger = true,
    this.enabled = true,
    super.key,
  });

  /// Faux : pas de balayage (par exemple en mode sélection).
  final bool enabled;

  /// Clé du geste, unique dans la liste (identifiant de l'élément).
  final Key swipeKey;
  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onSwiped;
  final Future<bool> Function()? confirm;

  /// Rouge (retrait) ; sinon menthe profonde (fermeture, rangement).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = danger ? scheme.error : scheme.primary;
    final foreground = danger ? scheme.onError : scheme.onPrimary;
    return Dismissible(
      key: swipeKey,
      direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: confirm == null ? null : (_) => confirm!(),
      onDismissed: (_) => onSwiped?.call(),
      background: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TikeoRadii.button),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: foreground),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: foreground),
              ],
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
