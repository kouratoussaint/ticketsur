import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/empty_state.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_providers.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/ticket_templates/application/template_providers.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_template.dart';
import 'package:ticketsur/features/ticket_templates/domain/ticket_theme.dart';
import 'package:ticketsur/features/ticket_templates/presentation/ticket_artwork.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Données d'exemple des aperçus (jamais un vrai ticket).
const _sampleNumber = 123;
const _sampleReference = 'TS-7K2M-9QXA';
final _sampleToken = 'TS1.${'A' * 43}';

/// Nom d'un thème intégré.
String themeName(AppLocalizations l10n, int id) => switch (id) {
  1 => l10n.ticketTheme1,
  2 => l10n.ticketTheme2,
  3 => l10n.ticketTheme3,
  4 => l10n.ticketTheme4,
  5 => l10n.ticketTheme5,
  6 => l10n.ticketTheme6,
  7 => l10n.ticketTheme7,
  8 => l10n.ticketTheme8,
  9 => l10n.ticketTheme9,
  10 => l10n.ticketTheme10,
  11 => l10n.ticketTheme11,
  _ => l10n.ticketTheme12,
};

/// Message d'un échec d'enregistrement ou d'import.
String templateFailureText(AppLocalizations l10n, TemplateFailure failure) =>
    switch (failure) {
      TemplateFailure.qrTooSmall => l10n.templateErrorQrTooSmall,
      TemplateFailure.imageInvalid => l10n.templateErrorImage,
      TemplateFailure.imageTooLarge => l10n.templateErrorTooLarge,
      TemplateFailure.imageFormat => l10n.templateErrorFormat,
      TemplateFailure.locked => l10n.templateErrorLocked,
      TemplateFailure.notFound => l10n.templateErrorNotFound,
      TemplateFailure.invalid => l10n.templateErrorInvalid,
      TemplateFailure.network => l10n.templateErrorNetwork,
    };

/// Aperçu dessiné avec des données d'exemple et l'événement réel.
TicketArtArtwork _preview(
  TicketArt art,
  TicketTemplate template,
  TicketCategory category, {
  Key? key,
}) => TicketArtArtwork(
  key: key,
  art: art,
  template: template,
  categoryName: category.name,
  invitation: category.isInvitation,
);

/// [TicketArtwork] avec les données d'exemple.
class TicketArtArtwork extends StatelessWidget {
  const new({
    required this.art,
    required this.template,
    required this.categoryName,
    this.invitation = false,
    this.holderName,
    super.key,
  });

  final TicketArt art;
  final TicketTemplate template;
  final String categoryName;
  final bool invitation;

  /// Titulaire d'exemple (placement du nom sur un design importé).
  final String? holderName;

  @override
  Widget build(BuildContext context) => TicketArtwork(
    art: art,
    template: template,
    categoryName: categoryName,
    invitation: invitation,
    number: _sampleNumber,
    reference: _sampleReference,
    token: _sampleToken,
    holderName: holderName,
  );
}

/// Ce dont les pages de modèles ont besoin : événement, catégories, modèles.
({
  TicketEvent? event,
  AsyncValue<List<TicketCategory>> categories,
  AsyncValue<Map<String, TicketTemplate>> templates,
  TicketArt? art,
})
_watchTemplates(WidgetRef ref, String eventId) {
  final event = ref.watch(eventByIdProvider(eventId));
  final categories = ref.watch(categoriesProvider(eventId));
  final templates = ref.watch(eventTemplatesProvider(eventId));
  final organization = ref.watch(activeOrganizationProvider);
  return (
    event: event,
    categories: categories,
    templates: templates,
    art: event == null
        ? null
        : TicketArt(
            event: event,
            organizationName: organization?.name ?? '',
            organizationLogoUrl: organization?.logoUrl,
            templates: templates.value ?? const {},
          ),
  );
}

