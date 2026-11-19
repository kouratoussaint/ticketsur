import 'package:intl/intl.dart';
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
    DateFormat("d MMM 'à' HH:mm", 'fr').format(instant.toLocal());
