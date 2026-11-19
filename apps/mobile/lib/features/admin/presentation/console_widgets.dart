import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/status_chip.dart';
import 'package:ticketsur/features/admin/domain/admin.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Message d'un échec de la console.
String consoleFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      AdminFailure.forbidden => l10n.consoleForbidden,
      AdminFailure.reasonRequired => l10n.consoleReasonRequired,
      AdminFailure.notAllowed => l10n.consoleNotAllowed,
      _ => l10n.consoleLoadError,
    };

/// Liste paginée de la console : premier chargement, « Voir plus », échec
/// avec nouvel essai. Changer la [key] relance depuis le début (recherche,
/// filtre).
class ConsolePagedList<T> extends StatefulWidget {
  const new({
    required this.load,
    required this.itemBuilder,
    this.pageSize = 30,
    this.header,
    super.key,
  });

  /// Page suivante ; `last` est le dernier élément déjà affiché.
  final Future<List<T>> Function(int offset, T? last) load;

  /// `reload` relit la liste depuis le début (après une action).
  final Widget Function(BuildContext context, T item, VoidCallback reload)
  itemBuilder;
  final int pageSize;

  /// Contenu fixe au-dessus de la liste (recherche, filtres).
  final Widget? header;

  @override
  State<ConsolePagedList<T>> createState() => _ConsolePagedListState<T>();
}

class _ConsolePagedListState<T> extends State<ConsolePagedList<T>> {
  final List<T> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_more());
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _hasMore = true;
      _error = null;
    });
    await _more();
  }

  Future<void> _more() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.load(
        _items.length,
        _items.isEmpty ? null : _items.last,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length >= widget.pageSize;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final children = <Widget>[
      ?widget.header,
      for (final item in _items)
        widget.itemBuilder(context, item, () => unawaited(_reload())),
      if (_error case final error?)
        Card(
          key: const Key('console-list-error'),
          child: ListTile(
            leading: const Icon(Icons.cloud_off_rounded),
            title: Text(consoleFailureMessage(l10n, error)),
            trailing: error == AdminFailure.forbidden
                ? null
                : TextButton(
                    onPressed: () => unawaited(_more()),
                    child: Text(l10n.consoleRetry),
                  ),
          ),
        )
      else if (_loading)
        const Padding(
          padding: EdgeInsets.all(TicketSurSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_items.isEmpty)
        Padding(
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          child: Text(
            l10n.consoleEmpty,
            key: const Key('console-list-empty'),
            textAlign: TextAlign.center,
          ),
        )
      else if (_hasMore)
        Center(
          child: TextButton(
            key: const Key('console-load-more'),
            onPressed: () => unawaited(_more()),
            child: Text(l10n.consoleLoadMore),
          ),
        ),
      const SizedBox(height: TicketSurSpacing.xl),
    ];
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: children,
      ),
    );
  }
}

/// Champ de recherche de la console, avec un court délai avant la requête.
class ConsoleSearchField extends StatefulWidget {
  const new({
    required this.hint,
    required this.onChanged,
    this.initial = '',
    super.key,
  });

  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<ConsoleSearchField> createState() => _ConsoleSearchFieldState();
}

class _ConsoleSearchFieldState extends State<ConsoleSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: const Icon(Icons.search_rounded),
    ),
    onChanged: (value) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 350),
        () => widget.onChanged(value.trim()),
      );
    },
    onSubmitted: (value) {
      _debounce?.cancel();
      widget.onChanged(value.trim());
    },
  );
}

/// Feuille de confirmation d'une action de modération. Avec [needsReason],
/// le motif est obligatoire ; renvoie le motif (ou `''`), `null` si annulé.
Future<String?> showConsoleConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required bool needsReason,
  required Key confirmKey,
  bool destructive = true,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ConfirmSheet(
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    needsReason: needsReason,
    confirmKey: confirmKey,
    destructive: destructive,
  ),
);

class _ConfirmSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.needsReason,
    required this.confirmKey,
    required this.destructive,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool needsReason;
  final Key confirmKey;
  final bool destructive;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final _reason = TextEditingController();
  bool _missing = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (widget.needsReason && reason.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: TicketSurSpacing.sm),
            Text(widget.body),
            if (widget.needsReason) ...[
              const SizedBox(height: TicketSurSpacing.md),
              TextField(
                key: const Key('console-reason'),
                controller: _reason,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.consoleReason,
                  errorText: _missing ? l10n.consoleReasonRequired : null,
                ),
                onChanged: (_) {
                  if (_missing) setState(() => _missing = false);
                },
              ),
            ],
            const SizedBox(height: TicketSurSpacing.md),
            FilledButton(
              key: widget.confirmKey,
              style: widget.destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    )
                  : null,
              onPressed: _confirm,
              child: Text(widget.confirmLabel),
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.consoleCancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petite pastille d'état (suspendue, retiré, au catalogue).
class ConsoleTag extends StatelessWidget {
  const new({required this.label, required this.danger, super.key});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: label,
    tone: danger ? StatusTone.danger : StatusTone.info,
  );
}