/// Modèles des tickets d'un événement : un par catégorie.
class TicketTemplatesPage extends ConsumerWidget {
  const new({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = _watchTemplates(ref, eventId);
    final art = data.art;
    final categories = data.categories.value;
    final loading =
        art == null ||
        categories == null ||
        (data.templates.isLoading && !data.templates.hasValue);
    final failed = data.templates.hasError || data.categories.hasError;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.templatesTitle)),
      body: switch ((loading, failed)) {
        (_, true) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.templatesLoadError,
          actionLabel: l10n.orgRetry,
          actionKey: const Key('templates-retry'),
          onAction: () {
            ref
              ..invalidate(eventTemplatesProvider(eventId))
              ..invalidate(categoriesProvider(eventId));
          },
        ),
        (true, _) => const Center(child: CircularProgressIndicator()),
        _ => ListView(
          key: const Key('templates-list'),
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          children: [
            Text(
              l10n.templatesIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: TicketSurSpacing.md),
            for (final category in categories!)
              Card(
                key: Key('templates-category-${category.id}'),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => unawaited(
                    context.push(
                      AppRoutes.ticketTemplate(eventId, category.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(TicketSurSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _preview(art!, art.templateFor(category.id), category),
                        const SizedBox(height: TicketSurSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                    _templateLabel(
                                      l10n,
                                      art.templates[category.id],
                                      art.templateFor(category.id),
                                    ),
                                    key: Key('templates-label-${category.id}'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      },
    );
  }

  static String _templateLabel(
    AppLocalizations l10n,
    TicketTemplate? saved,
    TicketTemplate shown,
  ) => switch ((saved, shown)) {
    (null, BuiltinTemplate(:final themeId)) => l10n.templatesProposed(
      themeName(l10n, themeId),
    ),
    (BuiltinTemplate(:final themeId), _) => l10n.templatesChosen(
      themeName(l10n, themeId),
    ),
    _ => l10n.templatesCustom,
  };
}

/// Choix du modèle d'une catégorie : thèmes intégrés ou design importé.
class TemplateEditorPage extends ConsumerStatefulWidget {
  const new({required this.eventId, required this.categoryId, super.key});

  final String eventId;
  final String categoryId;

  @override
  ConsumerState<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage> {
  TicketTemplate? _selected;
  bool _singleFont = false;
  String _mimeType = 'image/jpeg';
  bool _busy = false;
  bool _initialized = false;

  void _init(TicketArt art) {
    if (_initialized) return;
    _initialized = true;
    final current = art.templateFor(widget.categoryId);
    _selected = current;
    if (current is BuiltinTemplate) _singleFont = current.singleFontTitle;
  }

  TicketTemplate _effective() => switch (_selected) {
    final BuiltinTemplate builtin => builtin.copyWith(
      singleFontTitle: _singleFont,
    ),
    final other? => other,
    null => const BuiltinTemplate(1),
  };

  Future<void> _import(TicketArt art, TicketCategory category) async {
    final toaster = Toaster.of(context);
    final l10n = context.l10n;
    final picked = await ref.read(templateImagePickerProvider)();
    if (picked == null || !mounted) return;
    if (picked.bytes.length > 2 * 1024 * 1024) {
      toaster.error(templateFailureText(l10n, TemplateFailure.imageTooLarge));
      return;
    }
    AnalyzedImage analyzed;
    try {
      analyzed = await ref.read(templateImageAnalyzerProvider)(picked.bytes);
    } on Object {
      toaster.error(templateFailureText(l10n, TemplateFailure.imageFormat));
      return;
    }
    final aspect = analyzed.width / analyzed.height;
    if (aspect < 1.5 || aspect > 4) {
      toaster.error(
        templateFailureText(l10n, TemplateFailure.imageFormat),
        key: const Key('template-import-error'),
      );
      return;
    }
    final placement = defaultPlacement(
      width: analyzed.width,
      height: analyzed.height,
      square: analyzed.lightSquare,
      sampleWidth: analyzed.sampleWidth,
      sampleHeight: analyzed.sampleHeight,
    );
    final found =
        analyzed.lightSquare != null &&
        analyzed.lightSquare!.side / analyzed.sampleHeight >=
            QrPlacement.minSize;
    final custom = CustomTemplate(
      width: analyzed.width,
      height: analyzed.height,
      placement: placement,
      localBytes: picked.bytes,
    );
    setState(() {
      _selected = custom;
      _mimeType = picked.mimeType;
    });
    toaster.info(
      found ? l10n.placementFoundSquare : l10n.placementFallback,
      key: const Key('template-placement-info'),
    );
    await _adjust(art, category, custom, auto: placement);
  }

  Future<void> _adjust(
    TicketArt art,
    TicketCategory category,
    CustomTemplate template, {
    QrPlacement? auto,
  }) async {
    final result = await Navigator.of(context).push<QrPlacement>(
      MaterialPageRoute(
        builder: (_) => TemplatePlacementPage(
          art: art,
          template: template,
          categoryName: category.name,
          auto: auto ?? template.placement,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _selected = template.withPlacement(result));
  }

  /// Enregistre le modèle pour cette catégorie et, s'il y en a, pour
  /// [others] (copie vers d'autres catégories).
  Future<void> _save(TicketEvent event, {Set<String> others = const {}}) async {
    final toaster = Toaster.of(context);
    final l10n = context.l10n;
    final repository = ref.read(ticketTemplateRepositoryProvider);
    setState(() => _busy = true);
    try {
      var template = _effective();
      if (template case CustomTemplate(:final Uint8List localBytes)) {
        final path = await repository.uploadImage(event, localBytes, _mimeType);
        template = template.uploaded(path, repository.imageUrl(path));
        // Une seule image envoyée, même en cas de nouvel essai.
        _selected = template;
      }
      for (final categoryId in {widget.categoryId, ...others}) {
        await repository.save(categoryId, template);
      }
      ref.invalidate(eventTemplatesProvider(widget.eventId));
      if (others.isEmpty) {
        toaster.success(l10n.templateSaved, key: const Key('template-saved'));
      } else {
        toaster.success(
          l10n.templateCopied(others.length + 1),
          key: const Key('template-copied'),
        );
      }
      if (mounted) context.popOr(AppRoutes.ticketTemplates(widget.eventId));
    } on TemplateFailure catch (failure) {
      toaster.error(
        templateFailureText(l10n, failure),
        key: const Key('template-error'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Choix des autres catégories qui recevront ce modèle.
  Future<void> _copy(TicketEvent event, List<TicketCategory> others) async {
    final chosen = await showModalBottomSheet<Set<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CopySheet(categories: others),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    await _save(event, others: chosen);
  }

  /// Cadrage de la photo de couverture (thème intégré).
  Future<void> _crop(
    TicketArt art,
    TicketCategory category,
    BuiltinTemplate template,
  ) async {
    final result = await Navigator.of(context).push<BuiltinTemplate>(
      MaterialPageRoute(
        builder: (_) => CoverCropPage(
          art: art,
          template: template,
          categoryName: category.name,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _selected = result);
  }

  Future<void> _reset() async {
    final toaster = Toaster.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(ticketTemplateRepositoryProvider)
          .save(widget.categoryId, null);
      ref.invalidate(eventTemplatesProvider(widget.eventId));
      toaster.success(l10n.templateResetDone);
      if (mounted) context.popOr(AppRoutes.ticketTemplates(widget.eventId));
    } on TemplateFailure catch (failure) {
      toaster.error(templateFailureText(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _watchTemplates(ref, widget.eventId);
    final art = data.art;
    final category = data.categories.value
        ?.where((c) => c.id == widget.categoryId)
        .firstOrNull;
    if (art == null || category == null || !data.templates.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.templatesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _init(art);
    final effective = _effective();
    final others = [
      for (final c in data.categories.value ?? const <TicketCategory>[])
        if (c.id != widget.categoryId) c,
    ];
    final saved = art.templates[widget.categoryId];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.templateEditorTitle(category.name))),
      body: ListView(
        key: const Key('template-editor'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          _preview(
            art,
            effective,
            category,
            key: const Key('template-preview'),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.templateBuiltinSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.xs),
          for (var row = 0; row < ticketThemes.length; row += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, ticketTheme)
                      in ticketThemes.skip(row).take(2).indexed) ...[
                    if (i > 0) const SizedBox(width: TicketSurSpacing.sm),
                    Expanded(
                      child: _ThemeChoice(
                        art: art,
                        category: category,
                        themeId: ticketTheme.id,
                        singleFont: _singleFont,
                        selected:
                            _selected is BuiltinTemplate &&
                            (_selected! as BuiltinTemplate).themeId ==
                                ticketTheme.id,
                        onTap: _busy
                            ? null
                            : () => setState(
                                () =>
                                    _selected = BuiltinTemplate(ticketTheme.id),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (effective is BuiltinTemplate)
            SwitchListTile(
              key: const Key('template-single-font'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.templateSingleFont),
              subtitle: Text(l10n.templateSingleFontHint),
              value: _singleFont,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _singleFont = value),
            ),
          if (effective case final BuiltinTemplate builtin
              when art.event.coverUrl != null)
            OutlinedButton.icon(
              key: const Key('template-crop'),
              onPressed: _busy
                  ? null
                  : () => unawaited(_crop(art, category, builtin)),
              icon: const Icon(Icons.crop_rounded),
              label: Text(l10n.templateCrop),
            ),
          const SizedBox(height: TicketSurSpacing.sm),
          Text(l10n.templateCustomSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.xxs),
          Text(l10n.templateImportHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: TicketSurSpacing.xs),
          OutlinedButton.icon(
            key: const Key('template-import'),
            onPressed: _busy ? null : () => unawaited(_import(art, category)),
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(l10n.templateImport),
          ),
          if (effective case final CustomTemplate custom) ...[
            const SizedBox(height: TicketSurSpacing.xs),
            OutlinedButton.icon(
              key: const Key('template-adjust'),
              onPressed: _busy
                  ? null
                  : () => unawaited(_adjust(art, category, custom)),
              icon: const Icon(Icons.open_with_rounded),
              label: Text(l10n.templateAdjust),
            ),
          ],
          const SizedBox(height: TicketSurSpacing.lg),
          FilledButton(
            key: const Key('template-save'),
            onPressed: _busy ? null : () => unawaited(_save(art.event)),
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.templateSave),
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: TicketSurSpacing.xs),
            OutlinedButton.icon(
              key: const Key('template-copy'),
              onPressed: _busy
                  ? null
                  : () => unawaited(_copy(art.event, others)),
              icon: const Icon(Icons.copy_all_rounded),
              label: Text(l10n.templateCopy),
            ),
          ],
          if (saved != null) ...[
            const SizedBox(height: TicketSurSpacing.xs),
            TextButton(
              key: const Key('template-reset'),
              onPressed: _busy ? null : () => unawaited(_reset()),
              child: Text(l10n.templateReset),
            ),
          ],
          const SizedBox(height: TicketSurSpacing.xl),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const new({
    required this.art,
    required this.category,
    required this.themeId,
    required this.singleFont,
    required this.selected,
    required this.onTap,
  });

  final TicketArt art;
  final TicketCategory category;
  final int themeId;
  final bool singleFont;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: themeName(l10n, themeId),
      child: InkWell(
        key: Key('template-theme-$themeId'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TicketSurRadii.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TicketSurRadii.md),
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ExcludeSemantics(
                  child: _preview(
                    art,
                    BuiltinTemplate(themeId, singleFontTitle: singleFont),
                    category,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TicketSurSpacing.xxs),
            Row(
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: context.palette.accentText,
                    ),
                  ),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      themeName(l10n, themeId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placement du QR et de la référence sur un design importé : glisser,
/// pincer, ou régler la taille ; jamais sous 35 % de la hauteur.
class TemplatePlacementPage extends StatefulWidget {
  const new({
    required this.art,
    required this.template,
    required this.categoryName,
    required this.auto,
    super.key,
  });

  final TicketArt art;
  final CustomTemplate template;
  final String categoryName;

  /// Placement automatique (bouton « Placement automatique »).
  final QrPlacement auto;

  @override
  State<TemplatePlacementPage> createState() => _TemplatePlacementPageState();
}

class _TemplatePlacementPageState extends State<TemplatePlacementPage> {
  late QrPlacement _placement = widget.template.placement;
  double _startSize = 0;
  bool _minReached = false;

  double get _aspect => widget.template.aspectRatio;

  void _update(QrPlacement next, {bool shrinking = false}) {
    final clamped = next.clamped(_aspect);
    setState(() {
      _placement = clamped;
      _minReached = shrinking && clamped.qrSize <= QrPlacement.minSize + 0.0001;
    });
  }

  QrPlacement _with({
    double? qrX,
    double? qrY,
    double? qrSize,
    double? refX,
    double? refY,
  }) => QrPlacement(
    qrX: qrX ?? _placement.qrX,
    qrY: qrY ?? _placement.qrY,
    qrSize: qrSize ?? _placement.qrSize,
    refX: refX ?? _placement.refX,
    refY: refY ?? _placement.refY,
    holderX: _placement.holderX,
    holderY: _placement.holderY,
  );

  /// Taille demandée : centre du QR gardé, minimum signalé.
  void _resize(double size) {
    final shrinking = size < _placement.qrSize || size < QrPlacement.minSize;
    final target = size.clamp(
      QrPlacement.minSize,
      QrPlacement.maxSize(_aspect),
    );
    final centerX = _placement.qrX + _placement.qrSize / _aspect / 2;
    final centerY = _placement.qrY + _placement.qrSize / 2;
    _update(
      _with(
        qrSize: target,
        qrX: centerX - target / _aspect / 2,
        qrY: centerY - target / 2,
      ),
      shrinking: shrinking && size <= QrPlacement.minSize + 0.0001,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = _placement;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.placementTitle),
        actions: [
          TextButton(
            key: const Key('placement-done'),
            onPressed: () => Navigator.of(context).pop(_placement),
            child: Text(l10n.placementDone),
          ),
        ],
      ),
      body: ListView(
        key: const Key('placement'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          Text(l10n.placementHelp, style: theme.textTheme.bodyMedium),
          const SizedBox(height: TicketSurSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width / _aspect;
              final side = p.qrSize * height;
              final blockWidth =
                  TicketGeometry.customBlockWidth /
                  TicketGeometry.width *
                  width;
              return SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TicketArtArtwork(
                        art: widget.art,
                        template: widget.template.withPlacement(p),
                        categoryName: widget.categoryName,
                        holderName: l10n.placementSampleHolder,
                      ),
                    ),
                    Positioned(
                      left: p.qrX * width,
                      top: p.qrY * height,
                      width: side,
                      height: side,
                      child: GestureDetector(
                        key: const Key('placement-qr'),
                        onScaleStart: (_) => _startSize = p.qrSize,
                        onScaleUpdate: (details) {
                          if (details.pointerCount > 1) {
                            _resize(_startSize * details.scale);
                          }
                          final current = _placement;
                          _update(
                            QrPlacement(
                              qrX:
                                  current.qrX +
                                  details.focalPointDelta.dx / width,
                              qrY:
                                  current.qrY +
                                  details.focalPointDelta.dy / height,
                              qrSize: current.qrSize,
                              refX: current.refX,
                              refY: current.refY,
                              holderX: current.holderX,
                              holderY: current.holderY,
                            ),
                            shrinking: _minReached,
                          );
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: p.refX * width - blockWidth / 2,
                      top: p.refY * height,
                      width: blockWidth,
                      height: blockWidth * 0.32,
                      child: GestureDetector(
                        key: const Key('placement-ref'),
                        onPanUpdate: (details) => _update(
                          _with(
                            refX: p.refX + details.delta.dx / width,
                            refY: p.refY + details.delta.dy / height,
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.tertiary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (p.holderPlaced)
                      Positioned(
                        left: p.holderX! * width - blockWidth / 2,
                        top: p.holderY! * height,
                        width: blockWidth,
                        height: blockWidth * 0.14,
                        child: GestureDetector(
                          key: const Key('placement-holder'),
                          onPanUpdate: (details) => _update(
                            _placement.withHolder(
                              p.holderX! + details.delta.dx / width,
                              p.holderY! + details.delta.dy / height,
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.secondary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            key: const Key('placement-holder-free'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.placementHolderFree),
            subtitle: Text(l10n.placementHolderFreeHint),
            value: p.holderPlaced,
            onChanged: (free) => _update(
              free
                  ? _placement.withHolder(p.refX, (p.refY + 0.2).clamp(0, 0.9))
                  : _placement.withHolder(null, null),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.placementSize, style: theme.textTheme.titleSmall),
          Slider(
            key: const Key('placement-qr-size'),
            min: QrPlacement.minSize,
            max: QrPlacement.maxSize(_aspect),
            value: p.qrSize.clamp(
              QrPlacement.minSize,
              QrPlacement.maxSize(_aspect),
            ),
            label: '${(p.qrSize * 100).round()} %',
            onChanged: _resize,
          ),
          if (_minReached)
            Text(
              l10n.placementMinReached,
              key: const Key('placement-min-message'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: TicketSurSpacing.sm),
          OutlinedButton.icon(
            key: const Key('placement-auto'),
            onPressed: () => _update(widget.auto),
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: Text(l10n.placementAuto),
          ),
        ],
      ),
    );
  }
}

/// Catégories qui recevront le même modèle.
class _CopySheet extends StatefulWidget {
  const new({required this.categories});

  final List<TicketCategory> categories;

  @override
  State<_CopySheet> createState() => _CopySheetState();
}

class _CopySheetState extends State<_CopySheet> {
  final _chosen = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TicketSurSpacing.md,
          0,
          TicketSurSpacing.md,
          TicketSurSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.templateCopyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: TicketSurSpacing.xs),
            for (final category in widget.categories)
              CheckboxListTile(
                key: Key('copy-category-${category.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(category.name),
                value: _chosen.contains(category.id),
                onChanged: (value) => setState(
                  () => value == true
                      ? _chosen.add(category.id)
                      : _chosen.remove(category.id),
                ),
              ),
            const SizedBox(height: TicketSurSpacing.sm),
            FilledButton(
              key: const Key('copy-confirm'),
              onPressed: _chosen.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(Set.of(_chosen)),
              child: Text(l10n.templateCopyConfirm(_chosen.length)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cadrage de la photo de couverture sur un thème intégré : glisser pour
/// choisir la partie visible, curseur pour le zoom.
class CoverCropPage extends StatefulWidget {
  const new({
    required this.art,
    required this.template,
    required this.categoryName,
    super.key,
  });

  final TicketArt art;
  final BuiltinTemplate template;
  final String categoryName;

  @override
  State<CoverCropPage> createState() => _CoverCropPageState();
}

class _CoverCropPageState extends State<CoverCropPage> {
  late BuiltinTemplate _template = widget.template;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cropTitle),
        actions: [
          TextButton(
            key: const Key('crop-done'),
            onPressed: () => Navigator.of(context).pop(_template),
            child: Text(l10n.placementDone),
          ),
        ],
      ),
      body: ListView(
        key: const Key('crop'),
        padding: const EdgeInsets.all(TicketSurSpacing.md),
        children: [
          Text(l10n.cropHelp, style: theme.textTheme.bodyMedium),
          const SizedBox(height: TicketSurSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                key: const Key('crop-area'),
                onPanUpdate: (details) => setState(() {
                  // Le doigt tire la photo : la partie visible va à l'opposé.
                  final speed = 1.6 / _template.coverZoom;
                  _template = _template.copyWith(
                    coverX:
                        (_template.coverX - details.delta.dx / width * speed)
                            .clamp(0, 1),
                    coverY:
                        (_template.coverY -
                                details.delta.dy / (width / 2.4) * speed)
                            .clamp(0, 1),
                  );
                }),
                child: TicketArtArtwork(
                  art: widget.art,
                  template: _template,
                  categoryName: widget.categoryName,
                ),
              );
            },
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.cropZoom, style: theme.textTheme.titleSmall),
          Slider(
            key: const Key('crop-zoom'),
            min: 1,
            max: BuiltinTemplate.maxZoom,
            value: _template.coverZoom,
            label: '× ${_template.coverZoom.toStringAsFixed(1)}',
            onChanged: (zoom) =>
                setState(() => _template = _template.copyWith(coverZoom: zoom)),
          ),
          OutlinedButton.icon(
            key: const Key('crop-reset'),
            onPressed: () => setState(
              () => _template = _template.copyWith(
                coverX: 1,
                coverY: 0.5,
                coverZoom: 1,
              ),
            ),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.cropReset),
          ),
        ],
      ),
    );
  }
}
