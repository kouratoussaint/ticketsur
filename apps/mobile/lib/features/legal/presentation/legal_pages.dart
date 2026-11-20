import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/features/legal/application/legal_providers.dart';
import 'package:ticketsur/features/legal/domain/legal_document.dart';
import 'package:ticketsur/l10n/l10n.dart';

String legalTitle(AppLocalizations l10n, LegalSlug slug) => switch (slug) {
  LegalSlug.terms => l10n.legalTerms,
  LegalSlug.privacy => l10n.legalPrivacy,
};

String legalDate(DateTime instant) =>
    DateFormat.yMMMMd(appLocaleTag).format(instant.toLocal());

/// Corps d'un document : intertitres, puces, paragraphes.
class LegalBodyView extends StatelessWidget {
  const new({required this.body, super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final placeholder = context.palette.warningText;
    // Passages à compléter (« [raison sociale] ») mis en évidence.
    TextSpan rich(String text, TextStyle? style) {
      final spans = <TextSpan>[];
      text.splitMapJoin(
        RegExp(r'\[[^\]]+\]'),
        onMatch: (m) {
          spans.add(
            TextSpan(
              text: m[0],
              style: TextStyle(color: placeholder, fontWeight: FontWeight.w700),
            ),
          );
          return '';
        },
        onNonMatch: (t) {
          spans.add(TextSpan(text: t));
          return '';
        },
      );
      return TextSpan(style: style, children: spans);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in parseLegalBody(body))
          switch (block) {
            LegalHeading(:final text) => Padding(
              padding: const EdgeInsets.only(
                top: TicketSurSpacing.md,
                bottom: TicketSurSpacing.xs,
              ),
              child: Text(text, style: textTheme.titleMedium),
            ),
            LegalBullet(:final text) => Padding(
              padding: const EdgeInsets.only(
                left: TicketSurSpacing.sm,
                bottom: TicketSurSpacing.xxs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: textTheme.bodyMedium),
                  Expanded(child: Text.rich(rich(text, textTheme.bodyMedium))),
                ],
              ),
            ),
            LegalParagraph(:final text) => Padding(
              padding: const EdgeInsets.only(bottom: TicketSurSpacing.sm),
              child: Text.rich(rich(text, textTheme.bodyMedium)),
            ),
          },
      ],
    );
  }
}

/// Conditions d'utilisation ou politique de confidentialité.
class LegalPage extends ConsumerWidget {
  const new({required this.slug, super.key});

  final LegalSlug slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (slug: slug, locale: ref.watch(appLocaleProvider).languageCode);
    final document = ref.watch(legalDocumentProvider(key));
    return Scaffold(
      appBar: AppBar(
        title: Text(legalTitle(l10n, slug)),
        leading: BackButton(onPressed: () => context.popOr(AppRoutes.settings)),
      ),
      body: switch (document) {
        AsyncData(:final value) => ListView(
          key: Key('legal-${slug.wireName}'),
          padding: const EdgeInsets.all(TicketSurSpacing.lg),
          children: [
            Text(value.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: TicketSurSpacing.md),
            LegalBodyView(body: value.body),
            const SizedBox(height: TicketSurSpacing.lg),
            Text(
              l10n.legalUpdated(value.version, legalDate(value.updatedAt)),
              key: const Key('legal-version'),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.palette.mutedText),
            ),
          ],
        ),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(TicketSurSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.legalLoadError,
                  key: const Key('legal-error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TicketSurSpacing.sm),
                TextButton(
                  onPressed: () => ref.invalidate(legalDocumentProvider(key)),
                  child: Text(l10n.legalRetry),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
