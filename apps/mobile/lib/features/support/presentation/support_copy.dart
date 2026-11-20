import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/app_locale.dart';
import 'package:ticketsur/features/support/domain/support.dart';
import 'package:ticketsur/l10n/l10n.dart';

String supportCategoryLabel(AppLocalizations l10n, SupportCategory c) =>
    switch (c) {
      SupportCategory.question => l10n.supportCategoryQuestion,
      SupportCategory.problem => l10n.supportCategoryProblem,
      SupportCategory.account => l10n.supportCategoryAccount,
      SupportCategory.payment => l10n.supportCategoryPayment,
      SupportCategory.other => l10n.supportCategoryOther,
    };

String supportStatusLabel(AppLocalizations l10n, SupportStatus s) =>
    switch (s) {
      SupportStatus.open => l10n.supportStatusOpen,
      SupportStatus.answered => l10n.supportStatusAnswered,
      SupportStatus.closed => l10n.supportStatusClosed,
    };

String supportFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      SupportFailure.invalid => l10n.supportBodyInvalid,
      SupportFailure.limit => l10n.supportLimit,
      SupportFailure.notFound => l10n.supportNotFound,
      _ => l10n.supportError,
    };

/// « 19 nov. à 21:40 ».
String supportWhen(DateTime instant) =>
    formatDateAtTime(instant.toLocal(), year: false);

/// Icône d'une catégorie de demande.
IconData supportCategoryIcon(SupportCategory category) => switch (category) {
  SupportCategory.question => Icons.help_rounded,
  SupportCategory.problem => Icons.build_rounded,
  SupportCategory.account => Icons.person_rounded,
  SupportCategory.payment => Icons.payments_rounded,
  SupportCategory.other => Icons.chat_bubble_rounded,
};
