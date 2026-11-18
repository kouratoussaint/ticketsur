import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/ticketsur_theme.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/features/scanner/domain/scan_verdict.dart';
import 'package:ticketsur/features/scanner/presentation/verdict_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Écran plein page d'un verdict serveur (S23 à S26).
///
/// Trois signaux redondants portent le sens — couleur, icône, mot — pour
/// rester lisibles en plein soleil et pour les agents daltoniens. Le verdict
/// est annoncé à TalkBack dès son affichage.
class ScanVerdictView extends StatelessWidget {
  const new({
    required this.verdict,
    required this.onNext,
    this.onRetry,
    this.eventUtcOffset = Duration.zero,
    super.key,
  });

  final ScanVerdict verdict;

  /// Réarme le scanner pour le billet suivant.
  final VoidCallback onNext;

  /// Rejoue la MÊME requête (même `request_id`) pour un état indéterminé.
  final VoidCallback? onRetry;

  /// Décalage UTC du fuseau de l'événement, pour afficher les heures.
  final Duration eventUtcOffset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = verdict.kind;
    final colors = context.verdictColors;
    final background = colors.background(kind);
    final foreground = colors.foreground(kind);
    final textTheme = Theme.of(context).textTheme;

    final title = verdictTitle(l10n, kind);
    final reason = verdictReason(l10n, verdict.result);
    final details = <String>[
      ?_firstPassage(l10n),
      if (verdict.publicReference case final reference?)
        [l10n.verdictReference(reference), ?verdict.category].join(' · '),
      if (kind == VerdictKind.indeterminate) l10n.verdictIndeterminateAdvice,
    ];

    return Material(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  label: [title, reason, ...details].join('. '),
                  child: ExcludeSemantics(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_icon(kind), size: 112, color: foreground),
                            const SizedBox(height: TicketSurSpacing.lg),
                            Text(
                              title,
                              key: const Key('verdict-title'),
                              textAlign: TextAlign.center,
                              style: textTheme.headlineLarge?.copyWith(
                                color: foreground,
                              ),
                            ),
                            const SizedBox(height: TicketSurSpacing.sm),
                            Text(
                              reason,
                              key: const Key('verdict-reason'),
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: foreground,
                              ),
                            ),
                            for (final line in details) ...[
                              const SizedBox(height: TicketSurSpacing.sm),
                              Text(
                                line,
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: foreground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (kind == VerdictKind.indeterminate && onRetry != null) ...[
                _VerdictButton(
                  key: const Key('verdict-retry'),
                  label: l10n.verdictRetry,
                  onPressed: onRetry!,
                  foreground: foreground,
                  background: background,
                  filled: true,
                ),
                const SizedBox(height: TicketSurSpacing.sm),
              ],
              _VerdictButton(
                key: const Key('verdict-next'),
                label: l10n.verdictNextScan,
                onPressed: onNext,
                foreground: foreground,
                background: background,
                filled: kind != VerdictKind.indeterminate || onRetry == null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _firstPassage(AppLocalizations l10n) {
    final first = verdict.firstValidatedAt;
    if (first == null || verdict.result != ScanResult.alreadyUsed) return null;
    final time = formatEventTime(first, eventUtcOffset: eventUtcOffset);
    final checkpoint = verdict.checkpointLabel;
    return checkpoint == null
        ? l10n.verdictFirstPassage(time)
        : l10n.verdictFirstPassageAt(time, checkpoint);
  }

  static IconData _icon(VerdictKind kind) => switch (kind) {
    VerdictKind.admitted => Icons.check_circle_rounded,
    VerdictKind.refused => Icons.cancel_rounded,
    VerdictKind.indeterminate => Icons.schedule_rounded,
    VerdictKind.verifying => Icons.hourglass_top_rounded,
  };
}

/// Écran neutre affiché entre le décodage du QR et la réponse serveur.
/// Aucune couleur de verdict : l'agent ne doit rien anticiper.
class ScanVerifyingView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.verdictColors;
    final foreground = colors.foreground(VerdictKind.verifying);
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colors.background(VerdictKind.verifying),
      child: Semantics(
        liveRegion: true,
        label: '${l10n.verdictVerifying} ${l10n.verdictVerifyingHint}',
        child: ExcludeSemantics(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                Text(
                  l10n.verdictVerifying,
                  style: textTheme.headlineMedium?.copyWith(color: foreground),
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(
                  l10n.verdictVerifyingHint,
                  style: textTheme.titleMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerdictButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    required this.foreground,
    required this.background,
    required this.filled,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color foreground;
  final Color background;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const size = Size.fromHeight(kScannerActionHeight);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TicketSurRadii.md),
    );
    final textStyle = Theme.of(context).textTheme.titleMedium;
    // Bouton plein = couleurs inversées du verdict : le contraste reste celui
    // de la paire texte/fond déjà vérifiée.
    return filled
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              backgroundColor: foreground,
              foregroundColor: background,
              textStyle: textStyle,
            ),
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              shape: shape,
              foregroundColor: foreground,
              side: BorderSide(color: foreground, width: 2),
              textStyle: textStyle,
            ),
            child: Text(label),
          );
  }
}
