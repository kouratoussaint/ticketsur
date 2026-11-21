import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/design_system/widgets/offscreen_png.dart';
import 'package:ticketsur/design_system/widgets/tikeo_logo.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/catalog/presentation/explore_page.dart'
    show eventKindTag;
import 'package:ticketsur/features/catalog/presentation/featured_card.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/photo_viewer.dart';
import 'package:ticketsur/features/team/application/team_providers.dart'
    show shareTextProvider;
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Format de l'image de partage (#18).
enum ShareFormat {
  /// Statut WhatsApp, story : 1080 × 1920.
  story(Size(1080, 1920)),

  /// Publication : 1080 × 1350.
  post(Size(1080, 1350));

  new(this.size);

  final Size size;
}

/// Rend l'image de partage d'un événement (remplacé en test).
final eventImageRendererProvider =
    Provider<
      Future<Uint8List> Function(
        BuildContext context,
        PublicEventDetail detail,
        ShareFormat format,
      )
    >(
      (ref) =>
          (context, detail, format) => renderWidgetPng(
            context,
            child: EventShareImage(detail: detail, format: format),
            size: format.size,
            images: [
              // Logos (en-tête et bandeau), décodés avant l'unique image.
              const AssetImage('assets/branding/Tikeo_Logo_Clair.png'),
              const AssetImage('assets/branding/Tikeo_Logo.png'),
              if (detail.summary.coverUrl case final url?) networkImage(url),
              if (detail.organizationLogoUrl case final url?) networkImage(url),
            ],
          ),
    );

/// Texte joint à l'image : titre, date, lieu, prix, appel à Tikéo.
String eventShareText(AppLocalizations l10n, PublicEventDetail detail) {
  final event = detail.summary;
  return [
    l10n.publicEventShareText(
      event.title,
      summaryWhen(event),
      summaryPlace(event),
    ),
    ?summaryPrice(l10n, event),
    l10n.shareImageCta,
  ].join('\n');
}

/// Image de partage d'un événement, à sa taille réelle (1080 de large) :
/// fond Nuit, photo entière, type et prix, titre, date, lieu, structure,
/// bandeau « Obtenez votre ticket sur l'application Tikéo ». Pas de QR : ce
/// n'est pas un ticket.
class EventShareImage extends StatelessWidget {
  const new({required this.detail, required this.format, super.key});

