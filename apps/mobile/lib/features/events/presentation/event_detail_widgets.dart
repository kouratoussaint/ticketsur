// Partie de `event_detail_page.dart` (découpage du lot 4-9) :
// en-tête, cartes et lignes de la fiche.
part of 'event_detail_page.dart';

class _Header extends StatelessWidget {
  const new({required this.event, required this.uploading, this.onChangeCover});

  final TicketEvent event;
  final bool uploading;
  final VoidCallback? onChangeCover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final white = textTheme.bodyMedium?.copyWith(color: TicketSurColors.white);
    return Stack(
      fit: StackFit.expand,
      children: [
        EventCover.forEvent(
          event,
          aspectRatio: 0.1,
          overlay: const CoverScrim(child: SizedBox.expand()),
        ),
        Positioned(
          left: TicketSurSpacing.md,
          right: TicketSurSpacing.md,
          bottom: TicketSurSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: TicketSurSpacing.xs,
                runSpacing: TicketSurSpacing.xxs,
                children: [
                  EventStatusChip(
                    key: const Key('event-status'),
                    status: event.status,
                  ),
                  KindOnPhotoPill(
                    label: eventKindLabel(l10n, event.kind),
                    color: eventKindColor(event.kind),
                  ),
                ],
              ),
              const SizedBox(height: TicketSurSpacing.sm),
              Text(
                event.title,
                key: const Key('event-detail-title'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TikeoTextStyles.heroCardTitle.copyWith(
                  color: TicketSurColors.white,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.xxs),
              Text(formatEventRange(event), style: white),
              if (event.city case final city?)
                Text(city, key: const Key('event-city-line'), style: white),
            ],
          ),
        ),
        // Photo en grand, avec téléchargement (#2) : un appui n'importe où
        // sur l'en-tête, y compris sur le titre, et un bouton visible.
        if (event.coverUrl case final url?) ...[
          Positioned.fill(
            child: GestureDetector(
              key: const Key('event-photo'),
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(
                openEventPhoto(context, url: url, title: event.title),
              ),
            ),
          ),
          Positioned(
            left: TicketSurSpacing.md,
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            child: PhotoZoomButton(
              key: const Key('event-photo-open'),
              onPressed: () => unawaited(
                openEventPhoto(context, url: url, title: event.title),
              ),
            ),
          ),
        ],
        if (onChangeCover != null || uploading)
          Positioned(
            right: TicketSurSpacing.md,
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            child: uploading
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x99000000),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: TicketSurColors.white,
                        ),
                      ),
                    ),
                  )
                : FilledButton.tonalIcon(
                    key: const Key('event-change-cover'),
                    // Le thème impose une largeur pleine aux boutons.
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: onChangeCover,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(
                      event.coverPath == null
                          ? l10n.eventCoverAdd
                          : l10n.eventCoverChange,
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Ce qu'il manque pour publier, avec un raccourci pour chaque élément.
class _CompleteCard extends StatelessWidget {
  const new({required this.event, this.onAddCover});

  final TicketEvent event;
  final VoidCallback? onAddCover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final ink = context.palette.warningText;
    return Container(
      key: const Key('event-complete'),
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.warningContainer,
        borderRadius: BorderRadius.circular(TicketSurRadii.md),
        border: Border.all(color: context.palette.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: ink),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(
                child: Text(
                  l10n.eventToCompleteTitle,
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Wrap(
            spacing: TicketSurSpacing.sm,
            runSpacing: TicketSurSpacing.xs,
            children: [
              if (event.coverPath == null)
                ActionChip(
                  key: const Key('event-complete-cover'),
                  avatar: const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(l10n.eventMissingCover),
                  onPressed: onAddCover,
                ),
              if (event.city == null)
                ActionChip(
                  key: const Key('event-complete-city'),
                  avatar: const Icon(Icons.location_city_rounded),
                  label: Text(l10n.eventMissingCity),
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.editEvent(event.id))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const new({
    required this.primary,
    required this.destructive,
    required this.busy,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool primary;
  final bool destructive;
  final bool busy;
  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leading = busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);
    final onTap = enabled ? onPressed : null;
    if (primary && !destructive) {
      return TikeoPrimaryButton(
        onPressed: onTap,
        busy: busy,
        icon: icon,
        label: label,
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: leading,
      label: Text(label),
      style: destructive
          ? OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            )
          : null,
    );
  }
}

/// Visibilité dans l'Explorer public (refonte Tikéo, ADR 0012).
class _PublicCard extends ConsumerStatefulWidget {
  const new({required this.event});

  final TicketEvent event;

  @override
  ConsumerState<_PublicCard> createState() => _PublicCardState();
}

class _PublicCardState extends ConsumerState<_PublicCard> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(eventsProvider.notifier)
          .setPublic(widget.event.id, public: value);
    } on EventFailure catch (failure) {
      toast.error(eventFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final public = widget.event.isPublic;
    final blocked = widget.event.publicBlocked;
    return TikeoCard(
      key: const Key('event-public-card'),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TicketSurSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('event-public'),
              value: public,
              onChanged: _busy || (blocked && !public)
                  ? null
                  : (value) => unawaited(_toggle(value)),
              secondary: Icon(
                public ? Icons.public_rounded : Icons.lock_outline_rounded,
              ),
              title: Text(l10n.eventPublicTitle),
              subtitle: Text(public ? l10n.eventPublicOn : l10n.eventPublicOff),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TicketSurSpacing.md,
                0,
                TicketSurSpacing.md,
                TicketSurSpacing.xs,
              ),
              child: Text(l10n.eventPublicHelp, style: textTheme.bodySmall),
            ),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                  TicketSurSpacing.md,
                  TicketSurSpacing.xs,
                ),
                child: Text(
                  [
                    l10n.eventPublicBlocked,
                    ?widget.event.publicBlockedReason,
                  ].join(' '),
                  key: const Key('event-public-blocked'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'information : rond teinté, intitulé, valeur.
class _InfoRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    this.divider = true,
    super.key,
  });

  final IconData icon;
  final TikeoTint tint;
  final String title;
  final Widget body;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: tint.background,
                child: Icon(icon, size: 22, color: tint.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 72,
            color: theme.colorScheme.outlineVariant,
          ),
      ],
    );
  }
}
