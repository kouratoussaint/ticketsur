import 'dart:async';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/admin/application/admin_providers.dart';
import 'package:ticketsur/features/security/application/admin_mfa_providers.dart';
import 'package:ticketsur/features/security/domain/admin_mfa.dart';
import 'package:ticketsur/l10n/l10n.dart';

String mfaFailureMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      MfaFailure.invalidCode => l10n.mfaErrorCode,
      MfaFailure.rateLimited => l10n.mfaErrorRateLimited,
      MfaFailure.notEnrolled => l10n.mfaErrorNotEnrolled,
      MfaFailure.network => l10n.mfaErrorNetwork,
      _ => l10n.mfaErrorUnknown,
    };

/// Relit tout ce qui dépend du niveau de la session (console, état).
void refreshAfterMfa(WidgetRef ref) {
  ref
    ..invalidate(adminMfaStatusProvider)
    ..invalidate(adminOverviewProvider)
    ..invalidate(adminDailyStatsProvider);
}

/// Saisie du code à 6 chiffres de l'application d'authentification.
class MfaCodeForm extends ConsumerStatefulWidget {
  const new({
    required this.onVerified,
    this.factorId,
    this.fieldKey = const Key('mfa-code'),
    this.buttonKey = const Key('mfa-verify'),
    super.key,
  });

  /// Facteur à activer ; nul = facteur déjà activé (ouverture de session).
  final String? factorId;
  final Future<void> Function() onVerified;
  final Key fieldKey;
  final Key buttonKey;

  @override
  ConsumerState<MfaCodeForm> createState() => _MfaCodeFormState();
}

class _MfaCodeFormState extends ConsumerState<MfaCodeForm> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    final l10n = context.l10n;
    if (!isTotpCode(_code.text)) {
      setState(() => _error = l10n.mfaErrorCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminMfaRepositoryProvider)
          .verify(_code.text, factorId: widget.factorId);
      await widget.onVerified();
    } on Object catch (error) {
      if (mounted) setState(() => _error = mfaFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: widget.fieldKey,
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.mfaCodeLabel,
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => unawaited(_verify()),
          ),
        ),
        const SizedBox(width: TicketSurSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FilledButton(
            key: widget.buttonKey,
            // Boutons pleine largeur par défaut : pas dans une ligne.
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: _busy ? null : () => unawaited(_verify()),
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.mfaVerify),
          ),
        ),
      ],
    );
  }
}

/// Console : code demandé une fois par session, ou code de secours.
class ConsoleMfaCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return TikeoCard(
      key: const Key('console-mfa'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded),
              const SizedBox(width: TicketSurSpacing.sm),
              Expanded(
                child: Text(l10n.mfaConsoleTitle, style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(l10n.mfaConsoleBody, style: textTheme.bodySmall),
          const SizedBox(height: TicketSurSpacing.md),
          MfaCodeForm(
            fieldKey: const Key('console-mfa-code'),
            buttonKey: const Key('console-mfa-verify'),
            onVerified: () async => refreshAfterMfa(ref),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const Key('console-mfa-recovery'),
              onPressed: () => unawaited(_recover(context, ref)),
              child: Text(l10n.mfaUseRecovery),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recover(BuildContext context, WidgetRef ref) async {
    final recovered = await showDialog<bool>(
      context: context,
      builder: (context) => const _RecoveryDialog(),
    );
    if (recovered ?? false) {
      refreshAfterMfa(ref);
      if (context.mounted) {
        Toaster.of(context).info(context.l10n.mfaRecovered);
      }
    }
  }
}

class _RecoveryDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends ConsumerState<_RecoveryDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _code.text.trim().isEmpty) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(adminMfaRepositoryProvider)
          .useRecoveryCode(_code.text.trim());
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = l10n.mfaRecoveryInvalid);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = mfaFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.mfaUseRecovery),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.mfaRecoveryBody),
          const SizedBox(height: TicketSurSpacing.sm),
          TextField(
            key: const Key('mfa-recovery-code'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.mfaRecoveryLabel,
              hintText: 'XXXXX-XXXXX',
              errorText: _error,
            ),
            onSubmitted: (_) => unawaited(_submit()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.profileCancel),
        ),
        FilledButton(
          key: const Key('mfa-recovery-submit'),
          onPressed: _busy ? null : () => unawaited(_submit()),
          child: Text(l10n.mfaVerify),
        ),
      ],
    );
  }
}

/// Profil › Sécurité › Double authentification (administrateurs).
class AdminMfaPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminMfaPage> createState() => _AdminMfaPageState();
}

