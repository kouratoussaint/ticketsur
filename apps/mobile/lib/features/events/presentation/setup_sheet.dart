// Partie de `event_setup_sections.dart` (découpage du lot 4-9) :
// feuille d'ajout ou de modification d'une catégorie ou d'une porte.
part of 'event_setup_sections.dart';

/// Issue d'une feuille de saisie.
enum SetupSheetResult {
  /// Élément créé ou modifié.
  saved,

  /// Élément supprimé.
  deleted,
}

/// Valeurs saisies dans la feuille.
typedef SetupValues = ({
  String name,
  int? capacity,
  bool invitation,
  int? price,
  EntryPolicy entryPolicy,
  int? maxEntries,
});

/// Ouvre la feuille de saisie. [onSubmit] et [onDelete] lèvent une
/// [SetupFailure] en cas de refus ; la feuille reste alors ouverte et
/// affiche le message.
Future<SetupSheetResult?> showSetupSheet(
  BuildContext context, {
  required String title,
  required String nameLabel,
  required String nameHint,
  required String initialName,
  required bool withCapacity,
  required String submitLabel,
  required Future<void> Function(SetupValues values) onSubmit,
  int? initialCapacity,
  bool? initialInvitation,
  bool withPrice = false,
  int? initialPrice,
  bool withEntries = false,
  EntryPolicy initialEntryPolicy = EntryPolicy.single,
  int? initialMaxEntries,
  bool entriesLocked = false,
  Future<void> Function()? onDelete,
  String? deleteTitle,
  String? deleteBody,
}) => showModalBottomSheet<SetupSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _SetupSheet(
    title: title,
    nameLabel: nameLabel,
    nameHint: nameHint,
    initialName: initialName,
    withCapacity: withCapacity,
    initialCapacity: initialCapacity,
    initialInvitation: initialInvitation,
    withPrice: withPrice,
    initialPrice: initialPrice,
    withEntries: withEntries,
    initialEntryPolicy: initialEntryPolicy,
    initialMaxEntries: initialMaxEntries,
    entriesLocked: entriesLocked,
    submitLabel: submitLabel,
    onSubmit: onSubmit,
    onDelete: onDelete,
    deleteTitle: deleteTitle,
    deleteBody: deleteBody,
  ),
);

