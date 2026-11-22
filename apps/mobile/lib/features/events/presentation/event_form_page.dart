import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/feedback/feedback.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
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
import 'package:ticketsur/features/org_settings/application/org_settings_providers.dart';
import 'package:ticketsur/features/org_settings/domain/org_settings.dart';
import 'package:ticketsur/l10n/l10n.dart';

part 'event_form_fields.dart';
part 'event_form_widgets.dart';

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
  final _tagline = TextEditingController();
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
  // Réglages de la structure : valeurs d'un nouvel événement.
  OrgSettings _settings = const OrgSettings();
  bool _seeded = false;
  bool _applyDefaults = true;

  bool get _editing => widget.eventId != null;

  /// `setState` pour les champs découpés dans `event_form_fields.dart`.
  void _update(VoidCallback change) => setState(change);

  @override
  void initState() {
    super.initState();
    if (_editing) return;
    ref.listenManual(orgSettingsProvider, (_, next) {
      if (next.value case final settings?) {
        if (_initialized) {
          setState(() => _seed(settings));
        } else {
          _seed(settings);
        }
      }
    }, fireImmediately: true);
  }

  /// Valeurs par défaut de la structure, tant que rien n'a été saisi.
  void _seed(OrgSettings settings) {
    _settings = settings;
    if (_seeded) return;
    _seeded = true;
    if (_city.text.isEmpty) _city.text = settings.defaultCity ?? '';
    if (_kind == EventKind.other) _kind = settings.defaultKind ?? _kind;
    if (_timezone == defaultEventTimeZone) {
      _timezone = settings.defaultTimezone ?? _timezone;
    }
  }

  void _initFrom(TicketEvent? event) {
    if (_initialized) return;
    _initialized = true;
    _existing = event;
    if (event != null) {
      _title.text = event.title;
      _description.text = event.description ?? '';
      _tagline.text = event.tagline ?? '';
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
      _tagline,
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
      context.popOr(AppRoutes.events);
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
      tagline: _tagline.text,
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
      var defaultsFailed = false;
      if (!_editing && _applyDefaults && _settings.hasProposals) {
        try {
          await ref.read(orgSettingsRepositoryProvider).applyToEvent(saved.id);
        } on Object {
          defaultsFailed = true;
        }
      }
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
      } else if (defaultsFailed) {
        toaster.error(l10n.eventDefaultsApplyFailed);
      } else {
        toaster.success(
          _editing ? l10n.eventSaved : l10n.eventCreated(saved.title),
        );
      }
      if (_editing) {
        context.popOr(AppRoutes.events);
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
        appBar: TikeoAppBar(title: Text(l10n.eventFormEditTitle)),
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
        // En-tête Nuit compact : laisse la place au clavier.
        appBar: TikeoAppBar(
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
            preferredSize: Size.fromHeight(_StepHeader.heightFor(context)),
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
}
