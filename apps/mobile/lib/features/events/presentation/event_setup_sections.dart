import 'dart:async';

import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/ticketsur_motion.dart';
import 'package:ticketsur/design_system/ticketsur_palette.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/widgets/animated_count.dart';
import 'package:ticketsur/design_system/widgets/motion_size.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/events/application/event_setup_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart';
import 'package:ticketsur/features/events/domain/event_setup.dart';
import 'package:ticketsur/l10n/l10n.dart';

part 'setup_categories_section.dart';
part 'setup_checkpoints_section.dart';
part 'setup_sheet.dart';

/// Message d'un échec de configuration.
String setupFailureMessage(AppLocalizations l10n, SetupFailure failure) =>
    switch (failure) {
      SetupFailure.notFound => l10n.setupErrorNotFound,
      SetupFailure.nameInvalid => l10n.setupErrorName,
      SetupFailure.nameTaken => l10n.setupErrorNameTaken,
      SetupFailure.capacityInvalid => l10n.setupErrorCapacity,
      SetupFailure.capacityBelowIssued => l10n.setupErrorCapacityBelowIssued,
      SetupFailure.hasTickets => l10n.setupErrorHasTickets,
      SetupFailure.locked => l10n.setupErrorLocked,
      SetupFailure.entriesInvalid => l10n.setupErrorEntriesInvalid,
      SetupFailure.entriesLocked => l10n.setupErrorEntriesLocked,
      SetupFailure.network => l10n.eventErrorNetwork,
      SetupFailure.unknown => l10n.eventErrorUnknown,
    };

/// Vrai si la structure de l'événement (catégories, portes) est modifiable.
bool isConfigurable(TicketEvent event) =>
    event.status != EventStatus.closed &&
    event.status != EventStatus.archived &&
    event.status != EventStatus.cancelled;

/// En-tête de section : titre et bouton « Ajouter ».
class _SectionHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.icon,
    required this.tint,
    this.onAdd,
    this.addKey,
  });

  final String title;
  final IconData icon;
  final TikeoTint tint;
  final VoidCallback? onAdd;
  final Key? addKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TicketSurSpacing.md,
        TicketSurSpacing.sm,
        TicketSurSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tint.background,
            child: Icon(icon, size: 20, color: tint.icon),
          ),
          const SizedBox(width: TicketSurSpacing.sm),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (onAdd != null)
            TextButton.icon(
              key: addKey,
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.setupAdd),
            ),
        ],
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const new({required this.text, this.onRetry, super.key});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TicketSurSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(context.l10n.orgRetry)),
        ],
      ),
    );
  }
}

Widget _sectionBody<T>(
  BuildContext context,
  AsyncValue<List<T>> value, {
  required String empty,
  required String emptyKey,
  required VoidCallback onRetry,
  required Widget Function(List<T> items) builder,
}) {
  final child = switch (value) {
    AsyncData(:final value) when value.isEmpty => _SectionMessage(
      key: Key(emptyKey),
      text: empty,
    ),
    AsyncData(:final value) => builder(value),
    AsyncError() => _SectionMessage(
      key: const ValueKey('error'),
      text: context.l10n.setupLoadError,
      onRetry: onRetry,
    ),
    _ => const Padding(
      key: ValueKey('loading'),
      padding: EdgeInsets.all(TicketSurSpacing.md),
      child: Center(child: CircularProgressIndicator()),
    ),
  };
  return MotionSize(alignment: Alignment.topCenter, child: child);
}

// ---------------------------------------------------------------------------
// Catégories (S10, EVT-03)
// ---------------------------------------------------------------------------
