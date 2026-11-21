import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/domain/event.dart' show EventKind;
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/org_settings/application/org_settings_providers.dart';
import 'package:ticketsur/features/org_settings/domain/org_settings.dart';
import 'package:ticketsur/features/ticket_send/application/send_providers.dart'
    show firstNameOf;
import 'package:ticketsur/l10n/l10n.dart';

/// Texte d'un échec des réglages.
String orgSettingsFailureMessage(
  AppLocalizations l10n,
  OrgSettingsFailure failure,
) => switch (failure) {
  OrgSettingsFailure.network => l10n.orgSettingsErrorNetwork,
  OrgSettingsFailure.forbidden => l10n.orgSettingsErrorForbidden,
  OrgSettingsFailure.message => l10n.orgSettingsErrorMessage,
  OrgSettingsFailure.timezone => l10n.orgSettingsErrorTimezone,
  OrgSettingsFailure.city => l10n.orgSettingsErrorCity,
  OrgSettingsFailure.categories => l10n.orgSettingsErrorCategories,
  OrgSettingsFailure.checkpoints => l10n.orgSettingsErrorCheckpoints,
  OrgSettingsFailure.unknown => l10n.orgSettingsErrorUnknown,
};

String _fieldLabel(AppLocalizations l10n, MessageField field) =>
    switch (field) {
      MessageField.firstName => l10n.orgSettingsFieldFirstName,
      MessageField.event => l10n.orgSettingsFieldEvent,
      MessageField.date => l10n.orgSettingsFieldDate,
      MessageField.place => l10n.orgSettingsFieldPlace,
      MessageField.category => l10n.orgSettingsFieldCategory,
    };

/// Réglages de la structure active (propriétaire et gestionnaires) : message
/// d'envoi et valeurs d'un nouvel événement, partagés par toute l'équipe.
class OrgSettingsPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OrgSettingsPage> createState() => _OrgSettingsPageState();
}

class _OrgSettingsPageState extends ConsumerState<OrgSettingsPage> {
  final _ticket = TextEditingController();
  final _invitation = TextEditingController();
  final _city = TextEditingController();
  final _door = TextEditingController();
  String? _timezone;
  EventKind? _kind;
  List<DefaultCategory> _categories = [];
  List<String> _doors = [];
  bool _initialized = false;
  bool _saving = false;
  String? _doorError;

