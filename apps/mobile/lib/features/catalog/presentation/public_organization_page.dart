import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Page publique d'une structure, ouverte depuis « Organisé par » sur la
/// fiche d'un événement (ADR 0045) : identité, contact WhatsApp, chiffres
/// et événements à venir.
class PublicOrganizationPage extends ConsumerWidget {
  const new({required this.organizationId, super.key});

  final String organizationId;

  Future<void> _contact(
    BuildContext context,
    WidgetRef ref,
    PublicOrganization organization,
  ) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final phone = organization.publicPhone;
    if (phone == null) return;
    final opened = await ref.read(externalLinkProvider)(
      whatsAppUri(phone, l10n.publicOrgWhatsAppMessage(organization.name)),
    );
    if (!opened) toast.error(l10n.publicEventWhatsAppFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final page = ref.watch(publicOrganizationProvider(organizationId));
    final organization = page.value;
    final header = TikeoHeroHeader(
      title: l10n.publicOrgTitle,
      onBack: () => context.popOr(AppRoutes.discover),
      overlap: organization == null ? 0 : TikeoSizes.heroOverlap,
    );
    final content = switch (page) {
      AsyncData(:final value) => [
        _Identity(organization: value, header: header),
        if (value.publicPhone != null) ...[
          const SizedBox(height: TikeoSizes.cardGap),
          _padded(
            TikeoPrimaryButton(
              key: const Key('public-org-whatsapp'),
              label: l10n.publicOrgContact,
              icon: Icons.chat_rounded,
              onPressed: () => unawaited(_contact(context, ref, value)),
            ),
          ),
        ],
        const SizedBox(height: TikeoSizes.sectionGap - 4),
        _padded(
          SectionHeader(title: l10n.publicOrgEvents, icon: Icons.event_rounded),
        ),
        const SizedBox(height: 8),
        if (value.events.isEmpty)
          _padded(
            TikeoCard(
              key: const Key('public-org-empty'),
              child: Text(
                l10n.publicOrgNoEvents,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        for (final event in value.events)
          _padded(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PublicEventTile(event: event),
            ),
          ),
      ],
      AsyncError(:final error) => [
        header,
        const SizedBox(height: TikeoSizes.cardGap),
        _padded(
          TintedBanner(
            key: const Key('public-org-error'),
            tint: tints.red,
            icon: error == CatalogFailure.notFound
                ? Icons.storefront_rounded
                : Icons.wifi_off_rounded,
            title: error == CatalogFailure.notFound
                ? l10n.publicOrgNotFound
                : error == CatalogFailure.network
                ? l10n.exploreErrorNetwork
                : l10n.exploreErrorLoad,
          ),
        ),
      ],
      _ => [
        header,
        const SizedBox(height: TikeoSizes.cardGap),
        _padded(const Shimmer(child: SkeletonBox(height: 120, radius: 16))),
      ],
    };
    return Scaffold(
      key: const Key('public-org-page'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicOrganizationProvider(organizationId));
          try {
            await ref.read(publicOrganizationProvider(organizationId).future);
          } on Object {
            // L'échec s'affiche dans la page.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: TikeoSizes.sectionGap),
          children: content,
        ),
      ),
    );
  }

  static Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TikeoSizes.screenMargin),
    child: child,
  );
}

/// En-tête et carte d'identité (logo, nom, ville, ancienneté), dans une même
/// `Column` pour que la carte qui remonte reste touchable.
class _Identity extends StatelessWidget {
  const new({required this.organization, required this.header});

  final PublicOrganization organization;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final initials = organization.name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        TikeoOverlapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  UserAvatar(
                    key: const Key('public-org-logo'),
                    initials: initials,
                    url: organization.logoUrl,
                    radius: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          key: const Key('public-org-name'),
                          style: textTheme.titleLarge,
                        ),
                        if (organization.city case final city?)
                          Text(city, style: textTheme.bodyMedium),
                        Text(
                          l10n.publicOrgSince(
                            '${organization.createdAt.toLocal().year}',
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: context.palette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: 24,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              StatStrip(
                key: const Key('public-org-stats'),
                centered: true,
                items: [
                  (
                    value: '${organization.events.length}',
                    label: l10n.publicOrgUpcoming,
                    color: context.tints.mint.text,
                  ),
                  (
                    value: '${organization.pastEvents}',
                    label: l10n.publicOrgPast,
                    color: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
