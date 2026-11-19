import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/presentation/auth_failure_copy.dart';
import 'package:ticketsur/features/events/application/cover_picker.dart';
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/events/presentation/image_source_sheet.dart';
import 'package:ticketsur/features/organizations/application/organization_providers.dart';
import 'package:ticketsur/features/organizations/domain/organization.dart';
import 'package:ticketsur/features/organizations/presentation/organization_copy.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/domain/profile.dart'
    show isValidPhone;
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Fiche de l'organisation active (propriétaires) : logo, nom, contacts,
/// ville.
class OrganizationEditPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OrganizationEditPage> createState() =>
      _OrganizationEditPageState();
}

class _OrganizationEditPageState extends ConsumerState<OrganizationEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _publicPhone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  String? _initializedFor;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _publicPhone.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  void _initFrom(Organization organization) {
    if (_initializedFor == organization.id) return;
    _initializedFor = organization.id;
    _name.text = organization.name;
    _phone.text = organization.phone ?? '';
    _publicPhone.text = organization.publicPhone ?? '';
    _email.text = organization.contactEmail ?? '';
    _city.text = organization.city ?? '';
  }

  Future<void> _changeLogo(Organization organization) async {
    final l10n = context.l10n;
    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final toast = Toaster.of(context);
    final CoverImage? image;
    try {
      image = await ref.read(squareImagePickerProvider)(source);
    } on Object {
      toast.error(l10n.orgErrorLogo);
      return;
    }
    if (image == null || !mounted) return;
    if (!acceptedCoverTypes.contains(image.mimeType) ||
        image.bytes.length > maxSquareImageBytes) {
      toast.error(l10n.orgErrorLogo);
      return;
    }
    setState(() => _uploading = true);
    try {
      await ref
          .read(organizationsProvider.notifier)
          .setLogo(organization.id, image);
      toast.success(l10n.orgLogoSaved);
    } on OrganizationFailure catch (failure) {
      toast.error(organizationFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save(Organization organization) async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(organizationsProvider.notifier)
          .updateDetails(
            organization.id,
            OrganizationDraft(
              name: _name.text,
              phone: _phone.text,
              publicPhone: _publicPhone.text,
              contactEmail: _email.text,
              city: _city.text,
            ),
          );
      toast.success(l10n.orgSaved);
      if (mounted) context.popOr(AppRoutes.profile);
    } on OrganizationFailure catch (failure) {
      toast.error(organizationFailureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final organization = ref.watch(activeOrganizationProvider);
    if (organization == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orgEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _initFrom(organization);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orgEditTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    key: const Key('org-logo-edit'),
                    onTap: _uploading ? null : () => _changeLogo(organization),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        UserAvatar(
                          radius: 52,
                          initials: initialsOf(organization.name),
                          url: organization.logoUrl,
                        ),
                        if (_uploading)
                          const SizedBox.square(
                            dimension: 104,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: TicketSurColors.mintDeep,
                            child: Icon(
                              Icons.photo_camera_rounded,
                              size: 16,
                              color: TicketSurColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    key: const Key('org-logo-change'),
                    onPressed: _uploading
                        ? null
                        : () => _changeLogo(organization),
                    child: Text(l10n.orgLogoChange),
                  ),
                ),
                Text(
                  l10n.orgEditHelp,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: TicketSurSpacing.md),
                TextFormField(
                  key: const Key('org-name-field'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: l10n.orgNameLabel,
                    prefixIcon: const Icon(Icons.apartment_rounded),
                  ),
                  validator: (value) {
                    final length = (value ?? '').trim().length;
                    return length < 2 || length > 120
                        ? l10n.orgErrorInvalidName
                        : null;
                  },
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                TextFormField(
                  key: const Key('org-phone-field'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.orgPhoneLabel,
                    hintText: l10n.profilePhoneHint,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) =>
                      isValidPhone(value ?? '') ? null : l10n.orgErrorPhone,
                ),
                const SizedBox(height: TicketSurSpacing.md),
                TextFormField(
                  key: const Key('org-public-phone-field'),
                  controller: _publicPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.orgPublicPhoneLabel,
                    hintText: l10n.profilePhoneHint,
                    helperText: l10n.orgPublicPhoneHelp,
                    helperMaxLines: 3,
                    prefixIcon: const Icon(Icons.chat_outlined),
                  ),
                  validator: (value) =>
                      isValidPhone(value ?? '') ? null : l10n.orgErrorPhone,
                ),
                const SizedBox(height: TicketSurSpacing.md),
                TextFormField(
                  key: const Key('org-email-field'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.orgEmailLabel,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? null
                      : validateEmail(l10n, value) == null
                      ? null
                      : l10n.orgErrorEmail,
                ),
                const SizedBox(height: TicketSurSpacing.md),
                TextFormField(
                  key: const Key('org-city-field'),
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: l10n.orgCityLabel,
                    hintText: l10n.eventCityHint,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                  validator: (value) {
                    final length = (value ?? '').trim().length;
                    return length == 1 ? l10n.orgErrorCity : null;
                  },
                  onFieldSubmitted: (_) => _save(organization),
                ),
                const SizedBox(height: TicketSurSpacing.xl),
                FilledButton(
                  key: const Key('org-save'),
                  onPressed: _saving ? null : () => _save(organization),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(l10n.profileSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
