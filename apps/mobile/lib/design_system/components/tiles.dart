import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';

/// Titre de section : icône contour, titre Nunito 20 / 800 et lien
/// « Tout voir → » en Menthe profonde.
class SectionHeader extends StatelessWidget {
  const new({
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      // En très grand texte, le bouton d'action ne prend jamais plus de la
      // moitié de la ligne (lot 4-9 : audit à 200 %).
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            if (icon case final glyph?) ...[
              Icon(glyph, size: 22, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            if (actionLabel case final label? when onAction != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: TextButton(
                  key: actionKey,
                  onPressed: onAction,
                  child: Text(
                    '$label →',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tuile de chiffre : fond pastel d'une teinte par sens, icône 26, chiffre
/// Nunito 24 / 900, libellé 13 (hauteur 88, arrondi 18).
class StatTile extends StatelessWidget {
  const new({
    required this.tint,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    super.key,
  });

  final TikeoTint tint;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$value $label',
      child: ExcludeSemantics(
        child: Material(
          color: tint.background,
          borderRadius: BorderRadius.circular(TikeoRadii.tile),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: TikeoSizes.statTile),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 26, color: tint.icon),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TikeoTextStyles.tileNumber.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tint.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une valeur d'un bandeau de chiffres.
typedef StatItem = ({String value, String label, Color? color});

/// Bandeau de 3 ou 4 chiffres séparés par des filets, dans une carte.
class StatStrip extends StatelessWidget {
  const new({
    required this.items,
    this.onDark = false,
    this.valueKeys = const [],
    this.centered = false,
    super.key,
  });

  final List<StatItem> items;

  /// Clés des chiffres, dans l'ordre (tests).
  final List<Key?> valueKeys;

  /// Sur une carte Nuit (carte événement héros) : texte blanc.
  final bool onDark;

  /// Chiffres et libellés centrés dans leur colonne (résumés : contrôle,
  /// historique, Mes tickets), à toute taille de texte.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = onDark ? TicketSurColors.white : theme.colorScheme.onSurface;
    final muted = onDark
        ? TicketSurColors.white.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant;
    final rule = onDark
        ? TicketSurColors.white.withValues(alpha: 0.2)
        : theme.colorScheme.outlineVariant;
    return IntrinsicHeight(
      child: Row(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) VerticalDivider(width: 24, thickness: 1, color: rule),
            Expanded(
              child: Semantics(
                container: true,
                label: '${item.value} ${item.label}',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: centered
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    crossAxisAlignment: centered
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: centered
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: Text(
                          item.value,
                          key: i < valueKeys.length ? valueKeys[i] : null,
                          style: TikeoTextStyles.tileNumber.copyWith(
                            color: item.color ?? ink,
                          ),
                        ),
                      ),
                      // Un seul mot (« gestionnaires ») : réduit plutôt que
                      // coupé au milieu ; sinon deux lignes.
                      if (item.label.contains(' '))
                        Text(
                          item.label,
                          maxLines: 2,
                          textAlign: centered ? TextAlign.center : null,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: centered
                              ? Alignment.center
                              : Alignment.centerLeft,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            textAlign: centered ? TextAlign.center : null,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                    ],
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

/// Anneau de pourcentage (taux d'entrée) : anneau menthe de 56.
class StatRing extends StatelessWidget {
  const new({
    required this.value,
    required this.label,
    this.size = 56,
    super.key,
  });

  /// Entre 0 et 1.
  final double value;

  /// Texte au centre (« 35 % »).
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: TicketSurMotion.reduced(context)
                ? Duration.zero
                : TicketSurMotion.entrance,
            curve: TicketSurMotion.enter,
            builder: (context, shown, _) => CustomPaint(
              painter: _RingPainter(
                value: shown,
                track: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const new({required this.value, required this.track});

  final double value;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(rect, 0, math.pi * 2, false, paint..color = track)
      ..drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = TicketSurColors.mint,
      );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.track != track;
}

/// Action rapide : 96 de haut, arrondi 20 ; la principale en dégradé
/// menthe (icône dans un carré blanc de 40), les autres sur la teinte des
/// tuiles avec une icône Nuit ; libellé 14 / 700 sur deux lignes.
class QuickActionTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.labelSize,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  /// Taille du libellé imposée : sans elle, la tuile la choisit selon sa
  /// largeur (mais ne peut alors pas être mesurée par `IntrinsicHeight`).
  final double? labelSize;

  /// Libellé réduit à 12 sous 84 de large.
  static bool compactLabel(double width) => width < 84;

  Widget _label(ThemeData theme, Color ink, double size) => Text(
    label,
    textAlign: TextAlign.center,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.labelMedium?.copyWith(
      color: ink,
      fontSize: size,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = primary || !dark
        ? TicketSurColors.navy
        : theme.colorScheme.onSurface;
    return PressableScale(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: primary ? TikeoColors.mintGradient : null,
          color: primary ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(TikeoRadii.card),
          boxShadow: primary && !dark ? TikeoShadows.mintGlow : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(TikeoRadii.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TikeoSizes.quickAction,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (primary)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TicketSurColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 28, color: ink),
                      )
                    else
                      Icon(icon, size: 28, color: ink),
                    const SizedBox(height: 8),
                    // 14 / 700 ; un peu plus petit sur un écran étroit,
                    // pour ne pas couper « événement » au milieu.
                    if (labelSize case final size?)
                      _label(theme, ink, size)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) => _label(
                          theme,
                          ink,
                          compactLabel(constraints.maxWidth) ? 12 : 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