class _SetupSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.nameLabel,
    required this.nameHint,
    required this.initialName,
    required this.withCapacity,
    required this.submitLabel,
    required this.onSubmit,
    this.initialCapacity,
    this.initialInvitation,
    this.withPrice = false,
    this.initialPrice,
    this.withEntries = false,
    this.initialEntryPolicy = EntryPolicy.single,
    this.initialMaxEntries,
    this.entriesLocked = false,
    this.onDelete,
    this.deleteTitle,
    this.deleteBody,
  });

  final String title;
  final String nameLabel;
  final String nameHint;
  final String initialName;
  final bool withCapacity;
  final int? initialCapacity;

  /// `null` : pas de choix « invitation » (portes).
  final bool? initialInvitation;

  /// Champ « prix indicatif » (catégories).
  final bool withPrice;
  final int? initialPrice;

  /// Règle d'entrée (catégories) : une seule, une par jour ou N au total.
  final bool withEntries;
  final EntryPolicy initialEntryPolicy;
  final int? initialMaxEntries;

  /// Règle figée : des tickets de la catégorie sont déjà entrés.
  final bool entriesLocked;
  final String submitLabel;
  final Future<void> Function(SetupValues values) onSubmit;
  final Future<void> Function()? onDelete;
  final String? deleteTitle;
  final String? deleteBody;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _capacity = TextEditingController(
    text: widget.initialCapacity?.toString() ?? '',
  );
  late final _price = TextEditingController(
    text: widget.initialPrice?.toString() ?? '',
  );
  late final _maxEntries = TextEditingController(
    text: (widget.initialMaxEntries ?? 3).toString(),
  );
  late bool _invitation = widget.initialInvitation ?? false;
  late EntryPolicy _entryPolicy = widget.initialEntryPolicy;
  bool _busy = false;
  SetupFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _price.dispose();
    _maxEntries.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() action,
    SetupSheetResult result,
  ) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(result);
    } on SetupFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final text = _capacity.text.trim();
    final price = _price.text.trim();
    await _run(
      () => widget.onSubmit((
        name: _name.text,
        capacity: text.isEmpty ? null : int.parse(text),
        invitation: _invitation,
        price: !widget.withPrice || _invitation || price.isEmpty
            ? null
            : int.parse(price),
        entryPolicy: _entryPolicy,
        maxEntries: _entryPolicy == EntryPolicy.limited
            ? int.parse(_maxEntries.text.trim())
            : null,
      )),
      SetupSheetResult.saved,
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.deleteTitle ?? ''),
        content: Text(widget.deleteBody ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.setupCancel),
          ),
          FilledButton(
            key: const Key('setup-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.categoryDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(widget.onDelete!, SetupSheetResult.deleted);
    }
  }

  List<Widget> _entries(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locked = widget.entriesLocked;
    return [
      const SizedBox(height: TicketSurSpacing.md),
      Text(l10n.categoryEntriesLabel, style: theme.textTheme.titleSmall),
      const SizedBox(height: TicketSurSpacing.xs),
      SegmentedButton<EntryPolicy>(
        key: const Key('setup-entries'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: EntryPolicy.single,
            label: Text(
              l10n.categoryEntriesSingle,
              key: const Key('setup-entries-single'),
            ),
          ),
          ButtonSegment(
            value: EntryPolicy.perDay,
            label: Text(
              l10n.categoryEntriesPerDay,
              key: const Key('setup-entries-per-day'),
            ),
          ),
          ButtonSegment(
            value: EntryPolicy.limited,
            label: Text(
              l10n.categoryEntriesLimited,
              key: const Key('setup-entries-limited'),
            ),
          ),
        ],
        selected: {_entryPolicy},
        onSelectionChanged: _busy || locked
            ? null
            : (selection) => setState(() => _entryPolicy = selection.first),
      ),
      const SizedBox(height: TicketSurSpacing.xs),
      Text(
        locked
            ? l10n.categoryEntriesLocked
            : switch (_entryPolicy) {
                EntryPolicy.single => l10n.categoryEntriesHelpSingle,
                EntryPolicy.perDay => l10n.categoryEntriesHelpPerDay,
                EntryPolicy.limited => l10n.categoryEntriesHelpLimited,
              },
        key: const Key('setup-entries-help'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_entryPolicy == EntryPolicy.limited) ...[
        const SizedBox(height: TicketSurSpacing.sm),
        TextFormField(
          key: const Key('setup-max-entries'),
          controller: _maxEntries,
          enabled: !locked,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: l10n.categoryMaxEntriesLabel),
          validator: (value) {
            final number = int.tryParse((value ?? '').trim());
            return number == null ||
                    number < minPassEntries ||
                    number > maxPassEntries
                ? l10n.categoryMaxEntriesError(minPassEntries, maxPassEntries)
                : null;
          },
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: TicketSurSpacing.lg,
        right: TicketSurSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TicketSurSpacing.md),
            AnimatedSize(
              duration: TicketSurMotion.medium,
              child: _failure == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(
                        bottom: TicketSurSpacing.sm,
                      ),
                      child: Text(
                        setupFailureMessage(l10n, _failure!),
                        key: const Key('setup-error'),
                        style: TextStyle(color: colors.error),
                      ),
                    ),
            ),
            TextFormField(
              key: const Key('setup-name'),
              controller: _name,
              autofocus: widget.initialName.isEmpty,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: widget.withCapacity
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: widget.withCapacity
                  ? null
                  : (_) => unawaited(_submit()),
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                hintText: widget.nameHint,
              ),
              validator: (value) {
                final length = (value ?? '').trim().length;
                return length < 1 || length > 60 ? l10n.setupErrorName : null;
              },
            ),
            if (widget.withCapacity) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              TextFormField(
                key: const Key('setup-capacity'),
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.categoryQuotaLabel,
                  helperText: l10n.categoryQuotaHelp,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final number = int.tryParse(text);
                  return number == null || number < 1 || number > 1000000
                      ? l10n.setupErrorCapacity
                      : null;
                },
              ),
            ],
            if (widget.initialInvitation != null)
              SwitchListTile(
                key: const Key('setup-invitation'),
                contentPadding: EdgeInsets.zero,
                value: _invitation,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _invitation = value),
                title: Text(l10n.categoryInvitationLabel),
                subtitle: Text(l10n.categoryInvitationHelp),
              ),
            if (widget.withPrice && !_invitation) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              TextFormField(
                key: const Key('setup-price'),
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.categoryPriceLabel,
                  helperText: l10n.categoryPriceHelp,
                  suffixText: 'FCFA',
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final number = int.tryParse(text);
                  return number == null || number > 10000000
                      ? l10n.categoryPriceError
                      : null;
                },
              ),
            ],
            if (widget.withEntries) ..._entries(context),
            const SizedBox(height: TicketSurSpacing.lg),
            FilledButton(
              key: const Key('setup-submit'),
              onPressed: _busy ? null : () => unawaited(_submit()),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(widget.submitLabel),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: TicketSurSpacing.xs),
              TextButton.icon(
                key: const Key('setup-delete'),
                onPressed: _busy ? null : () => unawaited(_delete()),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.categoryDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
