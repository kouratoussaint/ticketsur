import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/domain/billing_option.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Ce que comprend un pack : options incluses (coche verte), suppléments
/// (plus bleu avec prix), non inclus (croix grise). Écrans P2, P3 et
/// aperçu de la console.
class PackOptionLines extends StatelessWidget {
  const new({required this.pack, this.onlyNotable = false, super.key});

  final BillingPack pack;

  /// Seulement les options réglées (pas les « illimité » par défaut).
  final bool onlyNotable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tints = context.tints;
    Widget line(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
    final perUnit = pack.system == BillingSystem.flat
        ? l10n.billingPerMonthShort
        : l10n.billingPerEventShort;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final option in BillingOption.values)
          if (pack.system == BillingSystem.flat ||
              (option != BillingOption.structures &&
                  option != BillingOption.ticketsPerPeriod))
            switch (pack.options[option]) {
              null when onlyNotable => const SizedBox.shrink(),
              null => line(
                Icons.check_circle_rounded,
                tints.green.icon,
                option.numeric
                    ? l10n.billingPreviewUnlimited(option.label(l10n))
                    : option.label(l10n),
              ),
              PackOptionSetting(state: FeatureState.unavailable)
                  when !option.numeric =>
                line(Icons.cancel_rounded, tints.gray.icon, option.label(l10n)),
              PackOptionSetting(
                state: FeatureState.addon,
                addonPrice: final price?,
              )
                  when !option.numeric =>
                line(
                  Icons.add_circle_rounded,
                  tints.blue.icon,
                  l10n.billingPreviewAddon(
                    option.label(l10n),
                    '${money(l10n, price)} $perUnit',
                  ),
                ),
              final setting => line(
                Icons.check_circle_rounded,
                tints.green.icon,
                [
                  if (option.numeric)
                    l10n.billingPreviewIncluded(
                      setting.included?.toString() ?? '∞',
                      option.label(l10n),
                    )
                  else
                    option.label(l10n),
                  if (option.numeric && setting.addonPrice != null)
                    l10n.billingPreviewMore(
                      money(l10n, setting.addonPrice!),
                      setting.addonStep,
                    ),
                ].join(' · '),
              ),
            },
      ],
    );
  }
}