  final PublicEventDetail detail;
  final ShareFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final event = detail.summary;
    final story = format == ShareFormat.story;
    final price = summaryPrice(l10n, event);
    final place = summaryPlace(event);
    const white = TicketSurColors.white;
    TextStyle text(double size, {FontWeight weight = FontWeight.w600}) =>
        TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          fontWeight: weight,
          // Police variable : la graisse passe par l'axe « wght ».
          fontVariations: [FontVariation.weight(weight.value.toDouble())],
          color: white,
          height: 1.25,
        );
    Widget pill(String label, Color background, Color ink) => DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Text(
          label,
          style: text(30, weight: FontWeight.w800).copyWith(color: ink),
        ),
      ),
    );
    Widget info(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Icon(icon, size: 44, color: TicketSurColors.mint),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text(38),
            ),
          ),
        ],
      ),
    );
    // Material transparent : style de texte correct, même rendu hors écran
    // (couche de l'Overlay, hors de tout Scaffold).
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        key: const Key('event-share-image'),
        decoration: const BoxDecoration(gradient: TikeoColors.heroGradient),
        child: Padding(
          padding: EdgeInsets.fromLTRB(64, story ? 120 : 64, 64, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (detail.organizationLogoUrl case final url?) ...[
                    ClipOval(
                      child: Image(
                        image: networkImage(url),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.square(dimension: 72),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                  Expanded(
                    child: Text(
                      event.organizationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text(34, weight: FontWeight.w700),
                    ),
                  ),
                  const TikeoLogo(height: 64, onDark: true),
                ],
              ),
              const SizedBox(height: 40),
              // La photo prend la place laissée par le texte : rien ne
              // déborde, même avec un titre long.
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: WholePhoto(url: event.coverUrl, kind: event.kind),
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  pill(
                    eventKindTag(l10n, event.kind),
                    eventKindColor(event.kind),
                    white,
                  ),
                  if (price != null)
                    pill(price, TicketSurColors.mint, TicketSurColors.navy),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                event.title,
                maxLines: story ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TikeoTextStyles.heroCardTitle.copyWith(
                  fontSize: story ? 76 : 64,
                  color: white,
                  height: 1.1,
                ),
              ),
              info(Icons.event_rounded, summaryWhen(event)),
              if (place.isNotEmpty) info(Icons.place_rounded, place),
              const SizedBox(height: 48),
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
                          l10n.shareImageBanner,
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

/// Feuille « Partager l'événement » : format, aperçu, Enregistrer, Partager.
Future<void> showEventShareSheet(
  BuildContext context,
  PublicEventDetail detail,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => EventShareSheet(detail: detail),
);

class EventShareSheet extends ConsumerStatefulWidget {
  const new({required this.detail, super.key});

  final PublicEventDetail detail;

  @override
  ConsumerState<EventShareSheet> createState() => _EventShareSheetState();
}

class _EventShareSheetState extends ConsumerState<EventShareSheet> {
  ShareFormat _format = ShareFormat.story;
  bool _busy = false;

  Future<void> _run(Future<void> Function(Uint8List bytes) action) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(eventImageRendererProvider)(
        context,
        widget.detail,
        _format,
      );
      await action(bytes);
    } on Object {
      toast.error(l10n.shareImageFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _name =>
      '${imageFileName(widget.detail.summary.title)}-${_format.name}';

  Future<void> _save() {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final save = ref.read(gallerySaverProvider);
    return _run((bytes) async {
      await save(bytes, _name);
      toast.success(l10n.photoSaved);
    });
  }

  Future<void> _share() {
    final l10n = context.l10n;
    final share = ref.read(shareFilesProvider);
    return _run(
      (bytes) => share([
        (bytes: bytes, name: '$_name.png', mimeType: 'image/png'),
      ], text: eventShareText(l10n, widget.detail)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final size = _format.size;
    final previewHeight = MediaQuery.sizeOf(context).height * 0.45;
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('event-share-sheet'),
        padding: const EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          0,
          TikeoSizes.screenMargin,
          TikeoSizes.screenMargin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.shareImageTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<ShareFormat>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ShareFormat.story,
                  icon: const Icon(Icons.stay_current_portrait_rounded),
                  label: Text(
                    l10n.shareImageStory,
                    key: const Key('event-share-story'),
                  ),
                ),
                ButtonSegment(
                  value: ShareFormat.post,
                  icon: const Icon(Icons.crop_portrait_rounded),
                  label: Text(
                    l10n.shareImagePost,
                    key: const Key('event-share-post'),
                  ),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (value) =>
                  setState(() => _format = value.single),
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                height: previewHeight,
                child: AspectRatio(
                  aspectRatio: size.width / size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FittedBox(
                      child: SizedBox.fromSize(
                        size: size,
                        child: MediaQuery(
                          data: const MediaQueryData(),
                          child: EventShareImage(
                            key: const Key('event-share-preview'),
                            detail: widget.detail,
                            format: _format,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            TikeoPrimaryButton(
              key: const Key('event-share-send'),
              busy: _busy,
              onPressed: _busy ? null : () => unawaited(_share()),
              icon: Icons.share_rounded,
              label: l10n.shareImageShare,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('event-share-save'),
              onPressed: _busy ? null : () => unawaited(_save()),
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.shareImageSave),
            ),
            TextButton.icon(
              key: const Key('event-share-text'),
              onPressed: _busy
                  ? null
                  : () => unawaited(
                      ref.read(shareTextProvider)(
                        eventShareText(l10n, widget.detail),
                      ),
                    ),
              icon: const Icon(Icons.short_text_rounded),
              label: Text(l10n.shareImageTextOnly),
            ),
          ],
        ),
      ),
    );
  }
}
