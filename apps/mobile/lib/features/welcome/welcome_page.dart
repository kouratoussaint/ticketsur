import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/features/announcements/presentation/announcement_banner.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final mint = context.tints.mint;
    final canPop = Navigator.of(context).canPop();
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: mint.background,
            child: Icon(Icons.check_rounded, size: 18, color: mint.icon),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(child: Text(text, style: textTheme.titleSmall)),
        ],
      ),
    );
    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
      child: child,
    );
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.lg),
              children: [
                // Écran A : en-tête « Découvrez les événements ».
                TikeoHeroHeader(
                  title: l10n.welcomeDiscoverTitle,
                  subtitle: l10n.appSlogan,
                  onBack: canPop
                      ? () => Navigator.of(context).maybePop()
                      : null,
                  actions: [
                    if (canPop)
                      const TikeoLogo(
                        height: TikeoSizes.headerLogo,
                        onDark: true,
                      ),
                  ],
                  overlap: 0,
                ),
                const SizedBox(height: TikeoSizes.cardGap),
                const AnnouncementBanner(
                  padding: EdgeInsets.fromLTRB(
                    TikeoSizes.screenMargin,
                    0,
                    TikeoSizes.screenMargin,
                    TikeoSizes.cardGap,
                  ),
                ),
                padded(
                  Text(
                    l10n.welcomeDiscoverBody,
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                const FadeSlideIn(child: _DiscoverStrip()),
                padded(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('welcome-discover-all'),
                      onPressed: () => context.go(AppRoutes.discover),
                      icon: const Icon(Icons.explore_rounded),
                      label: Text(l10n.welcomeDiscoverAll),
                    ),
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                // Organiser -------------------------------------------------
                padded(
                  TikeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: l10n.organizeTitle,
                          icon: Icons.campaign_rounded,
                        ),
                        const SizedBox(height: TicketSurSpacing.xs),
                        Text(l10n.organizeBody, style: textTheme.bodyMedium),
                        const SizedBox(height: TicketSurSpacing.md),
                        point(l10n.organizePoint1),
                        point(l10n.organizePoint2),
                        point(l10n.organizePoint3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // « Votre espace Tikéo » : créer un compte, se connecter, code.
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TikeoRadii.navBar),
              ),
              boxShadow: TikeoShadows.cardFor(theme.brightness),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.welcomeSpaceTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: TicketSurSpacing.sm),
                    TikeoPrimaryButton(
                      key: const Key('welcome-sign-up'),
                      onPressed: () =>
                          unawaited(context.push(AppRoutes.signUp)),
                      icon: Icons.person_add_alt_1_rounded,
                      label: l10n.welcomeCreateAccount,
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          key: const Key('welcome-terms'),
                          onPressed: () => unawaited(
                            context.push(AppRoutes.legal(LegalSlug.terms)),
                          ),
                          child: Text(
                            l10n.legalTerms,
                            style: textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          key: const Key('welcome-privacy'),
                          onPressed: () => unawaited(
                            context.push(AppRoutes.legal(LegalSlug.privacy)),
                          ),
                          child: Text(
                            l10n.legalPrivacy,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          style: textTheme.bodyMedium,
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
        child: Center(child: CircularProgressIndicator()),
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
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TikeoRadii.card),
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
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    Text(
                      summaryWhen(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.accentText,
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
