import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';

/// Illustrations de marque (direction artistique, section 6) : style plat
/// avec un léger relief, menthe, bleu, blanc, Nuit pour les détails,
/// étincelles jaunes ; légèrement inclinées, sans contour noir.
///
/// Dessinées en code (vectorielles, nettes à toute taille, aucune image à
/// télécharger). Décoratives : ignorées par les lecteurs d'écran.
enum TikeoIllustration {
  // En-têtes (120 × 96).
  /// Tickets : ticket blanc incliné avec QR, trois étincelles.
  tickets,

  /// Équipe : trois personnages menthe.
  team,

  /// Organiser, mes événements : calendrier avec une étoile.
  calendar,

  /// Scanner : téléphone avec viseur et ticket.
  scanner,

  /// Statistiques et rapports : barres et flèche montante.
  stats,

  /// Mes tickets : portefeuille avec deux tickets.
  wallet,

  /// Support : deux bulles de discussion.
  support,

  /// Paramètres : engrenage et interrupteur.
  settings,

  /// Console : bouclier avec une coche.
  console,

  // Connexion et compte.
  /// Connexion : cadenas.
  lock,

  /// Confirmation de l'adresse e-mail : enveloppe.
  mail,

  // États vides et succès (160 × 120).
  /// Aucun événement.
  noEvents,

  /// Aucun ticket.
  noTickets,

  /// Aucune recherche trouvée.
  noResults,

  /// Pas de réseau.
  offline,

  /// Premier événement créé.
  firstEvent,

  /// Premier ticket émis.
  firstTicket,
}

/// Une illustration à sa taille d'affichage (dessinée sur 160 × 120, mise
/// à l'échelle sans déformation).
class TikeoIllustrationView extends StatelessWidget {
  const new(this.kind, {this.width = 160, this.height = 120, super.key});

  /// Taille d'en-tête : 120 × 96.
  const new header(this.kind, {super.key}) : width = 120, height = 96;

  final TikeoIllustration kind;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: TikeoIllustrationPainter(kind)),
    ),
  );
}

/// Peintre des illustrations.
class TikeoIllustrationPainter extends CustomPainter {
  const new(this.kind);

  final TikeoIllustration kind;

  static const double _w = 160;
  static const double _h = 120;

