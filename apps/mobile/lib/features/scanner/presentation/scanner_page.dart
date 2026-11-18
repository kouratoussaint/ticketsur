import 'dart:async';

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/presentation/scan_verdict_view.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Poste de scan (S22 à S26) pour un événement et une porte.
///
/// Saisie ou collage du code ; la lecture caméra se branchera sur le même
/// contrôleur ([ScanSessionController.submit]).
class ScannerPage extends ConsumerStatefulWidget {
  const new({required this.post, super.key});

  final ScanPost post;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _code = TextEditingController();

  ScanPostKey get _key =>
      (eventId: widget.post.eventId, checkpointId: widget.post.checkpointId);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit(String code) async {
    if (code.trim().isEmpty) return;
    await ref.read(scanSessionProvider(_key).notifier).submit(code);
  }

  Future<void> _paste() async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      toast.info(l10n.scannerEmptyClipboard);
      return;
    }
    _code.text = text;
    await _submit(text);
  }

  void _next() {
    _code.clear();
    ref.read(scanSessionProvider(_key).notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider(_key));
    final verdict = session.verdict;
    // Verdict immédiat : transition très courte, jamais de quoi ralentir.
    final duration = TicketSurMotion.reduced(context)
        ? Duration.zero
        : TicketSurMotion.short;
    final Widget body = switch (session.phase) {
      ScanPhase.verifying => const ScanVerifyingView(
        key: ValueKey('verifying'),
      ),
      ScanPhase.verdict when verdict != null => ScanVerdictView(
        key: ValueKey('verdict-${session.scanned}'),
        verdict: verdict,
        eventUtcOffset: utcOffsetOf(
          widget.post.timezone,
          verdict.firstValidatedAt ?? DateTime.now(),
        ),
        onNext: _next,
        onRetry: verdict.kind == VerdictKind.indeterminate
            ? () => unawaited(
                ref.read(scanSessionProvider(_key).notifier).retry(),
              )
            : null,
      ),
      _ => _ReadyView(
        key: const ValueKey('ready'),
        post: widget.post,
        controller: _code,
        scanned: session.scanned,
        onSubmit: (value) => unawaited(_submit(value)),
        onPaste: () => unawaited(_paste()),
      ),
    };
    return AnimatedSwitcher(duration: duration, child: body);
  }
}

class _ReadyView extends StatelessWidget {
  const new({
    required this.post,
    required this.controller,
    required this.scanned,
    required this.onSubmit,
    required this.onPaste,
    super.key,
  });

  final ScanPost post;
  final TextEditingController controller;
  final int scanned;
  final ValueChanged<String> onSubmit;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final outside = post.windowAt(DateTime.now().toUtc()) != ScanWindow.open;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.eventTitle, overflow: TextOverflow.ellipsis),
            Text(
              post.checkpointName,
              key: const Key('scanner-door'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (outside)
                Card(
                  key: const Key('scanner-outside-window'),
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(TicketSurSpacing.md),
                    child: Text(
                      l10n.scannerOutsideWindow,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: TicketSurSpacing.md),
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              Text(
                l10n.scannerManualHelp,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              FilledButton.icon(
                key: const Key('scanner-paste'),
                onPressed: onPaste,
                icon: const Icon(Icons.content_paste_go_rounded),
                label: Text(l10n.scannerPaste),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              TextField(
                key: const Key('scanner-code'),
                controller: controller,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  labelText: l10n.scannerManualLabel,
                  hintText: 'TS1.…',
                ),
                onSubmitted: onSubmit,
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              OutlinedButton(
                key: const Key('scanner-validate'),
                onPressed: () => onSubmit(controller.text),
                child: Text(l10n.scannerValidate),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              AnimatedCount(
                value: scanned,
                duration: const Duration(milliseconds: 400),
                builder: (context, value) => Text(
                  l10n.scannerCount(value),
                  key: const Key('scanner-count'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
