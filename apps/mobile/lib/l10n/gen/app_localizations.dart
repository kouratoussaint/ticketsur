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

  /// No description provided for @categoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories de billets'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie. Ajoutez-en une, par exemple Standard, VIP ou Invitation.'**
  String get categoriesEmpty;

  /// No description provided for @setupAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get setupAdd;

  /// No description provided for @setupSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get setupSave;

  /// No description provided for @setupCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get setupCancel;

  /// No description provided for @setupLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible.'**
  String get setupLoadError;

  /// No description provided for @categoryCounts.
  ///
  /// In fr, this message translates to:
  /// **'{issued} émis · {redeemed} entrés'**
  String categoryCounts(int issued, int redeemed);

  /// No description provided for @categoryQuota.
  ///
  /// In fr, this message translates to:
  /// **'Quota : {capacity}'**
  String categoryQuota(int capacity);

  /// No description provided for @categoryNoQuota.
  ///
  /// In fr, this message translates to:
  /// **'Sans quota'**
  String get categoryNoQuota;

  /// No description provided for @categoriesTotal.
  ///
  /// In fr, this message translates to:
  /// **'{issued} billets émis sur {capacity}'**
  String categoriesTotal(int issued, int capacity);

  /// No description provided for @categoriesTotalUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'{issued} billets émis, capacité non limitée'**
  String categoriesTotalUnlimited(int issued);

  /// No description provided for @categoryNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoryNewTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get categoryEditTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. VIP'**
  String get categoryNameHint;

  /// No description provided for @categoryQuotaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quota (facultatif)'**
  String get categoryQuotaLabel;

  /// No description provided for @categoryQuotaHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vide : limité seulement par la capacité de l\'événement.'**
  String get categoryQuotaHelp;

  /// No description provided for @categoryDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie ?'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimée. C\'est impossible si des billets y ont été émis.'**
  String categoryDeleteBody(String name);

  /// No description provided for @categorySaved.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie enregistrée'**
  String get categorySaved;

  /// No description provided for @categoryDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie supprimée'**
  String get categoryDeleted;

  /// No description provided for @checkpointsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Portes de contrôle'**
  String get checkpointsTitle;

  /// No description provided for @checkpointsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune porte. Ajoutez les entrées où vos contrôleurs scanneront les billets.'**
  String get checkpointsEmpty;

  /// No description provided for @checkpointActive.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get checkpointActive;

  /// No description provided for @checkpointInactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée : scans refusés'**
  String get checkpointInactive;

  /// No description provided for @checkpointNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle porte'**
  String get checkpointNewTitle;

  /// No description provided for @checkpointEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la porte'**
  String get checkpointEditTitle;

  /// No description provided for @checkpointNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Entrée principale'**
  String get checkpointNameHint;

  /// No description provided for @checkpointDeactivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la porte ?'**
  String get checkpointDeactivateTitle;

  /// No description provided for @checkpointDeactivateBody.
  ///
  /// In fr, this message translates to:
  /// **'Les scans à « {name} » seront refusés immédiatement, jusqu\'à sa réactivation.'**
  String checkpointDeactivateBody(String name);

  /// No description provided for @checkpointDeactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get checkpointDeactivate;

  /// No description provided for @checkpointSaved.
  ///
  /// In fr, this message translates to:
  /// **'Porte enregistrée'**
  String get checkpointSaved;

  /// No description provided for @setupErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Élément introuvable ou droits insuffisants.'**
  String get setupErrorNotFound;

  /// No description provided for @setupErrorName.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nom de 1 à 60 caractères.'**
  String get setupErrorName;

  /// No description provided for @setupErrorNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom est déjà utilisé pour cet événement.'**
  String get setupErrorNameTaken;

  /// No description provided for @setupErrorCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un quota entre 1 et 1 000 000.'**
  String get setupErrorCapacity;

  /// No description provided for @setupErrorCapacityBelowIssued.
  ///
  /// In fr, this message translates to:
  /// **'Le quota ne peut pas être inférieur aux billets déjà émis.'**
  String get setupErrorCapacityBelowIssued;

  /// No description provided for @setupErrorHasTickets.
  ///
  /// In fr, this message translates to:
  /// **'Des billets existent dans cette catégorie : suppression impossible.'**
  String get setupErrorHasTickets;

  /// No description provided for @setupErrorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Événement clôturé : sa configuration est figée.'**
  String get setupErrorLocked;

  /// No description provided for @teamInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get teamInvite;

  /// No description provided for @teamMembersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get teamMembersTitle;

  /// No description provided for @teamInvitationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitations en cours'**
  String get teamInvitationsTitle;

  /// No description provided for @teamInvitationLine.
  ///
  /// In fr, this message translates to:
  /// **'{role} · code …{hint}'**
  String teamInvitationLine(String role, String hint);

  /// No description provided for @teamInvitationDetail.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date} · {uses} sur {max}'**
  String teamInvitationDetail(String date, int uses, int max);

  /// No description provided for @teamRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get teamRevoke;

  /// No description provided for @teamRevokeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer l\'invitation ?'**
  String get teamRevokeTitle;

  /// No description provided for @teamRevokeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le code se terminant par {hint} ne fonctionnera plus.'**
  String teamRevokeBody(String hint);

  /// No description provided for @teamInactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get teamInactive;

  /// No description provided for @teamYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get teamYou;

  /// No description provided for @teamControllerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipe gérée par les organisateurs'**
  String get teamControllerTitle;

  /// No description provided for @teamControllerBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes contrôleur de « {org} ». Les organisateurs gèrent l\'équipe et vos affectations aux portes.'**
  String teamControllerBody(String org);

  /// No description provided for @inviteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inviter dans l\'équipe'**
  String get inviteTitle;

  /// No description provided for @inviteRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get inviteRoleLabel;

  /// No description provided for @inviteRoleControllerHelp.
  ///
  /// In fr, this message translates to:
  /// **'Scanne les billets aux portes qui lui sont affectées.'**
  String get inviteRoleControllerHelp;

  /// No description provided for @inviteRoleManagerHelp.
  ///
  /// In fr, this message translates to:
  /// **'Gère les événements, les billets et les contrôleurs.'**
  String get inviteRoleManagerHelp;

  /// No description provided for @inviteValidity.
  ///
  /// In fr, this message translates to:
  /// **'Validité'**
  String get inviteValidity;

  /// No description provided for @inviteDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour} other{{days} jours}}'**
  String inviteDays(int days);

  /// No description provided for @inviteUses.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de personnes'**
  String get inviteUses;

  /// No description provided for @inviteUsesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 personne} other{{count} personnes}}'**
  String inviteUsesCount(int count);

  /// No description provided for @inviteCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer le code'**
  String get inviteCreate;

  /// No description provided for @inviteCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez-le maintenant : il ne sera plus jamais affiché.'**
  String get inviteCodeHint;

  /// No description provided for @inviteCodeValid.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu\'au {date}'**
  String inviteCodeValid(String date);

  /// No description provided for @inviteShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get inviteShare;

  /// No description provided for @inviteCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get inviteCopy;

  /// No description provided for @inviteCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get inviteCopied;

  /// No description provided for @inviteShareText.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez « {org} » sur TicketSûr en tant que {role}. Dans l\'application, touchez « Rejoindre avec un code » et saisissez {code} (valable jusqu\'au {date}).'**
  String inviteShareText(String org, String role, String code, String date);

  /// No description provided for @inviteDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get inviteDone;

  /// No description provided for @memberRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get memberRoleLabel;

  /// No description provided for @memberActiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Accès actif'**
  String get memberActiveLabel;

  /// No description provided for @memberActiveHelp.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé : plus aucune action possible, scans refusés immédiatement.'**
  String get memberActiveHelp;

  /// No description provided for @memberSaved.
  ///
  /// In fr, this message translates to:
  /// **'Accès mis à jour'**
  String get memberSaved;

  /// No description provided for @teamErrorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Action non autorisée pour votre rôle.'**
  String get teamErrorForbidden;

  /// No description provided for @teamErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres invalides.'**
  String get teamErrorInvalid;

  /// No description provided for @teamErrorMemberNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Membre introuvable ou accès désactivé.'**
  String get teamErrorMemberNotFound;

  /// No description provided for @teamErrorIsOwner.
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire ne peut pas être modifié.'**
  String get teamErrorIsOwner;

  /// No description provided for @teamErrorIsSelf.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas modifier votre propre accès.'**
  String get teamErrorIsSelf;

  /// No description provided for @teamErrorCheckpoint.
  ///
  /// In fr, this message translates to:
  /// **'Porte inconnue pour cet événement.'**
  String get teamErrorCheckpoint;

  /// No description provided for @joinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre une organisation'**
  String get joinTitle;

  /// No description provided for @joinIntro.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code reçu d\'un organisateur. Il commence par TSI.'**
  String get joinIntro;

  /// No description provided for @joinCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get joinCodeLabel;

  /// No description provided for @joinSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinSubmit;

  /// No description provided for @joinWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans « {org} »'**
  String joinWelcome(String org);

  /// No description provided for @joinInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code inconnu ou révoqué. Vérifiez-le auprès de l\'organisateur.'**
  String get joinInvalid;

  /// No description provided for @joinExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré ou a déjà servi. Demandez-en un nouveau.'**
  String get joinExpired;

  /// No description provided for @joinAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites déjà partie de cette organisation.'**
  String get joinAlreadyMember;

  /// No description provided for @joinRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessayez dans un quart d\'heure.'**
  String get joinRateLimited;

  /// No description provided for @joinUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous.'**
  String get joinUnauthorized;

  /// No description provided for @joinAction.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre avec un code'**
  String get joinAction;

  /// No description provided for @joinHaveCode.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un code d\'invitation'**
  String get joinHaveCode;

  /// No description provided for @eventTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleurs affectés'**
  String get eventTeamTitle;

  /// No description provided for @eventTeamEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'est affecté. Ajoutez les membres qui scanneront à cet événement.'**
  String get eventTeamEmpty;

  /// No description provided for @eventTeamAllCheckpoints.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les portes'**
  String get eventTeamAllCheckpoints;

  /// No description provided for @eventTeamAssignTitle.
  ///
  /// In fr, this message translates to:
  /// **'Affecter un membre'**
  String get eventTeamAssignTitle;

  /// No description provided for @eventTeamMemberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get eventTeamMemberLabel;

  /// No description provided for @eventTeamCheckpointLabel.
  ///
  /// In fr, this message translates to:
  /// **'Porte'**
  String get eventTeamCheckpointLabel;

  /// No description provided for @eventTeamAssign.
  ///
  /// In fr, this message translates to:
  /// **'Affecter'**
  String get eventTeamAssign;

  /// No description provided for @eventTeamRemoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'affectation ?'**
  String get eventTeamRemoveTitle;

  /// No description provided for @eventTeamRemoveBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne pourra plus scanner à cette porte.'**
  String eventTeamRemoveBody(String name);

  /// No description provided for @eventTeamRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get eventTeamRemove;

  /// No description provided for @eventTeamNoMembers.
  ///
  /// In fr, this message translates to:
  /// **'Invitez d\'abord des membres depuis l\'onglet Équipe.'**
  String get eventTeamNoMembers;

  /// No description provided for @eventTeamMemberInactive.
  ///
  /// In fr, this message translates to:
  /// **'Accès désactivé'**
  String get eventTeamMemberInactive;

  /// No description provided for @ticketRevokedStamp.
  ///
  /// In fr, this message translates to:
  /// **'Billet annulé'**
  String get ticketRevokedStamp;

  /// No description provided for @ticketRedeemedStamp.
  ///
  /// In fr, this message translates to:
  /// **'UTILISÉ'**
  String get ticketRedeemedStamp;

  /// No description provided for @ticketQrHidden.
  ///
  /// In fr, this message translates to:
  /// **'QR masqué'**
  String get ticketQrHidden;

  /// No description provided for @ticketFooter.
  ///
  /// In fr, this message translates to:
  /// **'Billet à usage unique. Ne le publiez pas : la première présentation à l\'entrée fait foi.'**
  String get ticketFooter;

  /// No description provided for @ticketsNoEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement publié'**
  String get ticketsNoEventTitle;

  /// No description provided for @ticketsNoEventBody.
  ///
  /// In fr, this message translates to:
  /// **'Publiez un événement pour émettre ses billets.'**
  String get ticketsNoEventBody;

  /// No description provided for @ticketsGoEvents.
  ///
  /// In fr, this message translates to:
  /// **'Voir les événements'**
  String get ticketsGoEvents;

  /// No description provided for @ticketsEventLabel.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get ticketsEventLabel;

  /// No description provided for @ticketsSummary.
  ///
  /// In fr, this message translates to:
  /// **'{issued} émis · {redeemed} entrés'**
  String ticketsSummary(int issued, int redeemed);

  /// No description provided for @ticketsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get ticketsFilterAll;

  /// No description provided for @ticketsFilterValid.
  ///
  /// In fr, this message translates to:
  /// **'Valables'**
  String get ticketsFilterValid;

  /// No description provided for @ticketsFilterRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Utilisés'**
  String get ticketsFilterRedeemed;

  /// No description provided for @ticketsFilterRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Annulés'**
  String get ticketsFilterRevoked;

  /// No description provided for @ticketsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Référence ou catégorie'**
  String get ticketsSearchHint;

  /// No description provided for @ticketsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun billet pour l\'instant. Touchez « Émettre » pour créer les premiers.'**
  String get ticketsEmpty;

  /// No description provided for @ticketsEmptyFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun billet ne correspond.'**
  String get ticketsEmptyFilter;

  /// No description provided for @ticketsLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus'**
  String get ticketsLoadMore;

  /// No description provided for @ticketsCount.
  ///
  /// In fr, this message translates to:
  /// **'{shown} sur {total}'**
  String ticketsCount(int shown, int total);

  /// No description provided for @ticketsIssue.
  ///
  /// In fr, this message translates to:
  /// **'Émettre'**
  String get ticketsIssue;

  /// No description provided for @ticketsControllerBody.
  ///
  /// In fr, this message translates to:
  /// **'Les billets sont gérés par les organisateurs. Vous les contrôlerez à l\'entrée.'**
  String get ticketsControllerBody;

  /// No description provided for @ticketStatusIssued.
  ///
  /// In fr, this message translates to:
  /// **'Valable'**
  String get ticketStatusIssued;

  /// No description provided for @ticketStatusRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé'**
  String get ticketStatusRedeemed;

  /// No description provided for @ticketStatusRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get ticketStatusRevoked;

  /// No description provided for @ticketStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get ticketStatusExpired;

  /// No description provided for @issueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Émettre des billets'**
  String get issueTitle;

  /// No description provided for @issueCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get issueCategory;

  /// No description provided for @issueRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count} restants'**
  String issueRemaining(int count);

  /// No description provided for @issueUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'sans quota'**
  String get issueUnlimited;

  /// No description provided for @issueQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de billets'**
  String get issueQuantity;

  /// No description provided for @issueQuantityHelp.
  ///
  /// In fr, this message translates to:
  /// **'De 1 à 500 par lot.'**
  String get issueQuantityHelp;

  /// No description provided for @issueQuantityError.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre entre 1 et 500.'**
  String get issueQuantityError;

  /// No description provided for @issueSubmit.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Émettre 1 billet} other{Émettre {count} billets}}'**
  String issueSubmit(int count);

  /// No description provided for @issueNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord une catégorie dans la fiche de l\'événement.'**
  String get issueNoCategory;

  /// No description provided for @issueDraft.
  ///
  /// In fr, this message translates to:
  /// **'Publiez l\'événement pour émettre des billets.'**
  String get issueDraft;

  /// No description provided for @issueDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 billet émis} other{{count} billets émis}}'**
  String issueDoneTitle(int count);

  /// No description provided for @issueDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'Partagez-les maintenant. Vous pourrez aussi les retélécharger plus tard depuis leur fiche.'**
  String get issueDoneBody;

  /// No description provided for @issueSharePdf.
  ///
  /// In fr, this message translates to:
  /// **'Partager en PDF'**
  String get issueSharePdf;

  /// No description provided for @issueSeeTickets.
  ///
  /// In fr, this message translates to:
  /// **'Voir les billets'**
  String get issueSeeTickets;

  /// No description provided for @ticketErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Billet ou événement introuvable, ou droits insuffisants.'**
  String get ticketErrorNotFound;

  /// No description provided for @ticketErrorNotPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiez l\'événement avant d\'émettre des billets.'**
  String get ticketErrorNotPublished;

  /// No description provided for @ticketErrorCategoryCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Quota de la catégorie atteint.'**
  String get ticketErrorCategoryCapacity;

  /// No description provided for @ticketErrorEventCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité de l\'événement atteinte.'**
  String get ticketErrorEventCapacity;

  /// No description provided for @ticketErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée par le serveur (quantité ou catégorie).'**
  String get ticketErrorInvalid;

  /// No description provided for @ticketDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Billet'**
  String get ticketDetailTitle;

  /// No description provided for @ticketShowQr.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le QR'**
  String get ticketShowQr;

  /// No description provided for @ticketShowQrHint.
  ///
  /// In fr, this message translates to:
  /// **'Le retéléchargement est inscrit au journal de l\'organisation.'**
  String get ticketShowQrHint;

  /// No description provided for @ticketShareImage.
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'image'**
  String get ticketShareImage;

  /// No description provided for @ticketSharePdf.
  ///
  /// In fr, this message translates to:
  /// **'PDF'**
  String get ticketSharePdf;

  /// No description provided for @ticketShareText.
  ///
  /// In fr, this message translates to:
  /// **'Votre billet pour « {event} ». Présentez ce QR code à l\'entrée.'**
  String ticketShareText(String event);

  /// No description provided for @ticketRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le billet'**
  String get ticketRevoke;

  /// No description provided for @ticketRevokeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce billet ?'**
  String get ticketRevokeTitle;

  /// No description provided for @ticketRevokeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le billet {reference} sera refusé à l\'entrée. Cette action est définitive.'**
  String ticketRevokeBody(String reference);

  /// No description provided for @ticketRevokeReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif)'**
  String get ticketRevokeReason;

  /// No description provided for @ticketRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Billet annulé'**
  String get ticketRevoked;

  /// No description provided for @ticketAlreadyRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Ce billet a déjà été utilisé : il ne peut plus être annulé.'**
  String get ticketAlreadyRedeemed;

  /// No description provided for @ticketIssuedAt.
  ///
  /// In fr, this message translates to:
  /// **'Émis le {date}'**
  String ticketIssuedAt(String date);

  /// No description provided for @ticketRedeemedAt.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé le {date} · {checkpoint}'**
  String ticketRedeemedAt(String date, String checkpoint);

  /// No description provided for @ticketRevokedAt.
  ///
  /// In fr, this message translates to:
  /// **'Annulé le {date}'**
  String ticketRevokedAt(String date);

  /// No description provided for @ticketPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation…'**
  String get ticketPreparing;

  /// No description provided for @navControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle'**
  String get navControl;

  /// No description provided for @navHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get navHistory;

  /// No description provided for @controlTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle des entrées'**
  String get controlTitle;

  /// No description provided for @controlEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun poste attribué'**
  String get controlEmptyTitle;

  /// No description provided for @controlEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Un organisateur doit vous affecter à un événement et à une porte. Tirez vers le bas pour actualiser.'**
  String get controlEmptyBody;

  /// No description provided for @controlWindowOpen.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle ouvert'**
  String get controlWindowOpen;

  /// No description provided for @controlWindowUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture le {date}'**
  String controlWindowUpcoming(String date);

  /// No description provided for @controlWindowClosed.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle terminé'**
  String get controlWindowClosed;

  /// No description provided for @controlChooseDoor.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre porte'**
  String get controlChooseDoor;

  /// No description provided for @controlLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos postes.'**
  String get controlLoadError;

  /// No description provided for @scannerManualLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code du billet'**
  String get scannerManualLabel;

  /// No description provided for @scannerManualHelp.
  ///
  /// In fr, this message translates to:
  /// **'Collez ou saisissez le code du billet. Il commence par TS1.'**
  String get scannerManualHelp;

  /// No description provided for @scannerPaste.
  ///
  /// In fr, this message translates to:
  /// **'Coller et vérifier'**
  String get scannerPaste;

  /// No description provided for @scannerValidate.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get scannerValidate;

  /// No description provided for @scannerCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun billet vérifié} =1{1 billet vérifié} other{{count} billets vérifiés}}'**
  String scannerCount(int count);

  /// No description provided for @scannerOutsideWindow.
  ///
  /// In fr, this message translates to:
  /// **'Hors de la fenêtre de contrôle : le serveur refusera les entrées.'**
  String get scannerOutsideWindow;

  /// No description provided for @scannerEmptyClipboard.
  ///
  /// In fr, this message translates to:
  /// **'Le presse-papiers ne contient pas de texte.'**
  String get scannerEmptyClipboard;

  /// No description provided for @historyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes scans récents'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun scan ces 7 derniers jours.'**
  String get historyEmpty;

  /// No description provided for @historyLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'historique.'**
  String get historyLoadError;

  /// No description provided for @homeControlTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôler les entrées'**
  String get homeControlTitle;

  /// No description provided for @homeControlBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 porte vous est attribuée} other{{count} portes vous sont attribuées}}'**
  String homeControlBody(int count);

  /// No description provided for @eventControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôler les entrées'**
  String get eventControl;
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
