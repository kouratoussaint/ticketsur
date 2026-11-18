import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Nom de marque, accent circonflexe obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'TicketSûr'**
  String get appName;

  /// Slogan officiel, ne pas modifier.
  ///
  /// In fr, this message translates to:
  /// **'Votre événement en un clic'**
  String get appSlogan;

  /// No description provided for @welcomeSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get welcomeSignIn;

  /// No description provided for @welcomeVerdictPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des écrans de contrôle'**
  String get welcomeVerdictPreview;

  /// No description provided for @verdictPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Écrans de verdict'**
  String get verdictPreviewTitle;

  /// No description provided for @verdictTitleAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'ENTRÉE AUTORISÉE'**
  String get verdictTitleAdmitted;

  /// No description provided for @verdictTitleRefused.
  ///
  /// In fr, this message translates to:
  /// **'ENTRÉE REFUSÉE'**
  String get verdictTitleRefused;

  /// No description provided for @verdictTitleIndeterminate.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAT À CONFIRMER'**
  String get verdictTitleIndeterminate;

  /// No description provided for @verdictVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification…'**
  String get verdictVerifying;

  /// No description provided for @verdictVerifyingHint.
  ///
  /// In fr, this message translates to:
  /// **'Ne laissez pas entrer avant le verdict.'**
  String get verdictVerifyingHint;

  /// No description provided for @verdictReasonAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Ticket valide — entrée autorisée'**
  String get verdictReasonAccepted;

  /// No description provided for @verdictReasonAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Ticket déjà utilisé'**
  String get verdictReasonAlreadyUsed;

  /// No description provided for @verdictReasonRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Ticket annulé'**
  String get verdictReasonRevoked;

  /// No description provided for @verdictReasonExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ticket expiré'**
  String get verdictReasonExpired;

  /// No description provided for @verdictReasonNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ticket introuvable'**
  String get verdictReasonNotFound;

  /// No description provided for @verdictReasonWrongEvent.
  ///
  /// In fr, this message translates to:
  /// **'Billet non valable pour cet événement'**
  String get verdictReasonWrongEvent;

  /// No description provided for @verdictReasonUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle non autorisé'**
  String get verdictReasonUnauthorized;

  /// No description provided for @verdictReasonEventInactive.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle indisponible pour cet événement'**
  String get verdictReasonEventInactive;

  /// No description provided for @verdictReasonRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives, réessayez'**
  String get verdictReasonRateLimited;

  /// No description provided for @verdictReasonPending.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation de validation en cours'**
  String get verdictReasonPending;

  /// No description provided for @verdictReasonUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vérification impossible — connexion requise'**
  String get verdictReasonUnavailable;

  /// No description provided for @verdictFirstPassage.
  ///
  /// In fr, this message translates to:
  /// **'Premier passage à {time}'**
  String verdictFirstPassage(String time);

  /// No description provided for @verdictFirstPassageAt.
  ///
  /// In fr, this message translates to:
  /// **'Premier passage à {time} · {checkpoint}'**
  String verdictFirstPassageAt(String time, String checkpoint);

  /// No description provided for @verdictReference.
  ///
  /// In fr, this message translates to:
  /// **'Réf. {reference}'**
  String verdictReference(String reference);

  /// No description provided for @verdictIndeterminateAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Ne laissez pas entrer sur la base de l\'application seule.'**
  String get verdictIndeterminateAdvice;

  /// No description provided for @verdictNextScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner suivant'**
  String get verdictNextScan;

  /// No description provided for @verdictRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer la vérification'**
  String get verdictRetry;

  /// No description provided for @signInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get signInTitle;

  /// No description provided for @signInEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get signInEmailLabel;

  /// No description provided for @signInPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get signInPasswordLabel;

  /// No description provided for @signInShowPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get signInShowPassword;

  /// No description provided for @signInHidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get signInHidePassword;

  /// No description provided for @signInSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signInSubmit;

  /// No description provided for @signInForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get signInForgotPassword;

  /// No description provided for @validationEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre adresse e-mail'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre mot de passe'**
  String get validationPasswordRequired;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail non confirmée. Ouvrez le lien reçu par e-mail.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez une minute avant de réessayer.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au serveur impossible. Vérifiez le réseau et réessayez.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get authErrorUnknown;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordIntro.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez l\'adresse e-mail de votre compte. Vous recevrez un lien pour choisir un nouveau mot de passe.'**
  String get forgotPasswordIntro;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte existe pour {email}, un e-mail de réinitialisation vient d\'être envoyé.'**
  String forgotPasswordSent(String email);

  /// No description provided for @forgotPasswordBackToSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get forgotPasswordBackToSignIn;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTitle;

  /// No description provided for @homeSignedInAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté : {email}'**
  String homeSignedInAs(String email);

  /// No description provided for @homeComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Les espaces organisateur et contrôleur arrivent dans les prochaines versions.'**
  String get homeComingSoon;

  /// No description provided for @homeSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get homeSignOut;

  /// No description provided for @configErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration manquante'**
  String get configErrorTitle;

  /// No description provided for @configErrorHint.
  ///
  /// In fr, this message translates to:
  /// **'Lancez l\'application avec --dart-define-from-file=config/staging.json.'**
  String get configErrorHint;

  /// No description provided for @exitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez encore sur Retour pour quitter TicketSûr'**
  String get exitConfirm;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get navEvents;

  /// No description provided for @navTickets.
  ///
  /// In fr, this message translates to:
  /// **'Billets'**
  String get navTickets;

  /// No description provided for @navTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get navTeam;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur TicketSûr'**
  String get homeGreeting;

  /// No description provided for @homeNextTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt dans votre espace'**
  String get homeNextTitle;

  /// No description provided for @phaseBadge.
  ///
  /// In fr, this message translates to:
  /// **'Phase {phase}'**
  String phaseBadge(String phase);

  /// No description provided for @ticketsSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos billets'**
  String get ticketsSoonTitle;

  /// No description provided for @ticketsSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'Générer des billets à QR unique, à l\'unité ou par lots, les exporter en PDF et les révoquer.'**
  String get ticketsSoonBody;

  /// No description provided for @teamSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre équipe'**
  String get teamSoonTitle;

  /// No description provided for @teamSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des gestionnaires et des contrôleurs, puis les affecter à un événement et à une porte.'**
  String get teamSoonBody;

  /// No description provided for @scanSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner à l\'entrée'**
  String get scanSoonTitle;

  /// No description provided for @scanSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'Scan caméra avec verdict serveur en plein écran, une seule entrée par billet.'**
  String get scanSoonBody;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileAccountActive.
  ///
  /// In fr, this message translates to:
  /// **'Compte actif'**
  String get profileAccountActive;

  /// No description provided for @profileAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profileAbout;

  /// No description provided for @orgLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de vos organisations…'**
  String get orgLoading;

  /// No description provided for @orgLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos organisations.'**
  String get orgLoadError;

  /// No description provided for @orgRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get orgRetry;

  /// No description provided for @orgCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre organisation'**
  String get orgCreateTitle;

  /// No description provided for @orgCreateIntro.
  ///
  /// In fr, this message translates to:
  /// **'Votre organisation regroupe vos événements, vos billets et votre équipe. Vous en serez le propriétaire.'**
  String get orgCreateIntro;

  /// No description provided for @orgCreateAnotherTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle organisation'**
  String get orgCreateAnotherTitle;

  /// No description provided for @orgNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'organisation'**
  String get orgNameLabel;

  /// No description provided for @orgNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Festival des Nuits Sacrées'**
  String get orgNameHint;

  /// No description provided for @orgNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nom d\'au moins 2 caractères'**
  String get orgNameRequired;

  /// No description provided for @orgCreateSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'organisation'**
  String get orgCreateSubmit;

  /// No description provided for @orgErrorInvalidName.
  ///
  /// In fr, this message translates to:
  /// **'Nom invalide : entre 2 et 120 caractères.'**
  String get orgErrorInvalidName;

  /// No description provided for @orgErrorLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint la limite de 5 organisations.'**
  String get orgErrorLimit;

  /// No description provided for @orgCreated.
  ///
  /// In fr, this message translates to:
  /// **'Organisation « {name} » créée'**
  String orgCreated(String name);

  /// No description provided for @orgSwitchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'organisation'**
  String get orgSwitchTitle;

  /// No description provided for @orgSwitchAction.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get orgSwitchAction;

  /// No description provided for @orgCreateAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer une organisation'**
  String get orgCreateAction;

  /// No description provided for @orgActiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Organisation'**
  String get orgActiveLabel;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In fr, this message translates to:
  /// **'Gestionnaire'**
  String get roleManager;

  /// No description provided for @roleController.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleur'**
  String get roleController;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement pour l\'instant'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier événement : titre, lieu, dates et fuseau horaire. Il reste en brouillon tant que vous ne le publiez pas.'**
  String get eventsEmptyBody;

  /// No description provided for @eventsEmptyControllerBody.
  ///
  /// In fr, this message translates to:
  /// **'Les événements auxquels vous êtes affecté apparaîtront ici.'**
  String get eventsEmptyControllerBody;

  /// No description provided for @eventsFilterEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement dans cette catégorie.'**
  String get eventsFilterEmpty;

  /// No description provided for @eventsNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get eventsNew;

  /// No description provided for @eventsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les événements.'**
  String get eventsLoadError;

  /// No description provided for @eventsFilterActive.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get eventsFilterActive;

  /// No description provided for @eventsFilterDrafts.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons'**
  String get eventsFilterDrafts;

  /// No description provided for @eventsFilterPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiés'**
  String get eventsFilterPublished;

  /// No description provided for @eventsFilterDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get eventsFilterDone;

  /// No description provided for @eventsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get eventsFilterAll;

  /// No description provided for @eventStatusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get eventStatusDraft;

  /// No description provided for @eventStatusPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get eventStatusPublished;

  /// No description provided for @eventStatusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get eventStatusInProgress;

  /// No description provided for @eventStatusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturé'**
  String get eventStatusClosed;

  /// No description provided for @eventStatusArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get eventStatusArchived;

  /// No description provided for @eventStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get eventStatusCancelled;

  /// No description provided for @eventFormCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get eventFormCreateTitle;

  /// No description provided for @eventFormEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'événement'**
  String get eventFormEditTitle;

  /// No description provided for @eventTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get eventTitleLabel;

  /// No description provided for @eventTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Concert de la Saint-Sylvestre'**
  String get eventTitleHint;

  /// No description provided for @eventVenueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lieu (facultatif)'**
  String get eventVenueLabel;

  /// No description provided for @eventVenueHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Palais des sports, Ouaga 2000'**
  String get eventVenueHint;

  /// No description provided for @eventTimezoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fuseau horaire'**
  String get eventTimezoneLabel;

  /// No description provided for @eventTimezoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les heures sont saisies et affichées dans ce fuseau.'**
  String get eventTimezoneHelp;

  /// No description provided for @eventStartsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get eventStartsLabel;

  /// No description provided for @eventEndsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get eventEndsLabel;

  /// No description provided for @eventDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get eventDateLabel;

  /// No description provided for @eventTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get eventTimeLabel;

  /// No description provided for @eventCapacityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Capacité (facultatif)'**
  String get eventCapacityLabel;

  /// No description provided for @eventCapacityHint.
  ///
  /// In fr, this message translates to:
  /// **'Nombre maximal de participants'**
  String get eventCapacityHint;

  /// No description provided for @eventFormSubmitCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer le brouillon'**
  String get eventFormSubmitCreate;

  /// No description provided for @eventFormSubmitSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get eventFormSubmitSave;

  /// No description provided for @eventCreated.
  ///
  /// In fr, this message translates to:
  /// **'« {title} » créé en brouillon'**
  String eventCreated(String title);

  /// No description provided for @eventSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées'**
  String get eventSaved;

  /// No description provided for @eventErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un titre de 2 à 160 caractères.'**
  String get eventErrorTitle;

  /// No description provided for @eventErrorVenue.
  ///
  /// In fr, this message translates to:
  /// **'Le lieu ne doit pas dépasser 160 caractères.'**
  String get eventErrorVenue;

  /// No description provided for @eventErrorDates.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit suivre le début, sur 31 jours au plus.'**
  String get eventErrorDates;

  /// No description provided for @eventErrorTimezone.
  ///
  /// In fr, this message translates to:
  /// **'Fuseau horaire inconnu.'**
  String get eventErrorTimezone;

  /// No description provided for @eventErrorCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une capacité entre 1 et 1 000 000.'**
  String get eventErrorCapacity;

  /// No description provided for @eventErrorCapacityBelowIssued.
  ///
  /// In fr, this message translates to:
  /// **'La capacité ne peut pas être inférieure au nombre de billets déjà émis.'**
  String get eventErrorCapacityBelowIssued;

  /// No description provided for @eventErrorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement ne peut plus être modifié.'**
  String get eventErrorLocked;

  /// No description provided for @eventErrorInvalidTransition.
  ///
  /// In fr, this message translates to:
  /// **'Ce changement de statut n\'est pas permis.'**
  String get eventErrorInvalidTransition;

  /// No description provided for @eventErrorHasTickets.
  ///
  /// In fr, this message translates to:
  /// **'Des billets ont été émis : impossible de repasser en brouillon.'**
  String get eventErrorHasTickets;

  /// No description provided for @eventErrorAlreadyEnded.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est déjà terminé : il ne peut pas être publié.'**
  String get eventErrorAlreadyEnded;

  /// No description provided for @eventErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Événement introuvable ou droits insuffisants.'**
  String get eventErrorNotFound;

  /// No description provided for @eventErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get eventErrorNetwork;

  /// No description provided for @eventErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue. Réessayez.'**
  String get eventErrorUnknown;

  /// No description provided for @eventDetailDates.
  ///
  /// In fr, this message translates to:
  /// **'Dates'**
  String get eventDetailDates;

  /// No description provided for @eventDetailVenue.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get eventDetailVenue;

  /// No description provided for @eventDetailCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get eventDetailCapacity;

  /// No description provided for @eventCapacityValue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String eventCapacityValue(int count);

  /// No description provided for @eventNoCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Non limitée'**
  String get eventNoCapacity;

  /// No description provided for @eventNoVenue.
  ///
  /// In fr, this message translates to:
  /// **'Non précisé'**
  String get eventNoVenue;

  /// No description provided for @eventTimeZoneLine.
  ///
  /// In fr, this message translates to:
  /// **'{zone} ({offset})'**
  String eventTimeZoneLine(String zone, String offset);

  /// No description provided for @eventEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get eventEdit;

  /// No description provided for @eventLifecycleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get eventLifecycleTitle;

  /// No description provided for @eventLifecycleDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon : invisible des contrôleurs. Publiez-le pour émettre des billets et ouvrir le contrôle.'**
  String get eventLifecycleDraft;

  /// No description provided for @eventLifecyclePublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié : le contrôle est possible de 3 h avant le début à 6 h après la fin.'**
  String get eventLifecyclePublished;

  /// No description provided for @eventLifecycleInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle en cours aux portes.'**
  String get eventLifecycleInProgress;

  /// No description provided for @eventLifecycleClosed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturé : plus aucune entrée n\'est acceptée.'**
  String get eventLifecycleClosed;

  /// No description provided for @eventLifecycleArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé : consultation seule.'**
  String get eventLifecycleArchived;

  /// No description provided for @eventLifecycleCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé : aucune entrée n\'est acceptée.'**
  String get eventLifecycleCancelled;

  /// No description provided for @eventActionPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get eventActionPublish;

  /// No description provided for @eventActionStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer le contrôle'**
  String get eventActionStart;

  /// No description provided for @eventActionClose.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer'**
  String get eventActionClose;

  /// No description provided for @eventActionArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get eventActionArchive;

  /// No description provided for @eventActionDraft.
  ///
  /// In fr, this message translates to:
  /// **'Repasser en brouillon'**
  String get eventActionDraft;

  /// No description provided for @eventActionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'événement'**
  String get eventActionCancel;

  /// No description provided for @eventConfirmPublish.
  ///
  /// In fr, this message translates to:
  /// **'Les billets pourront être émis et contrôlés aux portes.'**
  String get eventConfirmPublish;

  /// No description provided for @eventConfirmStart.
  ///
  /// In fr, this message translates to:
  /// **'Les contrôleurs affectés pourront valider les entrées.'**
  String get eventConfirmStart;

  /// No description provided for @eventConfirmClose.
  ///
  /// In fr, this message translates to:
  /// **'Plus aucune entrée ne sera acceptée. Cette action est définitive.'**
  String get eventConfirmClose;

  /// No description provided for @eventConfirmArchive.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement passera en consultation seule. Cette action est définitive.'**
  String get eventConfirmArchive;

  /// No description provided for @eventConfirmDraft.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement redevient modifiable et invisible des contrôleurs.'**
  String get eventConfirmDraft;

  /// No description provided for @eventConfirmCancel.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée ne sera acceptée. Cette action est définitive.'**
  String get eventConfirmCancel;

  /// No description provided for @eventConfirmBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get eventConfirmBack;

  /// No description provided for @eventStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String eventStatusChanged(String status);

  /// No description provided for @eventNextStepsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines étapes'**
  String get eventNextStepsTitle;

  /// No description provided for @eventNextCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories de billets et quotas'**
  String get eventNextCategories;

  /// No description provided for @eventNextCheckpoints.
  ///
  /// In fr, this message translates to:
  /// **'Portes de contrôle'**
  String get eventNextCheckpoints;

  /// No description provided for @eventNextTeam.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleurs affectés'**
  String get eventNextTeam;

  /// No description provided for @eventNextSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get eventNextSoon;

  /// No description provided for @eventNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Événement introuvable'**
  String get eventNotFoundTitle;

  /// No description provided for @homeNextEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prochain événement'**
  String get homeNextEventTitle;

  /// No description provided for @homeNoEventBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement à venir.'**
  String get homeNoEventBody;

  /// No description provided for @homeCreateEvent.
  ///
  /// In fr, this message translates to:
  /// **'Créer un événement'**
  String get homeCreateEvent;

  /// No description provided for @homeSeeEvents.
  ///
  /// In fr, this message translates to:
  /// **'Voir les événements'**
  String get homeSeeEvents;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
