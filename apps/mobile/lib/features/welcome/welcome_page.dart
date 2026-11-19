import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Quelques événements publics à venir, pour la présentation.
final FutureProvider<List<PublicEventSummary>> welcomeEventsProvider =
    FutureProvider.autoDispose<List<PublicEventSummary>>(
      (ref) => ref
          .read(catalogRepositoryProvider)
          .search(
            const CatalogQuery(),
            now: ref.read(catalogClockProvider)(),
            limit: 8,
          ),
      retry: (retryCount, error) => null,
    );

/// Présentation de Tikéo sans compte : découvrir les événements, puis
/// organiser les siens ; créer un compte, se connecter ou rejoindre une
/// équipe avec un code.
class WelcomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    const white = TicketSurColors.white;
    const soft = Color(0xFFC9D6E3);
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: TicketSurColors.mint,
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: TicketSurColors.navy,
            ),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: textTheme.titleSmall?.copyWith(color: white),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: TicketSurColors.navy,
      appBar: AppBar(
        backgroundColor: TicketSurColors.navy,
        foregroundColor: white,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: TicketSurSpacing.lg),
                children: [
                  const FadeSlideIn(
                    duration: Duration(milliseconds: 450),
                    child: Center(child: TikeoLogo(height: 72, onDark: true)),
                  ),
                  const SizedBox(height: TicketSurSpacing.xs),
                  Text(
                    l10n.appSlogan,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: soft),
                  ),
                  const SizedBox(height: TicketSurSpacing.xl),
                  // Découvrir --------------------------------------------
                  _Section(
                    title: l10n.welcomeDiscoverTitle,
                    body: l10n.welcomeDiscoverBody,
                  ),
                  const SizedBox(height: TicketSurSpacing.md),
                  const _DiscoverStrip(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TicketSurSpacing.lg,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('welcome-discover-all'),
                        style: TextButton.styleFrom(
                          foregroundColor: TicketSurColors.mint,
                        ),
                        onPressed: () => context.go(AppRoutes.discover),
                        icon: const Icon(Icons.explore_rounded),
                        label: Text(l10n.welcomeDiscoverAll),
                      ),
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.lg),
                  // Organiser --------------------------------------------
                  _Section(title: l10n.organizeTitle, body: l10n.organizeBody),
                  const SizedBox(height: TicketSurSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TicketSurSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        point(l10n.organizePoint1),
                        point(l10n.organizePoint2),
                        point(l10n.organizePoint3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.lg,
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: const Key('welcome-sign-up'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signUp)),
                      child: Text(l10n.welcomeCreateAccount),
                    ),
                    const SizedBox(height: TicketSurSpacing.xs),
                    OutlinedButton(
                      key: const Key('welcome-sign-in'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signIn)),
                      child: Text(l10n.welcomeSignIn),
                    ),
                    TextButton.icon(
                      key: const Key('welcome-code'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signUpWithCode)),
                      icon: const Icon(Icons.key_rounded),
                      label: Text(l10n.welcomeHaveCode),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TicketSurSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: TicketSurColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(
            body,
            style: textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFC9D6E3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bande horizontale d'événements publics à venir.
class _DiscoverStrip extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(welcomeEventsProvider);
    final textTheme = Theme.of(context).textTheme;
    return switch (events) {
      AsyncData(:final value) when value.isEmpty => Padding(
        padding: const EdgeInsets.symmetric(horizontal: TicketSurSpacing.lg),
        child: Text(
          l10n.welcomeDiscoverEmpty,
          key: const Key('welcome-discover-empty'),
          style: textTheme.bodyMedium?.copyWith(color: TicketSurColors.white),
        ),
      ),
      AsyncData(:final value) => SizedBox(
        height: 214,
        child: ListView.separated(
          key: const Key('welcome-discover'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: TicketSurSpacing.lg),
          itemCount: value.length,
          separatorBuilder: (_, _) =>
              const SizedBox(width: TicketSurSpacing.sm),
          itemBuilder: (context, index) => _DiscoverCard(event: value[index]),
        ),
      ),
      // Hors ligne : la présentation reste utilisable sans la bande.
      AsyncError() => const SizedBox.shrink(),
      _ => const SizedBox(
        height: 214,
        child: Center(
          child: CircularProgressIndicator(color: TicketSurColors.mint),
        ),
      ),
    };
  }
}

class _DiscoverCard extends StatelessWidget {
  const new({required this.event});

  final PublicEventSummary event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: Card(
        key: Key('welcome-event-${event.id}'),
        margin: EdgeInsets.zero,
        color: TicketSurColors.navyLight,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TicketSurRadii.md),
        ),
        child: InkWell(
          onTap: () => unawaited(context.push(AppRoutes.publicEvent(event.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventCover(kind: event.kind, url: event.coverUrl),
              Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: TicketSurColors.white,
                      ),
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    Text(
                      summaryWhen(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: TicketSurColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
