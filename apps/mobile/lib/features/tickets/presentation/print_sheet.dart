import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Nombre de tickets par feuille proposé d'abord : le plus grand qui garde
/// les tickets en pleine largeur pour les thèmes intégrés.
const defaultTicketsPerSheet = 3;

/// Feuille « Imprimer des tickets » (#4) : 1 à [maxTicketsPerSheet]
/// tickets par feuille A4, aperçu, nombre de feuilles et taille du QR.
/// Rend le nombre choisi, ou null si la feuille est fermée.
Future<int?> showPrintSheet(BuildContext context, {required int count}) =>
    showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => PrintSheet(count: count),
    );

class PrintSheet extends StatefulWidget {
  const new({required this.count, super.key});

  /// Nombre de tickets à imprimer.
  final int count;

  @override
  State<PrintSheet> createState() => _PrintSheetState();
}

class _PrintSheetState extends State<PrintSheet> {
  int _perPage = defaultTicketsPerSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sheets = (widget.count / _perPage).ceil();
    final qrCm = sheetTicketWidthMm(_perPage) * builtinQrRatio / 10;
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('print-sheet'),
        padding: const EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          0,
          TikeoSizes.screenMargin,
          TikeoSizes.screenMargin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.printTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.printCount(widget.count),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            Text(l10n.printPerPage, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const Key('print-per-page'),
              showSelectedIcon: false,
              segments: [
                for (var n = 1; n <= maxTicketsPerSheet; n++)
                  ButtonSegment(
                    value: n,
                    label: Text('$n', key: Key('print-per-page-$n')),
                  ),
              ],
              selected: {_perPage},
              onSelectionChanged: (value) =>
                  setState(() => _perPage = value.single),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 132,
                  child: _A4Preview(perPage: _perPage, count: widget.count),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Fact(
                        key: const Key('print-sheets'),
                        icon: Icons.description_rounded,
                        label: l10n.printSheets(sheets),
                      ),
                      const SizedBox(height: 12),
                      _Fact(
                        key: const Key('print-qr'),
                        icon: Icons.qr_code_2_rounded,
                        label: l10n.printQrSize(qrCm),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.printHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TikeoSizes.sectionGap),
            FilledButton.icon(
              key: const Key('print-generate'),
              onPressed: () => Navigator.of(context).pop(_perPage),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(l10n.printGenerate),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const new({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tints = context.tints;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tints.blue.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: tints.blue.icon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Aperçu à l'échelle de la première feuille A4.
class _A4Preview extends StatelessWidget {
  const new({required this.perPage, required this.count});

  final int perPage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPage = count < perPage ? count : perPage;
    return AspectRatio(
      aspectRatio: 210 / 297,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 210;
          final width = sheetTicketWidthMm(perPage) * scale;
          final height = width / builtinTicketAspect;
          final qr = width * builtinQrRatio;
          Widget cut() => SizedBox(
            height: 8 * scale,
            child: Center(
              child: Container(height: 0.6, color: const Color(0xFF9CA3AF)),
            ),
          );
          return DecoratedBox(
            key: const Key('print-preview'),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: TikeoShadows.card,
            ),
            child: Padding(
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                children: [
                  cut(),
                  for (var i = 0; i < onPage; i++) ...[
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        // Papier blanc dans les deux thèmes : ticket sombre.
                        color: TicketSurColors.navy,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: width * 0.06),
                      child: Container(
                        width: qr,
                        height: qr,
                        color: Colors.white,
                      ),
                    ),
                    cut(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
