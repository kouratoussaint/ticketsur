import 'package:barcode_widget/barcode_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/widgets/cached_network_image.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_theme.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Logo Tikéo du talon (réduit au décodage : il est dessiné en 70 × 28).
const ImageProvider ticketStubLogo = ResizeImage(
  AssetImage('assets/branding/Tikeo_Logo.png'),
  width: 280,
);

/// Orange des invitations.
const _spark = Color(0xFFFF6B3D);
const _white = Color(0xFFFFFFFF);

/// Ticket dessiné avec le modèle de sa catégorie (ADR 0022) : format
/// horizontal, mis à l'échelle de la place disponible.
///
/// [background] : le fond seul, sans QR, numéro, référence ni titulaire
/// (fond partagé par tous les tickets d'une catégorie dans le PDF).
class TicketArtwork extends StatelessWidget {
  const new({
    required this.art,
    required this.template,
    required this.categoryName,
    this.number,
    this.reference,
    this.token,
    this.holderName,
    this.invitation = false,
    this.background = false,
    super.key,
  });

  final TicketArt art;
  final TicketTemplate template;
  final String categoryName;

  /// Numéro d'ordre dans l'événement (« N° 000123 »).
  final int? number;
  final String? reference;

  /// Contenu du QR (`TS1.…`) ; `null` : emplacement vide.
  final String? token;
  final String? holderName;
  final bool invitation;
  final bool background;

  /// Images à charger avant un rendu hors écran.
  static List<ImageProvider> imagesOf(TicketArt art, TicketTemplate template) =>
      [
        if (template is BuiltinTemplate) ...[
          ticketStubLogo,
          if (art.event.coverUrl case final url?) networkImage(url),
          if (art.organizationLogoUrl case final url?) networkImage(url),
        ],
        if (template case CustomTemplate(:final localBytes?))
          MemoryImage(localBytes)
        else if (template case CustomTemplate(:final imageUrl?))
          networkImage(imageUrl),
      ];

