// Partie de `event_form_page.dart` (découpage du lot 4-9) :
// barre d'étapes, barre du bas et champs communs.
part of 'event_form_page.dart';

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
                                ? TicketSurColors.mint
                                : TicketSurColors.white.withValues(alpha: 0.22),
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
              style: textTheme.labelLarge?.copyWith(
                color: TicketSurColors.white,
              ),
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
      color: Theme.of(context).cardTheme.color,
      shadowColor: const Color(0x33022445),
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
                    ? TikeoPrimaryButton(
                        key: const Key('event-submit'),
                        busy: submitting,
                        onPressed: submitting ? null : onSubmit,
                        icon: editing
                            ? Icons.save_rounded
                            : Icons.check_rounded,
                        label: editing
                            ? l10n.eventFormSubmitSave
                            : l10n.eventFormSubmitCreate,
                      )
                    : TikeoPrimaryButton(
                        key: const Key('event-next'),
                        onPressed: submitting ? null : onNext,
                        icon: Icons.arrow_forward_rounded,
                        label: l10n.eventStepNext,
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
                    leading: const Icon(Icons.location_on_rounded),
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
