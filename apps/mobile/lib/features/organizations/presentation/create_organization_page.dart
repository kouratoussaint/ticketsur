import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/double_back_to_exit.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/fade_slide_in.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/auth/presentation/auth_error_banner.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Création d'une organisation (ADR 0007 : libre-service).
///
/// [firstTime] : affichée d'office après la première connexion, tant que
/// l'utilisateur n'appartient à aucune organisation.
class CreateOrganizationPage extends ConsumerStatefulWidget {
  const new({this.firstTime = false, super.key});

  final bool firstTime;

  @override
  ConsumerState<CreateOrganizationPage> createState() =>
      _CreateOrganizationPageState();
}

class _CreateOrganizationPageState
    extends ConsumerState<CreateOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _submitting = false;
  OrganizationFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(organizationsProvider.notifier)
          .create(_name.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.orgCreated(created.name))),
      );
      if (!widget.firstTime) context.go(AppRoutes.home);
    } on OrganizationFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final failure = _failure;
    final page = Scaffold(
      appBar: AppBar(
        title: Text(
          widget.firstTime ? l10n.appName : l10n.orgCreateAnotherTitle,
        ),
        actions: [
          if (widget.firstTime)
            IconButton(
              key: const Key('org-first-sign-out'),
              tooltip: l10n.homeSignOut,
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(TicketSurSpacing.lg),
            children: [
              FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(TicketSurRadii.lg),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 36,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: TicketSurSpacing.lg),
                    Text(l10n.orgCreateTitle, style: textTheme.headlineSmall),
                    const SizedBox(height: TicketSurSpacing.sm),
                    Text(
                      l10n.orgCreateIntro,
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TicketSurSpacing.lg),
              if (failure != null) ...[
                AuthErrorBanner(
                  message: organizationFailureMessage(l10n, failure),
                ),
                const SizedBox(height: TicketSurSpacing.md),
              ],
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: TextFormField(
                  key: const Key('org-name'),
                  controller: _name,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: 120,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.orgNameLabel,
                    hintText: l10n.orgNameHint,
                  ),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? l10n.orgNameRequired
                      : null,
                ),
              ),
              const SizedBox(height: TicketSurSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: FilledButton(
                  key: const Key('org-create-submit'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(l10n.orgCreateSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Première fois : écran racine, Retour suit la règle du double appui.
    return widget.firstTime ? DoubleBackToExit(child: page) : page;
  }
}
