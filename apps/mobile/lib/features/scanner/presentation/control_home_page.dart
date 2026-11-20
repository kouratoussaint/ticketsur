import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/illustrations.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Postes de contrôle (S20, S21) : événements attribués, puis porte.
///
/// Onglet « Contrôle » des contrôleurs ; page empilée pour les
/// organisateurs affectés.
class ControlHomePage extends ConsumerWidget {
  const new({this.eventId, super.key});

  /// Limite l'affichage à un événement (accès depuis sa fiche).
  final String? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final posts = ref.watch(scanPostsProvider);
    final canPop = Navigator.of(context).canPop();
    final mine = switch (posts) {
      AsyncData(:final value) => [
        for (final p in value)
          if (eventId == null || p.eventId == eventId) p,
      ],
      _ => null,
    };
    final header = TikeoHeroHeader(
      title: l10n.controlTitle,
      subtitle: l10n.controlHeroSubtitle,
      illustration: TikeoIllustration.scanner,
      onBack: canPop ? () => Navigator.of(context).maybePop() : null,
      overlap: mine == null || mine.isEmpty ? 0 : TikeoSizes.heroOverlap,
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(scanPostsProvider.future),
        child: ListView(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            // En-tête et carte dans une même colonne : la carte reste
            // touchable dans sa partie posée sur l'en-tête.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (mine != null && mine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TikeoSizes.screenMargin,
                    ),
                    child: TikeoOverlapCard(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _Summary(posts: mine),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TikeoSizes.screenMargin,
                TikeoSizes.cardGap,
                TikeoSizes.screenMargin,
                0,
              ),
              child: switch (posts) {
                AsyncData() => _Posts(posts: mine!),
                AsyncError() => _Error(
                  onRetry: () => ref.invalidate(scanPostsProvider),
                ),
                _ => const Shimmer(
                  child: Column(
                    children: [
                      SkeletonBox(height: 220, radius: TikeoRadii.card),
                      SizedBox(height: TikeoSizes.cardGap),
                      SkeletonBox(height: 220, radius: TikeoRadii.card),
                    ],
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Postes ouverts, à venir et nombre de portes.
class _Summary extends StatelessWidget {
  const new({required this.posts});

  final List<ScanPost> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    final events = {for (final p in posts) p.eventId: p.window};
    int count(ScanWindow w) => events.values.where((v) => v == w).length;
    return StatStrip(
      key: const Key('control-summary'),
      items: [
        (
          value: '${count(ScanWindow.open)}',
          label: l10n.controlSummaryOpen,
          color: tints.live.text,
        ),
        (
          value: '${count(ScanWindow.upcoming)}',
          label: l10n.controlSummaryUpcoming,
          color: tints.blue.text,
        ),
        (
          value: '${posts.length}',
          label: l10n.controlSummaryDoors,
          color: tints.violet.text,
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    return Column(
      children: [
        TintedBanner(
          tint: tints.red,
          icon: Icons.wifi_off_rounded,
          title: l10n.controlLoadError,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('control-error'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.orgRetry),
        ),
      ],
    );
  }
}

class _Posts extends StatelessWidget {
  const new({required this.posts});

  final List<ScanPost> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (posts.isEmpty) {
      return Column(
        children: [
          const AnnouncementBanner(),
          const SizedBox(height: 32),
          const TikeoIllustrationView(TikeoIllustration.scanner),
          const SizedBox(height: 16),
          Text(
            l10n.controlEmptyTitle,
            key: const Key('control-empty'),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.controlEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    // Regroupement par événement, dans l'ordre chronologique.
    final byEvent = <String, List<ScanPost>>{};
    for (final post in [
      ...posts,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt))) {
      byEvent.putIfAbsent(post.eventId, () => []).add(post);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AnnouncementBanner(),
        SectionHeader(
          title: l10n.controlMyPosts,
          icon: Icons.door_front_door_rounded,
        ),
        const SizedBox(height: 8),
        for (final (index, group) in byEvent.values.indexed)
          FadeSlideIn(
            key: ValueKey('post-${group.first.eventId}'),
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: TikeoSizes.cardGap),
              child: _EventPosts(posts: group),
            ),
          ),
      ],
    );
  }
}

class _EventPosts extends StatelessWidget {
  const new({required this.posts});

  final List<ScanPost> posts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final first = posts.first;
    final window = first.window;
    final (label, tint, icon) = switch (window) {
      ScanWindow.open => (
        l10n.controlWindowOpen,
        tints.live,
        Icons.play_circle_rounded,
      ),
      ScanWindow.upcoming => (
        l10n.controlNotStarted,
        tints.blue,
        Icons.schedule_rounded,
      ),
      ScanWindow.closed => (
        l10n.controlWindowClosed,
        tints.gray,
        Icons.stop_circle_rounded,
      ),
    };
    final muted = theme.colorScheme.onSurfaceVariant;
    return TikeoCard(
      key: Key('control-event-${first.eventId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TikeoPill(
            key: Key('control-window-${first.eventId}'),
            label: label,
            tint: tint,
            icon: icon,
          ),
          const SizedBox(height: 12),
          Text(first.eventTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            first.organizationName,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 10),
          _Info(
            icon: Icons.calendar_month_rounded,
            text: formatEventRange(first.event),
          ),
          if (first.venue case final venue? when venue.trim().isNotEmpty)
            _Info(icon: Icons.place_rounded, text: venue),
          const SizedBox(height: 14),
          Text(l10n.controlChooseDoor, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final post in posts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: window == ScanWindow.open
                  ? TikeoDarkButton(
                      key: Key('control-door-${post.checkpointId}'),
                      onPressed: () => _open(context, post),
                      icon: Icons.qr_code_scanner_rounded,
                      label: post.checkpointName,
                    )
                  : OutlinedButton.icon(
                      key: Key('control-door-${post.checkpointId}'),
                      onPressed: () => _open(context, post),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(post.checkpointName),
                    ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, ScanPost post) =>
      unawaited(context.push(AppRoutes.scanner, extra: post));
}

class _Info extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.tints.mint.text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
