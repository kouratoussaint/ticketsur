import 'package:barcode_widget/barcode_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/tickets/domain/ticket.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ticket tel qu'il est montré et partagé en image : bandeau de marque,
/// événement, QR sur fond blanc (zone de silence comprise), référence.
///
/// Couleurs fixes, indépendantes du thème : l'image partagée doit être
/// identique en mode clair et sombre, et le QR toujours noir sur blanc.
class TicketCard extends StatelessWidget {
  const new({
    required this.event,
    required this.reference,
    required this.categoryName,
    this.token,
    this.status = TicketStatus.issued,
    this.holderName,
    this.invitation = false,
    this.notchColor = TicketSurColors.surfaceLight,
    super.key,
  });

  /// Logo Tikéo pour le bandeau bleu nuit.
  static const AssetImage logo = AssetImage(
    'assets/branding/Tikeo_Logo_Clair_480.png',
  );

  final TicketEvent event;
  final String reference;
  final String categoryName;

  /// Contenu du QR ; `null` : QR masqué (non chargé ou ticket annulé).
  final String? token;
  final TicketStatus status;

  /// Nom du titulaire (ticket nominatif), imprimé sous l'événement.
  final String? holderName;

  /// Présenté comme une invitation : mention et filet orange, texte adapté.
  final bool invitation;

  /// Couleur du cadre derrière le ticket, pour les encoches de la ligne de
  /// découpe (le cadre de la fiche et de l'image partagée est clair).
  final Color notchColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    const ink = TicketSurColors.navy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TicketSurColors.white,
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TicketSurColors.navy, TicketSurColors.navyLight],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(TicketSurSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image(
                          key: const Key('ticket-logo'),
                          image: logo,
                          height: 30,
                          semanticLabel: l10n.appName,
                          errorBuilder: (_, _, _) => Text(
                            l10n.appName,
                            style: textTheme.titleMedium?.copyWith(
                              color: TicketSurColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        DecoratedBox(
                          key: const Key('ticket-category'),
                          decoration: BoxDecoration(
                            color: TicketSurColors.mint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TicketSurSpacing.sm,
                              vertical: TicketSurSpacing.xxs,
                            ),
                            child: Text(
                              categoryName,
                              style: textTheme.labelMedium?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TicketSurSpacing.sm),
                    if (invitation)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: TicketSurSpacing.xxs,
                        ),
                        child: Text(
                          l10n.ticketInvitation.toUpperCase(),
                          key: const Key('ticket-invitation'),
                          style: textTheme.labelLarge?.copyWith(
                            color: TicketSurColors.spark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    Text(
                      event.title,
                      style: textTheme.titleLarge?.copyWith(
                        color: TicketSurColors.white,
                      ),
                    ),
                    const SizedBox(height: TicketSurSpacing.xxs),
                    _HeaderLine(
                      icon: Icons.schedule_rounded,
                      text: formatEventRange(event),
                    ),
                    if (event.venue case final venue?)
                      _HeaderLine(
                        icon: Icons.place_rounded,
                        text: [venue, ?event.city].join(' · '),
                      ),
                    if (holderName case final name?) ...[
                      const SizedBox(height: TicketSurSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: TicketSurColors.mint,
                          ),
                          const SizedBox(width: TicketSurSpacing.xxs),
                          Expanded(
                            child: Text(
                              l10n.ticketCardHolder(name),
                              key: const Key('ticket-holder'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: TicketSurColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (invitation)
              const SizedBox(
                key: Key('ticket-invitation-strip'),
                height: 4,
                child: ColoredBox(color: TicketSurColors.spark),
              ),
            _Perforation(notchColor: notchColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TicketSurSpacing.lg,
                TicketSurSpacing.xs,
                TicketSurSpacing.lg,
                TicketSurSpacing.md,
              ),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: switch ((token, status)) {
                      (_, TicketStatus.revoked) => _QrPlaceholder(
                        icon: Icons.block_rounded,
                        label: l10n.ticketRevokedStamp,
                      ),
                      (final String value, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          BarcodeWidget(
                            key: const Key('ticket-qr'),
                            barcode: Barcode.qrCode(
                              errorCorrectLevel:
                                  BarcodeQRCorrectionLevel.medium,
                            ),
                            data: value,
                            backgroundColor: TicketSurColors.white,
                            // Zone de silence de 4 modules autour du QR.
                            padding: const EdgeInsets.all(TicketSurSpacing.sm),
                          ),
                          if (status == TicketStatus.redeemed)
                            Center(
                              child: _Stamp(label: l10n.ticketRedeemedStamp),
                            ),
                        ],
                      ),
                      _ => _QrPlaceholder(
                        icon: Icons.qr_code_2_rounded,
                        label: l10n.ticketQrHidden,
                      ),
                    },
                  ),
                  const SizedBox(height: TicketSurSpacing.xs),
                  Text(
                    reference,
                    key: const Key('ticket-reference'),
                    style: textTheme.titleMedium?.copyWith(
                      color: ink,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.xs),
                  Text(
                    invitation ? l10n.invitationFooter : l10n.ticketFooter,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF52627A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'information du bandeau : icône menthe, texte blanc.
class _HeaderLine extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: TicketSurSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: TicketSurColors.mint),
        ),
        const SizedBox(width: TicketSurSpacing.xxs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: TicketSurColors.white),
          ),
        ),
      ],
    ),
  );
}

/// Ligne pointillée façon ticket détachable, avec une encoche de chaque côté
/// (demi-disques de la couleur du fond, le reste étant rogné par la carte).
class _Perforation extends StatelessWidget {
  const new({required this.notchColor});

  final Color notchColor;

  @override
  Widget build(BuildContext context) {
    const notch = 24.0;
    Widget hole() => Container(
      width: notch,
      height: notch,
      decoration: BoxDecoration(color: notchColor, shape: BoxShape.circle),
    );
    return SizedBox(
      height: notch,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _PerforationPainter())),
          Positioned(left: -notch / 2, top: 0, child: hole()),
          Positioned(right: -notch / 2, top: 0, child: hole()),
        ],
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (double x = 16; x < size.width - 16; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrPlaceholder extends StatelessWidget {
  const new({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(TicketSurRadii.md),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: const Color(0xFF52627A)),
              const SizedBox(height: TicketSurSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: TicketSurColors.navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.25,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEEFFFFFF),
          border: Border.all(color: const Color(0xFFB02A37), width: 3),
          borderRadius: BorderRadius.circular(TicketSurRadii.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TicketSurSpacing.md,
            vertical: TicketSurSpacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFB02A37),
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
