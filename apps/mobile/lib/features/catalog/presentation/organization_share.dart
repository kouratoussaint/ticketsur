import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/offscreen_png.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/event_share.dart';
import 'package:ticketsur/features/events/presentation/photo_viewer.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Rend l'image de partage d'une structure (remplacé en test).
final organizationImageRendererProvider =
    Provider<
      Future<Uint8List> Function(
        BuildContext context,
        PublicOrganization organization,
        ShareFormat format,
      )
    >(
      (ref) =>
          (context, organization, format) => renderWidgetPng(
            context,
            child: OrganizationShareImage(
              organization: organization,
              format: format,
            ),
            size: format.size,
            images: [
              const AssetImage('assets/branding/Tikeo_Logo_Clair.png'),
              const AssetImage('assets/branding/Tikeo_Logo.png'),
              if (organization.logoUrl case final url?) networkImage(url),
            ],
          ),
    );

/// Texte joint : la structure, ses prochains événements (3 au plus), Tikéo.
String organizationShareText(
  AppLocalizations l10n,
  PublicOrganization organization,
) => [
  l10n.publicOrgShareText([organization.name, ?organization.city].join(' · ')),
  l10n.publicOrgShareUpcoming(organization.events.length),
  for (final event in organization.events.take(3))
    '• ${event.title} — ${summaryWhen(event)}',
].join('\n');

/// Feuille « Partager la structure ».
Future<void> showOrganizationShareSheet(
  BuildContext context,
  PublicOrganization organization,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final l10n = context.l10n;
      return ShareImageSheet(
        keyPrefix: 'org-share',
        title: l10n.publicOrgShare,
        fileBase: imageFileName(organization.name),
        text: organizationShareText(l10n, organization),
        preview: (format) => OrganizationShareImage(
          key: const Key('org-share-preview'),
          organization: organization,
          format: format,
        ),
        render: (context, format) => ref.read(
          organizationImageRendererProvider,
        )(context, organization, format),
      );
    },
  ),
);

/// Image de partage d'une structure, à sa taille réelle (1080 de large) :
/// fond Nuit, logo, nom, ville, prochains événements, bandeau Tikéo.
class OrganizationShareImage extends StatelessWidget {
  const new({required this.organization, required this.format, super.key});

  final PublicOrganization organization;
  final ShareFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final story = format == ShareFormat.story;
    const white = TicketSurColors.white;
    TextStyle text(double size, {FontWeight weight = FontWeight.w600}) =>
        TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          fontWeight: weight,
          fontVariations: [FontVariation.weight(weight.value.toDouble())],
          color: white,
          height: 1.25,
        );
    final initials = organization.name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final logoSize = story ? 260.0 : 200.0;
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        key: const Key('org-share-image'),
        decoration: const BoxDecoration(gradient: TikeoColors.heroGradient),
        child: Padding(
          padding: EdgeInsets.fromLTRB(64, story ? 120 : 64, 64, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: TikeoLogo(height: 64, onDark: true),
              ),
              SizedBox(height: story ? 80 : 32),
              Center(
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: logoSize,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TicketSurColors.mintDeep,
                            TicketSurColors.navy,
                          ],
                        ),
                      ),
                      child: switch (organization.logoUrl) {
                        final url? => Image(
                          image: networkImage(url),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const SizedBox.shrink(),
                        ),
                        null => Center(
                          child: Text(
                            initials,
                            style: text(
                              logoSize * 0.36,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                organization.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TikeoTextStyles.heroCardTitle.copyWith(
                  fontSize: story ? 80 : 68,
                  color: white,
                  height: 1.1,
                ),
              ),
              if (organization.city case final city?) ...[
                const SizedBox(height: 12),
                Text(city, textAlign: TextAlign.center, style: text(40)),
              ],
              const SizedBox(height: 48),
              Text(
                l10n.publicOrgShareUpcoming(organization.events.length),
                style: text(
                  38,
                  weight: FontWeight.w800,
                ).copyWith(color: TicketSurColors.mint),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final event in organization.events.take(story ? 3 : 2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text(42, weight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  summaryWhen(event),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text(32),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: TikeoColors.mintGradient,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.publicOrgShareBanner,
                          style: text(
                            36,
                            weight: FontWeight.w800,
                          ).copyWith(color: TicketSurColors.navy),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const TikeoLogo(height: 56, onDark: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
