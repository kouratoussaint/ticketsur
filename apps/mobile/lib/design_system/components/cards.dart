import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/pressable_scale.dart';

/// Ligne d'information d'une carte (date, heure, lieu).
typedef InfoLine = ({IconData icon, String text});

/// Carte événement héros : carte Nuit, photo fondue à droite, pastilles de
/// statut et de type, titre blanc, date et lieu, chiffres séparés par des
/// filets, bouton menthe (« Suivre les entrées en direct »).
class HeroEventCard extends StatelessWidget {
  const new({
    required this.title,
    this.image,
    this.badges = const [],
    this.overline,
    this.lines = const [],
    this.stats = const [],
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.onTap,
    this.corner,
    this.actionKey,
    this.statKeys = const [],
    this.height = TikeoSizes.heroCardHeight,
    this.radius = TikeoRadii.hero,
    this.imageShare = 0.55,
    super.key,
  });

  final String title;

  /// Photo (couverture) affichée sur la droite, fondue vers le Nuit.
  final Widget? image;

  /// Pastilles en haut à gauche (statut…).
  final List<Widget> badges;

  /// Sur-titre en haut à droite (type, en capitales, menthe).
  final String? overline;
  final List<InfoLine> lines;
  final List<StatItem> stats;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  /// Bouton en haut à droite (favori…), après le sur-titre.
  final Widget? corner;
  final Key? actionKey;

  /// Clés des chiffres de [stats], dans l'ordre (tests).
  final List<Key?> statKeys;
  final double height;
  final double radius;

  /// Part de la largeur occupée par la photo.
  final double imageShare;

  @override
  Widget build(BuildContext context) {
    const white = TicketSurColors.white;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return PressableScale(
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: TicketSurColors.navy,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: dark ? null : TikeoShadows.overlap,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                if (image case final photo?)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: imageShare,
                        heightFactor: 1,
                        child: ExcludeSemantics(
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [Color(0x00000000), Color(0xFF000000)],
                              stops: [0, 0.6],
                            ).createShader(rect),
                            child: photo,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: badges,
                            ),
                          ),
                          if (overline case final text?)
                            Text(
                              text.toUpperCase(),
                              style: TikeoTextStyles.overline.copyWith(
                                color: TicketSurColors.mint,
                              ),
                            ),
                          ?corner,
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TikeoTextStyles.heroCardTitle.copyWith(
                          color: white,
                        ),
                      ),
                      for (final line in lines) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              line.icon,
                              size: 18,
                              color: TicketSurColors.mint,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        StatStrip(
                          items: stats,
                          onDark: true,
                          valueKeys: statKeys,
                        ),
                      ],
                      if (actionLabel case final label?) ...[
                        const SizedBox(height: 16),
                        TikeoPrimaryButton(
                          key: actionKey,
                          label: label,
                          icon: actionIcon,
                          onPressed: onAction,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Points d'un carrousel « À la une » : l'actif menthe, 18 × 8.
class CarouselDots extends StatelessWidget {
  const new({required this.count, required this.index, super.key});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? TicketSurColors.mint
                  : TicketSurColors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(TikeoRadii.pill),
            ),
          ),
      ],
    ),
  );
}

/// Ligne de liste : carte blanche avec vignette ou avatar, titre,
/// informations, pastille, menu « ⋮ » et chevron (ou cœur). Un trait
/// vertical de 4 à gauche peut reprendre la couleur d'un statut.
class TikeoListRow extends StatelessWidget {
  const new({
    required this.title,
    this.leading,
    this.subtitle,
    this.lines = const [],
    this.badge,
    this.trailing,
    this.menu,
    this.stripe,
    this.onTap,
    this.onLongPress,
    this.chevron = true,
    super.key,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final List<String> lines;

  /// Pastille sous le titre.
  final Widget? badge;

  /// Remplace le chevron (cœur, case à cocher…).
  final Widget? trailing;

  /// Bouton « ⋮ » (garde les actions qu'une maquette ne montre pas).
  final Widget? menu;

  /// Trait de statut à gauche.
  final Color? stripe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return PressableScale(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(TikeoRadii.button),
          boxShadow: TikeoShadows.cardFor(theme.brightness),
          border: dark
              ? Border.all(color: theme.colorScheme.outlineVariant)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stripe case final color?)
                    Container(width: TikeoSizes.statusStripe, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                      child: Row(
                        children: [
                          if (leading case final widget?) ...[
                            widget,
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (subtitle case final text?)
                                  Text(
                                    text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                for (final line in lines)
                                  Text(
                                    line,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (badge case final pill?) ...[
                                  const SizedBox(height: 6),
                                  pill,
                                ],
                              ],
                            ),
                          ),
                          ?menu,
                          if (trailing case final widget?)
                            widget
                          else if (chevron && onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
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

/// Ligne de réglage : rond pastel de 44 avec une icône pleine 22, titre,
/// sous-titre, chevron ou interrupteur (72 de haut).
class SettingsRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.tint,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final TikeoTint tint;
  final String? subtitle;

  /// Interrupteur, valeur… ; chevron par défaut si [onTap] est donné.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TikeoRadii.button),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: TikeoSizes.settingsRow),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: TikeoSizes.settingsIconCircle,
                height: TikeoSizes.settingsIconCircle,
                decoration: BoxDecoration(
                  color: tint.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: tint.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle case final text?)
                      Text(
                        text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing case final widget?)
                widget
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau teinté : grand rond plein avec icône blanche, titre et phrase
/// (bandeau d'état « Ticket valable », bandeau d'annonce saumon…). [onClose]
/// ajoute une croix.
class TintedBanner extends StatelessWidget {
  const new({
    required this.tint,
    required this.icon,
    required this.title,
    this.body,
    this.onClose,
    this.closeTooltip,
    this.bodyKey,
    super.key,
  });

  final TikeoTint tint;
  final IconData icon;
  final String title;
  final String? body;

  /// Clé de la phrase (tests).
  final Key? bodyKey;
  final VoidCallback? onClose;
  final String? closeTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(TikeoRadii.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.icon, shape: BoxShape.circle),
            child: Icon(
              icon,
              color: theme.brightness == Brightness.dark
                  ? TicketSurColors.navy
                  : TicketSurColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: tint.text),
                ),
                if (body case final text?)
                  Text(
                    text,
                    key: bodyKey,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tint.text,
                    ),
                  ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              tooltip: closeTooltip,
              color: tint.text,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

/// Carte blanche standard (arrondi 20, ombre douce en clair).
class TikeoCard extends StatelessWidget {
  const new({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(TikeoRadii.card),
        boxShadow: TikeoShadows.cardFor(theme.brightness),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.colorScheme.outlineVariant)
            : null,
      ),
      // Les tuiles de liste (interrupteurs, lignes) dessinent leurs effets
      // sur ce support transparent, au-dessus du fond de la carte.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
