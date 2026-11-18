import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/team/presentation/team_copy.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.controlTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(scanPostsProvider.future),
        child: switch (posts) {
          AsyncData(:final value) => _Posts(
            posts: [
              for (final p in value)
                if (eventId == null || p.eventId == eventId) p,
            ],
          ),
          AsyncError() => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(
                  l10n.controlLoadError,
                  key: const Key('control-error'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(scanPostsProvider),
                  child: Text(l10n.orgRetry),
                ),
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
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
      return ListView(
        padding: const EdgeInsets.all(TicketSurSpacing.xl),
        children: [
          const SizedBox(height: 60),
          FadeSlideIn(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.door_front_door_outlined,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                Text(
                  l10n.controlEmptyTitle,
                  key: const Key('control-empty'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(l10n.controlEmptyBody, textAlign: TextAlign.center),
              ],
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
    final now = DateTime.now().toUtc();
    return ListView(
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      children: [
        for (final (index, group) in byEvent.values.indexed)
          FadeSlideIn(
            key: ValueKey('post-${group.first.eventId}'),
            delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.md),
              child: _EventPosts(posts: group, now: now),
            ),
          ),
      ],
    );
  }
}

class _EventPosts extends StatelessWidget {
  const new({required this.posts, required this.now});

  final List<ScanPost> posts;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final first = posts.first;
    final window = first.windowAt(now);
    final (label, color) = switch (window) {
      ScanWindow.open => (
        l10n.controlWindowOpen,
        TicketSurColors.successStrong,
      ),
      ScanWindow.upcoming => (
        l10n.controlWindowUpcoming(formatLocalDateTime(first.scanOpensAt)),
        TicketSurColors.blueText,
      ),
      ScanWindow.closed => (l10n.controlWindowClosed, const Color(0xFF52627A)),
    };
    return Card(
      key: Key('control-event-${first.eventId}'),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(first.eventTitle, style: theme.textTheme.titleLarge),
            Text(first.organizationName, style: theme.textTheme.bodySmall),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(formatEventRange(first.event)),
            const SizedBox(height: TicketSurSpacing.xs),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: TicketSurSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TicketSurSpacing.md),
            Text(l10n.controlChooseDoor, style: theme.textTheme.titleSmall),
            const SizedBox(height: TicketSurSpacing.xs),
            for (final post in posts)
              Padding(
                padding: const EdgeInsets.only(bottom: TicketSurSpacing.xs),
                child: FilledButton.tonalIcon(
                  key: Key('control-door-${post.checkpointId}'),
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.scanner, extra: post)),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(post.checkpointName),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
