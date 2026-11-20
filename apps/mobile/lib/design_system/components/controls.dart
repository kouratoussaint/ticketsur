import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';

// Boutons

/// Bouton principal : dégradé Menthe vive → Menthe, texte Nuit, halo menthe,
/// 56 de haut, arrondi 16, icône 22. Pleine largeur par défaut.
class TikeoPrimaryButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Indicateur d'attente à la place du libellé (bouton inactif).
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !busy;
    final dark = theme.brightness == Brightness.dark;
    // Inactif : gris lisible (≥ 4,5:1) sur la teinte des tuiles.
    final ink = enabled || busy
        ? TicketSurColors.navy
        : theme.colorScheme.onSurfaceVariant;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: TicketSurColors.navy,
            ),
          )
        else ...[
          if (icon case final glyph?) ...[
            Icon(glyph, size: TikeoSizes.buttonIcon, color: ink),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(color: ink),
            ),
          ),
        ],
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: PressableScale(
        child: AnimatedContainer(
          duration: TicketSurMotion.reduced(context)
              ? Duration.zero
              : TicketSurMotion.short,
          constraints: const BoxConstraints(
            minHeight: TikeoSizes.primaryButton,
          ),
          decoration: BoxDecoration(
            gradient: enabled || busy ? TikeoColors.mintGradient : null,
            color: enabled || busy
                ? null
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(TikeoRadii.button),
            boxShadow: enabled && !dark ? TikeoShadows.mintGlow : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(TikeoRadii.button),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(widthFactor: 1, heightFactor: 1, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton sombre : Nuit, texte blanc (« Scanner à l'entrée »).
class TikeoDarkButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = FilledButton.styleFrom(
      backgroundColor: dark ? TicketSurColors.white : TicketSurColors.navy,
      foregroundColor: dark ? TicketSurColors.navy : TicketSurColors.white,
      minimumSize: const Size.fromHeight(TikeoSizes.primaryButton),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TikeoRadii.button),
      ),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

/// Bouton danger : fond rouge pâle, texte rouge (annuler un ticket, se
/// déconnecter) ; 52 de haut, arrondi 14.
class TikeoDangerButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tint = context.tints.red;
    final style = FilledButton.styleFrom(
      backgroundColor: tint.background,
      foregroundColor: tint.text,
      minimumSize: const Size.fromHeight(TikeoSizes.secondaryButton),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TikeoRadii.field),
      ),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

/// Bouton d'action carré (recherche, filtre) : 48 × 48, arrondi 14,
/// avec un compteur facultatif (filtres actifs).
class TikeoSquareButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.count = 0,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int count;

  /// Plein Nuit (bouton filtre de l'Explorer), sinon à contour.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = filled
        ? (dark ? TicketSurColors.mint : TicketSurColors.navy)
        : Theme.of(context).cardTheme.color;
    final ink = filled
        ? (dark ? TicketSurColors.navy : TicketSurColors.white)
        : scheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TikeoRadii.field),
          side: filled
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: TikeoSizes.squareButton,
            child: Center(
              child: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: TicketSurColors.mint,
                textColor: TicketSurColors.navy,
                child: Icon(icon, color: ink, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Champs et options

/// Libellé au-dessus d'un champ : icône, texte 14 / 600 et astérisque rouge
/// si le champ est obligatoire.
class TikeoFieldLabel extends StatelessWidget {
  const new({required this.label, this.icon, this.required = false, super.key});

  final String label;
  final IconData? icon;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (icon case final glyph?) ...[
            Icon(glyph, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: context.tints.red.text),
                    ),
                ],
              ),
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Option sélectionnable : carte avec icône, libellé, rond ou coche ;
/// sélectionnée : fond menthe pâle, bordure et coche menthe.
class SelectableOption extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.subtitle,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mint = context.tints.mint;
    final border = selected
        ? TicketSurColors.mint
        : theme.colorScheme.outlineVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? mint.background : theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TikeoRadii.field),
          side: BorderSide(color: border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TikeoSizes.option),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  if (icon case final glyph?) ...[
                    Icon(
                      glyph,
                      color: selected
                          ? mint.text
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: theme.textTheme.labelMedium),
                        if (subtitle case final text?)
                          Text(text, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? mint.icon : theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recherche : champ blanc arrondi 16 avec loupe, et bouton filtre carré.
class TikeoSearchBar extends StatelessWidget {
  const new({
    required this.hint,
    this.controller,
    this.onChanged,
    this.onFilter,
    this.filterTooltip,
    this.filterCount = 0,
    this.fieldKey,
    this.filterKey,
    this.onSubmitted,
    this.suffix,
    this.semanticLabel,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final String hint;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Bouton dans le champ (effacer…).
  final Widget? suffix;
  final String? semanticLabel;
  final Key? filterKey;
  final VoidCallback? onFilter;
  final String? filterTooltip;
  final int filterCount;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(TikeoRadii.button);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textCapitalization: textCapitalization,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              semanticCounterText: semanticLabel,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: suffix,
              filled: true,
              fillColor: theme.cardTheme.color,
              border: border(theme.colorScheme.outlineVariant),
              enabledBorder: border(theme.colorScheme.outlineVariant),
              focusedBorder: border(
                theme.brightness == Brightness.dark
                    ? TicketSurColors.mint
                    : TicketSurColors.mintDeep,
                2,
              ),
            ),
          ),
        ),
        if (onFilter != null) ...[
          const SizedBox(width: 8),
          TikeoSquareButton(
            key: filterKey,
            icon: Icons.tune_rounded,
            tooltip: filterTooltip ?? hint,
            onPressed: onFilter,
            count: filterCount,
            filled: true,
          ),
        ],
      ],
    );
  }
}

