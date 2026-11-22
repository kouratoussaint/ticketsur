import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Structures suivies par le compte (ADR 0047) : un appui ouvre leur page.
class FollowedOrganizationsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final followed = ref.watch(followedOrganizationsProvider);
    final content = switch (followed) {
      AsyncData(:final value) when value.isEmpty => [
        TikeoCard(
          key: const Key('followed-empty'),
          child: Text(
            l10n.followedEmpty,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
      AsyncData(:final value) => [
        for (final organization in value)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TikeoListRow(
              key: Key('followed-${organization.id}'),
              leading: UserAvatar(
                initials: organization.name.characters.first.toUpperCase(),
                url: organization.logoUrl,
                radius: 24,
              ),
              title: organization.name,
              subtitle: organization.city,
              lines: [l10n.followedUpcoming(organization.upcoming)],
              onTap: () => unawaited(
                context.push(AppRoutes.publicOrganization(organization.id)),
              ),
            ),
          ),
      ],
      AsyncError() => [
        TintedBanner(
          key: const Key('followed-error'),
          tint: context.tints.red,
          icon: Icons.wifi_off_rounded,
          title: l10n.closedOrgsLoadError,
        ),
      ],
      _ => [const Shimmer(child: SkeletonBox(height: 88, radius: 16))],
    };
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(followedOrganizationsProvider);
          try {
            await ref.read(followedOrganizationsProvider.future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          key: const Key('followed-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: [
            TikeoHeroHeader(
              title: l10n.followedTitle,
              subtitle: l10n.followedSubtitle,
              onBack: () => context.popOr(AppRoutes.favorites),
              overlap: 0,
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            for (final child in content)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TikeoSizes.screenMargin,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

/// Entrée « N structures suivies » des favoris (rien s'il n'y en a pas).
class FollowedOrganizationsEntry extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedOrganizationsProvider).value ?? const [];
    if (followed.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TikeoSizes.screenMargin,
        TikeoSizes.cardGap,
        TikeoSizes.screenMargin,
        0,
      ),
      child: TikeoCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SettingsRow(
          key: const Key('favorites-followed'),
          icon: Icons.storefront_rounded,
          tint: context.tints.violet,
          title: l10n.followedEntry(followed.length),
          subtitle: l10n.followedSubtitle,
          onTap: () => unawaited(context.push(AppRoutes.followedOrganizations)),
        ),
      ),
    );
  }
}
