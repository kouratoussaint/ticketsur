import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/presentation/scan_verdict_view.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Galerie des écrans de verdict, pour la revue UX sur appareil réel
/// (lisibilité au soleil, TalkBack, grande police) avant le branchement
/// de la caméra. Données fictives, aucun appel réseau.
class VerdictPreviewPage extends StatefulWidget {
  const new({super.key});

  @override
  State<VerdictPreviewPage> createState() => _VerdictPreviewPageState();
}

class _VerdictPreviewPageState extends State<VerdictPreviewPage> {
  static final DateTime _firstPassage = DateTime.utc(2026, 11, 18, 19, 42);

  static List<ScanVerdict> get _samples => [
    for (final result in ScanResult.values)
      ScanVerdict(
        requestId: 'apercu-${result.wireName}',
        result: result,
        validationId: result == ScanResult.accepted ? 'apercu' : null,
        publicReference:
            result == ScanResult.notFound || result == ScanResult.unauthorized
            ? null
            : 'TS-7K3P-9QXM',
        category: 'Standard',
        firstValidatedAt: result == ScanResult.alreadyUsed
            ? _firstPassage
            : null,
        checkpointLabel: result == ScanResult.alreadyUsed
            ? 'Entrée principale'
            : null,
      ),
  ];

  int _index = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_index == -1) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.verdictPreviewTitle)),
        body: ListView(
          children: [
            ListTile(
              title: Text(l10n.verdictVerifying),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: ScanVerifyingView()),
                ),
              ),
            ),
            for (final (i, sample) in _samples.indexed)
              ListTile(
                title: Text(verdictReason(l10n, sample.result)),
                subtitle: Text(sample.result.wireName),
                onTap: () => setState(() => _index = i),
              ),
          ],
        ),
      );
    }
    final sample = _samples[_index];
    return Scaffold(
      body: ScanVerdictView(
        verdict: sample,
        onNext: () => setState(() => _index = -1),
        onRetry: () => setState(() => _index = -1),
      ),
    );
  }
}
