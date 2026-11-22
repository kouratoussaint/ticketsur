import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/ticketsur_colors.dart';
import 'package:ticketsur/design_system/ticketsur_spacing.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/auth/application/auth_providers.dart';
import 'package:ticketsur/features/events/domain/event.dart' show CoverImage;
import 'package:ticketsur/features/events/presentation/image_source_sheet.dart';
import 'package:ticketsur/features/profile/application/profile_providers.dart';
import 'package:ticketsur/features/profile/domain/profile.dart';
import 'package:ticketsur/features/profile/presentation/user_avatar.dart';
import 'package:ticketsur/l10n/l10n.dart';

/// Modification du profil : photo, nom affiché, téléphone.
class EditProfilePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _initFrom(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _name.text = profile.displayName;
    _phone.text = profile.phone ?? '';
  }

  String _messageFor(ProfileFailure failure) {
    final l10n = context.l10n;
    return switch (failure) {
      ProfileFailure.nameInvalid => l10n.profileNameError,
      ProfileFailure.phoneInvalid => l10n.profilePhoneError,
      ProfileFailure.avatarInvalid => l10n.profilePhotoError,
      ProfileFailure.network => l10n.authErrorNetwork,
      ProfileFailure.unknown => l10n.profileErrorUnknown,
    };
  }

  Future<void> _changePhoto() async {
    final l10n = context.l10n;
    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final toast = Toaster.of(context);
    final CoverImage? image;
    try {
      image = await ref.read(squareImagePickerProvider)(source);
    } on Object {
      toast.error(l10n.profilePhotoError);
      return;
    }
    if (image == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ref.read(profileProvider.notifier).setAvatar(image);
      toast.success(l10n.profilePhotoSaved);
    } on ProfileFailure catch (failure) {
      toast.error(_messageFor(failure));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .save(displayName: _name.text, phone: _phone.text);
      toast.success(l10n.profileSaved);
      if (mounted) context.popOr(AppRoutes.profile);
    } on ProfileFailure catch (failure) {
      toast.error(_messageFor(failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final email = ref.watch(currentUserProvider).value?.email ?? '';
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _initFrom(profile);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TicketSurSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _AvatarEditor(
                    busy: _uploading,
                    onTap: _changePhoto,
                    child: Hero(
                      tag: 'profile-avatar',
                      child: UserAvatar(
                        radius: 56,
                        initials: profile.initials,
                        url: profile.avatarUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.xs),
                Center(
                  child: TextButton(
                    key: const Key('profile-photo-change'),
                    onPressed: _uploading ? null : _changePhoto,
                    child: Text(l10n.profilePhotoChange),
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.md),
                TikeoCard(
                  key: const Key('profile-form-card'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('profile-name-field'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 60,
                        decoration: InputDecoration(
                          labelText: l10n.profileNameLabel,
                          hintText: l10n.profileNameHint,
                          prefixIcon: const Icon(Icons.badge_rounded),
                        ),
                        validator: (value) => isValidDisplayName(value ?? '')
                            ? null
                            : l10n.profileNameError,
                      ),
                      const SizedBox(height: TicketSurSpacing.xs),
                      TextFormField(
                        key: const Key('profile-phone-field'),
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: InputDecoration(
                          labelText: l10n.profilePhoneLabel,
                          hintText: l10n.profilePhoneHint,
                          helperText: l10n.profilePhoneHelp,
                          helperMaxLines: 2,
                          prefixIcon: const Icon(Icons.phone_rounded),
                        ),
                        validator: (value) => isValidPhone(value ?? '')
                            ? null
                            : l10n.profilePhoneError,
                        onFieldSubmitted: (_) => _save(),
                      ),
                      const SizedBox(height: TicketSurSpacing.md),
                      // L'adresse se change depuis « Sécurité » (lien envoyé).
                      TextFormField(
                        initialValue: email,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: l10n.profileEmailLabel,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TicketSurSpacing.xl),
                FilledButton(
                  key: const Key('profile-save'),
                  onPressed: _saving ? null : _save,
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

/// Photo cliquable avec pastille « appareil photo » et indicateur d'envoi.
class _AvatarEditor extends StatelessWidget {
  const new({required this.child, required this.busy, required this.onTap});

  final Widget child;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('profile-avatar-edit'),
      onTap: busy ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (busy)
            const SizedBox.square(
              dimension: 112,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TicketSurColors.mintDeep,
                shape: BoxShape.circle,
                border: Border.all(color: TicketSurColors.white, width: 3),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: 18,
                  color: TicketSurColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
