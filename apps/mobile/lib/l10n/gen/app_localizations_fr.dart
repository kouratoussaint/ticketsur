// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'TicketSûr';

  @override
  String get appSlogan => 'Votre événement en un clic';

  @override
  String get welcomeSignIn => 'Se connecter';

  @override
  String get welcomeVerdictPreview => 'Aperçu des écrans de contrôle';

  @override
  String get verdictPreviewTitle => 'Écrans de verdict';

  @override
  String get verdictTitleAdmitted => 'ENTRÉE AUTORISÉE';

  @override
  String get verdictTitleRefused => 'ENTRÉE REFUSÉE';

  @override
  String get verdictTitleIndeterminate => 'ÉTAT À CONFIRMER';

  @override
  String get verdictVerifying => 'Vérification…';

  @override
  String get verdictVerifyingHint => 'Ne laissez pas entrer avant le verdict.';

  @override
  String get verdictReasonAccepted => 'Ticket valide — entrée autorisée';

  @override
  String get verdictReasonAlreadyUsed => 'Ticket déjà utilisé';

  @override
  String get verdictReasonRevoked => 'Ticket annulé';

  @override
  String get verdictReasonExpired => 'Ticket expiré';

  @override
  String get verdictReasonNotFound => 'Ticket introuvable';

  @override
  String get verdictReasonWrongEvent => 'Billet non valable pour cet événement';

  @override
  String get verdictReasonUnauthorized => 'Contrôle non autorisé';

  @override
  String get verdictReasonEventInactive =>
      'Contrôle indisponible pour cet événement';

  @override
  String get verdictReasonRateLimited => 'Trop de tentatives, réessayez';

  @override
  String get verdictReasonPending => 'Confirmation de validation en cours';

  @override
  String get verdictReasonUnavailable =>
      'Vérification impossible — connexion requise';

  @override
  String verdictFirstPassage(String time) {
    return 'Premier passage à $time';
  }

  @override
  String verdictFirstPassageAt(String time, String checkpoint) {
    return 'Premier passage à $time · $checkpoint';
  }

  @override
  String verdictReference(String reference) {
    return 'Réf. $reference';
  }

  @override
  String get verdictIndeterminateAdvice =>
      'Ne laissez pas entrer sur la base de l\'application seule.';

  @override
  String get verdictNextScan => 'Scanner suivant';

  @override
  String get verdictRetry => 'Réessayer la vérification';

  @override
  String get signInTitle => 'Connexion';

  @override
  String get signInEmailLabel => 'Adresse e-mail';

  @override
  String get signInPasswordLabel => 'Mot de passe';

  @override
  String get signInShowPassword => 'Afficher le mot de passe';

  @override
  String get signInHidePassword => 'Masquer le mot de passe';

  @override
  String get signInSubmit => 'Se connecter';

  @override
  String get signInForgotPassword => 'Mot de passe oublié ?';

  @override
  String get validationEmailRequired => 'Saisissez votre adresse e-mail';

  @override
  String get validationEmailInvalid => 'Adresse e-mail invalide';

  @override
  String get validationPasswordRequired => 'Saisissez votre mot de passe';

  @override
  String get authErrorInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Adresse e-mail non confirmée. Ouvrez le lien reçu par e-mail.';

  @override
  String get authErrorRateLimited =>
      'Trop de tentatives. Patientez une minute avant de réessayer.';

  @override
  String get authErrorNetwork =>
      'Connexion au serveur impossible. Vérifiez le réseau et réessayez.';

  @override
  String get authErrorUnknown => 'Une erreur est survenue. Réessayez.';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordIntro =>
      'Saisissez l\'adresse e-mail de votre compte. Vous recevrez un lien pour choisir un nouveau mot de passe.';

  @override
  String get forgotPasswordSubmit => 'Envoyer le lien';

  @override
  String forgotPasswordSent(String email) {
    return 'Si un compte existe pour $email, un e-mail de réinitialisation vient d\'être envoyé.';
  }

  @override
  String get forgotPasswordBackToSignIn => 'Retour à la connexion';

  @override
  String get homeTitle => 'Accueil';

  @override
  String homeSignedInAs(String email) {
    return 'Connecté : $email';
  }

  @override
  String get homeComingSoon =>
      'Les espaces organisateur et contrôleur arrivent dans les prochaines versions.';

  @override
  String get homeSignOut => 'Se déconnecter';

  @override
  String get configErrorTitle => 'Configuration manquante';

  @override
  String get configErrorHint =>
      'Lancez l\'application avec --dart-define-from-file=config/staging.json.';

  @override
  String get exitConfirm => 'Appuyez encore sur Retour pour quitter TicketSûr';

  @override
  String get navHome => 'Accueil';

  @override
  String get navEvents => 'Événements';

  @override
  String get navTickets => 'Billets';

  @override
  String get navTeam => 'Équipe';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeGreeting => 'Bienvenue sur TicketSûr';

  @override
  String get homeNextTitle => 'Bientôt dans votre espace';

  @override
  String phaseBadge(String phase) {
    return 'Phase $phase';
  }

  @override
  String get eventsSoonTitle => 'Vos événements';

  @override
  String get eventsSoonBody =>
      'Créer un événement, ses catégories de billets et ses points d\'entrée, puis affecter vos contrôleurs.';

  @override
  String get ticketsSoonTitle => 'Vos billets';

  @override
  String get ticketsSoonBody =>
      'Générer des billets à QR unique, à l\'unité ou par lots, les exporter en PDF et les révoquer.';

  @override
  String get teamSoonTitle => 'Votre équipe';

  @override
  String get teamSoonBody =>
      'Inviter des gestionnaires et des contrôleurs, puis les affecter à un événement et à une porte.';

  @override
  String get scanSoonTitle => 'Scanner à l\'entrée';

  @override
  String get scanSoonBody =>
      'Scan caméra avec verdict serveur en plein écran, une seule entrée par billet.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileAccountActive => 'Compte actif';

  @override
  String get profileAbout => 'À propos';
}
