import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/catalog/domain/catalog.dart';
import 'package:ticketsur/features/catalog/presentation/catalog_copy.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ouvre les filtres de l'Explorer ; renvoie les nouveaux critères, ou
/// `null` si la feuille est fermée sans valider.
Future<CatalogQuery?> showFilterSheet(
  BuildContext context,
  CatalogQuery query,
) => showModalBottomSheet<CatalogQuery>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FilterSheet(initial: query),
);

class _FilterSheet extends StatefulWidget {
  const new({required this.initial});

  final CatalogQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CatalogQuery _query = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(
        top: TicketSurSpacing.md,
        bottom: TicketSurSpacing.xs,
      ),
      child: Text(title, style: theme.textTheme.titleSmall),
    );
    Widget chip({
      required Key key,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) => FilterChip(
      key: key,
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      shape: const StadiumBorder(),
      selectedColor: TicketSurColors.mint,
      labelStyle: TextStyle(
        color: selected ? TicketSurColors.navy : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) => onTap(),
    );
    final periods = {
      CatalogPeriod.any: l10n.filtersAnyTime,
      CatalogPeriod.today: l10n.filtersToday,
      CatalogPeriod.weekend: l10n.filtersWeekend,
      CatalogPeriod.week: l10n.filtersWeek,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        0,
        TicketSurSpacing.md,
        TicketSurSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.filtersTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                key: const Key('filters-clear'),
                onPressed: () => setState(
                  () => _query = CatalogQuery(
                    search: _query.search,
                    city: _query.city,
                  ),
                ),
                child: Text(l10n.filtersClear),
              ),
            ],
          ),
          section(l10n.filtersCategory),
          Wrap(
            spacing: TicketSurSpacing.xs,
            runSpacing: TicketSurSpacing.xs,
            children: [
              for (final kind in EventKind.values)
                chip(
                  key: Key('filter-kind-${kind.wireName}'),
                  label: exploreKindLabel(l10n, kind),
                  selected: _query.kinds.contains(kind),
                  onTap: () => setState(
                    () => _query = _query.copyWith(
                      kinds: _query.kinds.contains(kind)
                          ? ({..._query.kinds}..remove(kind))
                          : {..._query.kinds, kind},
                    ),
                  ),
                ),
            ],
          ),
          section(l10n.filtersWhen),
          Wrap(
            spacing: TicketSurSpacing.xs,
            runSpacing: TicketSurSpacing.xs,
            children: [
              for (final MapEntry(key: period, value: label) in periods.entries)
                chip(
                  key: Key('filter-period-${period.name}'),
                  label: label,
                  selected: _query.period == period,
                  onTap: () =>
                      setState(() => _query = _query.copyWith(period: period)),
                ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          SwitchListTile(
            key: const Key('filter-free'),
            contentPadding: EdgeInsets.zero,
            value: _query.freeOnly,
            onChanged: (value) =>
                setState(() => _query = _query.copyWith(freeOnly: value)),
            title: Text(l10n.filtersFree),
            subtitle: Text(l10n.filtersFreeHelp),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          FilledButton(
            key: const Key('filters-apply'),
            onPressed: () => Navigator.of(context).pop(_query),
            child: Text(l10n.filtersApply),
          ),
        ],
      ),
    );
  }
}