  // Palette des illustrations.
  static const Color _mint = TicketSurColors.mint;
  static const Color _mintBright = TikeoColors.mintBright;
  static const Color _mintPale = Color(0xFFBFF3E6);
  static const Color _blue = Color(0xFF2F6FED);
  static const Color _bluePale = Color(0xFFBCD3FB);
  static const Color _navy = TicketSurColors.navy;
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _gold = TikeoColors.sparkle;
  static const Color _red = Color(0xFFE5484D);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _w, size.height / _h);
    canvas
      ..save()
      ..translate((size.width - _w * scale) / 2, (size.height - _h * scale) / 2)
      ..scale(scale);
    switch (kind) {
      case TikeoIllustration.tickets:
        _ticket(canvas, const Offset(80, 60), -0.14, qr: true);
        _sparkles(canvas, const [
          Offset(30, 28),
          Offset(132, 22),
          Offset(138, 92),
        ]);
      case TikeoIllustration.team:
        _team(canvas);
      case TikeoIllustration.calendar:
        _calendar(canvas, const Offset(80, 62), -0.1, mark: _CalendarMark.star);
        _sparkles(canvas, const [Offset(28, 30), Offset(134, 26)]);
      case TikeoIllustration.scanner:
        _phone(canvas);
      case TikeoIllustration.stats:
        _stats(canvas);
      case TikeoIllustration.wallet:
        _wallet(canvas);
      case TikeoIllustration.support:
        _bubbles(canvas);
      case TikeoIllustration.settings:
        _settings(canvas);
      case TikeoIllustration.console:
        _shield(canvas);
      case TikeoIllustration.lock:
        _lock(canvas);
      case TikeoIllustration.mail:
        _mail(canvas);
      case TikeoIllustration.noEvents:
        _halo(canvas, _bluePale);
        _calendar(
          canvas,
          const Offset(80, 62),
          -0.08,
          mark: _CalendarMark.empty,
        );
        _sparkles(canvas, const [Offset(124, 24)], faded: true);
      case TikeoIllustration.noTickets:
        _halo(canvas, _mintPale);
        _ticket(canvas, const Offset(80, 60), -0.12, dashed: true);
        _sparkles(canvas, const [Offset(132, 24)], faded: true);
      case TikeoIllustration.noResults:
        _halo(canvas, _bluePale);
        _ticket(canvas, const Offset(70, 58), -0.12, scaleBy: 0.8);
        _magnifier(canvas, const Offset(104, 70));
      case TikeoIllustration.offline:
        _halo(canvas, _bluePale);
        _cloud(canvas);
      case TikeoIllustration.firstEvent:
        _confetti(canvas);
        _calendar(
          canvas,
          const Offset(80, 62),
          -0.08,
          mark: _CalendarMark.check,
        );
        _sparkles(canvas, const [
          Offset(26, 26),
          Offset(136, 24),
          Offset(140, 96),
        ]);
      case TikeoIllustration.firstTicket:
        _confetti(canvas);
        _ticket(canvas, const Offset(80, 60), -0.14, qr: true);
        _badge(canvas, const Offset(118, 36), _mint, Icons.check_rounded);
        _sparkles(canvas, const [Offset(26, 30), Offset(140, 96)]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TikeoIllustrationPainter oldDelegate) =>
      oldDelegate.kind != kind;

  // Outils

  static Paint _fill(Color color) => Paint()..color = color;

  static Paint _gradient(Rect rect, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);

  /// Ombre portée floue sous une forme.
  static void _shadow(Canvas canvas, RRect shape, {double dy = 6}) {
    canvas.drawRRect(
      shape.shift(Offset(0, dy)),
      Paint()
        ..color = _navy.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  /// Fait pivoter [draw] de [angle] autour de [center].
  static void _rotated(
    Canvas canvas,
    Offset center,
    double angle,
    void Function() draw,
  ) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle)
      ..translate(-center.dx, -center.dy);
    draw();
    canvas.restore();
  }

  static void _halo(Canvas canvas, Color color) {
    canvas.drawCircle(
      const Offset(80, 62),
      50,
      _fill(color.withValues(alpha: 0.45)),
    );
  }

  /// Étoile à quatre branches.
  static void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, _fill(color));
  }

  static void _sparkles(
    Canvas canvas,
    List<Offset> points, {
    bool faded = false,
  }) {
    for (final (i, p) in points.indexed) {
      _sparkle(
        canvas,
        p,
        i.isEven ? 8 : 6,
        faded ? _gold.withValues(alpha: 0.55) : _gold,
      );
    }
  }

  static void _confetti(Canvas canvas) {
    const pieces = [
      (Offset(22, 52), _mint, 0.4),
      (Offset(40, 18), _blue, -0.6),
      (Offset(118, 14), _gold, 0.3),
      (Offset(146, 58), _mint, -0.3),
      (Offset(30, 98), _blue, 0.8),
      (Offset(122, 106), _gold, -0.5),
    ];
    for (final (p, color, angle) in pieces) {
      _rotated(canvas, p, angle, () {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 10, height: 4),
            const Radius.circular(2),
          ),
          _fill(color),
        );
      });
    }
  }

  static void _badge(Canvas canvas, Offset c, Color color, IconData icon) {
    canvas
      ..drawCircle(
        c + const Offset(0, 3),
        14,
        Paint()
          ..color = _navy.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(c, 14, _fill(color));
    _icon(canvas, icon, c, 20, _navy);
  }

  static void _icon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  // Ticket

  static void _ticket(
    Canvas canvas,
    Offset c,
    double angle, {
    bool qr = false,
    bool dashed = false,
    double scaleBy = 1,
  }) {
    final rect = Rect.fromCenter(
      center: c,
      width: 104 * scaleBy,
      height: 58 * scaleBy,
    );
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(10 * scaleBy));
    _rotated(canvas, c, angle, () {
      // Encoches de découpe.
      final notch = 7 * scaleBy;
      final stub = rect.left + rect.width * 0.68;
      final path = Path()
        ..addRRect(shape)
        ..addOval(
          Rect.fromCircle(center: Offset(stub, rect.top), radius: notch),
        )
        ..addOval(
          Rect.fromCircle(center: Offset(stub, rect.bottom), radius: notch),
        )
        ..fillType = PathFillType.evenOdd;
      if (dashed) {
        _dashedRRect(canvas, shape, _mint);
        return;
      }
      // Ombre, corps blanc, puis bord menthe à gauche.
      canvas
        ..drawPath(
          path.shift(const Offset(0, 6)),
          Paint()
            ..color = _navy.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawPath(path, _fill(_white))
        ..drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(rect.left, rect.top, 8 * scaleBy, rect.height),
            topLeft: Radius.circular(10 * scaleBy),
            bottomLeft: Radius.circular(10 * scaleBy),
          ),
          _gradient(rect, const [_mintBright, _mint]),
        );
      // Traits bleus (texte du ticket).
      final lines = _fill(_bluePale);
      for (final (i, w) in const [34.0, 26.0, 30.0].indexed) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + 16 * scaleBy,
              rect.top + (12 + i * 12) * scaleBy,
              w * scaleBy,
              5 * scaleBy,
            ),
            const Radius.circular(3),
          ),
          i == 0 ? _fill(_blue) : lines,
        );
      }
      // Pointillés de découpe.
      final dash = Paint()
        ..color = _bluePale
        ..strokeWidth = 1.5;
      for (var y = rect.top + notch + 3; y < rect.bottom - notch - 3; y += 6) {
        canvas.drawLine(Offset(stub, y), Offset(stub, y + 3), dash);
      }
      if (qr) _qr(canvas, Offset(stub + rect.width * 0.16, c.dy), 20 * scaleBy);
    });
  }

  static void _dashedRRect(Canvas canvas, RRect shape, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()..addRRect(shape);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  /// QR stylisé (motif fixe, jamais un vrai code).
  static void _qr(Canvas canvas, Offset c, double size) {
    const pattern = [
      0x1F1,
      0x111,
      0x1F1,
      0x000,
      0x0AD,
      0x152,
      0x0B5,
      0x1A9,
      0x07E,
    ];
    final cell = size / 9;
    final origin = c - Offset(size / 2, size / 2);
    final ink = _fill(_navy);
    for (var y = 0; y < 9; y++) {
      for (var x = 0; x < 9; x++) {
        if ((pattern[y] >> (8 - x)) & 1 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              origin.dx + x * cell,
              origin.dy + y * cell,
              cell,
              cell,
            ),
            ink,
          );
        }
      }
    }
  }

  // Équipe

  static void _person(Canvas canvas, Offset feet, double scale, Color color) {
    final head = Offset(feet.dx, feet.dy - 52 * scale);
    final body = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(feet.dx, feet.dy - 18 * scale),
        width: 44 * scale,
        height: 36 * scale,
      ),
      topLeft: Radius.circular(22 * scale),
      topRight: Radius.circular(22 * scale),
      bottomLeft: Radius.circular(8 * scale),
      bottomRight: Radius.circular(8 * scale),
    );
    _shadow(canvas, body, dy: 4);
    canvas
      ..drawRRect(body, _fill(color))
      ..drawCircle(head, 15 * scale, _fill(color))
      ..drawCircle(
        head,
        15 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _mintPale,
      );
  }

  static void _team(Canvas canvas) {
    _person(canvas, const Offset(44, 104), 0.78, _mintPale);
    _person(canvas, const Offset(116, 104), 0.78, _mintPale);
    _person(canvas, const Offset(80, 108), 1, _mint);
    _sparkles(canvas, const [Offset(22, 26), Offset(140, 30)]);
  }

  // Calendrier

  static void _calendar(
    Canvas canvas,
    Offset c,
    double angle, {
    required _CalendarMark mark,
  }) {
    final rect = Rect.fromCenter(center: c, width: 84, height: 76);
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    _rotated(canvas, c, angle, () {
      _shadow(canvas, shape);
      canvas
        ..drawRRect(shape, _fill(_white))
        ..drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(rect.left, rect.top, rect.width, 20),
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
          ),
          _gradient(rect, const [_mintBright, _mint]),
        );
      for (final x in [rect.left + 22, rect.right - 22]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, rect.top), width: 7, height: 16),
            const Radius.circular(4),
          ),
          _fill(_navy),
        );
      }
      // Grille des jours.
      final day = _fill(_bluePale);
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 4; col++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rect.left + 12 + col * 16,
                rect.top + 28 + row * 14,
                10,
                8,
              ),
              const Radius.circular(2),
            ),
            day,
          );
        }
      }
      final markCenter = Offset(rect.right - 14, rect.bottom - 14);
      switch (mark) {
        case _CalendarMark.star:
          canvas.drawCircle(markCenter, 15, _fill(_mint));
          _sparkle(canvas, markCenter, 9, _white);
        case _CalendarMark.check:
          _badge(canvas, markCenter, _mint, Icons.check_rounded);
        case _CalendarMark.empty:
          canvas.drawCircle(markCenter, 13, _fill(_white));
          _icon(canvas, Icons.add_rounded, markCenter, 22, _blue);
      }
    });
  }

  // Scanner

  static void _phone(Canvas canvas) {
    _ticket(canvas, const Offset(112, 84), 0.12, scaleBy: 0.5, qr: true);
    const c = Offset(70, 60);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 60, height: 100),
      const Radius.circular(12),
    );
    _rotated(canvas, c, -0.1, () {
      _shadow(canvas, body);
      canvas.drawRRect(body, _fill(_navy));
      final screen = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 50, height: 86),
        const Radius.circular(8),
      );
      canvas.drawRRect(screen, _fill(const Color(0xFF0E3D73)));
      // Viseur à quatre coins.
      final corner = Paint()
        ..color = _mint
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final frame = Rect.fromCenter(center: c, width: 32, height: 32);
      const l = 9.0;
      for (final (p, dx, dy) in [
        (frame.topLeft, 1, 1),
        (frame.topRight, -1, 1),
        (frame.bottomLeft, 1, -1),
        (frame.bottomRight, -1, -1),
      ]) {
        canvas
          ..drawLine(p, p + Offset(l * dx, 0), corner)
          ..drawLine(p, p + Offset(0, l * dy), corner);
      }
      _qr(canvas, c, 18);
    });
    _sparkles(canvas, const [Offset(126, 26), Offset(26, 92)]);
  }

  // Statistiques

  static void _stats(Canvas canvas) {
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 22, 112, 84),
      const Radius.circular(14),
    );
    _shadow(canvas, card);
    canvas.drawRRect(card, _fill(_white));
    const bars = [
      (0.35, _bluePale),
      (0.55, _blue),
      (0.48, _bluePale),
      (0.8, _mint),
    ];
    for (final (i, (h, color)) in bars.indexed) {
      final height = 58 * h;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(38.0 + i * 24, 96 - height, 14, height),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        _fill(color),
      );
    }
    final arrow = Paint()
      ..color = _mint
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas
      ..drawPath(
        Path()
          ..moveTo(40, 70)
          ..lineTo(64, 54)
          ..lineTo(84, 62)
          ..lineTo(120, 32),
        arrow,
      )
      ..drawPath(
        Path()
          ..moveTo(108, 30)
          ..lineTo(124, 28)
          ..lineTo(122, 44),
        arrow,
      );
    _sparkles(canvas, const [Offset(144, 18)]);
  }

  // Portefeuille

  static void _wallet(Canvas canvas) {
    _ticket(canvas, const Offset(70, 40), -0.25, scaleBy: 0.62);
    _ticket(canvas, const Offset(96, 36), 0.18, scaleBy: 0.62, qr: true);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, 48, 100, 62),
      const Radius.circular(14),
    );
    _shadow(canvas, body);
    canvas.drawRRect(
      body,
      _gradient(body.outerRect, const [_blue, Color(0xFF1F4FB8)]),
    );
    final flap = RRect.fromRectAndRadius(
      const Rect.fromLTWH(96, 68, 40, 24),
      const Radius.circular(8),
    );
    canvas
      ..drawRRect(flap, _fill(_mint))
      ..drawCircle(const Offset(110, 80), 4, _fill(_white));
    _sparkles(canvas, const [Offset(26, 26), Offset(140, 18)]);
  }

  // Support

  static void _bubble(Canvas canvas, Rect rect, Color color, bool tailLeft) {
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    _shadow(canvas, shape, dy: 4);
    final tail = Path();
    if (tailLeft) {
      tail
        ..moveTo(rect.left + 16, rect.bottom - 2)
        ..lineTo(rect.left + 8, rect.bottom + 12)
        ..lineTo(rect.left + 30, rect.bottom - 2);
    } else {
      tail
        ..moveTo(rect.right - 16, rect.bottom - 2)
        ..lineTo(rect.right - 8, rect.bottom + 12)
        ..lineTo(rect.right - 30, rect.bottom - 2);
    }
    canvas
      ..drawRRect(shape, _fill(color))
      ..drawPath(tail, _fill(color));
  }

  static void _bubbles(Canvas canvas) {
    _bubble(canvas, const Rect.fromLTWH(18, 18, 84, 46), _mint, true);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(44.0 + i * 16, 41), 5, _fill(_navy));
    }
    _bubble(canvas, const Rect.fromLTWH(60, 56, 84, 44), _white, false);
    for (final (i, w) in const [44.0, 30.0].indexed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(74, 68.0 + i * 12, w, 6),
          const Radius.circular(3),
        ),
        _fill(i == 0 ? _blue : _bluePale),
      );
    }
    _sparkles(canvas, const [Offset(140, 24)]);
  }

  // Paramètres

  static void _gear(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    const teeth = 8;
    for (var i = 0; i < teeth * 2; i++) {
      final angle = i * math.pi / teeth;
      final radius = i.isEven ? r : r * 0.78;
      final a0 = angle - math.pi / teeth * 0.45;
      final a1 = angle + math.pi / teeth * 0.45;
      final p0 = c + Offset(math.cos(a0), math.sin(a0)) * radius;
      final p1 = c + Offset(math.cos(a1), math.sin(a1)) * radius;
      if (i == 0) {
        path.moveTo(p0.dx, p0.dy);
      } else {
        path.lineTo(p0.dx, p0.dy);
      }
      path.lineTo(p1.dx, p1.dy);
    }
    path
      ..close()
      ..addOval(Rect.fromCircle(center: c, radius: r * 0.36))
      ..fillType = PathFillType.evenOdd;
    canvas
      ..drawPath(
        path.shift(const Offset(0, 5)),
        Paint()
          ..color = _navy.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..drawPath(path, _fill(color));
  }

  static void _settings(Canvas canvas) {
    _gear(canvas, const Offset(62, 56), 36, _mint);
    _gear(canvas, const Offset(112, 34), 18, _bluePale);
    final track = RRect.fromRectAndRadius(
      const Rect.fromLTWH(86, 78, 52, 28),
      const Radius.circular(14),
    );
    _shadow(canvas, track, dy: 3);
    canvas
      ..drawRRect(track, _fill(_blue))
      ..drawCircle(const Offset(124, 92), 11, _fill(_white));
    _sparkles(canvas, const [Offset(22, 22)]);
  }

  // Console

  static void _shield(Canvas canvas) {
    final path = Path()
      ..moveTo(80, 12)
      ..cubicTo(98, 22, 112, 24, 124, 24)
      ..cubicTo(124, 62, 114, 92, 80, 110)
      ..cubicTo(46, 92, 36, 62, 36, 24)
      ..cubicTo(48, 24, 62, 22, 80, 12)
      ..close();
    canvas
      ..drawPath(
        path.shift(const Offset(0, 6)),
        Paint()
          ..color = _navy.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(
        path,
        _gradient(path.getBounds(), const [_blue, Color(0xFF1F4FB8)]),
      );
    final check = Paint()
      ..color = _mint
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(62, 60)
        ..lineTo(76, 74)
        ..lineTo(100, 48),
      check,
    );
    _sparkles(canvas, const [Offset(140, 24), Offset(24, 84)]);
  }

  // Cadenas et enveloppe

  static void _lock(Canvas canvas) {
    final shackle = Paint()
      ..color = _bluePale
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas
      ..drawArc(
        const Rect.fromLTWH(56, 18, 48, 52),
        math.pi,
        math.pi,
        false,
        shackle,
      )
      ..drawLine(const Offset(56, 44), const Offset(56, 56), shackle)
      ..drawLine(const Offset(104, 44), const Offset(104, 56), shackle);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 52, 80, 58),
      const Radius.circular(14),
    );
    _shadow(canvas, body);
    canvas
      ..drawRRect(body, _gradient(body.outerRect, const [_mintBright, _mint]))
      ..drawCircle(const Offset(80, 76), 8, _fill(_navy))
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(76, 78, 8, 18),
          const Radius.circular(4),
        ),
        _fill(_navy),
      );
    _sparkles(canvas, const [Offset(132, 30), Offset(28, 40)]);
  }

  static void _mail(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 40, 104, 70),
      const Radius.circular(12),
    );
    _shadow(canvas, body);
    // Lettre qui dépasse, bordée de bleu pâle (lisible sur fond blanc).
    final letter = RRect.fromRectAndRadius(
      const Rect.fromLTWH(42, 8, 76, 64),
      const Radius.circular(8),
    );
    canvas
      ..drawRRect(letter, _fill(_white))
      ..drawRRect(
        letter,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _bluePale,
      );
    for (final (i, w) in const [48.0, 36.0, 42.0].indexed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(54, 18.0 + i * 9, w, 5),
          const Radius.circular(3),
        ),
        _fill(i == 0 ? _blue : _bluePale),
      );
    }
    canvas
      ..drawRRect(
        body,
        _gradient(body.outerRect, const [_blue, Color(0xFF1F4FB8)]),
      )
      ..drawPath(
        Path()
          ..moveTo(28, 46)
          ..lineTo(80, 82)
          ..lineTo(132, 46)
          ..lineTo(132, 52)
          ..lineTo(80, 88)
          ..lineTo(28, 52)
          ..close(),
        _fill(_bluePale),
      );
    _badge(canvas, const Offset(126, 40), _mint, Icons.check_rounded);
    _sparkles(canvas, const [Offset(24, 24)]);
  }

  // Recherche et réseau

  static void _magnifier(Canvas canvas, Offset c) {
    final handle = Paint()
      ..color = _navy
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(c + const Offset(16, 16), c + const Offset(34, 34), handle)
      ..drawCircle(c, 24, _fill(_white.withValues(alpha: 0.7)))
      ..drawCircle(
        c,
        24,
        Paint()
          ..color = _blue
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke,
      );
    _icon(canvas, Icons.question_mark_rounded, c, 22, _blue);
  }

  static void _cloud(Canvas canvas) {
    final path = Path()
      ..addOval(const Rect.fromLTWH(34, 50, 44, 40))
      ..addOval(const Rect.fromLTWH(56, 30, 52, 52))
      ..addOval(const Rect.fromLTWH(90, 48, 40, 40))
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 64, 72, 26),
          const Radius.circular(13),
        ),
      );
    canvas
      ..drawPath(
        path.shift(const Offset(0, 6)),
        Paint()
          ..color = _navy.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(path, _fill(_white));
    final slash = Paint()
      ..color = _red
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(62, 52), const Offset(104, 86), slash);
    _icon(canvas, Icons.wifi_rounded, const Offset(82, 62), 28, _blue);
    canvas.drawLine(const Offset(62, 52), const Offset(104, 86), slash);
  }
}

enum _CalendarMark { star, check, empty }