  @override
  Widget build(BuildContext context) {
    final geometry = TicketGeometry.of(template);
    final ticket = SizedBox.fromSize(
      size: geometry.size,
      child: switch (template) {
        final BuiltinTemplate builtin => _BuiltinTicket(
          widget: this,
          template: builtin,
        ),
        final CustomTemplate custom => _CustomTicket(
          widget: this,
          template: custom,
          geometry: geometry,
        ),
      },
    );
    return Semantics(
      label: [
        art.event.title,
        categoryName,
        ?holderName,
        ?reference,
      ].join(', '),
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: geometry.size.aspectRatio,
          child: FittedBox(
            child: MediaQuery.withNoTextScaling(
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: 'Inter', color: _white),
                child: ticket,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// QR noir sur blanc, marge de 4 modules comprise, dans un carré de [side].
class _Qr extends StatelessWidget {
  const new({required this.token, required this.side});

  final String token;
  final double side;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: side,
    child: BarcodeWidget(
      key: const Key('artwork-qr'),
      barcode: Barcode.qrCode(
        errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
      ),
      data: token,
      backgroundColor: _white,
      padding: EdgeInsets.all(TicketGeometry.quietZone(side)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Thèmes intégrés
// ---------------------------------------------------------------------------

class _BuiltinTicket extends StatelessWidget {
  const new({required this.widget, required this.template});

  final TicketArtwork widget;
  final BuiltinTemplate template;

  @override
  Widget build(BuildContext context) {
    final theme = template.theme;
    const mainWidth = TicketGeometry.stubLeft - TicketGeometry.accentBarWidth;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: mainWidth,
            height: TicketGeometry.builtinHeight,
            child: _MainPart(widget: widget, template: template),
          ),
          Positioned(
            left: mainWidth,
            top: 0,
            width: TicketGeometry.accentBarWidth,
            height: TicketGeometry.builtinHeight,
            child: ColoredBox(color: theme.accent),
          ),
          Positioned(
            left: TicketGeometry.stubLeft,
            top: 0,
            width: TicketGeometry.stubWidth,
            height: TicketGeometry.builtinHeight,
            child: _Stub(widget: widget, theme: theme),
          ),
        ],
      ),
    );
  }
}

class _MainPart extends StatelessWidget {
  const new({required this.widget, required this.template});

  final TicketArtwork widget;
  final BuiltinTemplate template;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = template.theme;
    final art = widget.art;
    final event = art.event;
    final dark = theme.dark;
    final start = wallTimeIn(event.timezone, event.startsAt);
    final end = wallTimeIn(event.timezone, event.endsAt);
    final place = [?event.venue, ?event.city].join(', ');
    const contentWidth = 725.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: dark),
        if (event.coverUrl case final url?)
          Image(
            image: networkImage(url),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                dark.withValues(alpha: 0.96),
                dark.withValues(alpha: 0.86),
                dark.withValues(alpha: 0.35),
                dark.withValues(alpha: 0.05),
              ],
              stops: const [0, 0.38, 0.68, 1],
            ),
          ),
        ),
        Positioned(
          left: 40,
          top: 28,
          width: contentWidth,
          height: 40,
          child: Row(
            children: [
              _OrganizationMark(
                name: art.organizationName,
                logoUrl: art.organizationLogoUrl,
                accent: theme.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  art.organizationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 40,
          top: 92,
          width: contentWidth,
          child: Text(
            (widget.invitation
                    ? l10n.ticketInvitation
                    : eventKindLabel(l10n, event.kind))
                .toUpperCase(),
            key: widget.invitation ? const Key('artwork-invitation') : null,
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 3,
              color: widget.invitation ? _spark : theme.accent,
            ),
          ),
        ),
        Positioned(
          left: 40,
          top: 112,
          width: 700,
          height: 148,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TicketTitle(
              title: event.title,
              theme: theme,
              singleFont: template.singleFontTitle,
            ),
          ),
        ),
        if (event.tagline case final tagline?)
          Positioned(
            left: 40,
            top: 266,
            width: 700,
            child: Text(
              tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: _white.withValues(alpha: 0.88),
              ),
            ),
          ),
        if (!widget.background && widget.holderName != null)
          Positioned.fromRect(
            rect: TicketGeometry.holder,
            child: Text(
              l10n.ticketCardHolder(widget.holderName!),
              key: const Key('artwork-holder'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        Positioned(
          left: 40,
          top: 352,
          width: contentWidth,
          height: 1.5,
          child: ColoredBox(color: _white.withValues(alpha: 0.22)),
        ),
        Positioned(
          left: 40,
          top: 372,
          width: contentWidth,
          height: 44,
          child: Row(
            children: [
              _Info(
                icon: Icons.calendar_today_rounded,
                text: formatEventDay(start),
                accent: theme.accent,
              ),
              const SizedBox(width: 28),
              _Info(
                icon: Icons.schedule_rounded,
                text: '${formatEventTime(start)} – ${formatEventTime(end)}',
                accent: theme.accent,
              ),
              if (place.isNotEmpty) ...[
                const SizedBox(width: 28),
                Expanded(
                  child: _Info(
                    icon: Icons.place_rounded,
                    text: place,
                    accent: theme.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const new({required this.icon, required this.text, required this.accent});

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: accent),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

/// Logo de la structure dans un rond, ou ses initiales sur l'accent.
class _OrganizationMark extends StatelessWidget {
  const new({required this.name, required this.logoUrl, required this.accent});

  final String name;
  final String? logoUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    final fallback = ColoredBox(
      color: accent,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Color(0xFF111111),
          ),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: 40,
        child: switch (logoUrl) {
          null => fallback,
          final url => ColoredBox(
            color: _white,
            child: Image(
              image: networkImage(url),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          ),
        },
      ),
    );
  }
}

/// Talon blanc : « Scannez ici », QR, numéro, référence, catégorie, logo.
class _Stub extends StatelessWidget {
  const new({required this.widget, required this.theme});

  final TicketArtwork widget;
  final TicketTheme theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const width = TicketGeometry.stubWidth;
    final qr = TicketGeometry.of(const BuiltinTemplate(1)).qr;
    const frame = 208.0;
    final frameLeft = qr.left - TicketGeometry.stubLeft - 4;
    final frameTop = qr.top - 4;
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: _white)),
        Positioned.fill(child: CustomPaint(painter: _DashedEdgePainter())),
        Positioned(
          left: 0,
          top: 18,
          width: width,
          child: Column(
            children: [
              Text(
                l10n.ticketScanHere,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: theme.ink,
                ),
              ),
              Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 26,
                color: theme.ink,
              ),
            ],
          ),
        ),
        Positioned(
          left: frameLeft,
          top: frameTop,
          width: frame,
          height: frame,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _white,
              border: Border.all(color: theme.frame, width: 4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (!widget.background && widget.token != null)
          Positioned(
            left: qr.left - TicketGeometry.stubLeft,
            top: qr.top,
            child: _Qr(token: widget.token!, side: qr.width),
          ),
        if (!widget.background && widget.number != null)
          Positioned(
            left: 0,
            top: TicketGeometry.numberTop,
            width: width,
            child: Text(
              l10n.ticketNumber(formatTicketNumber(widget.number!)),
              key: const Key('artwork-number'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF111827),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        if (!widget.background && widget.reference != null)
          Positioned(
            left: 0,
            top: TicketGeometry.referenceTop,
            width: width,
            child: Text(
              widget.reference!,
              key: const Key('artwork-reference'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        Positioned(
          left: 20,
          top: 342,
          width: width - 40,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.chip,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Text(
                  widget.categoryName.toUpperCase(),
                  key: const Key('artwork-category'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: theme.chipText,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          left: (width - 70) / 2,
          top: 398,
          width: 70,
          height: 28,
          child: Image(image: ticketStubLogo, fit: BoxFit.contain),
        ),
      ],
    );
  }
}

/// Bordure gauche du talon, en pointillés gris clair.
class _DashedEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 2;
    for (double y = 6; y < size.height - 6; y += 12) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Titre de l'événement écrit selon le style du thème.
class TicketTitle extends StatelessWidget {
  const new({
    required this.title,
    required this.theme,
    this.singleFont = false,
    super.key,
  });

  final String title;
  final TicketTheme theme;
  final bool singleFont;

  /// Taille de base selon la longueur du titre.
  static double baseSize(String title) => switch (title.characters.length) {
    <= 12 => 56,
    <= 20 => 48,
    <= 30 => 40,
    <= 44 => 34,
    _ => 28,
  };

  static const _smallWords = {
    'du', 'de', 'des', 'la', 'le', 'les', 'et', 'au', 'aux', 'en', 'à', //
    "d'", 'of', 'the', 'and',
  };

  @override
  Widget build(BuildContext context) {
    final size = baseSize(title);
    final accent = theme.accent;
    final style = theme.titleStyle;
    final colored =
        style == TitleStyle.scriptAccent || style == TitleStyle.boldAccent;
    final baseColor = colored ? accent : _white;
    TextStyle bold([Color? color]) => TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w800,
      fontSize: size,
      height: 1.05,
      color: color ?? baseColor,
    );
    TextStyle script([Color? color]) => singleFont
        ? bold(color)
        : TextStyle(
            fontFamily: 'Yellowtail',
            fontSize: size * 1.25,
            height: 1,
            color: color ?? baseColor,
          );
    TextStyle condensed([Color? color]) => singleFont
        ? bold(color)
        : TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: size * 1.3,
            height: 1,
            letterSpacing: 1,
            color: color ?? baseColor,
          );
    final words = title.trim().split(RegExp(r'\s+'));
    String rest(int from, {bool caps = false}) {
      final text = words.skip(from).join(' ');
      return caps ? text.toUpperCase() : text;
    }

    final spans = switch (style) {
      TitleStyle.firstWordScriptCaps when words.length > 1 => [
        TextSpan(text: '${words.first} ', style: script()),
        TextSpan(text: rest(1, caps: true), style: bold()),
      ],
      TitleStyle.firstWordScript when words.length > 1 => [
        TextSpan(text: '${words.first} ', style: script()),
        TextSpan(text: rest(1), style: bold()),
      ],
      TitleStyle.firstWordScriptCaps ||
      TitleStyle.firstWordScript ||
      TitleStyle.script ||
      TitleStyle.scriptAccent => [TextSpan(text: title, style: script())],
      TitleStyle.capsAccentFirstLine when words.length > 1 => [
        TextSpan(text: '${words.first.toUpperCase()} ', style: bold(accent)),
        TextSpan(text: rest(1, caps: true), style: bold()),
      ],
      TitleStyle.capsAccentFirstLine ||
      TitleStyle.caps => [TextSpan(text: title.toUpperCase(), style: bold())],
      TitleStyle.condensedVersus => _versus(condensed),
      TitleStyle.boldScriptSmallWords => [
        for (final (i, word) in words.indexed)
          TextSpan(
            text: i == words.length - 1 ? word : '$word ',
            style: _smallWords.contains(word.toLowerCase()) ? script() : bold(),
          ),
      ],
      TitleStyle.boldAccentLastWord when words.length > 1 => [
        TextSpan(
          text: '${words.take(words.length - 1).join(' ')} ',
          style: bold(),
        ),
        TextSpan(text: words.last, style: bold(accent)),
      ],
      TitleStyle.boldAccentLastWord ||
      TitleStyle.bold ||
      TitleStyle.boldAccent => [TextSpan(text: title, style: bold())],
    };
    return Text.rich(
      TextSpan(children: spans),
      key: const Key('artwork-title'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// « Équipe A vs Équipe B » : losange VS entre les deux équipes.
  List<InlineSpan> _versus(TextStyle Function([Color?]) condensed) {
    final parts = title.split(
      RegExp(r'\s+(?:vs\.?|contre)\s+', caseSensitive: false),
    );
    if (parts.length != 2 || singleFont) {
      return [TextSpan(text: title.toUpperCase(), style: condensed())];
    }
    final size = baseSize(title);
    return [
      TextSpan(text: parts.first.toUpperCase(), style: condensed()),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.3),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              key: const Key('artwork-versus'),
              width: size * 0.8,
              height: size * 0.8,
              color: theme.accent,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: -0.785398,
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: size * 0.45,
                    color: const Color(0xFF0B1A10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      TextSpan(text: parts.last.toUpperCase(), style: condensed()),
    ];
  }
}

// ---------------------------------------------------------------------------
// Design importé
// ---------------------------------------------------------------------------

class _CustomTicket extends StatelessWidget {
  const new({
    required this.widget,
    required this.template,
    required this.geometry,
  });

  final TicketArtwork widget;
  final CustomTemplate template;
  final TicketGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final image = switch (template) {
      CustomTemplate(:final localBytes?) => MemoryImage(localBytes),
      CustomTemplate(:final imageUrl?) => networkImage(imageUrl),
      _ => null,
    };
    final placement = template.placement;
    final size = geometry.size;
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFE5E7EB))),
        if (image != null)
          Positioned.fill(
            child: Image(
              image: image,
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        if (!widget.background)
          Positioned.fromRect(
            rect: geometry.qr,
            child: widget.token == null
                ? const ColoredBox(color: _white)
                : _Qr(token: widget.token!, side: geometry.qr.width),
          ),
        if (!widget.background &&
            (widget.number != null || widget.reference != null))
          Positioned(
            left:
                placement.refX * size.width -
                TicketGeometry.customBlockWidth / 2,
            top: placement.refY * size.height,
            width: TicketGeometry.customBlockWidth,
            child: Center(child: CustomReferenceBlock(widget: widget)),
          ),
      ],
    );
  }
}

/// Numéro, référence et titulaire sur un design importé : bloc blanc,
/// lisible sur n'importe quel fond.
class CustomReferenceBlock extends StatelessWidget {
  const new({required this.widget, super.key});

  final TicketArtwork widget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.number case final number?)
              Text(
                l10n.ticketNumber(formatTicketNumber(number)),
                key: const Key('artwork-number'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Color(0xFF111827),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            if (widget.reference case final reference?)
              Text(
                reference,
                key: const Key('artwork-reference'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 1,
                  color: Color(0xFF4B5563),
                ),
              ),
            if (widget.holderName case final name?)
              Text(
                name,
                key: const Key('artwork-holder'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