class _AdminMfaPageState extends ConsumerState<AdminMfaPage> {
  MfaEnrollment? _enrollment;
  List<String>? _codes;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      toast.error(mfaFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enable() => _run(() async {
    final enrollment = await ref.read(adminMfaRepositoryProvider).enroll();
    if (mounted) setState(() => _enrollment = enrollment);
  });

  Future<void> _newCodes() => _run(() async {
    final codes = await ref
        .read(adminMfaRepositoryProvider)
        .generateRecoveryCodes();
    if (mounted) setState(() => _codes = codes);
    ref.invalidate(adminMfaStatusProvider);
  });

  Future<void> _activated() async {
    if (!mounted) return;
    setState(() => _enrollment = null);
    Toaster.of(context).success(context.l10n.mfaEnabledToast);
    refreshAfterMfa(ref);
    await _newCodes();
  }

  Future<void> _disable() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mfaDisable),
        content: Text(l10n.mfaDisableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            key: const Key('mfa-disable-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mfaDisable),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final toast = Toaster.of(context);
    await _run(() async {
      await ref.read(adminMfaRepositoryProvider).disable();
      toast.info(l10n.mfaDisabledToast);
      refreshAfterMfa(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(adminMfaStatusProvider);
    return Scaffold(
      appBar: TikeoAppBar(title: Text(l10n.mfaTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TicketSurSpacing.md),
          child: switch ((status, _codes, _enrollment)) {
            (_, final codes?, _) => _CodesView(
              codes: codes,
              onDone: () => setState(() => _codes = null),
            ),
            (_, _, final enrollment?) => _EnrollView(
              enrollment: enrollment,
              onVerified: _activated,
            ),
            (AsyncData(:final value), _, _) => _StatusView(
              status: value,
              busy: _busy,
              onEnable: () => unawaited(_enable()),
              onNewCodes: () => unawaited(_newCodes()),
              onDisable: () => unawaited(_disable()),
            ),
            (AsyncError(:final error), _, _) => Text(
              mfaFailureMessage(l10n, error),
              key: const Key('mfa-error'),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(TicketSurSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ),
      ),
    );
  }
}

class _StatusView extends ConsumerWidget {
  const new({
    required this.status,
    required this.busy,
    required this.onEnable,
    required this.onNewCodes,
    required this.onDisable,
  });

  final AdminMfaStatus status;
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onNewCodes;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    if (!status.enrolled) {
      return TikeoCard(
        key: const Key('mfa-off'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.mfaOffTitle, style: textTheme.titleMedium),
            const SizedBox(height: TicketSurSpacing.xs),
            Text(l10n.mfaOffBody),
            const SizedBox(height: TicketSurSpacing.md),
            FilledButton.icon(
              key: const Key('mfa-enable'),
              onPressed: busy ? null : onEnable,
              icon: const Icon(Icons.verified_user_rounded),
              label: Text(l10n.mfaEnable),
            ),
          ],
        ),
      );
    }
    return TikeoCard(
      key: const Key('mfa-on'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.mfaOnTitle, style: textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(
            l10n.mfaCodesLeft(status.recoveryCodesLeft),
            key: const Key('mfa-codes-left'),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          if (!status.aal2) ...[
            Text(l10n.mfaConfirmFirst, style: textTheme.bodySmall),
            const SizedBox(height: TicketSurSpacing.sm),
            MfaCodeForm(onVerified: () async => refreshAfterMfa(ref)),
          ] else ...[
            OutlinedButton.icon(
              key: const Key('mfa-new-codes'),
              onPressed: busy ? null : onNewCodes,
              icon: const Icon(Icons.password_rounded),
              label: Text(l10n.mfaNewCodes),
            ),
            const SizedBox(height: TicketSurSpacing.sm),
            TextButton.icon(
              key: const Key('mfa-disable'),
              onPressed: busy ? null : onDisable,
              icon: const Icon(Icons.no_encryption_rounded),
              label: Text(l10n.mfaDisable),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnrollView extends StatelessWidget {
  const new({required this.enrollment, required this.onVerified});

  final MfaEnrollment enrollment;
  final Future<void> Function() onVerified;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return TikeoCard(
      key: const Key('mfa-enroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.mfaEnrollTitle, style: textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(l10n.mfaEnrollStep1),
          const SizedBox(height: TicketSurSpacing.md),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: BarcodeWidget(
                key: const Key('mfa-qr'),
                barcode: Barcode.qrCode(),
                data: enrollment.uri,
                width: 200,
                height: 200,
              ),
            ),
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.mfaEnrollManual, style: textTheme.bodySmall),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  enrollment.secret,
                  key: const Key('mfa-secret'),
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                key: const Key('mfa-secret-copy'),
                tooltip: l10n.mfaCopy,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: enrollment.secret),
                  );
                  if (context.mounted) {
                    Toaster.of(context).info(l10n.mfaCopied);
                  }
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.md),
          Text(l10n.mfaEnrollStep2),
          const SizedBox(height: TicketSurSpacing.sm),
          MfaCodeForm(factorId: enrollment.factorId, onVerified: onVerified),
        ],
      ),
    );
  }
}

class _CodesView extends StatelessWidget {
  const new({required this.codes, required this.onDone});

  final List<String> codes;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return TikeoCard(
      key: const Key('mfa-codes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.mfaCodesTitle, style: textTheme.titleMedium),
          const SizedBox(height: TicketSurSpacing.xs),
          Text(l10n.mfaCodesBody),
          const SizedBox(height: TicketSurSpacing.md),
          Wrap(
            spacing: TicketSurSpacing.md,
            runSpacing: TicketSurSpacing.xs,
            children: [
              for (final code in codes)
                SelectableText(
                  code,
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: TicketSurSpacing.md),
          OutlinedButton.icon(
            key: const Key('mfa-codes-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: codes.join('\n')));
              if (context.mounted) Toaster.of(context).info(l10n.mfaCopied);
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.mfaCopy),
          ),
          const SizedBox(height: TicketSurSpacing.sm),
          FilledButton(
            key: const Key('mfa-codes-done'),
            onPressed: onDone,
            child: Text(l10n.mfaCodesDone),
          ),
        ],
      ),
    );
  }
}
