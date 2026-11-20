import 'dart:async';

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/verdict_colors.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/scanner/application/scan_providers.dart';
import 'package:ticketsur/features/scanner/domain/scan_post.dart';
import 'package:ticketsur/features/scanner/presentation/camera/scan_camera.dart';
import 'package:ticketsur/features/scanner/presentation/scan_verdict_view.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Délai pendant lequel le même QR n'est pas relu après un verdict
/// (§12 : réarmement contre la double lecture involontaire).
const Duration rearmDelay = Duration(milliseconds: 2500);

/// Poste de scan plein écran (S22 à S26) : caméra, verdict par-dessus,
/// saisie manuelle en secours. La caméra reste allumée sous le verdict :
/// le ticket suivant est lu sans attendre son redémarrage.
class ScannerPage extends ConsumerStatefulWidget {
  const new({required this.post, super.key});

  final ScanPost post;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  ScanPostKey get _key =>
      (eventId: widget.post.eventId, checkpointId: widget.post.checkpointId);

  ScanSessionController get _session =>
      ref.read(scanSessionProvider(_key).notifier);

  /// QR lu par la caméra : ignoré hors de l'état « prêt » et pendant le
  /// délai de réarmement pour le même code.
  void _onCameraCode(String raw) {
    if (ref.read(scanSessionProvider(_key)).phase != ScanPhase.ready) return;
    final now = DateTime.now();
    if (raw == _lastCode && now.difference(_lastAt) < rearmDelay) return;
    _lastCode = raw;
    _lastAt = now;
    unawaited(_session.submit(raw));
  }

  void _next() {
    // Le ticket est souvent encore devant l'objectif : délai repart d'ici.
    _lastAt = DateTime.now();
    _session.next();
  }

