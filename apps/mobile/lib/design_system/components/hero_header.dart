import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';

/// Fond de l'en-tête héros : dégradé Nuit, halo menthe en haut à droite,
/// vague organique en bas à droite (direction artistique, section 2).
class TikeoHeroBackground extends StatelessWidget {
  const new({this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: TikeoColors.heroGradient),
    child: CustomPaint(painter: const TikeoWavePainter(), child: child),
  );
}

/// Halo et vague de l'en-tête héros.
class TikeoWavePainter extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    final halo = Rect.fromCircle(
      center: Offset(size.width, 0),
      radius: math.max(size.width, size.height) * 0.6,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = TikeoColors.heroHalo.createShader(halo),
    );
    final w = size.width;
    final h = size.height;
    final wave = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(w * 0.58, h * 0.78, w * 0.7, h * 0.92, w * 0.82, h * 0.66)
      ..cubicTo(w * 0.9, h * 0.48, w * 0.96, h * 0.5, w, h * 0.38)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wave, Paint()..color = TikeoColors.heroWave);
  }

  @override
  bool shouldRepaint(TikeoWavePainter oldDelegate) => false;
}

/// En-tête héros des écrans principaux : logo Tikéo blanc (ou retour sur
/// un écran de détail), actions (cloche, avatar…), titre Nunito 28 / 800,
/// sous-titre, illustration facultative. Le bas laisse [overlap] pour la
/// carte blanche qui remonte dessus ([TikeoOverlapCard]).
class TikeoHeroHeader extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.illustration,
    this.onBack,
    this.showLogo = true,
    this.actions = const [],
    this.overlap = TikeoSizes.heroOverlap,
    this.titleKey,
    super.key,
  });

  final String title;
  final String? subtitle;
  final TikeoIllustration? illustration;

  /// Bouton retour (écran de détail) à la place du logo.
  final VoidCallback? onBack;
  final bool showLogo;

  /// Cloche, avatar, menu… en haut à droite.
  final List<Widget> actions;

  /// Place laissée en bas pour la carte qui chevauche l'en-tête.
  final double overlap;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    const white = TicketSurColors.white;
    return TikeoHeroBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            8,
            TikeoSizes.screenMargin,
            overlap + 20,
          ),
          child: IconTheme(
            data: const IconThemeData(
              color: white,
              size: TikeoSizes.headerBell,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          key: const Key('hero-back'),
                          onPressed: onBack,
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          color: white,
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      else if (showLogo)
                        const TikeoLogo(
                          height: TikeoSizes.headerLogo,
                          onDark: true,
                        ),
                      const Spacer(),
                      ...actions,
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            key: titleKey,
                            style: TikeoTextStyles.heroTitle.copyWith(
                              color: white,
                            ),
                          ),
                          if (subtitle case final text?) ...[
                            const SizedBox(height: 6),
                            Text(
                              text,
                              style: TikeoTextStyles.heroSubtitle.copyWith(
                                color: white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (illustration case final kind?)
                      TikeoIllustrationView.header(kind),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cloche de l'en-tête, avec un point rouge s'il y a du nouveau.
class TikeoHeaderBell extends StatelessWidget {
  const new({
    required this.onPressed,
    required this.tooltip,
    this.dot = false,
    super.key,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final bool dot;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    color: TicketSurColors.white,
    icon: Badge(
      isLabelVisible: dot,
      smallSize: TikeoSizes.notificationDot,
      backgroundColor: TikeoColors.notificationDot,
      child: const Icon(
        Icons.notifications_rounded,
        size: TikeoSizes.headerBell,
      ),
    ),
  );
}

/// Version repliable de l'en-tête héros, pour un `CustomScrollView` : se
/// replie à 64 (titre Nunito 20 / 800) au défilement.
class TikeoHeroSliver extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.illustration,
    this.onBack,
    this.actions = const [],
    this.expandedHeight = TikeoSizes.heroHeaderLong,
    super.key,
  });

  final String title;
  final String? subtitle;
  final TikeoIllustration? illustration;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Hauteur dépliée, hors zone système.
  final double expandedHeight;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
    pinned: true,
    delegate: _HeroDelegate(
      header: this,
      top: MediaQuery.paddingOf(context).top,
    ),
  );
}

class _HeroDelegate extends SliverPersistentHeaderDelegate {
  new({required this.header, required this.top});

  final TikeoHeroSliver header;
  final double top;

  @override
  double get minExtent => top + TikeoSizes.heroCollapsed;

  @override
  double get maxExtent => math.max(minExtent, top + header.expandedHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final t = range == 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    const white = TicketSurColors.white;
    return TikeoHeroBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Contenu déplié : s'efface au repli.
          Opacity(
            opacity: (1 - t * 1.6).clamp(0.0, 1.0),
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: maxExtent,
              child: TikeoHeroHeader(
                title: header.title,
                subtitle: header.subtitle,
                illustration: header.illustration,
                onBack: header.onBack,
                actions: header.actions,
                overlap: 0,
              ),
            ),
          ),
          // Barre repliée : titre 20 / 800.
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: TikeoSizes.heroCollapsed,
            child: Opacity(
              opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
              child: Row(
                children: [
                  if (header.onBack != null)
                    IconButton(
                      onPressed: header.onBack,
                      color: white,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: TikeoSizes.screenMargin),
                  Expanded(
                    child: Text(
                      header.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: white),
                    ),
                  ),
                  ...header.actions,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HeroDelegate oldDelegate) =>
      oldDelegate.header != header || oldDelegate.top != top;
}

/// Carte blanche qui remonte de [overlap] sur l'en-tête héros (sélecteur
/// de structure, résumé du profil, sélecteur d'événement).
class TikeoOverlapCard extends StatelessWidget {
  const new({
    required this.child,
    this.overlap = TikeoSizes.heroOverlap,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final double overlap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _PullUp(
      overlap: overlap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(TikeoRadii.card),
          boxShadow: dark ? null : TikeoShadows.overlap,
        ),
        child: child,
      ),
    );
  }
}

/// Remonte son enfant de [overlap] : la place occupée diminue d'autant.
class _PullUp extends SingleChildRenderObjectWidget {
  const new({required this.overlap, super.child});

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPullUp(overlap);

  @override
  void updateRenderObject(BuildContext context, _RenderPullUp renderObject) {
    renderObject.overlap = overlap;
  }
}

class _RenderPullUp extends RenderProxyBox {
  new(this._overlap);

  double _overlap;
  double get overlap => _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = constraints.smallest;
      return;
    }
    box.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(box.size.width, math.max(0, box.size.height - _overlap)),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child case final box?) {
      context.paintChild(box, offset - Offset(0, _overlap));
    }
  }

  /// La partie remontée sur l'en-tête reste touchable : le parent (liste,
  /// colonne) teste les enfants du dernier au premier, donc la carte avant
  /// l'en-tête.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final area = Rect.fromLTWH(
      0,
      -_overlap,
      size.width,
      size.height + _overlap,
    );
    if (!area.contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final box = child;
    if (box == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, -_overlap),
      position: position,
      hitTest: (result, transformed) =>
          box.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_overlap, 0, 1);
  }
}
