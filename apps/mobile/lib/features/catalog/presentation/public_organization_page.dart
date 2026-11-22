import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/catalog/application/catalog_providers.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart';
import 'package:ticketsur/features/catalog/presentation/organization_share.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Page publique d'une structure, ouverte depuis « Organisé par » sur la
/// fiche d'un événement (ADR 0045) : identité, contact WhatsApp, chiffres
/// et événements à venir.
class PublicOrganizationPage extends ConsumerStatefulWidget {
  const new({required this.organizationId, super.key});

  final String organizationId;

  @override
  ConsumerState<PublicOrganizationPage> createState() =>
      _PublicOrganizationPageState();
}

class _PublicOrganizationPageState
    extends ConsumerState<PublicOrganizationPage> {
  /// État de suivi après un appui (sans recharger la page).
  ({bool following, int followers})? _follow;
  bool _following = false;

  String get organizationId => widget.organizationId;

  Future<void> _toggleFollow(PublicOrganization organization) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    if (ref.read(currentUserProvider).value == null) {
      unawaited(
        context.push(
          AppRoutes.signInThen(AppRoutes.publicOrganization(organization.id)),
        ),
      );
      return;
    }
    final follow = !organization.following;
    setState(() => _following = true);
    try {
      final state = await ref
          .read(catalogRepositoryProvider)
          .follow(organization.id, follow: follow);
      if (!mounted) return;
      setState(() => _follow = state);
      ref
        ..invalidate(followedOrganizationsProvider)
        // Autres pages de la même structure ouvertes : relues.
        ..invalidate(publicOrganizationProvider(organization.id));
      if (follow) toast.success(l10n.publicOrgFollowedToast);
    } on CatalogFailure catch (failure) {
      toast.error(
        failure == CatalogFailure.followLimit
            ? l10n.publicOrgFollowLimit
            : l10n.publicOrgFollowFailed,
      );
    } finally {
      if (mounted) setState(() => _following = false);
    }
  }

  Future<void> _openLink(String url) async {
    final failed = context.l10n.publicEventDirectionsFailed;
    final toast = Toaster.of(context);
    final opened = await ref.read(externalLinkProvider)(Uri.parse(url));
    if (!opened) toast.error(failed);
  }

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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final page = ref.watch(publicOrganizationProvider(organizationId));
    final organization = switch ((page.value, _follow)) {
      (final value?, final state?) => value.withFollow(state),
      (final value, _) => value,
    };
    final header = TikeoHeroHeader(
      title: l10n.publicOrgTitle,
      actions: [
        if (organization != null)
          IconButton(
            key: const Key('public-org-share'),
            tooltip: l10n.publicOrgShare,
            color: TicketSurColors.white,
            onPressed: () =>
                unawaited(showOrganizationShareSheet(context, organization)),
            icon: const Icon(Icons.share_rounded),
          ),
      ],
      onBack: () => context.popOr(AppRoutes.discover),
      overlap: organization == null ? 0 : TikeoSizes.heroOverlap,
    );
    final content = switch ((page, organization)) {
      // Page déjà lue (y compris pendant une relecture).
      (_, final value?) => [
        _Identity(organization: value, header: header),
        const SizedBox(height: TikeoSizes.cardGap),
        _padded(
          value.following
              ? OutlinedButton.icon(
                  key: const Key('public-org-follow'),
                  onPressed: _following
                      ? null
                      : () => unawaited(_toggleFollow(value)),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.publicOrgFollowing),
                )
              : TikeoPrimaryButton(
                  key: const Key('public-org-follow'),
                  label: l10n.publicOrgFollow,
                  icon: Icons.notifications_active_rounded,
                  busy: _following,
                  onPressed: _following
                      ? null
                      : () => unawaited(_toggleFollow(value)),
                ),
        ),
        if (value.publicPhone != null) ...[
          const SizedBox(height: 8),
          _padded(
            OutlinedButton.icon(
              key: const Key('public-org-whatsapp'),
              onPressed: () => unawaited(_contact(context, ref, value)),
              icon: const Icon(Icons.chat_rounded),
              label: Text(l10n.publicOrgContact),
            ),
          ),
        ],
        if (value.description case final text?) ...[
          const SizedBox(height: TikeoSizes.sectionGap - 4),
          _padded(
            SectionHeader(
              title: l10n.publicOrgAbout,
              icon: Icons.info_outline_rounded,
            ),
          ),
          const SizedBox(height: 8),
          _padded(
            TikeoCard(
              key: const Key('public-org-about'),
              child: SelectableText(text, style: theme.textTheme.bodyLarge),
            ),
          ),
        ],
        if ([
          value.facebookUrl,
          value.instagramUrl,
          value.tiktokUrl,
        ].any((url) => url != null)) ...[
          const SizedBox(height: TikeoSizes.cardGap),
          _padded(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (name, url, icon, label) in [
                  (
                    'facebook',
                    value.facebookUrl,
                    Icons.facebook_rounded,
                    'Facebook',
                  ),
                  (
                    'instagram',
                    value.instagramUrl,
                    Icons.photo_camera_rounded,
                    'Instagram',
                  ),
                  (
                    'tiktok',
                    value.tiktokUrl,
                    Icons.music_note_rounded,
                    'TikTok',
                  ),
                ])
                  if (url != null)
                    ActionChip(
                      key: Key('public-org-$name'),
                      avatar: Icon(icon, size: 18),
                      label: Text(label),
                      onPressed: () => unawaited(_openLink(url)),
                    ),
              ],
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
      (AsyncError(:final error), _) => [
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
                          l10n.publicOrgFollowers(organization.followers),
                          key: const Key('public-org-followers'),
                          style: textTheme.bodySmall?.copyWith(
                            color: context.palette.accentText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
