import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/domain/cities.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_time.dart';
import 'package:ticketsur/features/events/presentation/event_copy.dart';
import 'package:ticketsur/features/events/presentation/event_cover.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Étapes de l'assistant.
enum _Step { info, whenWhere, cover, review }

/// Création (S08) ou modification d'un événement, en quatre étapes :
/// infos, date et lieu, photo, aperçu. Les heures sont saisies dans le
/// fuseau choisi puis converties en UTC (EVT-02) ; le serveur revérifie tout.
class EventFormPage extends ConsumerStatefulWidget {
  const new({this.eventId, super.key});

  /// Événement à modifier ; `null` pour une création.
  final String? eventId;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final Map<_Step, GlobalKey<FormState>> _formKeys = {
    for (final step in _Step.values) step: GlobalKey<FormState>(),
  };
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _capacity = TextEditingController();
  String _timezone = defaultEventTimeZone;
  EventKind _kind = EventKind.other;
  // Heures murales dans [_timezone].
  late DateTime _start;
  late DateTime _end;
  TicketEvent? _existing;
  CoverImage? _pickedCover;
  _Step _step = _Step.info;
  bool _forward = true;
  bool _initialized = false;
  bool _submitting = false;
  EventFailure? _failure;
  bool _datesError = false;

  bool get _editing => widget.eventId != null;