/// Onglets de statut en pastilles : l'actif en Menthe profonde, texte blanc.
class StatusTabs<T> extends StatelessWidget {
  const new({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.keyOf,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final Key Function(T value)? keyOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, value) in values.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Semantics(
              selected: value == selected,
              button: true,
              child: Material(
                key: keyOf?.call(value),
                color: value == selected
                    ? (dark ? TicketSurColors.mint : TicketSurColors.mintDeep)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TikeoRadii.pill),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          labelOf(value),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: value == selected
                                ? (dark
                                      ? TicketSurColors.navy
                                      : TicketSurColors.white)
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Pastilles

/// Pastille d'une teinte par sens (rôle, catégorie, prix, type sur fond
/// clair). [large] : 40 de haut, texte 18 / 800 (fiche ticket).
class TikeoPill extends StatelessWidget {
  const new({
    required this.label,
    required this.tint,
    this.icon,
    this.large = false,
    this.uppercase = false,
    super.key,
  });

  final String label;
  final TikeoTint tint;
  final IconData? icon;
  final bool large;

  /// Sur-titre en capitales (types d'événement).
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final style = uppercase
        ? TikeoTextStyles.overline
        : (large ? TikeoTextStyles.chipLarge : TikeoTextStyles.chip);
    return Container(
      constraints: BoxConstraints(
        minHeight: large ? TikeoSizes.chipLarge : TikeoSizes.chip,
      ),
      padding: EdgeInsets.symmetric(horizontal: large ? 16 : 12, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(TikeoRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final glyph?) ...[
            Icon(
              glyph,
              size: large ? 22 : TikeoSizes.chipIcon,
              color: tint.icon,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(color: tint.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Type d'événement en sur-titre posé sur une photo : fond plein à 85 %,
/// texte blanc, fin contour clair.
class KindOnPhotoPill extends StatelessWidget {
  const new({required this.label, required this.color, super.key});

  final String label;

  /// Couleur pleine du type (`TikeoKindColors`).
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 24),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: TikeoKindColors.onPhoto(color),
      borderRadius: BorderRadius.circular(TikeoRadii.pill),
      border: Border.all(color: TicketSurColors.white.withValues(alpha: 0.35)),
    ),
    child: Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TikeoTextStyles.overline.copyWith(color: TicketSurColors.white),
    ),
  );
}

/// Point « en direct » qui pulse toutes les 1,6 s (fixe si les animations
/// sont réduites).
class LiveDot extends StatefulWidget {
  const new({this.color, this.size = 10, super.key});

  final Color? color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TicketSurMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.tints.live.icon;
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size * 2,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - _controller.value) * 0.5,
                child: Transform.scale(
                  scale: 1 + _controller.value,
                  child: dot,
                ),
              ),
              child!,
            ],
          ),
          child: dot,
        ),
      ),
    );
  }
}

/// Cadre de QR : QR sur fond blanc dans un viseur à 4 coins menthe (coins
/// de 22, trait 4).
class QrViewfinder extends StatelessWidget {
  const new({required this.child, this.size = TikeoSizes.ticketQr, super.key});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size + 24,
    child: CustomPaint(
      painter: const _ViewfinderPainter(),
      child: Center(
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: TicketSurColors.white,
            borderRadius: BorderRadius.circular(TikeoRadii.xs),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _ViewfinderPainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    const corner = 22.0;
    const radius = 8.0;
    final paint = Paint()
      ..color = TicketSurColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final r = (Offset.zero & size).deflate(2);
    final corners = [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ];
    for (final (p, dx, dy) in corners) {
      final path = Path()
        ..moveTo(p.dx, p.dy + corner * dy)
        ..lineTo(p.dx, p.dy + radius * dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + radius * dx, p.dy)
        ..lineTo(p.dx + corner * dx, p.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}