  @override
  void initState() {
    super.initState();
    // L'aperçu suit la saisie.
    for (final controller in [_ticket, _invitation]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final controller in [_ticket, _invitation, _city, _door]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initFrom(OrgSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _ticket.text = settings.ticketMessage ?? '';
    _invitation.text = settings.invitationMessage ?? '';
    _city.text = settings.defaultCity ?? '';
    _timezone = settings.defaultTimezone;
    _kind = settings.defaultKind;
    _categories = [...settings.defaultCategories];
    _doors = [...settings.defaultCheckpoints];
  }

  static String? _text(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final city = _text(_city);
    if (city != null && city.length < 2) {
      toast.error(l10n.orgSettingsErrorCity);
      return;
    }
    setState(() => _saving = true);
    try {
      await saveOrgSettings(
        ref,
        OrgSettings(
          ticketMessage: _text(_ticket),
          invitationMessage: _text(_invitation),
          defaultTimezone: _timezone,
          defaultCity: city,
          defaultKind: _kind,
          defaultCategories: _categories,
          defaultCheckpoints: _doors,
        ),
      );
      toast.success(l10n.orgSettingsSaved);
      if (mounted) context.popOr(AppRoutes.profile);
    } on OrgSettingsFailure catch (failure) {
      toast.error(orgSettingsFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addDoor() {
    final l10n = context.l10n;
    final name = _door.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    String? error;
    if (name.isEmpty || name.length > 60) {
      error = l10n.orgSettingsNameInvalid;
    } else if (_doors.any((d) => d.toLowerCase() == name.toLowerCase())) {
      error = l10n.orgSettingsNameTaken;
    } else if (_doors.length >= maxDefaultItems) {
      error = l10n.orgSettingsMaxItems;
    }
    setState(() {
      _doorError = error;
      if (error == null) {
        _doors = [..._doors, name];
        _door.clear();
      }
    });
  }

  Future<void> _editCategory([int? index]) async {
    final result = await showModalBottomSheet<DefaultCategory>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CategorySheet(
        initial: index == null ? null : _categories[index],
        taken: {
          for (final (i, c) in _categories.indexed)
            if (i != index) c.name.toLowerCase(),
        },
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _categories = [..._categories];
      if (index == null) {
        _categories.add(result);
      } else {
        _categories[index] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(orgSettingsProvider);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.orgSettingsTitle)),
      body: SafeArea(
        child: switch (settings) {
          AsyncData(:final value) => _form(context, value),
          AsyncError() => Center(
            child: Padding(
              padding: const EdgeInsets.all(TicketSurSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.orgSettingsLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: TicketSurSpacing.md),
                  FilledButton.tonal(
                    key: const Key('org-settings-retry'),
                    onPressed: () => ref.invalidate(orgSettingsProvider),
                    child: Text(l10n.orgRetry),
                  ),
                ],
              ),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _form(BuildContext context, OrgSettings settings) {
    _initFrom(settings);
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final zones = [
      ...eventTimeZones,
      if (_timezone case final zone?
          when !eventTimeZones.any((z) => z.id == zone))
        (id: zone, label: zone),
    ];
    // Page courte : tout est construit (pas de liste paresseuse).
    return SingleChildScrollView(
      key: const Key('org-settings-list'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.orgSettingsMessageTitle,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(l10n.orgSettingsMessageHelp, style: textTheme.bodySmall),
                const SizedBox(height: TicketSurSpacing.md),
                _MessageEditor(
                  id: 'ticket',
                  controller: _ticket,
                  label: l10n.orgSettingsTicketLabel,
                  defaultPreview: l10n.sendMessageNamed(
                    _sampleName,
                    _sampleEvent,
                    l10n.orgSettingsSampleDate,
                    ' — $_samplePlace',
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                _MessageEditor(
                  id: 'invitation',
                  controller: _invitation,
                  label: l10n.orgSettingsInvitationLabel,
                  defaultPreview: l10n.invitationMessageNamed(
                    _sampleName,
                    _sampleEvent,
                    l10n.orgSettingsSampleDate,
                    ' — $_samplePlace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          TikeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.orgSettingsDefaultsTitle,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Text(l10n.orgSettingsDefaultsHelp, style: textTheme.bodySmall),
                const SizedBox(height: TicketSurSpacing.md),
                DropdownButtonFormField<String?>(
                  key: const Key('org-settings-timezone'),
                  initialValue: _timezone,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.eventTimezoneLabel,
                    prefixIcon: const Icon(Icons.public_rounded),
                  ),
                  items: [
                    DropdownMenuItem(child: Text(l10n.orgSettingsNone)),
                    for (final zone in zones)
                      DropdownMenuItem(
                        value: zone.id,
                        child: Text(
                          zone.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (zone) => setState(() => _timezone = zone),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                TextField(
                  key: const Key('org-settings-city'),
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: l10n.orgCityLabel,
                    hintText: l10n.eventCityHint,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                ),
                DropdownButtonFormField<EventKind?>(
                  key: const Key('org-settings-kind'),
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.eventKindLabel,
                    prefixIcon: const Icon(Icons.category_rounded),
                  ),
                  items: [
                    DropdownMenuItem(child: Text(l10n.orgSettingsNone)),
                    for (final kind in EventKind.values)
                      DropdownMenuItem(
                        value: kind,
                        child: Text(eventKindLabel(l10n, kind)),
                      ),
                  ],
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                Text(l10n.orgSettingsCategories, style: textTheme.titleSmall),
                for (final (index, category) in _categories.indexed)
                  ListTile(
                    key: Key('org-settings-category-$index'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      category.invitation
                          ? Icons.card_giftcard_rounded
                          : Icons.confirmation_number_rounded,
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      [
                        if (category.capacity case final count?)
                          l10n.orgSettingsQuota(count)
                        else
                          l10n.orgSettingsUnlimited,
                        if (category.price case final price?)
                          l10n.orgSettingsPrice(price),
                        if (category.invitation) l10n.orgSettingsInvitationTag,
                      ].join(' · '),
                    ),
                    onTap: () => _editCategory(index),
                    trailing: IconButton(
                      key: Key('org-settings-category-remove-$index'),
                      tooltip: l10n.orgSettingsRemove,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(
                        () => _categories = [..._categories]..removeAt(index),
                      ),
                    ),
                  ),
                if (_categories.length < maxDefaultItems)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('org-settings-category-add'),
                      onPressed: _editCategory,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.orgSettingsAddCategory),
                    ),
                  ),
                const SizedBox(height: TicketSurSpacing.md),
                Text(l10n.orgSettingsCheckpoints, style: textTheme.titleSmall),
                const SizedBox(height: TicketSurSpacing.sm),
                Wrap(
                  spacing: TicketSurSpacing.sm,
                  runSpacing: TicketSurSpacing.sm,
                  children: [
                    for (final (index, door) in _doors.indexed)
                      InputChip(
                        key: Key('org-settings-door-$index'),
                        label: Text(door),
                        onDeleted: () => setState(
                          () => _doors = [..._doors]..removeAt(index),
                        ),
                        deleteButtonTooltipMessage: l10n.orgSettingsRemove,
                      ),
                  ],
                ),
                if (_doors.length < maxDefaultItems)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('org-settings-door-field'),
                          controller: _door,
                          maxLength: 60,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: l10n.orgSettingsCheckpointName,
                            errorText: _doorError,
                          ),
                          onSubmitted: (_) => _addDoor(),
                        ),
                      ),
                      const SizedBox(width: TicketSurSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton.tonal(
                          key: const Key('org-settings-door-add'),
                          // Boutons pleine largeur par défaut : pas dans une
                          // ligne.
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _addDoor,
                          child: Text(l10n.orgSettingsAdd),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
          FilledButton(
            key: const Key('org-settings-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(l10n.profileSave),
          ),
          const SizedBox(height: TicketSurSpacing.lg),
        ],
      ),
    );
  }
}

const _sampleName = 'Aïcha Ouédraogo';
const _sampleEvent = 'Nuit du Djembé';
const _samplePlace = 'Maison du Peuple, Ouagadougou';

/// Champ d'un message : saisie, champs à insérer, aperçu, retour au défaut.
class _MessageEditor extends StatelessWidget {
  const new({
    required this.id,
    required this.controller,
    required this.label,
    required this.defaultPreview,
  });

  final String id;
  final TextEditingController controller;
  final String label;
  final String defaultPreview;

  void _insert(MessageField field) {
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(
      selection.start,
      selection.end,
      field.token,
    );
    if (text.length > maxSendMessageLength) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.start + field.token.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final template = controller.text.trim();
    final preview = template.isEmpty
        ? defaultPreview
        : fillSendMessage(
            template,
            firstName: firstNameOf(_sampleName),
            event: _sampleEvent,
            date: l10n.orgSettingsSampleDate,
            place: _samplePlace,
            category: 'VIP',
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key('org-settings-$id-message'),
          controller: controller,
          minLines: 3,
          maxLines: 8,
          maxLength: maxSendMessageLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.orgSettingsMessageHint,
            alignLabelWithHint: true,
          ),
        ),
        Text(l10n.orgSettingsInsertField, style: textTheme.labelMedium),
        const SizedBox(height: TicketSurSpacing.xs),
        Wrap(
          spacing: TicketSurSpacing.xs,
          runSpacing: TicketSurSpacing.xs,
          children: [
            for (final field in MessageField.values)
              ActionChip(
                key: Key('org-settings-$id-insert-${field.name}'),
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: Text(_fieldLabel(l10n, field)),
                onPressed: () => _insert(field),
              ),
          ],
        ),
        const SizedBox(height: TicketSurSpacing.sm),
        Text(l10n.orgSettingsPreview, style: textTheme.labelMedium),
        const SizedBox(height: TicketSurSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.sm),
            child: Text(
              preview,
              key: Key('org-settings-$id-preview'),
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        if (template.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: Key('org-settings-$id-reset'),
              onPressed: controller.clear,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.orgSettingsResetMessage),
            ),
          ),
      ],
    );
  }
}

/// Saisie d'une catégorie proposée.
class _CategorySheet extends StatefulWidget {
  const new({required this.taken, this.initial});

  final DefaultCategory? initial;

  /// Noms déjà utilisés (en minuscules).
  final Set<String> taken;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _capacity = TextEditingController(
    text: widget.initial?.capacity?.toString(),
  );
  late final _price = TextEditingController(
    text: widget.initial?.price?.toString(),
  );
  late bool _invitation = widget.initial?.invitation ?? false;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      DefaultCategory(
        name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        capacity: int.tryParse(_capacity.text.trim()),
        price: int.tryParse(_price.text.trim()),
        invitation: _invitation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + TicketSurSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.orgSettingsEditCategory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: TicketSurSpacing.md),
              TextFormField(
                key: const Key('org-settings-category-name'),
                controller: _name,
                autofocus: widget.initial == null,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.orgSettingsCategoryName,
                ),
                validator: (value) {
                  final name = (value ?? '').trim();
                  if (name.isEmpty || name.length > 60) {
                    return l10n.orgSettingsNameInvalid;
                  }
                  if (widget.taken.contains(
                    name.replaceAll(RegExp(r'\s+'), ' ').toLowerCase(),
                  )) {
                    return l10n.orgSettingsNameTaken;
                  }
                  return null;
                },
              ),
              TextFormField(
                key: const Key('org-settings-category-capacity'),
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.orgSettingsCategoryCapacity,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final count = int.tryParse(text);
                  return count == null || count < 1 || count > 1000000
                      ? l10n.orgSettingsCapacityInvalid
                      : null;
                },
              ),
              const SizedBox(height: TicketSurSpacing.md),
              TextFormField(
                key: const Key('org-settings-category-price'),
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.orgSettingsCategoryPrice,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final price = int.tryParse(text);
                  return price == null || price > 10000000
                      ? l10n.orgSettingsPriceInvalid
                      : null;
                },
              ),
              SwitchListTile(
                key: const Key('org-settings-category-invitation'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.orgSettingsCategoryInvitation),
                value: _invitation,
                onChanged: (value) => setState(() => _invitation = value),
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              FilledButton(
                key: const Key('org-settings-category-submit'),
                onPressed: _submit,
                child: Text(l10n.profileSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
