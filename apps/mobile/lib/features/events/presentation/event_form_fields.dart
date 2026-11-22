// Partie de `event_form_page.dart` (découpage du lot 4-9) :
// champs des quatre étapes.
part of 'event_form_page.dart';

/// Champs des quatre étapes du formulaire d'événement (découpés de
/// `_EventFormPageState`, lot 4-9).
extension _EventFormFields on _EventFormPageState {
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
        validator: (value) => _EventFormPageState._titleError(l10n, value),
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
                _update(() => _kind = kind);
              },
            ),
        ],
      ),
      const SizedBox(height: TicketSurSpacing.lg),
      TextFormField(
        key: const Key('event-tagline'),
        controller: _tagline,
        maxLength: EventDraft.maxTagline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.eventTaglineLabel,
          hintText: l10n.eventTaglineHint,
        ),
      ),
      const SizedBox(height: TicketSurSpacing.sm),
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
        validator: (value) =>
            _EventFormPageState._descriptionError(l10n, value),
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
          if (zone != null) _update(() => _timezone = zone);
        },
      ),
      const SizedBox(height: TicketSurSpacing.lg),
      _CityField(
        controller: _city,
        validator: (value) => _EventFormPageState._cityError(l10n, value),
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
          prefixIcon: const Icon(Icons.place_rounded),
        ),
        validator: (value) => _EventFormPageState._venueError(l10n, value),
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
          prefixIcon: const Icon(Icons.signpost_rounded),
        ),
        validator: (value) => _EventFormPageState._addressError(l10n, value),
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
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(l10n.eventCoverGallery),
            ),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: FilledButton.tonalIcon(
              key: const Key('event-cover-camera'),
              onPressed: () => _pickCover(CoverSource.camera),
              icon: const Icon(Icons.photo_camera_rounded),
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
            onPressed: () => _update(() => _pickedCover = null),
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
                    icon: Icons.place_rounded,
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
      if (!_editing && _settings.hasProposals) ...[
        const SizedBox(height: TicketSurSpacing.md),
        CheckboxListTile(
          key: const Key('event-apply-defaults'),
          contentPadding: EdgeInsets.zero,
          value: _applyDefaults,
          onChanged: (value) => _update(() => _applyDefaults = value ?? false),
          title: Text(l10n.eventApplyDefaults),
          subtitle: Text(
            [
              if (_settings.defaultCategories.isNotEmpty)
                l10n.eventDefaultsCategories(
                  _settings.defaultCategories.map((c) => c.name).join(', '),
                ),
              if (_settings.defaultCheckpoints.isNotEmpty)
                l10n.eventDefaultsDoors(
                  _settings.defaultCheckpoints.join(', '),
                ),
            ].join('\n'),
          ),
        ),
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
        validator: (value) => _EventFormPageState._capacityError(l10n, value),
      ),
    ];
  }
}