  Future<void> _openDoorSearch() async {
    final ticketId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (_) => DoorSearchSheet(post: _key),
    );
    if (ticketId != null) await _session.submitTicket(ticketId);
  }

  Future<void> _openManualEntry() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _ManualEntrySheet(),
    );
    if (code != null && code.trim().isNotEmpty) {
      await _session.submit(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider(_key));
    final verdict = session.verdict;
    final camera = ref.watch(scanCameraBuilderProvider);
    // Verdict immédiat : transition très courte, jamais de quoi ralentir.
    final duration = TicketSurMotion.reduced(context)
        ? Duration.zero
        : TicketSurMotion.short;
    final layer = switch (session.phase) {
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
            ? () => unawaited(_session.retry())
            : null,
      ),
      _ => const SizedBox.shrink(key: ValueKey('camera')),
    };
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          camera(
            onCode: _onCameraCode,
            onManualEntry: () => unawaited(_openManualEntry()),
            header: _Header(post: widget.post),
            footer: _Footer(
              post: widget.post,
              scanned: session.scanned,
              onManualEntry: () => unawaited(_openManualEntry()),
              onSearch: () => unawaited(_openDoorSearch()),
            ),
          ),
          AnimatedSwitcher(
            duration: duration,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.04, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: layer,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.post});

  final ScanPost post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(TicketSurSpacing.xs),
      child: Row(
        children: [
          IconButton(
            key: const Key('scanner-leave'),
            tooltip: context.l10n.scannerLeave,
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x55000000),
              foregroundColor: TicketSurColors.white,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: TicketSurSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.eventTitle,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: TicketSurColors.white,
                    shadows: const [Shadow(blurRadius: 6)],
                  ),
                ),
                Text(
                  post.checkpointName,
                  key: const Key('scanner-door'),
                  style: textTheme.bodySmall?.copyWith(
                    color: TicketSurColors.white,
                    shadows: const [Shadow(blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const new({
    required this.post,
    required this.scanned,
    required this.onManualEntry,
    required this.onSearch,
  });

  final ScanPost post;
  final int scanned;
  final VoidCallback onManualEntry;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final outside = post.window != ScanWindow.open;
    const white = TicketSurColors.white;
    return Padding(
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (outside)
            Container(
              key: const Key('scanner-outside-window'),
              margin: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: TicketSurSpacing.md,
                vertical: TicketSurSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFA4262C),
                borderRadius: BorderRadius.circular(TicketSurRadii.sm),
              ),
              child: Text(
                l10n.scannerOutsideWindow,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: white),
              ),
            ),
          Text(
            l10n.scannerHint,
            style: textTheme.titleSmall?.copyWith(
              color: white,
              shadows: const [Shadow(blurRadius: 6)],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          AnimatedCount(
            value: scanned,
            duration: const Duration(milliseconds: 400),
            builder: (context, value) => Text(
              l10n.scannerCount(value),
              key: const Key('scanner-count'),
              style: textTheme.bodySmall?.copyWith(
                color: white,
                shadows: const [Shadow(blurRadius: 6)],
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          OutlinedButton.icon(
            key: const Key('scanner-manual'),
            onPressed: onManualEntry,
            style: OutlinedButton.styleFrom(
              foregroundColor: white,
              backgroundColor: const Color(0x55000000),
              side: const BorderSide(color: white),
            ),
            icon: const Icon(Icons.keyboard_rounded),
            label: Text(l10n.scannerManual),
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          TextButton.icon(
            key: const Key('scanner-search'),
            onPressed: onSearch,
            style: TextButton.styleFrom(
              foregroundColor: white,
              backgroundColor: const Color(0x55000000),
            ),
            icon: const Icon(Icons.person_search_rounded),
            label: Text(l10n.scannerSearch),
          ),
        ],
      ),
    );
  }
}

/// Saisie ou collage du code, en secours de la caméra.
class _ManualEntrySheet extends StatefulWidget {
  const new();

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    Navigator.of(context).pop(value.trim());
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
    if (mounted) _submit(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: TicketSurSpacing.lg,
        right: TicketSurSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.scannerManual,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(l10n.scannerManualHelp),
            const SizedBox(height: TicketSurSpacing.md),
            FilledButton.icon(
              key: const Key('scanner-paste'),
              onPressed: () => unawaited(_paste()),
              icon: const Icon(Icons.content_paste_go_rounded),
              label: Text(l10n.scannerPaste),
            ),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('scanner-code'),
              controller: _code,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.go,
              decoration: InputDecoration(
                labelText: l10n.scannerManualLabel,
                hintText: 'TS1.…',
              ),
              onSubmitted: _submit,
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            OutlinedButton(
              key: const Key('scanner-validate'),
              onPressed: () => _submit(_code.text),
              child: Text(l10n.scannerValidate),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recherche d'un ticket à la porte (QR perdu). Renvoie l'identifiant du
/// ticket choisi ; la validation passe ensuite par le serveur, comme un scan.
class DoorSearchSheet extends ConsumerStatefulWidget {
  const new({required this.post, super.key});

  final ScanPostKey post;

  @override
  ConsumerState<DoorSearchSheet> createState() => _DoorSearchSheetState();
}

class _DoorSearchSheetState extends ConsumerState<DoorSearchSheet> {
  final _query = TextEditingController();
  List<DoorMatch>? _results;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final l10n = context.l10n;
    final query = _query.text.trim();
    if (query.length < 3) {
      setState(() => _error = l10n.doorSearchTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(scanRepositoryProvider)
          .lookup(
            eventId: widget.post.eventId,
            checkpointId: widget.post.checkpointId,
            query: query,
          );
      if (mounted) setState(() => _results = results);
    } on DoorLookupFailure catch (failure) {
      if (!mounted) return;
      setState(
        () => _error = switch (failure) {
          DoorLookupFailure.tooShort => l10n.doorSearchTooShort,
          DoorLookupFailure.rateLimited => l10n.doorSearchRateLimited,
          DoorLookupFailure.forbidden => l10n.doorSearchForbidden,
          DoorLookupFailure.network => l10n.doorSearchNetwork,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.lg,
          0,
          TicketSurSpacing.lg,
          TicketSurSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.doorSearchTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(l10n.doorSearchIntro),
            const SizedBox(height: TicketSurSpacing.md),
            TextField(
              key: const Key('door-search-field'),
              controller: _query,
              autofocus: true,
              enabled: !_busy,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.doorSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  key: const Key('door-search-submit'),
                  onPressed: _busy ? null : () => unawaited(_search()),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              onSubmitted: (_) => unawaited(_search()),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: TicketSurSpacing.sm),
                child: LinearProgressIndicator(),
              ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: TicketSurSpacing.sm),
                child: Text(
                  error,
                  key: const Key('door-search-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (results != null && results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: TicketSurSpacing.md),
                child: Text(
                  l10n.doorSearchEmpty,
                  key: const Key('door-search-empty'),
                  textAlign: TextAlign.center,
                ),
              ),
            for (final match in results ?? const <DoorMatch>[])
              Card(
                key: Key('door-match-${match.ticketId}'),
                child: Padding(
                  padding: const EdgeInsets.all(TicketSurSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        match.holderName ?? match.reference,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        [
                          match.category,
                          if (match.holderName != null) match.reference,
                          ?match.phoneHint,
                          ticketStatusLabel(l10n, match.status),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: TicketSurSpacing.xs),
                      FilledButton.tonal(
                        key: Key('door-validate-${match.ticketId}'),
                        onPressed: () =>
                            Navigator.of(context).pop(match.ticketId),
                        child: Text(l10n.doorSearchValidate),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
