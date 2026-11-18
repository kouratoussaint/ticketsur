import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Création (S08) ou modification d'un événement. Les heures sont saisies
/// dans le fuseau choisi puis converties en UTC (EVT-02) ; le serveur
/// revérifie tout.
class EventFormPage extends ConsumerStatefulWidget {
  const new({this.eventId, super.key});

  /// Événement à modifier ; `null` pour une création.
  final String? eventId;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _venue = TextEditingController();
  final _capacity = TextEditingController();
  String _timezone = defaultEventTimeZone;
  // Heures murales dans [_timezone].
  late DateTime _start;
  late DateTime _end;
  bool _initialized = false;
  bool _submitting = false;
  EventFailure? _failure;
  bool _datesError = false;

  bool get _editing => widget.eventId != null;

  void _initFrom(TicketEvent? event) {
    if (_initialized) return;
    _initialized = true;
    if (event != null) {
      _title.text = event.title;
      _venue.text = event.venue ?? '';
      _capacity.text = event.capacity?.toString() ?? '';
      _timezone = event.timezone;
      _start = wallTimeIn(event.timezone, event.startsAt);
      _end = wallTimeIn(event.timezone, event.endsAt);
    } else {
      // Par défaut : demain, 18:00 → 23:00, heure de Ouagadougou.
      final now = wallTimeIn(_timezone, DateTime.now());
      _start = DateTime(now.year, now.month, now.day + 1, 18);
      _end = DateTime(now.year, now.month, now.day + 1, 23);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    _capacity.dispose();
    super.dispose();
  }

  /// Décalage du fuseau [zone] à la date de début saisie (heure d'été…).
  String _offsetOf(String zone) =>
      utcOffsetLabel(zone, instantFromWallTime(zone, _start));

  bool _datesValid() {
    final duration = _end.difference(_start);
    return duration > Duration.zero && duration <= EventDraft.maxDuration;
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _start : _end;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final next = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (start) {
        // Déplacer le début déplace la fin d'autant (durée conservée).
        final length = _end.difference(_start);
        _start = next;
        _end = next.add(length);
      } else {
        _end = next;
      }
      _datesError = false;
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final next = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (start) {
        final length = _end.difference(_start);
        _start = next;
        _end = next.add(length);
      } else {
        _end = next;
      }
      _datesError = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    final datesValid = _datesValid();
    setState(() {
      _failure = null;
      _datesError = !datesValid;
    });
    if (!formValid || !datesValid) return;
    final capacityText = _capacity.text.trim();
    final draft = EventDraft(
      title: _title.text,
      venue: _venue.text,
      timezone: _timezone,
      startsAt: instantFromWallTime(_timezone, _start),
      endsAt: instantFromWallTime(_timezone, _end),
      capacity: capacityText.isEmpty ? null : int.parse(capacityText),
    );
    setState(() => _submitting = true);
    final l10n = context.l10n;
    final controller = ref.read(eventsProvider.notifier);
    try {
      final saved = _editing
          ? await controller.edit(widget.eventId!, draft)
          : await controller.create(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing ? l10n.eventSaved : l10n.eventCreated(saved.title),
          ),
        ),
      );
      if (_editing) {
        context.pop();
      } else {
        // La fiche remplace le formulaire : Retour ramène à la liste.
        context.pushReplacement(AppRoutes.eventDetail(saved.id));
      }
    } on EventFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final existing = _editing
        ? ref.watch(eventByIdProvider(widget.eventId!))
        : null;
    if (_editing && existing == null) {
      // Liste pas encore chargée (lien direct) : on attend.
      ref.watch(eventsProvider);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.eventFormEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _initFrom(existing);
    final zones = [
      ...eventTimeZones,
      if (!eventTimeZones.any((z) => z.id == _timezone))
        (id: _timezone, label: _timezone),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? l10n.eventFormEditTitle : l10n.eventFormCreateTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // Colonne défilante plutôt que ListView : tous les champs sont
          // construits, donc tous validés, même hors de l'écran.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_failure case final failure?)
                  FadeSlideIn(
                    child: Card(
                      key: const Key('event-error'),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(TicketSurSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: TicketSurSpacing.sm),
                            Expanded(
                              child: Text(
                                eventFailureMessage(l10n, failure),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                TextFormField(
                  key: const Key('event-title'),
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 160,
                  decoration: InputDecoration(
                    labelText: l10n.eventTitleLabel,
                    hintText: l10n.eventTitleHint,
                  ),
                  validator: (value) {
                    final length = (value ?? '')
                        .trim()
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .length;
                    return length < 2 || length > 160
                        ? l10n.eventErrorTitle
                        : null;
                  },
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                TextFormField(
                  key: const Key('event-venue'),
                  controller: _venue,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 160,
                  decoration: InputDecoration(
                    labelText: l10n.eventVenueLabel,
                    hintText: l10n.eventVenueHint,
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().length > 160
                      ? l10n.eventErrorVenue
                      : null,
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                DropdownButtonFormField<String>(
                  key: const Key('event-timezone'),
                  initialValue: _timezone,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.eventTimezoneLabel,
                    helperText: l10n.eventTimezoneHelp,
                    prefixIcon: const Icon(Icons.public_rounded),
                  ),
                  items: [
                    for (final zone in zones)
                      DropdownMenuItem(
                        value: zone.id,
                        child: Text(
                          '${zone.label} · ${_offsetOf(zone.id)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (zone) {
                    // Heures saisies inchangées, dans le nouveau fuseau.
                    if (zone != null) setState(() => _timezone = zone);
                  },
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                _DateTimeRow(
                  label: l10n.eventStartsLabel,
                  value: _start,
                  keyPrefix: 'event-start',
                  onPickDate: () => _pickDate(start: true),
                  onPickTime: () => _pickTime(start: true),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                _DateTimeRow(
                  label: l10n.eventEndsLabel,
                  value: _end,
                  keyPrefix: 'event-end',
                  onPickDate: () => _pickDate(start: false),
                  onPickTime: () => _pickTime(start: false),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _datesError
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: TicketSurSpacing.xs,
                          ),
                          child: Text(
                            l10n.eventErrorDates,
                            key: const Key('event-dates-error'),
                            style: textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: TicketSurSpacing.lg),
                TextFormField(
                  key: const Key('event-capacity'),
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.eventCapacityLabel,
                    hintText: l10n.eventCapacityHint,
                    prefixIcon: const Icon(Icons.people_outline_rounded),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final number = int.tryParse(text);
                    return number == null || number < 1 || number > 1000000
                        ? l10n.eventErrorCapacity
                        : null;
                  },
                ),
                const SizedBox(height: TicketSurSpacing.xl),
                FilledButton(
                  key: const Key('event-submit'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          _editing
                              ? l10n.eventFormSubmitSave
                              : l10n.eventFormSubmitCreate,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.keyPrefix,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String label;
  final DateTime value;
  final String keyPrefix;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: TicketSurSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _PickerField(
                key: Key('$keyPrefix-date'),
                label: l10n.eventDateLabel,
                icon: Icons.calendar_today_rounded,
                text: formatEventDay(value),
                onTap: onPickDate,
              ),
            ),
            const SizedBox(width: TicketSurSpacing.sm),
            Expanded(
              flex: 2,
              child: _PickerField(
                key: Key('$keyPrefix-time'),
                label: l10n.eventTimeLabel,
                icon: Icons.schedule_rounded,
                text: formatEventTime(value),
                onTap: onPickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.text,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TicketSurRadii.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
