import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/moderation/application/moderation_providers.dart';
import 'package:ticketsur/features/moderation/domain/moderation.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Libellé d'un motif de signalement.
String reportReasonLabel(AppLocalizations l10n, ReportReason reason) =>
    switch (reason) {
      ReportReason.misleading => l10n.flagReasonMisleading,
      ReportReason.scam => l10n.flagReasonScam,
      ReportReason.offensive => l10n.flagReasonOffensive,
      ReportReason.duplicate => l10n.flagReasonDuplicate,
      ReportReason.other => l10n.flagReasonOther,
    };

IconData reportReasonIcon(ReportReason reason) => switch (reason) {
  ReportReason.misleading => Icons.info_rounded,
  ReportReason.scam => Icons.money_off_rounded,
  ReportReason.offensive => Icons.block_rounded,
  ReportReason.duplicate => Icons.content_copy_rounded,
  ReportReason.other => Icons.more_horiz_rounded,
};

/// « Signaler cet événement » / « Signaler cette structure », discret, en
/// bas d'une fiche publique (ADR 0050). Sans compte : connexion d'abord,
/// puis retour sur [returnRoute].
class ReportContentButton extends ConsumerWidget {
  const new({
    required this.kind,
    required this.id,
    required this.returnRoute,
    required this.buttonKey,
    super.key,
  });

  final ReportKind kind;
  final String id;
  final String returnRoute;
  final Key buttonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Center(
      child: TextButton.icon(
        key: buttonKey,
        style: TextButton.styleFrom(foregroundColor: context.palette.mutedText),
        onPressed: () {
          if (ref.read(currentUserProvider).value == null) {
            unawaited(context.push(AppRoutes.signInThen(returnRoute)));
            return;
          }
          unawaited(showReportSheet(context, kind: kind, id: id));
        },
        icon: const Icon(Icons.flag_rounded, size: 18),
        label: Text(
          kind == ReportKind.event
              ? l10n.flagEventAction
              : l10n.flagOrganizationAction,
        ),
      ),
    );
  }
}

/// Feuille du signalement : motif, commentaire facultatif, envoi.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportKind kind,
  required String id,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ReportSheet(kind: kind, id: id),
);

class _ReportSheet extends ConsumerStatefulWidget {
  const new({required this.kind, required this.id});

  final ReportKind kind;
  final String id;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _comment = TextEditingController();
  ReportReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final already = await ref
          .read(moderationRepositoryProvider)
          .report(
            widget.kind,
            widget.id,
            reason,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      toast.success(already ? l10n.flagAlready : l10n.flagSent);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (error) {
          ReportFailure.rateLimited => l10n.flagErrorRateLimited,
          ReportFailure.notFound => l10n.flagErrorNotFound,
          ReportFailure.commentTooLong => l10n.flagErrorComment,
          ReportFailure.network => l10n.exploreErrorNetwork,
          _ => l10n.flagErrorFailed,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        key: const Key('report-sheet'),
        padding: const EdgeInsets.fromLTRB(
          TikeoSizes.screenMargin,
          0,
          TikeoSizes.screenMargin,
          TikeoSizes.screenMargin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.kind == ReportKind.event
                  ? l10n.flagEventTitle
                  : l10n.flagOrganizationTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.flagIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.mutedText,
              ),
            ),
            const SizedBox(height: 12),
            for (final reason in ReportReason.values) ...[
              SelectableOption(
                key: Key('report-reason-${reason.name}'),
                label: reportReasonLabel(l10n, reason),
                icon: reportReasonIcon(reason),
                selected: _reason == reason,
                onTap: _busy ? null : () => setState(() => _reason = reason),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            TextField(
              key: const Key('report-comment'),
              controller: _comment,
              enabled: !_busy,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.flagCommentLabel,
                helperText: l10n.flagCommentHint,
                helperMaxLines: 2,
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const Key('report-error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TikeoPrimaryButton(
              key: const Key('report-submit'),
              label: l10n.flagSubmit,
              icon: Icons.flag_rounded,
              busy: _busy,
              onPressed: _reason == null ? null : () => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}