  void _initFrom(TicketEvent? event) {
    if (_initialized) return;
    _initialized = true;
    _existing = event;
    if (event != null) {
      _title.text = event.title;
      _description.text = event.description ?? '';
      _venue.text = event.venue ?? '';
      _address.text = event.venueAddress ?? '';
      _city.text = event.city ?? '';
      _capacity.text = event.capacity?.toString() ?? '';
      _timezone = event.timezone;
      _kind = event.kind;
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
    for (final controller in [
      _title,
      _description,
      _venue,
      _address,
      _city,
      _capacity,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Décalage du fuseau [zone] à la date de début saisie (heure d'été…).
  String _offsetOf(String zone) =>
      utcOffsetLabel(zone, instantFromWallTime(zone, _start));

  bool _datesValid() {
    final duration = _end.difference(_start);
    return duration > Duration.zero && duration <= EventDraft.maxDuration;
  }

  /// Valide l'étape affichée [step] et montre ses erreurs.
  bool _validate(_Step step) {
    final formValid = _formKeys[step]!.currentState?.validate() ?? true;
    if (step == _Step.whenWhere) {
      final datesValid = _datesValid();
      setState(() => _datesError = !datesValid);
      return formValid && datesValid;
    }
    return formValid;
  }

  /// Vrai si les saisies de [step] sont valides, même quand l'étape n'est
  /// pas affichée (seule l'étape courante est construite).
  bool _stepValid(_Step step, AppLocalizations l10n) => switch (step) {
    _Step.info =>
      _titleError(l10n, _title.text) == null &&
          _descriptionError(l10n, _description.text) == null,
    _Step.whenWhere =>
      _datesValid() &&
          _cityError(l10n, _city.text) == null &&
          _venueError(l10n, _venue.text) == null &&
          _addressError(l10n, _address.text) == null,
    _Step.cover => true,
    _Step.review => _capacityError(l10n, _capacity.text) == null,
  };

  static String? _titleError(AppLocalizations l10n, String? value) {
    final length = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').length;
    return length < 2 || length > 160 ? l10n.eventErrorTitle : null;
  }

  static String? _descriptionError(AppLocalizations l10n, String? value) =>
      (value ?? '').trim().length > EventDraft.maxDescription
      ? l10n.eventErrorDescription
      : null;

  static String? _cityError(AppLocalizations l10n, String? value) {
    final length = (value ?? '').trim().length;
    return length == 1 || length > 80 ? l10n.eventErrorCity : null;
  }

  static String? _venueError(AppLocalizations l10n, String? value) =>
      (value ?? '').trim().length > 160 ? l10n.eventErrorVenue : null;

  static String? _addressError(AppLocalizations l10n, String? value) =>
      (value ?? '').trim().length > 200 ? l10n.eventErrorAddress : null;

  static String? _capacityError(AppLocalizations l10n, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    return number == null || number < 1 || number > 1000000
        ? l10n.eventErrorCapacity
        : null;
  }

  void _goTo(_Step step) {
    if (step == _step) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(feedbackProvider).tap();
    setState(() {
      _forward = step.index > _step.index;
      _step = step;
    });
  }

  void _next() {
    if (!_validate(_step)) return;
    _goTo(_Step.values[_step.index + 1]);
  }

  void _back() {
    if (_step == _Step.info) {
      context.pop();
    } else {
      _goTo(_Step.values[_step.index - 1]);
    }
  }

  /// Étape où se corrige l'échec [failure].
  _Step _stepOf(EventFailure failure) => switch (failure) {
    EventFailure.titleInvalid || EventFailure.descriptionInvalid => _Step.info,
    EventFailure.datesInvalid ||
    EventFailure.timezoneInvalid ||
    EventFailure.venueInvalid ||
    EventFailure.cityInvalid ||
    EventFailure.addressInvalid ||
    EventFailure.alreadyEnded => _Step.whenWhere,
    EventFailure.coverInvalid || EventFailure.incomplete => _Step.cover,
    _ => _Step.review,
  };

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

  Future<void> _pickCover(CoverSource source) async {
    final l10n = context.l10n;
    final CoverImage? image;
    try {
      image = await ref.read(coverPickerProvider)(source);
    } on Object {
      if (mounted) Toaster.of(context).error(l10n.eventErrorCover);
      return;
    }
    if (image == null || !mounted) return;
    if (!acceptedCoverTypes.contains(image.mimeType) ||
        image.bytes.length > CoverImage.maxBytes) {
      Toaster.of(context).error(l10n.eventErrorCover);
      return;
    }
    setState(() {
      _pickedCover = image;
      if (_failure == EventFailure.coverInvalid) _failure = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    // Toutes les étapes sont revérifiées ; on montre la première en défaut.
    final l10nCheck = context.l10n;
    if (!_validate(_step)) return;
    for (final step in _Step.values) {
      if (!_stepValid(step, l10nCheck)) {
        _goTo(step);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _validate(step);
        });
        return;
      }
    }
    final capacityText = _capacity.text.trim();
    final draft = EventDraft(
      title: _title.text,
      description: _description.text,
      kind: _kind,
      venue: _venue.text,
      venueAddress: _address.text,
      city: _city.text,
      timezone: _timezone,
      startsAt: instantFromWallTime(_timezone, _start),
      endsAt: instantFromWallTime(_timezone, _end),
      capacity: capacityText.isEmpty ? null : int.parse(capacityText),
    );
    setState(() {
      _submitting = true;
      _failure = null;
    });
    final l10n = context.l10n;
    final toaster = Toaster.of(context);
    final controller = ref.read(eventsProvider.notifier);
    try {
      final saved = _editing
          ? await controller.edit(widget.eventId!, draft)
          : await controller.create(draft);
      var coverFailed = false;
      if (_pickedCover case final cover?) {
        try {
          await controller.setCover(saved.id, cover);
        } on EventFailure {
          coverFailed = true;
        }
      }
      if (!mounted) return;
      if (coverFailed) {
        toaster.error(l10n.eventCoverUploadFailed);
      } else {
        toaster.success(
          _editing ? l10n.eventSaved : l10n.eventCreated(saved.title),
        );
      }
      if (_editing) {
        context.pop();
      } else {
        // La fiche remplace le formulaire : Retour ramène à la liste.
        context.pushReplacement(AppRoutes.eventDetail(saved.id));
      }
    } on EventFailure catch (failure) {
      if (!mounted) return;
      setState(() => _failure = failure);
      _goTo(_stepOf(failure));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
    final isLast = _step == _Step.review;
    return PopScope(
      // Retour système : étape précédente plutôt que sortie du formulaire.
      canPop: _step == _Step.info,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _editing ? l10n.eventFormEditTitle : l10n.eventFormCreateTitle,
          ),
          actions: [
            if (_editing && !isLast)
              TextButton(
                key: const Key('event-save-now'),
                onPressed: _submitting ? null : _submit,
                child: Text(l10n.eventFormSubmitSave),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: _StepHeader(
              current: _step,
              // En modification, chaque étape est accessible directement.
              onTap: _editing ? _goTo : null,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(_step);
              final dx = (incoming == _forward) ? 0.12 : -0.12;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            // Seule l'étape courante est construite ; les saisies vivent
            // dans les contrôleurs de l'état et sont donc conservées.
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _buildStep(context, _step),
            ),
          ),
        ),
        bottomNavigationBar: _BottomBar(
          isFirst: _step == _Step.info,
          isLast: isLast,
          editing: _editing,
          submitting: _submitting,
          onBack: _back,
          onNext: _next,
          onSubmit: _submit,
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, _Step step) {
    final children = switch (step) {
      _Step.info => _infoFields(context),
      _Step.whenWhere => _whenWhereFields(context),
      _Step.cover => _coverFields(context),
      _Step.review => _reviewFields(context),
    };
    return Form(
      key: _formKeys[step],
      child: SingleChildScrollView(
        key: Key('event-step-${step.name}'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failure case final failure?)
              FadeSlideIn(child: _ErrorCard(failure: failure)),
            ...children,
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- étape 1
  List<Widget> _infoFields(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return [
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
        validator: (value) => _titleError(l10n, value),
      ),
      const SizedBox(height: TicketSurSpacing.sm),
      Text(l10n.eventKindLabel, style: textTheme.titleSmall),
      const SizedBox(height: TicketSurSpacing.sm),
      Wrap(
        spacing: TicketSurSpacing.sm,
        runSpacing: TicketSurSpacing.sm,
        children: [
          for (final kind in EventKind.values)
            ChoiceChip(
              key: Key('event-kind-${kind.wireName}'),
              avatar: Icon(eventKindIcon(kind), size: 18),
              label: Text(eventKindLabel(l10n, kind)),
              selected: _kind == kind,
              showCheckmark: false,
              onSelected: (_) {
                ref.read(feedbackProvider).tap();
                setState(() => _kind = kind);
              },
            ),
        ],
      ),
      const SizedBox(height: TicketSurSpacing.lg),
      TextFormField(
        key: const Key('event-description'),
        controller: _description,
        minLines: 4,
        maxLines: 10,
        maxLength: EventDraft.maxDescription,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: l10n.eventDescriptionLabel,
          hintText: l10n.eventDescriptionHint,
          alignLabelWithHint: true,
        ),
        validator: (value) => _descriptionError(l10n, value),
      ),
    ];
  }

  // ---------------------------------------------------------------- étape 2
  List<Widget> _whenWhereFields(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final zones = [
      ...eventTimeZones,
      if (!eventTimeZones.any((z) => z.id == _timezone))
        (id: _timezone, label: _timezone),
    ];
    return [
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
                padding: const EdgeInsets.only(top: TicketSurSpacing.xs),
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
      const SizedBox(height: TicketSurSpacing.md),
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
      _CityField(
        controller: _city,
        validator: (value) => _cityError(l10n, value),
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
        validator: (value) => _venueError(l10n, value),
      ),
      const SizedBox(height: TicketSurSpacing.xs),
      TextFormField(
        key: const Key('event-address'),
        controller: _address,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 200,
        decoration: InputDecoration(
          labelText: l10n.eventAddressLabel,
          hintText: l10n.eventAddressHint,
          prefixIcon: const Icon(Icons.signpost_outlined),
        ),
        validator: (value) => _addressError(l10n, value),
      ),
    ];
  }

  // ---------------------------------------------------------------- étape 3
  List<Widget> _coverFields(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final hasCover = _pickedCover != null || _existing?.coverUrl != null;
    return [
      Text(l10n.eventCoverTitle, style: textTheme.titleMedium),
      const SizedBox(height: TicketSurSpacing.xs),
      Text(l10n.eventCoverHelp, style: textTheme.bodyMedium),
      const SizedBox(height: TicketSurSpacing.md),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: EventCover(
          key: ValueKey(_pickedCover?.bytes.hashCode ?? _existing?.coverUrl),
          kind: _kind,
          url: _existing?.coverUrl,
          bytes: _pickedCover?.bytes,
          borderRadius: BorderRadius.circular(TicketSurRadii.md),
          overlay: hasCover
              ? null
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(TicketSurSpacing.sm),
                    child: Text(
                      l10n.eventCoverEmpty,
                      style: textTheme.bodyMedium?.copyWith(
                        color: TicketSurColors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
      const SizedBox(height: TicketSurSpacing.md),
      Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              key: const Key('event-cover-gallery'),
              onPressed: () => _pickCover(CoverSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.eventCoverGallery),
            ),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: FilledButton.tonalIcon(
              key: const Key('event-cover-camera'),
              onPressed: () => _pickCover(CoverSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.eventCoverCamera),
            ),
          ),
        ],
      ),
      if (_pickedCover != null) ...[
        const SizedBox(height: TicketSurSpacing.xs),
        Align(
          child: TextButton.icon(
            key: const Key('event-cover-remove'),
            onPressed: () => setState(() => _pickedCover = null),
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.eventCoverRemove),
          ),
        ),
      ],
      if (!_editing && !hasCover) ...[
        const SizedBox(height: TicketSurSpacing.sm),
        Text(
          l10n.eventCoverLater,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
      ],
    ];
  }

  // ---------------------------------------------------------------- étape 4
  List<Widget> _reviewFields(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final city = _city.text.trim();
    final venue = _venue.text.trim();
    final hasCover = _pickedCover != null || _existing?.coverUrl != null;
    final missing = [
      if (!hasCover) l10n.eventMissingCover,
      if (city.isEmpty) l10n.eventMissingCity,
    ];
    final place = [venue, city].where((part) => part.isNotEmpty).join(' · ');
    return [
      Text(l10n.eventReviewTitle, style: textTheme.titleMedium),
      const SizedBox(height: TicketSurSpacing.xs),
      Text(l10n.eventReviewHint, style: textTheme.bodyMedium),
      const SizedBox(height: TicketSurSpacing.md),
      Card(
        key: const Key('event-review-card'),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EventCover(
              kind: _kind,
              url: _existing?.coverUrl,
              bytes: _pickedCover?.bytes,
            ),
            Padding(
              padding: const EdgeInsets.all(TicketSurSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventKindLabel(l10n, _kind).toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: context.palette.accentText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: TicketSurSpacing.xs),
                  Text(
                    _title.text.trim().replaceAll(RegExp(r'\s+'), ' '),
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: TicketSurSpacing.sm),
                  _ReviewLine(
                    icon: Icons.event_rounded,
                    text:
                        '${formatEventDay(_start)} · '
                        '${formatEventTime(_start)} – ${formatEventTime(_end)}',
                  ),
                  _ReviewLine(
                    icon: Icons.place_outlined,
                    text: place.isEmpty ? l10n.eventCityMissing : place,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (missing.isNotEmpty) ...[
        const SizedBox(height: TicketSurSpacing.md),
        _MissingCard(items: missing),
      ],
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
        validator: (value) => _capacityError(l10n, value),
      ),
    ];
  }
}

/// Barre de progression : quatre segments et le nom de l'étape.
class _StepHeader extends StatelessWidget {
  const new({required this.current, this.onTap});

  final _Step current;
  final ValueChanged<_Step>? onTap;

  static String _label(AppLocalizations l10n, _Step step) => switch (step) {
    _Step.info => l10n.eventStepInfo,
    _Step.whenWhere => l10n.eventStepWhenWhere,
    _Step.cover => l10n.eventStepCover,
    _Step.review => l10n.eventStepReview,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        TicketSurSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final step in _Step.values) ...[
                if (step.index > 0) const SizedBox(width: TicketSurSpacing.xs),
                Expanded(
                  child: Semantics(
                    button: onTap != null,
                    label: _label(l10n, step),
                    child: GestureDetector(
                      key: Key('event-step-tab-${step.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap == null ? null : () => onTap!(step),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: 6,
                          decoration: BoxDecoration(
                            color: step.index <= current.index
                                ? scheme.secondary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${l10n.eventStepCounter(current.index + 1, _Step.values.length)}'
              ' · ${_label(l10n, current)}',
              key: ValueKey(current),
              style: textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const new({
    required this.isFirst,
    required this.isLast,
    required this.editing,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isFirst;
  final bool isLast;
  final bool editing;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TicketSurSpacing.md,
            TicketSurSpacing.sm,
            TicketSurSpacing.md,
            TicketSurSpacing.sm,
          ),
          child: Row(
            children: [
              if (!isFirst) ...[
                Expanded(
                  child: OutlinedButton(
                    key: const Key('event-back'),
                    onPressed: submitting ? null : onBack,
                    child: Text(l10n.eventStepBack),
                  ),
                ),
                const SizedBox(width: TicketSurSpacing.sm),
              ],
              Expanded(
                flex: 2,
                child: isLast
                    ? FilledButton(
                        key: const Key('event-submit'),
                        onPressed: submitting ? null : onSubmit,
                        child: submitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                editing
                                    ? l10n.eventFormSubmitSave
                                    : l10n.eventFormSubmitCreate,
                              ),
                      )
                    : FilledButton.icon(
                        key: const Key('event-next'),
                        onPressed: submitting ? null : onNext,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.eventStepNext),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ville : saisie libre avec suggestions des villes du Burkina Faso.
class _CityField extends StatefulWidget {
  const new({required this.controller, required this.validator});

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  State<_CityField> createState() => _CityFieldState();
}

class _CityFieldState extends State<_CityField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        if (!_focusNode.hasFocus) return const <String>[];
        final options = suggestCities(value.text);
        // Rien à proposer si la saisie est déjà une ville de la liste.
        return options.length == 1 &&
                foldAccents(options.single) == foldAccents(value.text.trim())
            ? const <String>[]
            : options;
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) =>
          TextFormField(
            key: const Key('event-city'),
            controller: textController,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: l10n.eventCityLabel,
              hintText: l10n.eventCityHint,
              helperText: l10n.eventCityHelp,
              prefixIcon: const Icon(Icons.location_city_rounded),
            ),
            validator: widget.validator,
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(TicketSurRadii.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final city in options)
                  ListTile(
                    key: Key('event-city-option-$city'),
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(city),
                    onTap: () => onSelected(city),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const new({required this.failure});

  final EventFailure failure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('event-error'),
      color: scheme.errorContainer,
      margin: const EdgeInsets.only(bottom: TicketSurSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: TicketSurSpacing.sm),
            Expanded(
              child: Text(
                eventFailureMessage(context.l10n, failure),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste de ce qui manque pour publier.
class _MissingCard extends StatelessWidget {
  const new({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const Key('event-missing'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.warningContainer,
        borderRadius: BorderRadius.circular(TicketSurRadii.md),
        border: Border.all(color: context.palette.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: context.palette.warningText),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.eventToCompleteTitle,
                  style: textTheme.titleSmall,
                ),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• $item', style: textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TicketSurSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.palette.accentText),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
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
