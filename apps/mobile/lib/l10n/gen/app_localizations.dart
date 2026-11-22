import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de marque, accent circonflexe obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Tikéo'**
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
  /// **'Ticket non valable pour cet événement'**
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
  /// **'Les espaces promoteur et contrôleur arrivent dans les prochaines versions.'**
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
  /// **'Appuyez encore sur Retour pour quitter Tikéo'**
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
  /// **'Tickets'**
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
  /// **'Bienvenue sur Tikéo'**
  String get homeGreeting;

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
  /// **'Chargement…'**
  String get orgLoading;

  /// No description provided for @orgLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos structures.'**
  String get orgLoadError;

  /// No description provided for @orgRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get orgRetry;

  /// No description provided for @orgCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre structure'**
  String get orgCreateTitle;

  /// No description provided for @orgCreateIntro.
  ///
  /// In fr, this message translates to:
  /// **'Votre structure (entreprise, association, collectif…) regroupe vos événements, vos tickets et votre équipe. Vous en serez le propriétaire.'**
  String get orgCreateIntro;

  /// No description provided for @orgCreateAnotherTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle structure'**
  String get orgCreateAnotherTitle;

  /// No description provided for @orgNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la structure ou de l\'entreprise'**
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
  /// **'Créer la structure'**
  String get orgCreateSubmit;

  /// No description provided for @orgErrorInvalidName.
  ///
  /// In fr, this message translates to:
  /// **'Nom invalide : entre 2 et 120 caractères.'**
  String get orgErrorInvalidName;

  /// No description provided for @orgErrorLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint la limite de 5 structures.'**
  String get orgErrorLimit;

  /// No description provided for @orgCreated.
  ///
  /// In fr, this message translates to:
  /// **'Structure « {name} » créée'**
  String orgCreated(String name);

  /// No description provided for @orgSwitchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer de structure'**
  String get orgSwitchTitle;

  /// No description provided for @orgSwitchAction.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get orgSwitchAction;

  /// No description provided for @orgCreateAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer une structure'**
  String get orgCreateAction;

  /// No description provided for @orgActiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
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
  /// **'Passés'**
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
  /// **'La capacité ne peut pas être inférieure au nombre de tickets déjà émis.'**
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
  /// **'Des tickets ont été émis : impossible de repasser en brouillon.'**
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
  /// **'Brouillon : invisible des contrôleurs. Publiez-le pour émettre des tickets.'**
  String get eventLifecycleDraft;

  /// No description provided for @eventLifecyclePublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié : vous pouvez émettre des tickets. Les entrées seront validées dès que vous démarrerez le contrôle.'**
  String get eventLifecyclePublished;

  /// No description provided for @eventLifecycleInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle en cours : les contrôleurs valident les entrées jusqu\'à ce que vous arrêtiez le contrôle.'**
  String get eventLifecycleInProgress;

  /// No description provided for @eventLifecycleClosed.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle arrêté : plus aucune entrée n\'est acceptée.'**
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
  /// **'Les tickets pourront être émis. Le contrôle aux portes commencera quand vous le démarrerez.'**
  String get eventConfirmPublish;

  /// No description provided for @eventConfirmStart.
  ///
  /// In fr, this message translates to:
  /// **'Les contrôleurs affectés peuvent valider les entrées dès maintenant, quelle que soit l\'heure, jusqu\'à ce que vous arrêtiez le contrôle.'**
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
  /// **'Catégories de tickets'**
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
  /// **'{issued} tickets émis sur {capacity}'**
  String categoriesTotal(int issued, int capacity);

  /// No description provided for @categoriesTotalUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'{issued} tickets émis, capacité non limitée'**
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
  /// **'« {name} » sera supprimée. C\'est impossible si des tickets y ont été émis.'**
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
  /// **'Aucune porte. Ajoutez les entrées où vos contrôleurs scanneront les tickets.'**
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
  /// **'Le quota ne peut pas être inférieur aux tickets déjà émis.'**
  String get setupErrorCapacityBelowIssued;

  /// No description provided for @setupErrorHasTickets.
  ///
  /// In fr, this message translates to:
  /// **'Des tickets existent dans cette catégorie : suppression impossible.'**
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
  /// **'Équipe gérée par les promoteurs'**
  String get teamControllerTitle;

  /// No description provided for @teamControllerBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes contrôleur de « {org} ». Les promoteurs gèrent l\'équipe et vos affectations aux portes.'**
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
  /// **'Scanne les tickets aux portes qui lui sont affectées.'**
  String get inviteRoleControllerHelp;

  /// No description provided for @inviteRoleManagerHelp.
  ///
  /// In fr, this message translates to:
  /// **'Gère les événements, les tickets et les contrôleurs.'**
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
  /// **'Partagez-le maintenant. Vous pourrez le retrouver dans les détails de l\'invitation tant qu\'elle est active.'**
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
  /// **'Rejoignez « {org} » sur Tikéo en tant que {role}. Dans l\'application, touchez « Rejoindre avec un code » et saisissez {code} (valable jusqu\'au {date}).'**
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
  /// **'Rejoindre une structure'**
  String get joinTitle;

  /// No description provided for @joinIntro.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code reçu d\'un promoteur d\'événement. Il commence par TSI.'**
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
  /// **'Code inconnu ou révoqué. Vérifiez-le auprès du promoteur.'**
  String get joinInvalid;

  /// No description provided for @joinExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré ou a déjà servi. Demandez-en un nouveau.'**
  String get joinExpired;

  /// No description provided for @joinAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites déjà partie de cette structure.'**
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
  /// **'Ticket annulé'**
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
  /// **'Ticket à usage unique. Ne le publiez pas : la première présentation à l\'entrée fait foi.'**
  String get ticketFooter;

  /// No description provided for @ticketsNoEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement publié'**
  String get ticketsNoEventTitle;

  /// No description provided for @ticketsNoEventBody.
  ///
  /// In fr, this message translates to:
  /// **'Publiez un événement pour émettre ses tickets.'**
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
  /// **'Référence, catégorie, nom ou téléphone'**
  String get ticketsSearchHint;

  /// No description provided for @ticketsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket pour l\'instant. Touchez « Émettre » pour créer les premiers.'**
  String get ticketsEmpty;

  /// No description provided for @ticketsEmptyFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket ne correspond.'**
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
  /// **'Les tickets sont gérés par les promoteurs. Vous les contrôlerez à l\'entrée.'**
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
  /// **'Émettre des tickets'**
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
  /// **'Nombre de tickets'**
  String get issueQuantity;

  /// No description provided for @issueQuantityHelp.
  ///
  /// In fr, this message translates to:
  /// **'De 1 à 1 000 par lot.'**
  String get issueQuantityHelp;

  /// No description provided for @issueQuantityError.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre entre 1 et 1 000.'**
  String get issueQuantityError;

  /// No description provided for @issueSubmit.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Émettre 1 ticket} other{Émettre {count} tickets}}'**
  String issueSubmit(int count);

  /// No description provided for @issueNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord une catégorie dans la fiche de l\'événement.'**
  String get issueNoCategory;

  /// No description provided for @issueDraft.
  ///
  /// In fr, this message translates to:
  /// **'Publiez l\'événement pour émettre des tickets.'**
  String get issueDraft;

  /// No description provided for @issueDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ticket émis} other{{count} tickets émis}}'**
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
  /// **'Voir les tickets'**
  String get issueSeeTickets;

  /// No description provided for @ticketErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ticket ou événement introuvable, ou droits insuffisants.'**
  String get ticketErrorNotFound;

  /// No description provided for @ticketErrorNotPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiez l\'événement avant d\'émettre des tickets.'**
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
  /// **'Ticket'**
  String get ticketDetailTitle;

  /// No description provided for @ticketShowQr.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le QR'**
  String get ticketShowQr;

  /// No description provided for @ticketShowQrHint.
  ///
  /// In fr, this message translates to:
  /// **'Le retéléchargement est inscrit au journal de la structure.'**
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
  /// **'Votre ticket pour « {event} ». Présentez ce QR code à l\'entrée.'**
  String ticketShareText(String event);

  /// No description provided for @ticketRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le ticket'**
  String get ticketRevoke;

  /// No description provided for @ticketRevokeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce ticket ?'**
  String get ticketRevokeTitle;

  /// No description provided for @ticketRevokeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket {reference} sera refusé à l\'entrée. Cette action est définitive.'**
  String ticketRevokeBody(String reference);

  /// No description provided for @ticketRevokeReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif)'**
  String get ticketRevokeReason;

  /// No description provided for @ticketRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Ticket annulé'**
  String get ticketRevoked;

  /// No description provided for @ticketAlreadyRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket a déjà été utilisé : il ne peut plus être annulé.'**
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
  /// **'Un promoteur doit vous affecter à un événement et à une porte. Tirez vers le bas pour actualiser.'**
  String get controlEmptyBody;

  /// No description provided for @controlWindowOpen.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle ouvert'**
  String get controlWindowOpen;

  /// No description provided for @controlWindowClosed.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle arrêté'**
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
  /// **'Code du ticket'**
  String get scannerManualLabel;

  /// No description provided for @scannerManualHelp.
  ///
  /// In fr, this message translates to:
  /// **'Collez ou saisissez le code du ticket. Il commence par TS1.'**
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
  /// **'{count, plural, =0{Aucun ticket vérifié} =1{1 ticket vérifié} other{{count} tickets vérifiés}}'**
  String scannerCount(int count);

  /// No description provided for @scannerOutsideWindow.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle non démarré ou arrêté : le promoteur doit le démarrer, sinon les entrées seront refusées.'**
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

  /// No description provided for @feedbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sons et vibrations'**
  String get feedbackTitle;

  /// No description provided for @feedbackScanSounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons du contrôle'**
  String get feedbackScanSounds;

  /// No description provided for @feedbackScanSoundsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un son distinct pour chaque verdict : entrée autorisée, refusée, à confirmer.'**
  String get feedbackScanSoundsHelp;

  /// No description provided for @feedbackUiSounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons de l\'interface'**
  String get feedbackUiSounds;

  /// No description provided for @feedbackUiSoundsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Navigation et confirmations, discrets.'**
  String get feedbackUiSoundsHelp;

  /// No description provided for @feedbackHaptics.
  ///
  /// In fr, this message translates to:
  /// **'Vibrations'**
  String get feedbackHaptics;

  /// No description provided for @feedbackPreviewAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Écouter : entrée autorisée'**
  String get feedbackPreviewAdmitted;

  /// No description provided for @feedbackPreviewRefused.
  ///
  /// In fr, this message translates to:
  /// **'Écouter : entrée refusée'**
  String get feedbackPreviewRefused;

  /// No description provided for @feedbackPreviewIndeterminate.
  ///
  /// In fr, this message translates to:
  /// **'Écouter : à confirmer'**
  String get feedbackPreviewIndeterminate;

  /// No description provided for @scannerHint.
  ///
  /// In fr, this message translates to:
  /// **'Placez le QR code dans le cadre'**
  String get scannerHint;

  /// No description provided for @scannerManual.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code'**
  String get scannerManual;

  /// No description provided for @scannerTorchOn.
  ///
  /// In fr, this message translates to:
  /// **'Allumer la lampe'**
  String get scannerTorchOn;

  /// No description provided for @scannerTorchOff.
  ///
  /// In fr, this message translates to:
  /// **'Éteindre la lampe'**
  String get scannerTorchOff;

  /// No description provided for @scannerLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le poste'**
  String get scannerLeave;

  /// No description provided for @cameraDeniedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la caméra refusé'**
  String get cameraDeniedTitle;

  /// No description provided for @cameraDeniedBody.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez la caméra pour Tikéo dans les réglages Android (Applications › Tikéo › Autorisations), puis réessayez. Vous pouvez aussi saisir le code.'**
  String get cameraDeniedBody;

  /// No description provided for @cameraErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible'**
  String get cameraErrorTitle;

  /// No description provided for @cameraErrorBody.
  ///
  /// In fr, this message translates to:
  /// **'Fermez les autres applications qui utilisent la caméra, puis réessayez. Vous pouvez aussi saisir le code.'**
  String get cameraErrorBody;

  /// No description provided for @cameraRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get cameraRetry;

  /// No description provided for @homeQuickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get homeQuickTitle;

  /// No description provided for @homeQuickNewEvent.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get homeQuickNewEvent;

  /// No description provided for @homeQuickIssue.
  ///
  /// In fr, this message translates to:
  /// **'Émettre des tickets'**
  String get homeQuickIssue;

  /// No description provided for @homeQuickInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter l\'équipe'**
  String get homeQuickInvite;

  /// No description provided for @eventErrorIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une photo de couverture et une ville avant de publier.'**
  String get eventErrorIncomplete;

  /// No description provided for @eventErrorCity.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez une ville de 2 à 80 caractères.'**
  String get eventErrorCity;

  /// No description provided for @eventErrorAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de 200 caractères au plus.'**
  String get eventErrorAddress;

  /// No description provided for @eventErrorDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description de 2 000 caractères au plus.'**
  String get eventErrorDescription;

  /// No description provided for @eventErrorCover.
  ///
  /// In fr, this message translates to:
  /// **'Photo refusée : choisissez une image JPEG, PNG ou WebP de 2 Mo au plus.'**
  String get eventErrorCover;

  /// No description provided for @eventKindConcert.
  ///
  /// In fr, this message translates to:
  /// **'Concert'**
  String get eventKindConcert;

  /// No description provided for @eventKindConference.
  ///
  /// In fr, this message translates to:
  /// **'Conférence'**
  String get eventKindConference;

  /// No description provided for @eventKindWorship.
  ///
  /// In fr, this message translates to:
  /// **'Culte'**
  String get eventKindWorship;

  /// No description provided for @eventKindSport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get eventKindSport;

  /// No description provided for @eventKindWedding.
  ///
  /// In fr, this message translates to:
  /// **'Mariage'**
  String get eventKindWedding;

  /// No description provided for @eventKindTraining.
  ///
  /// In fr, this message translates to:
  /// **'Formation'**
  String get eventKindTraining;

  /// No description provided for @eventKindGala.
  ///
  /// In fr, this message translates to:
  /// **'Gala'**
  String get eventKindGala;

  /// No description provided for @eventKindOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get eventKindOther;

  /// No description provided for @eventStepInfo.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get eventStepInfo;

  /// No description provided for @eventStepWhenWhere.
  ///
  /// In fr, this message translates to:
  /// **'Date et lieu'**
  String get eventStepWhenWhere;

  /// No description provided for @eventStepCover.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get eventStepCover;

  /// No description provided for @eventStepReview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get eventStepReview;

  /// No description provided for @eventStepCounter.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String eventStepCounter(int current, int total);

  /// No description provided for @eventStepNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get eventStepNext;

  /// No description provided for @eventStepBack.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get eventStepBack;

  /// No description provided for @eventKindLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type d\'événement'**
  String get eventKindLabel;

  /// No description provided for @eventDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description (facultatif)'**
  String get eventDescriptionLabel;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Programme, artistes, consignes d\'accès…'**
  String get eventDescriptionHint;

  /// No description provided for @eventTaglineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Accroche (facultatif)'**
  String get eventTaglineLabel;

  /// No description provided for @eventTaglineHint.
  ///
  /// In fr, this message translates to:
  /// **'Une phrase courte imprimée sur le ticket'**
  String get eventTaglineHint;

  /// No description provided for @eventCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get eventCityLabel;

  /// No description provided for @eventCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Ouagadougou'**
  String get eventCityHint;

  /// No description provided for @eventCityHelp.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire pour publier.'**
  String get eventCityHelp;

  /// No description provided for @eventAddressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse (facultatif)'**
  String get eventAddressLabel;

  /// No description provided for @eventAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Secteur, rue, point de repère'**
  String get eventAddressHint;

  /// No description provided for @eventCoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture'**
  String get eventCoverTitle;

  /// No description provided for @eventCoverHelp.
  ///
  /// In fr, this message translates to:
  /// **'Format paysage conseillé. Elle apparaît sur la fiche, les tickets partagés et l\'écran de contrôle. Obligatoire pour publier.'**
  String get eventCoverHelp;

  /// No description provided for @eventCoverGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get eventCoverGallery;

  /// No description provided for @eventCoverCamera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get eventCoverCamera;

  /// No description provided for @eventCoverChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get eventCoverChange;

  /// No description provided for @eventCoverAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get eventCoverAdd;

  /// No description provided for @eventCoverRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get eventCoverRemove;

  /// No description provided for @eventCoverEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo pour l\'instant'**
  String get eventCoverEmpty;

  /// No description provided for @eventCoverSaved.
  ///
  /// In fr, this message translates to:
  /// **'Photo enregistrée'**
  String get eventCoverSaved;

  /// No description provided for @eventCoverUploadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Événement enregistré, mais la photo n\'a pas pu être envoyée. Réessayez depuis la fiche.'**
  String get eventCoverUploadFailed;

  /// No description provided for @eventCoverLater.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez aussi l\'ajouter plus tard depuis la fiche.'**
  String get eventCoverLater;

  /// No description provided for @eventReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voici votre événement'**
  String get eventReviewTitle;

  /// No description provided for @eventReviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les informations, puis enregistrez. L\'événement reste en brouillon tant que vous ne le publiez pas.'**
  String get eventReviewHint;

  /// No description provided for @eventCityMissing.
  ///
  /// In fr, this message translates to:
  /// **'Ville à préciser'**
  String get eventCityMissing;

  /// No description provided for @eventToCompleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'À compléter avant publication'**
  String get eventToCompleteTitle;

  /// No description provided for @eventMissingCover.
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture'**
  String get eventMissingCover;

  /// No description provided for @eventMissingCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get eventMissingCity;

  /// No description provided for @eventDetailDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get eventDetailDescription;

  /// No description provided for @eventDetailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get eventDetailAddress;

  /// No description provided for @eventDetailKind.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get eventDetailKind;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible : 8 caractères au moins, avec des lettres et des chiffres.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorSamePassword.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe doit être différent de l\'actuel.'**
  String get authErrorSamePassword;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse est déjà utilisée par un autre compte.'**
  String get authErrorEmailTaken;

  /// No description provided for @profileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEdit;

  /// No description provided for @profileEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profileEditTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Prénom et nom'**
  String get profileNameHint;

  /// No description provided for @profileNameError.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nom de 2 à 60 caractères.'**
  String get profileNameError;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get profilePhoneLabel;

  /// No description provided for @profilePhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. 70 12 34 56'**
  String get profilePhoneHint;

  /// No description provided for @profilePhoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Numéro burkinabè à 8 chiffres, ou format international (+225…).'**
  String get profilePhoneHelp;

  /// No description provided for @profilePhoneError.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get profilePhoneError;

  /// No description provided for @profileEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get profileEmailLabel;

  /// No description provided for @profileSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil enregistré'**
  String get profileSaved;

  /// No description provided for @profilePhotoChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil enregistrée'**
  String get profilePhotoSaved;

  /// No description provided for @profilePhotoError.
  ///
  /// In fr, this message translates to:
  /// **'Photo refusée : image JPEG, PNG ou WebP de 1 Mo au plus.'**
  String get profilePhotoError;

  /// No description provided for @profileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre profil.'**
  String get profileLoadError;

  /// No description provided for @profileErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Réessayez.'**
  String get profileErrorUnknown;

  /// No description provided for @profileSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get profileSecurityTitle;

  /// No description provided for @profileChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get profileChangePassword;

  /// No description provided for @profileChangeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'adresse e-mail'**
  String get profileChangeEmail;

  /// No description provided for @profileSignOutEverywhere.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tous les appareils'**
  String get profileSignOutEverywhere;

  /// No description provided for @profileSignOutEverywhereBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos sessions seront fermées, y compris celle-ci. Vous devrez vous reconnecter.'**
  String get profileSignOutEverywhereBody;

  /// No description provided for @profileCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get profileCurrentPassword;

  /// No description provided for @profileNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get profileNewPassword;

  /// No description provided for @profileConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get profileConfirmPassword;

  /// No description provided for @profilePasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins.'**
  String get profilePasswordTooShort;

  /// No description provided for @profilePasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe diffèrent.'**
  String get profilePasswordMismatch;

  /// No description provided for @profilePasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre mot de passe actuel.'**
  String get profilePasswordRequired;

  /// No description provided for @profileWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect.'**
  String get profileWrongPassword;

  /// No description provided for @profilePasswordChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe changé'**
  String get profilePasswordChanged;

  /// No description provided for @profileNewEmail.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse e-mail'**
  String get profileNewEmail;

  /// No description provided for @profileEmailHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de confirmation sera envoyé à la nouvelle adresse. Elle ne remplacera l\'actuelle qu\'après confirmation.'**
  String get profileEmailHelp;

  /// No description provided for @profileEmailSame.
  ///
  /// In fr, this message translates to:
  /// **'C\'est déjà votre adresse.'**
  String get profileEmailSame;

  /// No description provided for @profileEmailSent.
  ///
  /// In fr, this message translates to:
  /// **'Lien de confirmation envoyé à {email}.'**
  String profileEmailSent(String email);

  /// No description provided for @profileSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get profileSend;

  /// No description provided for @profileDangerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Zone sensible'**
  String get profileDangerTitle;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte sera supprimé dans 30 jours : vos données personnelles seront effacées, les tickets déjà émis restent à vos structures, et les structures dont vous êtes propriétaire seront suspendues. Vous pourrez annuler d\'ici là. Tapez SUPPRIMER pour confirmer.'**
  String get profileDeleteBody;

  /// No description provided for @profileDeleteWord.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get profileDeleteWord;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Programmer la suppression'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeletionPending.
  ///
  /// In fr, this message translates to:
  /// **'Suppression du compte prévue le {date}.'**
  String profileDeletionPending(String date);

  /// No description provided for @profileDeletionCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get profileDeletionCancel;

  /// No description provided for @profileDeletionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Suppression annulée'**
  String get profileDeletionCancelled;

  /// No description provided for @profileDeletionRequested.
  ///
  /// In fr, this message translates to:
  /// **'Suppression programmée dans 30 jours'**
  String get profileDeletionRequested;

  /// No description provided for @profileCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get profileCancel;

  /// No description provided for @profileConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get profileConfirm;

  /// No description provided for @orgCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get orgCardTitle;

  /// No description provided for @orgEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la fiche'**
  String get orgEdit;

  /// No description provided for @orgEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de la structure'**
  String get orgEditTitle;

  /// No description provided for @orgEditHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations apparaissent sur vos tickets et, bientôt, sur la page publique de vos événements.'**
  String get orgEditHelp;

  /// No description provided for @orgPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone de contact (facultatif)'**
  String get orgPhoneLabel;

  /// No description provided for @orgEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de contact (facultatif)'**
  String get orgEmailLabel;

  /// No description provided for @orgCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville (facultatif)'**
  String get orgCityLabel;

  /// No description provided for @orgLogoChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer le logo'**
  String get orgLogoChange;

  /// No description provided for @orgLogoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Logo enregistré'**
  String get orgLogoSaved;

  /// No description provided for @orgSaved.
  ///
  /// In fr, this message translates to:
  /// **'Fiche enregistrée'**
  String get orgSaved;

  /// No description provided for @orgLeave.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la structure'**
  String get orgLeave;

  /// No description provided for @orgLeaveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter « {name} » ?'**
  String orgLeaveTitle(String name);

  /// No description provided for @orgLeaveBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous perdrez l\'accès à ses événements, ses tickets et ses contrôles. Pour revenir, il faudra un nouveau code d\'invitation.'**
  String get orgLeaveBody;

  /// No description provided for @orgLeft.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quitté « {name} »'**
  String orgLeft(String name);

  /// No description provided for @orgErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Structure introuvable ou droits insuffisants.'**
  String get orgErrorNotFound;

  /// No description provided for @orgErrorPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get orgErrorPhone;

  /// No description provided for @orgErrorEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get orgErrorEmail;

  /// No description provided for @orgErrorCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville de 2 à 80 caractères.'**
  String get orgErrorCity;

  /// No description provided for @orgErrorLogo.
  ///
  /// In fr, this message translates to:
  /// **'Logo refusé : image JPEG, PNG ou WebP de 1 Mo au plus.'**
  String get orgErrorLogo;

  /// No description provided for @orgErrorLastOwner.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes le dernier propriétaire : nommez-en un autre avant de partir.'**
  String get orgErrorLastOwner;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @dashboardOpen.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord en direct'**
  String get dashboardOpen;

  /// No description provided for @dashboardLive.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get dashboardLive;

  /// No description provided for @dashboardClosed.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle fermé'**
  String get dashboardClosed;

  /// No description provided for @dashboardStale.
  ///
  /// In fr, this message translates to:
  /// **'Non actualisé'**
  String get dashboardStale;

  /// No description provided for @dashboardUpdatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Actualisé à {time}'**
  String dashboardUpdatedAt(String time);

  /// No description provided for @dashboardStaleBody.
  ///
  /// In fr, this message translates to:
  /// **'Connexion perdue : chiffres de {time}. Nouvel essai automatique.'**
  String dashboardStaleBody(String time);

  /// No description provided for @dashboardRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get dashboardRefresh;

  /// No description provided for @dashboardAttendance.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'entrée'**
  String get dashboardAttendance;

  /// No description provided for @dashboardAdmittedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune entrée} =1{1 entrée} other{{count} entrées}}'**
  String dashboardAdmittedCount(int count);

  /// No description provided for @dashboardIssuedOf.
  ///
  /// In fr, this message translates to:
  /// **'sur {count, plural, =1{1 ticket émis} other{{count} tickets émis}}'**
  String dashboardIssuedOf(int count);

  /// No description provided for @dashboardCapacityLine.
  ///
  /// In fr, this message translates to:
  /// **'Capacité : {value}'**
  String dashboardCapacityLine(String value);

  /// No description provided for @dashboardKpiAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Entrés'**
  String get dashboardKpiAdmitted;

  /// No description provided for @dashboardKpiRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Attendus'**
  String get dashboardKpiRemaining;

  /// No description provided for @dashboardKpiRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refus'**
  String get dashboardKpiRefused;

  /// No description provided for @dashboardKpiRate.
  ///
  /// In fr, this message translates to:
  /// **'Entrées / {minutes} min'**
  String dashboardKpiRate(int minutes);

  /// No description provided for @dashboardTimelineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passages dans le temps'**
  String get dashboardTimelineTitle;

  /// No description provided for @dashboardTimelineStepMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Par tranche de {minutes} min'**
  String dashboardTimelineStepMinutes(int minutes);

  /// No description provided for @dashboardTimelineStepHours.
  ///
  /// In fr, this message translates to:
  /// **'{hours, plural, =1{Par tranche d\'1 heure} other{Par tranche de {hours} heures}}'**
  String dashboardTimelineStepHours(int hours);

  /// No description provided for @dashboardTimelineEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Les passages apparaîtront ici dès le premier scan.'**
  String get dashboardTimelineEmpty;

  /// No description provided for @dashboardLegendAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get dashboardLegendAdmitted;

  /// No description provided for @dashboardLegendRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refus'**
  String get dashboardLegendRefused;

  /// No description provided for @dashboardTimelineSemantics.
  ///
  /// In fr, this message translates to:
  /// **'{accepted} entrées et {refused} refus entre {from} et {to}'**
  String dashboardTimelineSemantics(
    int accepted,
    int refused,
    String from,
    String to,
  );

  /// No description provided for @dashboardRefusalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motifs de refus'**
  String get dashboardRefusalsTitle;

  /// No description provided for @dashboardOtherReason.
  ///
  /// In fr, this message translates to:
  /// **'Autre motif'**
  String get dashboardOtherReason;

  /// No description provided for @dashboardCategoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get dashboardCategoriesTitle;

  /// No description provided for @dashboardCategoryLine.
  ///
  /// In fr, this message translates to:
  /// **'{admitted, plural, =0{Aucun entré} =1{1 entré} other{{admitted} entrés}} sur {issued}'**
  String dashboardCategoryLine(int admitted, int issued);

  /// No description provided for @dashboardQuota.
  ///
  /// In fr, this message translates to:
  /// **'Quota : {count}'**
  String dashboardQuota(int count);

  /// No description provided for @dashboardCheckpointsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Par porte'**
  String get dashboardCheckpointsTitle;

  /// No description provided for @dashboardCheckpointLine.
  ///
  /// In fr, this message translates to:
  /// **'{admitted, plural, =0{Aucune entrée} =1{1 entrée} other{{admitted} entrées}} · {refused, plural, =0{aucun refus} =1{1 refus} other{{refused} refus}}'**
  String dashboardCheckpointLine(int admitted, int refused);

  /// No description provided for @dashboardCheckpointInactive.
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get dashboardCheckpointInactive;

  /// No description provided for @dashboardLastScan.
  ///
  /// In fr, this message translates to:
  /// **'Dernier scan à {time}'**
  String dashboardLastScan(String time);

  /// No description provided for @dashboardNoScan.
  ///
  /// In fr, this message translates to:
  /// **'Aucun scan'**
  String get dashboardNoScan;

  /// No description provided for @dashboardControllersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleurs'**
  String get dashboardControllersTitle;

  /// No description provided for @dashboardRevokedExpired.
  ///
  /// In fr, this message translates to:
  /// **'Tickets annulés : {revoked} · expirés : {expired}'**
  String dashboardRevokedExpired(int revoked, int expired);

  /// No description provided for @dashboardNoTickets.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket émis pour cet événement.'**
  String get dashboardNoTickets;

  /// No description provided for @dashboardIssueTickets.
  ///
  /// In fr, this message translates to:
  /// **'Émettre des tickets'**
  String get dashboardIssueTickets;

  /// No description provided for @dashboardErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord indisponible : événement introuvable ou droits insuffisants.'**
  String get dashboardErrorNotFound;

  /// No description provided for @dashboardErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le tableau de bord.'**
  String get dashboardErrorLoad;

  /// No description provided for @homeDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les entrées en direct'**
  String get homeDashboard;

  /// No description provided for @holderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire'**
  String get holderTitle;

  /// No description provided for @holderOptional.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire (facultatif)'**
  String get holderOptional;

  /// No description provided for @holderOptionalHint.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est imprimé sur le ticket. Sans titulaire, le ticket est au porteur.'**
  String get holderOptionalHint;

  /// No description provided for @holderName.
  ///
  /// In fr, this message translates to:
  /// **'Nom et prénom'**
  String get holderName;

  /// No description provided for @holderPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get holderPhone;

  /// No description provided for @holderPhoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : 70 12 34 56 ou +225 07 08 09 10 11'**
  String get holderPhoneHelp;

  /// No description provided for @holderEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get holderEmail;

  /// No description provided for @holderNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun titulaire : ticket au porteur'**
  String get holderNone;

  /// No description provided for @holderAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un titulaire'**
  String get holderAdd;

  /// No description provided for @holderEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le titulaire'**
  String get holderEdit;

  /// No description provided for @holderSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get holderSave;

  /// No description provided for @holderSaved.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire enregistré'**
  String get holderSaved;

  /// No description provided for @holderErrorName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de 120 caractères au plus.'**
  String get holderErrorName;

  /// No description provided for @holderErrorPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get holderErrorPhone;

  /// No description provided for @holderErrorEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get holderErrorEmail;

  /// No description provided for @ticketErrorNotEditable.
  ///
  /// In fr, this message translates to:
  /// **'Seul un ticket valable, pas encore utilisé, peut changer de titulaire.'**
  String get ticketErrorNotEditable;

  /// No description provided for @ticketCardHolder.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire : {name}'**
  String ticketCardHolder(String name);

  /// No description provided for @importTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer une liste'**
  String get importTitle;

  /// No description provided for @importEntry.
  ///
  /// In fr, this message translates to:
  /// **'Importer une liste (Excel, CSV)'**
  String get importEntry;

  /// No description provided for @importIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une ligne par participant. Colonnes reconnues : nom (ou prénom et nom), téléphone, e-mail et catégorie. Fichier Excel (.xlsx) ou CSV, 1 000 lignes au plus.'**
  String get importIntro;

  /// No description provided for @importPick.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get importPick;

  /// No description provided for @importChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer de fichier'**
  String get importChange;

  /// No description provided for @importTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Partager un modèle à remplir'**
  String get importTemplate;

  /// No description provided for @importRowsRead.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune ligne lue} =1{1 ligne lue} other{{count} lignes lues}}'**
  String importRowsRead(int count);

  /// No description provided for @importDefaultCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie des lignes sans catégorie'**
  String get importDefaultCategory;

  /// No description provided for @importNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Créez d\'abord une catégorie de tickets pour cet événement.'**
  String get importNoCategory;

  /// No description provided for @importErrorUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Format non pris en charge : choisissez un fichier Excel (.xlsx) ou CSV.'**
  String get importErrorUnsupported;

  /// No description provided for @importErrorLegacy.
  ///
  /// In fr, this message translates to:
  /// **'Ancien format Excel (.xls) : enregistrez le fichier au format .xlsx ou CSV.'**
  String get importErrorLegacy;

  /// No description provided for @importErrorUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Fichier illisible ou endommagé.'**
  String get importErrorUnreadable;

  /// No description provided for @importErrorTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux (5 Mo au plus).'**
  String get importErrorTooLarge;

  /// No description provided for @importErrorNoName.
  ///
  /// In fr, this message translates to:
  /// **'Colonne du nom introuvable : ajoutez un en-tête « Nom » au-dessus de la liste.'**
  String get importErrorNoName;

  /// No description provided for @importErrorEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ligne à importer dans ce fichier.'**
  String get importErrorEmpty;

  /// No description provided for @importReady.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune ligne prête} =1{1 ligne prête} other{{count} lignes prêtes}}'**
  String importReady(int count);

  /// No description provided for @importErrorCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 en erreur} other{{count} en erreur}}'**
  String importErrorCount(int count);

  /// No description provided for @importWarningCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 à vérifier} other{{count} à vérifier}}'**
  String importWarningCount(int count);

  /// No description provided for @importColumnsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes reconnues'**
  String get importColumnsTitle;

  /// No description provided for @importColumnsGuessed.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'en-tête : colonnes devinées d\'après leur contenu.'**
  String get importColumnsGuessed;

  /// No description provided for @importColumnName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get importColumnName;

  /// No description provided for @importColumnFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get importColumnFirstName;

  /// No description provided for @importColumnPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get importColumnPhone;

  /// No description provided for @importColumnEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get importColumnEmail;

  /// No description provided for @importColumnCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get importColumnCategory;

  /// No description provided for @importColumnFrom.
  ///
  /// In fr, this message translates to:
  /// **'{field} ← « {header} »'**
  String importColumnFrom(String field, String header);

  /// No description provided for @importColumnAt.
  ///
  /// In fr, this message translates to:
  /// **'{field} ← colonne {letter}'**
  String importColumnAt(String field, String letter);

  /// No description provided for @importPerCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get importPerCategoryTitle;

  /// No description provided for @importQuotaCategory.
  ///
  /// In fr, this message translates to:
  /// **'{category} : {wanted} demandés, {remaining} restants'**
  String importQuotaCategory(String category, int wanted, int remaining);

  /// No description provided for @importQuotaEvent.
  ///
  /// In fr, this message translates to:
  /// **'Capacité de l\'événement : {wanted} demandés, {remaining} places restantes'**
  String importQuotaEvent(int wanted, int remaining);

  /// No description provided for @importErrorsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lignes en erreur'**
  String get importErrorsTitle;

  /// No description provided for @importWarningsTitle.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get importWarningsTitle;

  /// No description provided for @importLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line} · {reason}'**
  String importLine(int line, String reason);

  /// No description provided for @importMore.
  ///
  /// In fr, this message translates to:
  /// **'… et {count} autres'**
  String importMore(int count);

  /// No description provided for @importProblemNameMissing.
  ///
  /// In fr, this message translates to:
  /// **'nom manquant'**
  String get importProblemNameMissing;

  /// No description provided for @importProblemNameTooLong.
  ///
  /// In fr, this message translates to:
  /// **'nom trop long (120 caractères au plus)'**
  String get importProblemNameTooLong;

  /// No description provided for @importProblemPhone.
  ///
  /// In fr, this message translates to:
  /// **'téléphone invalide'**
  String get importProblemPhone;

  /// No description provided for @importProblemEmail.
  ///
  /// In fr, this message translates to:
  /// **'e-mail invalide'**
  String get importProblemEmail;

  /// No description provided for @importProblemCategory.
  ///
  /// In fr, this message translates to:
  /// **'catégorie « {label} » inconnue'**
  String importProblemCategory(String label);

  /// No description provided for @importProblemNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'catégorie manquante'**
  String get importProblemNoCategory;

  /// No description provided for @importWarningPhone.
  ///
  /// In fr, this message translates to:
  /// **'même téléphone qu\'une ligne précédente'**
  String get importWarningPhone;

  /// No description provided for @importWarningEmail.
  ///
  /// In fr, this message translates to:
  /// **'même e-mail qu\'une ligne précédente'**
  String get importWarningEmail;

  /// No description provided for @importPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get importPreviewTitle;

  /// No description provided for @importSkipErrors.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer les lignes en erreur'**
  String get importSkipErrors;

  /// No description provided for @importTooMany.
  ///
  /// In fr, this message translates to:
  /// **'1 000 tickets au plus par import : découpez la liste en plusieurs fichiers.'**
  String get importTooMany;

  /// No description provided for @importSubmit.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Émettre les tickets} =1{Émettre 1 ticket} other{Émettre {count} tickets}}'**
  String importSubmit(int count);

  /// No description provided for @sendMessageNamed.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}, voici votre ticket pour « {event} », {date}{place}. Présentez le QR code à l\'entrée. Ticket à usage unique : ne le transférez à personne.'**
  String sendMessageNamed(String name, String event, String date, String place);

  /// No description provided for @sendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, voici votre ticket pour « {event} », {date}{place}. Présentez le QR code à l\'entrée. Ticket à usage unique : ne le transférez à personne.'**
  String sendMessage(String event, String date, String place);

  /// No description provided for @sendSubject.
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket : {event}'**
  String sendSubject(String event);

  /// No description provided for @sendChannelWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get sendChannelWhatsApp;

  /// No description provided for @sendChannelSms.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get sendChannelSms;

  /// No description provided for @sendChannelEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get sendChannelEmail;

  /// No description provided for @sendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer au titulaire'**
  String get sendTitle;

  /// No description provided for @sendNoContact.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un téléphone ou un e-mail au titulaire pour lui envoyer son ticket.'**
  String get sendNoContact;

  /// No description provided for @sendConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket est-il parti ?'**
  String get sendConfirmTitle;

  /// No description provided for @sendConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez une fois le message envoyé par {channel}. Seuls les envois confirmés sont enregistrés.'**
  String sendConfirmBody(String channel);

  /// No description provided for @sendConfirmYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, envoyé'**
  String get sendConfirmYes;

  /// No description provided for @sendConfirmNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get sendConfirmNo;

  /// No description provided for @sendRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Envoi enregistré'**
  String get sendRecorded;

  /// No description provided for @sendMissingWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp n\'est pas installé sur ce téléphone.'**
  String get sendMissingWhatsApp;

  /// No description provided for @sendMissingSms.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application SMS disponible.'**
  String get sendMissingSms;

  /// No description provided for @sendMissingEmail.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application d\'e-mail configurée sur ce téléphone.'**
  String get sendMissingEmail;

  /// No description provided for @sendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture impossible. Réessayez.'**
  String get sendFailed;

  /// No description provided for @sendLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernier envoi : {channel}, {date}'**
  String sendLast(String channel, String date);

  /// No description provided for @ticketSentVia.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé par {channel} le {date}'**
  String ticketSentVia(String channel, String date);

  /// No description provided for @ticketErrorNotSendable.
  ///
  /// In fr, this message translates to:
  /// **'Seul un ticket valable, pas encore utilisé, peut être envoyé.'**
  String get ticketErrorNotSendable;

  /// No description provided for @sendBatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer les tickets'**
  String get sendBatchTitle;

  /// No description provided for @sendBatchIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les tickets valables jamais envoyés, un par un : l\'application s\'ouvre sur la bonne conversation avec le ticket joint, vous appuyez sur Envoyer, puis vous confirmez ici.'**
  String get sendBatchIntro;

  /// No description provided for @sendBatchProgress.
  ///
  /// In fr, this message translates to:
  /// **'Ticket {current} sur {total}'**
  String sendBatchProgress(int current, int total);

  /// No description provided for @sendBatchStats.
  ///
  /// In fr, this message translates to:
  /// **'{sent, plural, =0{Aucun envoyé} =1{1 envoyé} other{{sent} envoyés}} · {skipped, plural, =0{aucun passé} =1{1 passé} other{{skipped} passés}}'**
  String sendBatchStats(int sent, int skipped);

  /// No description provided for @sendBatchSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer par {channel}'**
  String sendBatchSend(String channel);

  /// No description provided for @sendBatchSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get sendBatchSkip;

  /// No description provided for @sendBatchRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get sendBatchRetry;

  /// No description provided for @sendBatchNext.
  ///
  /// In fr, this message translates to:
  /// **'Oui, envoyé · suivant'**
  String get sendBatchNext;

  /// No description provided for @sendBatchEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket à envoyer par {channel}'**
  String sendBatchEmptyTitle(String channel);

  /// No description provided for @sendBatchEmptyPhone.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les tickets valables, jamais envoyés, dont le titulaire a un numéro de téléphone sont proposés.'**
  String get sendBatchEmptyPhone;

  /// No description provided for @sendBatchEmptyEmail.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les tickets valables, jamais envoyés, dont le titulaire a une adresse e-mail sont proposés.'**
  String get sendBatchEmptyEmail;

  /// No description provided for @sendBatchDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Série terminée'**
  String get sendBatchDoneTitle;

  /// No description provided for @sendBatchClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get sendBatchClose;

  /// No description provided for @sendBatchLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les tickets à envoyer.'**
  String get sendBatchLoadError;

  /// No description provided for @reportAction.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get reportAction;

  /// No description provided for @reportSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport de l\'événement'**
  String get reportSheetTitle;

  /// No description provided for @reportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Bilan PDF'**
  String get reportPdf;

  /// No description provided for @reportPdfHint.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres clés, passages, catégories, portes, refus et contrôleurs.'**
  String get reportPdfHint;

  /// No description provided for @reportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Liste des tickets (Excel, CSV)'**
  String get reportCsv;

  /// No description provided for @reportCsvHint.
  ///
  /// In fr, this message translates to:
  /// **'Un ticket par ligne, titulaires compris. Chaque export est inscrit au journal de la structure.'**
  String get reportCsvHint;

  /// No description provided for @reportErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Rapport indisponible : événement introuvable ou droits insuffisants.'**
  String get reportErrorNotFound;

  /// No description provided for @reportErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de préparer le rapport. Réessayez.'**
  String get reportErrorLoad;

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport d\'événement'**
  String get reportTitle;

  /// No description provided for @reportStatsAt.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres arrêtés le {date}'**
  String reportStatsAt(String date);

  /// No description provided for @reportIssued.
  ///
  /// In fr, this message translates to:
  /// **'Tickets émis'**
  String get reportIssued;

  /// No description provided for @reportAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Entrés'**
  String get reportAdmitted;

  /// No description provided for @reportAttendance.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'entrée'**
  String get reportAttendance;

  /// No description provided for @reportNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Attendus, pas entrés'**
  String get reportNoShow;

  /// No description provided for @reportRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Annulés'**
  String get reportRevoked;

  /// No description provided for @reportRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refus au contrôle'**
  String get reportRefused;

  /// No description provided for @reportTimeline.
  ///
  /// In fr, this message translates to:
  /// **'Passages dans le temps'**
  String get reportTimeline;

  /// No description provided for @reportCategories.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get reportCategories;

  /// No description provided for @reportCheckpoints.
  ///
  /// In fr, this message translates to:
  /// **'Par porte'**
  String get reportCheckpoints;

  /// No description provided for @reportRefusals.
  ///
  /// In fr, this message translates to:
  /// **'Motifs de refus'**
  String get reportRefusals;

  /// No description provided for @reportControllers.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleurs'**
  String get reportControllers;

  /// No description provided for @reportColCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get reportColCategory;

  /// No description provided for @reportColQuota.
  ///
  /// In fr, this message translates to:
  /// **'Quota'**
  String get reportColQuota;

  /// No description provided for @reportColIssued.
  ///
  /// In fr, this message translates to:
  /// **'Émis'**
  String get reportColIssued;

  /// No description provided for @reportColAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Entrés'**
  String get reportColAdmitted;

  /// No description provided for @reportColRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get reportColRate;

  /// No description provided for @reportColCheckpoint.
  ///
  /// In fr, this message translates to:
  /// **'Porte'**
  String get reportColCheckpoint;

  /// No description provided for @reportColRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refus'**
  String get reportColRefused;

  /// No description provided for @reportColLastScan.
  ///
  /// In fr, this message translates to:
  /// **'Dernier scan'**
  String get reportColLastScan;

  /// No description provided for @reportColReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get reportColReason;

  /// No description provided for @reportColCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre'**
  String get reportColCount;

  /// No description provided for @reportColController.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleur'**
  String get reportColController;

  /// No description provided for @reportUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Illimité'**
  String get reportUnlimited;

  /// No description provided for @reportNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get reportNone;

  /// No description provided for @reportPage.
  ///
  /// In fr, this message translates to:
  /// **'Page {page} sur {pages}'**
  String reportPage(int page, int pages);

  /// No description provided for @reportCsvHeader.
  ///
  /// In fr, this message translates to:
  /// **'Référence;Catégorie;Type;Statut;Titulaire;Téléphone;E-mail;Émis le;Entré le;Porte;Annulé le;Dernier envoi;Envoyé le'**
  String get reportCsvHeader;

  /// No description provided for @categoryInvitationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie d\'invitations'**
  String get categoryInvitationLabel;

  /// No description provided for @categoryInvitationHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ses tickets sont présentés comme des invitations (carte, PDF, message). Le contrôle à l\'entrée ne change pas.'**
  String get categoryInvitationHelp;

  /// No description provided for @categoryInvitationBadge.
  ///
  /// In fr, this message translates to:
  /// **'Invitations'**
  String get categoryInvitationBadge;

  /// No description provided for @ticketInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Invitation'**
  String get ticketInvitation;

  /// No description provided for @ticketInvitationOf.
  ///
  /// In fr, this message translates to:
  /// **'Invitation {category}'**
  String ticketInvitationOf(String category);

  /// No description provided for @invitationFooter.
  ///
  /// In fr, this message translates to:
  /// **'Invitation personnelle à usage unique. Ne la publiez pas : la première présentation à l\'entrée fait foi.'**
  String get invitationFooter;

  /// No description provided for @invitationShareText.
  ///
  /// In fr, this message translates to:
  /// **'Votre invitation pour « {event} ». Présentez ce QR code à l\'entrée.'**
  String invitationShareText(String event);

  /// No description provided for @invitationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, vous êtes invité(e) à « {event} », {date}{place}. Votre invitation est jointe : présentez le QR code à l\'entrée. Invitation personnelle à usage unique : ne la transférez à personne.'**
  String invitationMessage(String event, String date, String place);

  /// No description provided for @invitationMessageNamed.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}, vous êtes invité(e) à « {event} », {date}{place}. Votre invitation est jointe : présentez le QR code à l\'entrée. Invitation personnelle à usage unique : ne la transférez à personne.'**
  String invitationMessageNamed(
    String name,
    String event,
    String date,
    String place,
  );

  /// No description provided for @invitationSubject.
  ///
  /// In fr, this message translates to:
  /// **'Votre invitation : {event}'**
  String invitationSubject(String event);

  /// No description provided for @dashboardInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Invités : {admitted} entrés sur {count, plural, =1{1 invitation} other{{count} invitations}}'**
  String dashboardInvitations(int admitted, int count);

  /// No description provided for @reportTypeTicket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get reportTypeTicket;

  /// No description provided for @reportTypeInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Invitation'**
  String get reportTypeInvitation;

  /// No description provided for @reportCategoryInvitation.
  ///
  /// In fr, this message translates to:
  /// **'{name} (invitations)'**
  String reportCategoryInvitation(String name);

  /// No description provided for @reportInvitationsLine.
  ///
  /// In fr, this message translates to:
  /// **'Dont invitations : {admitted} entrées sur {count}.'**
  String reportInvitationsLine(int admitted, int count);

  /// No description provided for @appearanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearanceTitle;

  /// No description provided for @appearanceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Sur cet appareil. « Système » suit le réglage clair ou sombre du téléphone.'**
  String get appearanceHelp;

  /// No description provided for @appearanceSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get appearanceDark;

  /// No description provided for @categoryPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix indicatif (facultatif)'**
  String get categoryPriceLabel;

  /// No description provided for @categoryPriceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Affiché sur la fiche publique de l\'événement. 0 pour une entrée gratuite.'**
  String get categoryPriceHelp;

  /// No description provided for @categoryPriceError.
  ///
  /// In fr, this message translates to:
  /// **'Prix de 0 à 10 000 000 FCFA.'**
  String get categoryPriceError;

  /// No description provided for @navExplore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get navExplore;

  /// No description provided for @navOrganize.
  ///
  /// In fr, this message translates to:
  /// **'Organiser'**
  String get navOrganize;

  /// No description provided for @navAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get navAccount;

  /// No description provided for @exploreSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Concert, lieu, promoteur…'**
  String get exploreSearchHint;

  /// No description provided for @exploreSearchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un événement'**
  String get exploreSearchLabel;

  /// No description provided for @exploreFilters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get exploreFilters;

  /// No description provided for @exploreAllCities.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les villes'**
  String get exploreAllCities;

  /// No description provided for @exploreCityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get exploreCityTitle;

  /// No description provided for @exploreAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get exploreAll;

  /// No description provided for @exploreFeatured.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get exploreFeatured;

  /// No description provided for @exploreUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'Prochainement'**
  String get exploreUpcoming;

  /// No description provided for @exploreUpcomingIn.
  ///
  /// In fr, this message translates to:
  /// **'Prochainement à {city}'**
  String exploreUpcomingIn(String city);

  /// No description provided for @exploreResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get exploreResults;

  /// No description provided for @exploreCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun événement} =1{1 événement} other{{count} événements}}'**
  String exploreCount(int count);

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement trouvé'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Essayez une autre catégorie, une autre ville ou un autre mot.'**
  String get exploreEmptyBody;

  /// No description provided for @exploreEmptyCatalogBody.
  ///
  /// In fr, this message translates to:
  /// **'Les promoteurs n\'ont pas encore publié d\'événement ouvert au public ici.'**
  String get exploreEmptyCatalogBody;

  /// No description provided for @exploreResetFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get exploreResetFilters;

  /// No description provided for @exploreErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifiez le réseau puis réessayez.'**
  String get exploreErrorNetwork;

  /// No description provided for @exploreErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les événements.'**
  String get exploreErrorLoad;

  /// No description provided for @exploreRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get exploreRetry;

  /// No description provided for @exploreMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus d\'événements'**
  String get exploreMore;

  /// No description provided for @exploreFromPrice.
  ///
  /// In fr, this message translates to:
  /// **'Dès {price}'**
  String exploreFromPrice(String price);

  /// No description provided for @exploreFree.
  ///
  /// In fr, this message translates to:
  /// **'Entrée gratuite'**
  String get exploreFree;

  /// No description provided for @explorePrice.
  ///
  /// In fr, this message translates to:
  /// **'{amount} FCFA'**
  String explorePrice(String amount);

  /// No description provided for @exploreKindConcert.
  ///
  /// In fr, this message translates to:
  /// **'Concerts'**
  String get exploreKindConcert;

  /// No description provided for @exploreKindConference.
  ///
  /// In fr, this message translates to:
  /// **'Conférences'**
  String get exploreKindConference;

  /// No description provided for @exploreKindWorship.
  ///
  /// In fr, this message translates to:
  /// **'Cultes'**
  String get exploreKindWorship;

  /// No description provided for @exploreKindSport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get exploreKindSport;

  /// No description provided for @exploreKindWedding.
  ///
  /// In fr, this message translates to:
  /// **'Mariages'**
  String get exploreKindWedding;

  /// No description provided for @exploreKindTraining.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get exploreKindTraining;

  /// No description provided for @exploreKindGala.
  ///
  /// In fr, this message translates to:
  /// **'Galas'**
  String get exploreKindGala;

  /// No description provided for @exploreKindOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get exploreKindOther;

  /// No description provided for @filtersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtersTitle;

  /// No description provided for @filtersClear.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get filtersClear;

  /// No description provided for @filtersCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get filtersCategory;

  /// No description provided for @filtersWhen.
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get filtersWhen;

  /// No description provided for @filtersAnyTime.
  ///
  /// In fr, this message translates to:
  /// **'Toutes dates'**
  String get filtersAnyTime;

  /// No description provided for @filtersToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get filtersToday;

  /// No description provided for @filtersWeekend.
  ///
  /// In fr, this message translates to:
  /// **'Ce week-end'**
  String get filtersWeekend;

  /// No description provided for @filtersWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get filtersWeek;

  /// No description provided for @filtersFree.
  ///
  /// In fr, this message translates to:
  /// **'Entrée gratuite seulement'**
  String get filtersFree;

  /// No description provided for @filtersFreeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Quand le promoteur l\'indique'**
  String get filtersFreeHelp;

  /// No description provided for @filtersApply.
  ///
  /// In fr, this message translates to:
  /// **'Voir les événements'**
  String get filtersApply;

  /// No description provided for @publicEventAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get publicEventAbout;

  /// No description provided for @publicEventTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets'**
  String get publicEventTickets;

  /// No description provided for @publicEventPriceUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Prix auprès du promoteur'**
  String get publicEventPriceUnknown;

  /// No description provided for @publicEventOrganizer.
  ///
  /// In fr, this message translates to:
  /// **'Organisé par'**
  String get publicEventOrganizer;

  /// No description provided for @publicEventGetTicket.
  ///
  /// In fr, this message translates to:
  /// **'Obtenir un ticket'**
  String get publicEventGetTicket;

  /// No description provided for @publicEventNoContact.
  ///
  /// In fr, this message translates to:
  /// **'Tickets auprès du promoteur'**
  String get publicEventNoContact;

  /// No description provided for @publicEventWhatsAppMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je souhaite obtenir un ticket pour « {event} » ({date}). Vu sur Tikéo.'**
  String publicEventWhatsAppMessage(String event, String date);

  /// No description provided for @publicEventWhatsAppFailed.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp n\'a pas pu s\'ouvrir sur ce téléphone.'**
  String get publicEventWhatsAppFailed;

  /// No description provided for @publicEventNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement n\'est plus visible.'**
  String get publicEventNotFound;

  /// No description provided for @publicEventShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get publicEventShare;

  /// No description provided for @publicEventShareText.
  ///
  /// In fr, this message translates to:
  /// **'« {event} », {date} — {place}. Sur Tikéo.'**
  String publicEventShareText(String event, String date, String place);

  /// No description provided for @publicEventOnline.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get publicEventOnline;

  /// No description provided for @organizeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes promoteur d\'événement ?'**
  String get organizeTitle;

  /// No description provided for @organizeBody.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre structure, émettez des tickets QR, envoyez-les par WhatsApp et contrôlez les entrées en direct.'**
  String get organizeBody;

  /// No description provided for @organizePoint1.
  ///
  /// In fr, this message translates to:
  /// **'Un ticket = une seule entrée, vérifiée en ligne'**
  String get organizePoint1;

  /// No description provided for @organizePoint2.
  ///
  /// In fr, this message translates to:
  /// **'Listes d\'invités depuis Excel'**
  String get organizePoint2;

  /// No description provided for @organizePoint3.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord et rapports'**
  String get organizePoint3;

  /// No description provided for @eventPublicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visible par le public'**
  String get eventPublicTitle;

  /// No description provided for @eventPublicHelp.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement apparaît dans l\'Explorer de Tikéo, sans compte, une fois publié. Ni les tickets ni les chiffres ne sont montrés.'**
  String get eventPublicHelp;

  /// No description provided for @eventPublicOn.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans l\'Explorer'**
  String get eventPublicOn;

  /// No description provided for @eventPublicOff.
  ///
  /// In fr, this message translates to:
  /// **'Privé : seuls vos invités ont leur ticket'**
  String get eventPublicOff;

  /// No description provided for @orgPublicPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp public'**
  String get orgPublicPhoneLabel;

  /// No description provided for @orgPublicPhoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Affiché sur vos événements publics (« Obtenir un ticket »). Facultatif.'**
  String get orgPublicPhoneHelp;

  /// No description provided for @homeAllEvents.
  ///
  /// In fr, this message translates to:
  /// **'Mes événements'**
  String get homeAllEvents;

  /// No description provided for @homeHello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String homeHello(String name);

  /// No description provided for @homeHelloPlain.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get homeHelloPlain;

  /// No description provided for @homeMyEventsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes événements'**
  String get homeMyEventsTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeSeeAll;

  /// No description provided for @homeStatAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'entrés'**
  String get homeStatAdmitted;

  /// No description provided for @homeStatIssued.
  ///
  /// In fr, this message translates to:
  /// **'émis'**
  String get homeStatIssued;

  /// No description provided for @homeStatAttendance.
  ///
  /// In fr, this message translates to:
  /// **'présence'**
  String get homeStatAttendance;

  /// No description provided for @homeProfileLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get homeProfileLabel;

  /// No description provided for @eventErrorBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement a été retiré du catalogue par Tikéo. Contactez le support.'**
  String get eventErrorBlocked;

  /// No description provided for @eventPublicBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Retiré du catalogue par Tikéo. Motif :'**
  String get eventPublicBlocked;

  /// No description provided for @consoleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Console Tikéo'**
  String get consoleTitle;

  /// No description provided for @consoleEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Administration de la plateforme'**
  String get consoleEntrySubtitle;

  /// No description provided for @consoleForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Cette console est réservée aux administrateurs de Tikéo.'**
  String get consoleForbidden;

  /// No description provided for @consoleLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifiez la connexion.'**
  String get consoleLoadError;

  /// No description provided for @consoleRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get consoleRetry;

  /// No description provided for @consoleUpdatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres de {time}'**
  String consoleUpdatedAt(String time);

  /// No description provided for @consoleStatLine.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {value}'**
  String consoleStatLine(String label, String value);

  /// No description provided for @consoleSectionOrganizations.
  ///
  /// In fr, this message translates to:
  /// **'Structures'**
  String get consoleSectionOrganizations;

  /// No description provided for @consoleSectionAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get consoleSectionAccounts;

  /// No description provided for @consoleSectionEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get consoleSectionEvents;

  /// No description provided for @consoleSectionTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets émis'**
  String get consoleSectionTickets;

  /// No description provided for @consoleSectionScans.
  ///
  /// In fr, this message translates to:
  /// **'Contrôles 24 h'**
  String get consoleSectionScans;

  /// No description provided for @consoleStatActiveF.
  ///
  /// In fr, this message translates to:
  /// **'Actives'**
  String get consoleStatActiveF;

  /// No description provided for @consoleStatDisabledF.
  ///
  /// In fr, this message translates to:
  /// **'Suspendues'**
  String get consoleStatDisabledF;

  /// No description provided for @consoleStatNew7d.
  ///
  /// In fr, this message translates to:
  /// **'Sur 7 jours'**
  String get consoleStatNew7d;

  /// No description provided for @consoleStatDisabledM.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés'**
  String get consoleStatDisabledM;

  /// No description provided for @consoleStatDeletion.
  ///
  /// In fr, this message translates to:
  /// **'À supprimer'**
  String get consoleStatDeletion;

  /// No description provided for @consoleStatUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get consoleStatUpcoming;

  /// No description provided for @consoleStatInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get consoleStatInProgress;

  /// No description provided for @consoleStatListed.
  ///
  /// In fr, this message translates to:
  /// **'Au catalogue'**
  String get consoleStatListed;

  /// No description provided for @consoleStatBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Retirés'**
  String get consoleStatBlocked;

  /// No description provided for @consoleStatRedeemed.
  ///
  /// In fr, this message translates to:
  /// **'Entrés'**
  String get consoleStatRedeemed;

  /// No description provided for @consoleStatAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptés'**
  String get consoleStatAccepted;

  /// No description provided for @consoleStatRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusés'**
  String get consoleStatRefused;

  /// No description provided for @consoleNavOrganizations.
  ///
  /// In fr, this message translates to:
  /// **'Structures'**
  String get consoleNavOrganizations;

  /// No description provided for @consoleNavOrganizationsHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher, suspendre ou réactiver'**
  String get consoleNavOrganizationsHint;

  /// No description provided for @consoleNavCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue public'**
  String get consoleNavCatalog;

  /// No description provided for @consoleNavCatalogHint.
  ///
  /// In fr, this message translates to:
  /// **'Modérer les événements publics'**
  String get consoleNavCatalogHint;

  /// No description provided for @consoleNavJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal d\'audit'**
  String get consoleNavJournal;

  /// No description provided for @consoleNavJournalHint.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les actions, des plus récentes aux plus anciennes'**
  String get consoleNavJournalHint;

  /// No description provided for @consoleSearchOrganizations.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une structure'**
  String get consoleSearchOrganizations;

  /// No description provided for @consoleDisabledOnly.
  ///
  /// In fr, this message translates to:
  /// **'Suspendues seulement'**
  String get consoleDisabledOnly;

  /// No description provided for @consoleOrgCounts.
  ///
  /// In fr, this message translates to:
  /// **'Membres : {members} · Événements : {events} · Tickets : {tickets}'**
  String consoleOrgCounts(int members, int events, int tickets);

  /// No description provided for @consoleOrgOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire : {name}'**
  String consoleOrgOwner(String name);

  /// No description provided for @consoleOrgCreated.
  ///
  /// In fr, this message translates to:
  /// **'Créée le {date}'**
  String consoleOrgCreated(String date);

  /// No description provided for @consoleSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendue'**
  String get consoleSuspended;

  /// No description provided for @consoleSuspendedSince.
  ///
  /// In fr, this message translates to:
  /// **'Suspendue le {date}. Motif : {reason}'**
  String consoleSuspendedSince(String date, String reason);

  /// No description provided for @consoleSuspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre la structure'**
  String get consoleSuspend;

  /// No description provided for @consoleSuspendHint.
  ///
  /// In fr, this message translates to:
  /// **'Ses membres ne pourront plus émettre ni contrôler de tickets, et ses événements quittent le catalogue.'**
  String get consoleSuspendHint;

  /// No description provided for @consoleReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (obligatoire)'**
  String get consoleReason;

  /// No description provided for @consoleReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un motif.'**
  String get consoleReasonRequired;

  /// No description provided for @consoleConfirmSuspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get consoleConfirmSuspend;

  /// No description provided for @consoleReactivate.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver la structure'**
  String get consoleReactivate;

  /// No description provided for @consoleSuspendedDone.
  ///
  /// In fr, this message translates to:
  /// **'Structure suspendue.'**
  String get consoleSuspendedDone;

  /// No description provided for @consoleReactivatedDone.
  ///
  /// In fr, this message translates to:
  /// **'Structure réactivée.'**
  String get consoleReactivatedDone;

  /// No description provided for @consoleActionError.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible. Réessayez.'**
  String get consoleActionError;

  /// No description provided for @consoleEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat.'**
  String get consoleEmpty;

  /// No description provided for @consoleLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get consoleLoadMore;

  /// No description provided for @consoleCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get consoleCancel;

  /// No description provided for @consoleSearchEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événement, structure ou ville'**
  String get consoleSearchEvents;

  /// No description provided for @consoleBlockedOnly.
  ///
  /// In fr, this message translates to:
  /// **'Retirés seulement'**
  String get consoleBlockedOnly;

  /// No description provided for @consoleListed.
  ///
  /// In fr, this message translates to:
  /// **'Au catalogue'**
  String get consoleListed;

  /// No description provided for @consoleNotListed.
  ///
  /// In fr, this message translates to:
  /// **'Hors catalogue'**
  String get consoleNotListed;

  /// No description provided for @consoleBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Retiré'**
  String get consoleBlocked;

  /// No description provided for @consoleBlockedSince.
  ///
  /// In fr, this message translates to:
  /// **'Retiré le {date}. Motif : {reason}'**
  String consoleBlockedSince(String date, String reason);

  /// No description provided for @consoleBlock.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du catalogue'**
  String get consoleBlock;

  /// No description provided for @consoleBlockHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement quitte le catalogue et le promoteur ne pourra plus le republier. Il verra le motif.'**
  String get consoleBlockHint;

  /// No description provided for @consoleConfirmBlock.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get consoleConfirmBlock;

  /// No description provided for @consoleUnblock.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get consoleUnblock;

  /// No description provided for @consoleUnblockHint.
  ///
  /// In fr, this message translates to:
  /// **'Le promoteur pourra de nouveau rendre l\'événement public.'**
  String get consoleUnblockHint;

  /// No description provided for @consoleBlockedDone.
  ///
  /// In fr, this message translates to:
  /// **'Événement retiré du catalogue.'**
  String get consoleBlockedDone;

  /// No description provided for @consoleUnblockedDone.
  ///
  /// In fr, this message translates to:
  /// **'Événement rétabli.'**
  String get consoleUnblockedDone;

  /// No description provided for @consoleAuditAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get consoleAuditAll;

  /// No description provided for @consoleAuditConsole.
  ///
  /// In fr, this message translates to:
  /// **'Console'**
  String get consoleAuditConsole;

  /// No description provided for @consoleAuditEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get consoleAuditEvents;

  /// No description provided for @consoleAuditTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets'**
  String get consoleAuditTickets;

  /// No description provided for @consoleAuditOrganizations.
  ///
  /// In fr, this message translates to:
  /// **'Structures'**
  String get consoleAuditOrganizations;

  /// No description provided for @consoleAuditBy.
  ///
  /// In fr, this message translates to:
  /// **'par {name}'**
  String consoleAuditBy(String name);

  /// No description provided for @auditAdminEventModerated.
  ///
  /// In fr, this message translates to:
  /// **'Modération du catalogue'**
  String get auditAdminEventModerated;

  /// No description provided for @auditAdminOrganizationStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut de structure modifié'**
  String get auditAdminOrganizationStatusChanged;

  /// No description provided for @auditAssignmentAdded.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleur affecté'**
  String get auditAssignmentAdded;

  /// No description provided for @auditAssignmentRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleur retiré'**
  String get auditAssignmentRemoved;

  /// No description provided for @auditCategoryCreated.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie créée'**
  String get auditCategoryCreated;

  /// No description provided for @auditCategoryDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie supprimée'**
  String get auditCategoryDeleted;

  /// No description provided for @auditCategoryPriceChanged.
  ///
  /// In fr, this message translates to:
  /// **'Prix indicatif modifié'**
  String get auditCategoryPriceChanged;

  /// No description provided for @auditCategoryUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie modifiée'**
  String get auditCategoryUpdated;

  /// No description provided for @auditCheckpointCreated.
  ///
  /// In fr, this message translates to:
  /// **'Porte créée'**
  String get auditCheckpointCreated;

  /// No description provided for @auditCheckpointUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Porte modifiée'**
  String get auditCheckpointUpdated;

  /// No description provided for @auditEventCoverChanged.
  ///
  /// In fr, this message translates to:
  /// **'Photo d\'événement modifiée'**
  String get auditEventCoverChanged;

  /// No description provided for @auditEventCreated.
  ///
  /// In fr, this message translates to:
  /// **'Événement créé'**
  String get auditEventCreated;

  /// No description provided for @auditEventReportExported.
  ///
  /// In fr, this message translates to:
  /// **'Rapport exporté'**
  String get auditEventReportExported;

  /// No description provided for @auditEventStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut d\'événement modifié'**
  String get auditEventStatusChanged;

  /// No description provided for @auditEventUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Événement modifié'**
  String get auditEventUpdated;

  /// No description provided for @auditEventVisibilityChanged.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité publique modifiée'**
  String get auditEventVisibilityChanged;

  /// No description provided for @auditInvitationAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Invitation d\'équipe acceptée'**
  String get auditInvitationAccepted;

  /// No description provided for @auditInvitationCreated.
  ///
  /// In fr, this message translates to:
  /// **'Invitation d\'équipe créée'**
  String get auditInvitationCreated;

  /// No description provided for @auditInvitationRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Invitation d\'équipe annulée'**
  String get auditInvitationRevoked;

  /// No description provided for @auditMemberLeft.
  ///
  /// In fr, this message translates to:
  /// **'Membre parti'**
  String get auditMemberLeft;

  /// No description provided for @auditMemberUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Membre modifié'**
  String get auditMemberUpdated;

  /// No description provided for @auditOrganizationCreated.
  ///
  /// In fr, this message translates to:
  /// **'Structure créée'**
  String get auditOrganizationCreated;

  /// No description provided for @auditOrganizationLogoChanged.
  ///
  /// In fr, this message translates to:
  /// **'Logo modifié'**
  String get auditOrganizationLogoChanged;

  /// No description provided for @auditOrganizationPublicPhoneChanged.
  ///
  /// In fr, this message translates to:
  /// **'Numéro public modifié'**
  String get auditOrganizationPublicPhoneChanged;

  /// No description provided for @auditOrganizationUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Structure modifiée'**
  String get auditOrganizationUpdated;

  /// No description provided for @auditTicketHolderUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire modifié'**
  String get auditTicketHolderUpdated;

  /// No description provided for @auditTicketRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Ticket annulé'**
  String get auditTicketRevoked;

  /// No description provided for @auditTicketsExported.
  ///
  /// In fr, this message translates to:
  /// **'Tickets exportés'**
  String get auditTicketsExported;

  /// No description provided for @auditTicketsIssued.
  ///
  /// In fr, this message translates to:
  /// **'Tickets émis'**
  String get auditTicketsIssued;

  /// No description provided for @auditDetailYes.
  ///
  /// In fr, this message translates to:
  /// **'oui'**
  String get auditDetailYes;

  /// No description provided for @auditDetailNo.
  ///
  /// In fr, this message translates to:
  /// **'non'**
  String get auditDetailNo;

  /// No description provided for @auditFieldPublic.
  ///
  /// In fr, this message translates to:
  /// **'public'**
  String get auditFieldPublic;

  /// No description provided for @auditFieldBlocked.
  ///
  /// In fr, this message translates to:
  /// **'retiré'**
  String get auditFieldBlocked;

  /// No description provided for @auditFieldStatus.
  ///
  /// In fr, this message translates to:
  /// **'statut'**
  String get auditFieldStatus;

  /// No description provided for @auditFieldQuantity.
  ///
  /// In fr, this message translates to:
  /// **'quantité'**
  String get auditFieldQuantity;

  /// No description provided for @auditFieldCount.
  ///
  /// In fr, this message translates to:
  /// **'nombre'**
  String get auditFieldCount;

  /// No description provided for @auditFieldRemoved.
  ///
  /// In fr, this message translates to:
  /// **'supprimé'**
  String get auditFieldRemoved;

  /// No description provided for @auditFieldFrom.
  ///
  /// In fr, this message translates to:
  /// **'de'**
  String get auditFieldFrom;

  /// No description provided for @auditFieldTo.
  ///
  /// In fr, this message translates to:
  /// **'vers'**
  String get auditFieldTo;

  /// No description provided for @auditFieldRole.
  ///
  /// In fr, this message translates to:
  /// **'rôle'**
  String get auditFieldRole;

  /// No description provided for @auditFieldCapacity.
  ///
  /// In fr, this message translates to:
  /// **'capacité'**
  String get auditFieldCapacity;

  /// No description provided for @auditFieldFields.
  ///
  /// In fr, this message translates to:
  /// **'champs'**
  String get auditFieldFields;

  /// No description provided for @auditFieldInvitation.
  ///
  /// In fr, this message translates to:
  /// **'invitation'**
  String get auditFieldInvitation;

  /// No description provided for @auditFieldRows.
  ///
  /// In fr, this message translates to:
  /// **'lignes'**
  String get auditFieldRows;

  /// No description provided for @auditFieldChannel.
  ///
  /// In fr, this message translates to:
  /// **'canal'**
  String get auditFieldChannel;

  /// No description provided for @auditFieldPrice.
  ///
  /// In fr, this message translates to:
  /// **'prix'**
  String get auditFieldPrice;

  /// No description provided for @eventActionStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le contrôle'**
  String get eventActionStop;

  /// No description provided for @eventConfirmStop.
  ///
  /// In fr, this message translates to:
  /// **'Plus aucune entrée ne sera acceptée aux portes. Cette action est définitive.'**
  String get eventConfirmStop;

  /// No description provided for @controlNotStarted.
  ///
  /// In fr, this message translates to:
  /// **'Le contrôle n\'a pas encore démarré'**
  String get controlNotStarted;

  /// No description provided for @ticketsTypeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous les types'**
  String get ticketsTypeAll;

  /// No description provided for @ticketsTypeCount.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {count}'**
  String ticketsTypeCount(String name, int count);

  /// No description provided for @eventsFilterCurrent.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get eventsFilterCurrent;

  /// No description provided for @eventsSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'{title} ({count})'**
  String eventsSectionTitle(String title, int count);

  /// No description provided for @favoriteAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get favoriteRemove;

  /// No description provided for @favoriteAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à vos favoris'**
  String get favoriteAdded;

  /// No description provided for @favoriteRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Retiré de vos favoris'**
  String get favoriteRemoved;

  /// No description provided for @navFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get navFavorites;

  /// No description provided for @favoritesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour l\'instant'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Touchez le cœur d\'un événement pour le retrouver ici, même sans compte.'**
  String get favoritesEmptyBody;

  /// No description provided for @favoritesExplore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer les événements'**
  String get favoritesExplore;

  /// No description provided for @favoritesUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get favoritesUpcoming;

  /// No description provided for @favoritesPast.
  ///
  /// In fr, this message translates to:
  /// **'Passés'**
  String get favoritesPast;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get welcomeCreateAccount;

  /// No description provided for @welcomeHaveCode.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un code d\'invitation'**
  String get welcomeHaveCode;

  /// No description provided for @signUpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get signUpTitle;

  /// No description provided for @signUpNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom et prénom'**
  String get signUpNameLabel;

  /// No description provided for @signUpNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre nom.'**
  String get signUpNameRequired;

  /// No description provided for @signUpPasswordHelp.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins'**
  String get signUpPasswordHelp;

  /// No description provided for @signUpPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins.'**
  String get signUpPasswordTooShort;

  /// No description provided for @signUpPromoter.
  ///
  /// In fr, this message translates to:
  /// **'Je suis promoteur d\'événement'**
  String get signUpPromoter;

  /// No description provided for @signUpPromoterHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre structure pour publier des événements, émettre des tickets et gérer votre équipe.'**
  String get signUpPromoterHint;

  /// No description provided for @signUpStructureRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le nom de votre structure.'**
  String get signUpStructureRequired;

  /// No description provided for @signUpCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation (facultatif)'**
  String get signUpCodeLabel;

  /// No description provided for @signUpCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Reçu d\'un promoteur pour rejoindre son équipe'**
  String get signUpCodeHelp;

  /// No description provided for @signUpSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get signUpSubmit;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get signUpHaveAccount;

  /// No description provided for @signInNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Créer un compte'**
  String get signInNoAccount;

  /// No description provided for @signUpConfirmEmail.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Confirmez votre adresse depuis l\'e-mail reçu, puis connectez-vous.'**
  String get signUpConfirmEmail;

  /// No description provided for @signUpWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Tikéo, {name} !'**
  String signUpWelcome(String name);

  /// No description provided for @signUpStepFailed.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est créé, mais l\'étape suivante a échoué : {reason} Vous pouvez la refaire depuis votre profil.'**
  String signUpStepFailed(String reason);

  /// No description provided for @profilePromoterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes promoteur d\'événement ?'**
  String get profilePromoterTitle;

  /// No description provided for @profilePromoterBody.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre structure pour publier vos événements et émettre des tickets.'**
  String get profilePromoterBody;

  /// No description provided for @profilePromoterAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer ma structure'**
  String get profilePromoterAction;

  /// No description provided for @profileJoinAction.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre une équipe avec un code'**
  String get profileJoinAction;

  /// No description provided for @consoleNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible pour ce compte.'**
  String get consoleNotAllowed;

  /// No description provided for @consoleStatDue.
  ///
  /// In fr, this message translates to:
  /// **'À supprimer'**
  String get consoleStatDue;

  /// No description provided for @consoleNavAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get consoleNavAccounts;

  /// No description provided for @consoleNavAccountsHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher, désactiver, supprimer à échéance'**
  String get consoleNavAccountsHint;

  /// No description provided for @consoleSearchAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou adresse e-mail'**
  String get consoleSearchAccounts;

  /// No description provided for @consoleAccountsAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get consoleAccountsAll;

  /// No description provided for @consoleAccountsDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés'**
  String get consoleAccountsDisabled;

  /// No description provided for @consoleAccountsDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Suppression demandée'**
  String get consoleAccountsDeletion;

  /// No description provided for @consoleAccountsDue.
  ///
  /// In fr, this message translates to:
  /// **'À supprimer'**
  String get consoleAccountsDue;

  /// No description provided for @consoleAccountsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Supprimés'**
  String get consoleAccountsDeleted;

  /// No description provided for @consoleAccountAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get consoleAccountAdmin;

  /// No description provided for @consoleAccountDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get consoleAccountDisabled;

  /// No description provided for @consoleAccountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé'**
  String get consoleAccountDeleted;

  /// No description provided for @consoleAccountDue.
  ///
  /// In fr, this message translates to:
  /// **'À supprimer'**
  String get consoleAccountDue;

  /// No description provided for @consoleAccountCreated.
  ///
  /// In fr, this message translates to:
  /// **'Inscrit le {date}'**
  String consoleAccountCreated(String date);

  /// No description provided for @consoleAccountLastSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Dernière connexion : {date}'**
  String consoleAccountLastSignIn(String date);

  /// No description provided for @consoleAccountNeverSignedIn.
  ///
  /// In fr, this message translates to:
  /// **'Jamais connecté'**
  String get consoleAccountNeverSignedIn;

  /// No description provided for @consoleAccountCounts.
  ///
  /// In fr, this message translates to:
  /// **'Structures : {memberships} · Propriétaire de {owned}'**
  String consoleAccountCounts(int memberships, int owned);

  /// No description provided for @consoleAccountDeletionAt.
  ///
  /// In fr, this message translates to:
  /// **'Suppression demandée le {date} · échéance le {due}'**
  String consoleAccountDeletionAt(String date, String due);

  /// No description provided for @consoleAccountDisabledSince.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé le {date}. Motif : {reason}'**
  String consoleAccountDisabledSince(String date, String reason);

  /// No description provided for @consoleAccountDeletedOn.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé le {date}'**
  String consoleAccountDeletedOn(String date);

  /// No description provided for @consoleDisableAccount.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le compte'**
  String get consoleDisableAccount;

  /// No description provided for @consoleDisableAccountHint.
  ///
  /// In fr, this message translates to:
  /// **'Le compte perd tous ses droits dans ses structures (émission, contrôle, équipe). Il peut toujours consulter l\'Explorer.'**
  String get consoleDisableAccountHint;

  /// No description provided for @consoleConfirmDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get consoleConfirmDisable;

  /// No description provided for @consoleReactivateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver le compte'**
  String get consoleReactivateAccount;

  /// No description provided for @consoleAccountDisabledDone.
  ///
  /// In fr, this message translates to:
  /// **'Compte désactivé.'**
  String get consoleAccountDisabledDone;

  /// No description provided for @consoleAccountReactivatedDone.
  ///
  /// In fr, this message translates to:
  /// **'Compte réactivé.'**
  String get consoleAccountReactivatedDone;

  /// No description provided for @consolePurgeAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get consolePurgeAccount;

  /// No description provided for @consolePurgeAccountHint.
  ///
  /// In fr, this message translates to:
  /// **'Le profil est anonymisé, la connexion devient impossible et les structures dont il est propriétaire sont suspendues. Les tickets et journaux restent. Action définitive.'**
  String get consolePurgeAccountHint;

  /// No description provided for @consolePurgeDone.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé. Structures suspendues : {count}'**
  String consolePurgeDone(int count);

  /// No description provided for @consolePurgeAll.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les {count, plural, =1{1 compte arrivé} other{{count} comptes arrivés}} à échéance'**
  String consolePurgeAll(int count);

  /// No description provided for @consolePurgeAllHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque compte dont la suppression a été demandée il y a 30 jours au moins est anonymisé ; les structures dont il est propriétaire sont suspendues. Action définitive.'**
  String get consolePurgeAllHint;

  /// No description provided for @consolePurgeAllDone.
  ///
  /// In fr, this message translates to:
  /// **'Comptes supprimés : {accounts} · structures suspendues : {structures}'**
  String consolePurgeAllDone(int accounts, int structures);

  /// No description provided for @auditAdminAccountStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut de compte modifié'**
  String get auditAdminAccountStatusChanged;

  /// No description provided for @auditAdminAccountPurged.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé définitivement'**
  String get auditAdminAccountPurged;

  /// No description provided for @auditFieldStructuresSuspended.
  ///
  /// In fr, this message translates to:
  /// **'structures suspendues'**
  String get auditFieldStructuresSuspended;

  /// No description provided for @auditFieldCause.
  ///
  /// In fr, this message translates to:
  /// **'cause'**
  String get auditFieldCause;

  /// No description provided for @auditValueOwnerDeleted.
  ///
  /// In fr, this message translates to:
  /// **'compte du propriétaire supprimé'**
  String get auditValueOwnerDeleted;

  /// No description provided for @announcementDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Masquer l\'annonce'**
  String get announcementDismiss;

  /// No description provided for @supportEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get supportEntryTitle;

  /// No description provided for @supportEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Posez une question à l\'équipe Tikéo'**
  String get supportEntrySubtitle;

  /// No description provided for @supportUnread.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nouvelle réponse} other{{count} nouvelles réponses}}'**
  String supportUnread(int count);

  /// No description provided for @supportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get supportTitle;

  /// No description provided for @supportNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get supportNew;

  /// No description provided for @supportEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande'**
  String get supportEmptyTitle;

  /// No description provided for @supportEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Une question, un problème ? Écrivez à l\'équipe Tikéo : la réponse arrive ici.'**
  String get supportEmptyBody;

  /// No description provided for @supportLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifiez la connexion.'**
  String get supportLoadError;

  /// No description provided for @supportStatusOpen.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusAnswered.
  ///
  /// In fr, this message translates to:
  /// **'Répondu'**
  String get supportStatusAnswered;

  /// No description provided for @supportStatusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get supportStatusClosed;

  /// No description provided for @supportCategoryQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question'**
  String get supportCategoryQuestion;

  /// No description provided for @supportCategoryProblem.
  ///
  /// In fr, this message translates to:
  /// **'Problème'**
  String get supportCategoryProblem;

  /// No description provided for @supportCategoryAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get supportCategoryAccount;

  /// No description provided for @supportCategoryPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get supportCategoryPayment;

  /// No description provided for @supportCategoryOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get supportCategoryOther;

  /// No description provided for @supportSubjectLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get supportSubjectLabel;

  /// No description provided for @supportBodyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get supportBodyLabel;

  /// No description provided for @supportCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get supportCategoryLabel;

  /// No description provided for @supportSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get supportSend;

  /// No description provided for @supportSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée. Vous serez prévenu ici dès la réponse.'**
  String get supportSent;

  /// No description provided for @supportSubjectInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entre 3 et 120 caractères.'**
  String get supportSubjectInvalid;

  /// No description provided for @supportBodyInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre message (2 000 caractères au plus).'**
  String get supportBodyInvalid;

  /// No description provided for @supportLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de demandes en cours ou de messages : réessayez plus tard.'**
  String get supportLimit;

  /// No description provided for @supportNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Demande introuvable.'**
  String get supportNotFound;

  /// No description provided for @supportError.
  ///
  /// In fr, this message translates to:
  /// **'Envoi impossible. Vérifiez la connexion.'**
  String get supportError;

  /// No description provided for @supportReplyHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get supportReplyHint;

  /// No description provided for @supportClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la demande'**
  String get supportClose;

  /// No description provided for @supportClosed.
  ///
  /// In fr, this message translates to:
  /// **'Demande fermée. Écrivez un message pour la rouvrir.'**
  String get supportClosed;

  /// No description provided for @supportTeam.
  ///
  /// In fr, this message translates to:
  /// **'Support Tikéo'**
  String get supportTeam;

  /// No description provided for @supportLastMessage.
  ///
  /// In fr, this message translates to:
  /// **'Dernier message le {date}'**
  String supportLastMessage(String date);

  /// No description provided for @consoleNavSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get consoleNavSupport;

  /// No description provided for @consoleNavSupportHint.
  ///
  /// In fr, this message translates to:
  /// **'Répondre aux demandes des utilisateurs'**
  String get consoleNavSupportHint;

  /// No description provided for @consoleNavSupportUnread.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune demande non lue} =1{1 demande non lue} other{{count} demandes non lues}}'**
  String consoleNavSupportUnread(int count);

  /// No description provided for @consoleSupportAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get consoleSupportAll;

  /// No description provided for @consoleSupportSearch.
  ///
  /// In fr, this message translates to:
  /// **'Sujet, nom ou adresse'**
  String get consoleSupportSearch;

  /// No description provided for @consoleSupportFrom.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {email}'**
  String consoleSupportFrom(String name, String email);

  /// No description provided for @consoleSupportMessages.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String consoleSupportMessages(int count);

  /// No description provided for @consoleNavAnnouncements.
  ///
  /// In fr, this message translates to:
  /// **'Annonces'**
  String get consoleNavAnnouncements;

  /// No description provided for @consoleNavAnnouncementsHint.
  ///
  /// In fr, this message translates to:
  /// **'Publier un message dans l\'application'**
  String get consoleNavAnnouncementsHint;

  /// No description provided for @consoleAnnouncementNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle annonce'**
  String get consoleAnnouncementNew;

  /// No description provided for @consoleAnnouncementTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get consoleAnnouncementTitleLabel;

  /// No description provided for @consoleAnnouncementBodyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get consoleAnnouncementBodyLabel;

  /// No description provided for @consoleAnnouncementAudience.
  ///
  /// In fr, this message translates to:
  /// **'Destinataires'**
  String get consoleAnnouncementAudience;

  /// No description provided for @consoleAudienceVisitors.
  ///
  /// In fr, this message translates to:
  /// **'Visiteurs sans compte'**
  String get consoleAudienceVisitors;

  /// No description provided for @consoleAudienceUsers.
  ///
  /// In fr, this message translates to:
  /// **'Comptes classiques'**
  String get consoleAudienceUsers;

  /// No description provided for @consoleAudiencePromoters.
  ///
  /// In fr, this message translates to:
  /// **'Promoteurs'**
  String get consoleAudiencePromoters;

  /// No description provided for @consoleAudienceControllers.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleurs'**
  String get consoleAudienceControllers;

  /// No description provided for @consoleAnnouncementAudienceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un destinataire.'**
  String get consoleAnnouncementAudienceRequired;

  /// No description provided for @consoleAnnouncementImportant.
  ///
  /// In fr, this message translates to:
  /// **'Importante (mise en avant)'**
  String get consoleAnnouncementImportant;

  /// No description provided for @consoleAnnouncementDuration.
  ///
  /// In fr, this message translates to:
  /// **'Affichée pendant'**
  String get consoleAnnouncementDuration;

  /// No description provided for @consoleDuration1d.
  ///
  /// In fr, this message translates to:
  /// **'24 heures'**
  String get consoleDuration1d;

  /// No description provided for @consoleDuration7d.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get consoleDuration7d;

  /// No description provided for @consoleDuration30d.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get consoleDuration30d;

  /// No description provided for @consoleDurationNone.
  ///
  /// In fr, this message translates to:
  /// **'Sans fin'**
  String get consoleDurationNone;

  /// No description provided for @consoleAnnouncementPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get consoleAnnouncementPublish;

  /// No description provided for @consoleAnnouncementPublished.
  ///
  /// In fr, this message translates to:
  /// **'Annonce publiée.'**
  String get consoleAnnouncementPublished;

  /// No description provided for @consoleAnnouncementArchive.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get consoleAnnouncementArchive;

  /// No description provided for @consoleAnnouncementArchived.
  ///
  /// In fr, this message translates to:
  /// **'Annonce retirée.'**
  String get consoleAnnouncementArchived;

  /// No description provided for @consoleAnnouncementActive.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get consoleAnnouncementActive;

  /// No description provided for @consoleAnnouncementInactive.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get consoleAnnouncementInactive;

  /// No description provided for @consoleAnnouncementUntil.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'au {date}'**
  String consoleAnnouncementUntil(String date);

  /// No description provided for @consoleAnnouncementInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Titre de 3 à 80 caractères, message de 1 000 caractères au plus.'**
  String get consoleAnnouncementInvalid;

  /// No description provided for @consoleStatSupportOpen.
  ///
  /// In fr, this message translates to:
  /// **'Support en attente'**
  String get consoleStatSupportOpen;

  /// No description provided for @auditAdminSupportReplied.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du support'**
  String get auditAdminSupportReplied;

  /// No description provided for @auditAdminAnnouncementPublished.
  ///
  /// In fr, this message translates to:
  /// **'Annonce publiée'**
  String get auditAdminAnnouncementPublished;

  /// No description provided for @auditAdminAnnouncementArchived.
  ///
  /// In fr, this message translates to:
  /// **'Annonce retirée'**
  String get auditAdminAnnouncementArchived;

  /// No description provided for @auditFieldAudiences.
  ///
  /// In fr, this message translates to:
  /// **'destinataires'**
  String get auditFieldAudiences;

  /// No description provided for @auditFieldLevel.
  ///
  /// In fr, this message translates to:
  /// **'importance'**
  String get auditFieldLevel;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence, langue, sons, stockage, version, mentions légales'**
  String get settingsEntrySubtitle;

  /// No description provided for @settingsStorage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage'**
  String get settingsStorage;

  /// No description provided for @settingsImageCache.
  ///
  /// In fr, this message translates to:
  /// **'Images enregistrées'**
  String get settingsImageCache;

  /// No description provided for @settingsImageCacheSize.
  ///
  /// In fr, this message translates to:
  /// **'{size} sur ce téléphone'**
  String settingsImageCacheSize(String size);

  /// No description provided for @settingsImageCacheEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune image enregistrée'**
  String get settingsImageCacheEmpty;

  /// No description provided for @settingsImageCacheClear.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get settingsImageCacheClear;

  /// No description provided for @settingsImageCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Images retirées du téléphone.'**
  String get settingsImageCacheCleared;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version pilote {build}'**
  String settingsVersion(int build);

  /// No description provided for @settingsVersionDev.
  ///
  /// In fr, this message translates to:
  /// **'Version de développement'**
  String get settingsVersionDev;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une mise à jour'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez la dernière version.'**
  String get settingsUpToDate;

  /// No description provided for @settingsCheckFailed.
  ///
  /// In fr, this message translates to:
  /// **'Vérification impossible. Vérifiez la connexion.'**
  String get settingsCheckFailed;

  /// No description provided for @legalTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get legalTerms;

  /// No description provided for @legalPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get legalPrivacy;

  /// No description provided for @legalUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} du {date}'**
  String legalUpdated(int version, String date);

  /// No description provided for @legalLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Document indisponible. Vérifiez la connexion.'**
  String get legalLoadError;

  /// No description provided for @legalRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get legalRetry;

  /// No description provided for @signUpLegalPrefix.
  ///
  /// In fr, this message translates to:
  /// **'En créant un compte, vous acceptez les '**
  String get signUpLegalPrefix;

  /// No description provided for @signUpLegalAnd.
  ///
  /// In fr, this message translates to:
  /// **' et la '**
  String get signUpLegalAnd;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version disponible'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In fr, this message translates to:
  /// **'La version pilote {build} est prête. Téléchargez-la puis installez-la par-dessus l\'actuelle : vos données sont conservées.'**
  String updateAvailableBody(int build);

  /// No description provided for @updateDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get updateDownload;

  /// No description provided for @consoleNavLegal.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get consoleNavLegal;

  /// No description provided for @consoleNavLegalHint.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation et confidentialité'**
  String get consoleNavLegalHint;

  /// No description provided for @consoleLegalVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} · {date}'**
  String consoleLegalVersion(int version, String date);

  /// No description provided for @consoleLegalTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get consoleLegalTitleLabel;

  /// No description provided for @consoleLegalBodyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get consoleLegalBodyLabel;

  /// No description provided for @consoleLegalBodyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ligne vide entre deux paragraphes, « ## » pour un intertitre, « - » pour une puce. Complétez les passages entre crochets.'**
  String get consoleLegalBodyHelp;

  /// No description provided for @consoleLegalEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get consoleLegalEdit;

  /// No description provided for @consoleLegalPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get consoleLegalPreview;

  /// No description provided for @consoleLegalSave.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get consoleLegalSave;

  /// No description provided for @consoleLegalConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Publier la version {version} ?'**
  String consoleLegalConfirm(int version);

  /// No description provided for @consoleLegalConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau texte s\'affiche aussitôt pour tous les utilisateurs.'**
  String get consoleLegalConfirmBody;

  /// No description provided for @consoleLegalSaved.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} publiée.'**
  String consoleLegalSaved(int version);

  /// No description provided for @consoleLegalInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Titre de 3 à 80 caractères, texte de 20 à 20 000 caractères.'**
  String get consoleLegalInvalid;

  /// No description provided for @consoleLegalPlaceholders.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 passage entre crochets reste à compléter.} other{{count} passages entre crochets restent à compléter.}}'**
  String consoleLegalPlaceholders(int count);

  /// No description provided for @auditAdminLegalUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales modifiées'**
  String get auditAdminLegalUpdated;

  /// No description provided for @auditFieldDocument.
  ///
  /// In fr, this message translates to:
  /// **'document'**
  String get auditFieldDocument;

  /// No description provided for @selectionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sélectionné} other{{count} sélectionnés}}'**
  String selectionCount(int count);

  /// No description provided for @selectionClose.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la sélection'**
  String get selectionClose;

  /// No description provided for @selectionAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectionAll;

  /// No description provided for @selectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long sur un ticket pour en sélectionner plusieurs'**
  String get selectionHint;

  /// No description provided for @ticketsBulkPdf.
  ///
  /// In fr, this message translates to:
  /// **'Partager en PDF'**
  String get ticketsBulkPdf;

  /// No description provided for @ticketsBulkRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get ticketsBulkRevoke;

  /// No description provided for @ticketsBulkRevokeTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Annuler 1 ticket ?} other{Annuler {count} tickets ?}}'**
  String ticketsBulkRevokeTitle(int count);

  /// No description provided for @ticketsBulkRevokeBody.
  ///
  /// In fr, this message translates to:
  /// **'Ils seront refusés à l\'entrée. Les tickets déjà utilisés ou annulés ne changent pas. Cette action est définitive.'**
  String get ticketsBulkRevokeBody;

  /// No description provided for @ticketsBulkRevoked.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun ticket à annuler.} =1{1 ticket annulé.} other{{count} tickets annulés.}}'**
  String ticketsBulkRevoked(int count);

  /// No description provided for @ticketsBulkNothingValid.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket valable dans la sélection.'**
  String get ticketsBulkNothingValid;

  /// No description provided for @ticketsBulkError.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible. Vérifiez la connexion.'**
  String get ticketsBulkError;

  /// No description provided for @eventDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get eventDuplicate;

  /// No description provided for @eventDuplicateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer l\'événement'**
  String get eventDuplicateTitle;

  /// No description provided for @eventDuplicateBody.
  ///
  /// In fr, this message translates to:
  /// **'Catégories, portes et équipe sont recopiées. Les tickets ne le sont pas. La copie est un brouillon.'**
  String get eventDuplicateBody;

  /// No description provided for @eventDuplicateName.
  ///
  /// In fr, this message translates to:
  /// **'{title} (copie)'**
  String eventDuplicateName(String title);

  /// No description provided for @eventDuplicateNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la copie'**
  String get eventDuplicateNameLabel;

  /// No description provided for @eventDuplicateStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get eventDuplicateStart;

  /// No description provided for @eventDuplicateKeepLength.
  ///
  /// In fr, this message translates to:
  /// **'La durée reste la même que celle de l\'original.'**
  String get eventDuplicateKeepLength;

  /// No description provided for @eventDuplicateSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer la copie'**
  String get eventDuplicateSubmit;

  /// No description provided for @eventDuplicated.
  ///
  /// In fr, this message translates to:
  /// **'Copie créée en brouillon.'**
  String get eventDuplicated;

  /// No description provided for @eventDuplicateError.
  ///
  /// In fr, this message translates to:
  /// **'Copie impossible. Vérifiez la date et la connexion.'**
  String get eventDuplicateError;

  /// No description provided for @firstStepsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Premiers pas'**
  String get firstStepsTitle;

  /// No description provided for @firstStepsProgress.
  ///
  /// In fr, this message translates to:
  /// **'{done} sur {total}'**
  String firstStepsProgress(int done, int total);

  /// No description provided for @firstStepsHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get firstStepsHide;

  /// No description provided for @firstStepsEvent.
  ///
  /// In fr, this message translates to:
  /// **'Créer un événement'**
  String get firstStepsEvent;

  /// No description provided for @firstStepsCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un type de ticket'**
  String get firstStepsCategory;

  /// No description provided for @firstStepsPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'événement'**
  String get firstStepsPublish;

  /// No description provided for @firstStepsIssue.
  ///
  /// In fr, this message translates to:
  /// **'Émettre un premier ticket'**
  String get firstStepsIssue;

  /// No description provided for @firstStepsTeam.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un contrôleur'**
  String get firstStepsTeam;

  /// No description provided for @firstStepsPhone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le numéro WhatsApp public'**
  String get firstStepsPhone;

  /// No description provided for @firstStepsDone.
  ///
  /// In fr, this message translates to:
  /// **'Bravo, votre structure est prête !'**
  String get firstStepsDone;

  /// No description provided for @navWallet.
  ///
  /// In fr, this message translates to:
  /// **'Mes tickets'**
  String get navWallet;

  /// No description provided for @walletTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes tickets'**
  String get walletTitle;

  /// No description provided for @walletEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les tickets que vous avez reçus pour aller à un événement'**
  String get walletEntrySubtitle;

  /// No description provided for @walletAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ticket'**
  String get walletAdd;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket pour l\'instant'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez reçu un ticket par WhatsApp, SMS ou e-mail ? Ajoutez-le ici : scannez son QR ou choisissez son image.'**
  String get walletEmptyBody;

  /// No description provided for @walletUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get walletUpcoming;

  /// No description provided for @walletPast.
  ///
  /// In fr, this message translates to:
  /// **'Passés'**
  String get walletPast;

  /// No description provided for @walletOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion : liste enregistrée le {date}. Les QR restent valables ; leur état sera vérifié à l\'entrée.'**
  String walletOffline(String date);

  /// No description provided for @walletLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifiez la connexion.'**
  String get walletLoadError;

  /// No description provided for @walletRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get walletRetry;

  /// No description provided for @walletStatusValid.
  ///
  /// In fr, this message translates to:
  /// **'Valable'**
  String get walletStatusValid;

  /// No description provided for @walletStatusUsed.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé'**
  String get walletStatusUsed;

  /// No description provided for @walletStatusRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get walletStatusRevoked;

  /// No description provided for @walletStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get walletStatusExpired;

  /// No description provided for @walletAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ticket'**
  String get walletAddTitle;

  /// No description provided for @walletAddIntro.
  ///
  /// In fr, this message translates to:
  /// **'Seul le QR prouve que le ticket est à vous : une fois ajouté, il ne peut plus entrer dans un autre compte.'**
  String get walletAddIntro;

  /// No description provided for @walletAddScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le QR'**
  String get walletAddScan;

  /// No description provided for @walletAddScanHint.
  ///
  /// In fr, this message translates to:
  /// **'Avec l\'appareil photo, si le ticket est sur un autre écran ou sur papier'**
  String get walletAddScanHint;

  /// No description provided for @walletAddImage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image'**
  String get walletAddImage;

  /// No description provided for @walletAddImageHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'image du ticket reçue par WhatsApp ou enregistrée dans la galerie'**
  String get walletAddImageHint;

  /// No description provided for @walletAddPaste.
  ///
  /// In fr, this message translates to:
  /// **'Coller le code'**
  String get walletAddPaste;

  /// No description provided for @walletAddPasteHint.
  ///
  /// In fr, this message translates to:
  /// **'Code commençant par TS1.'**
  String get walletAddPasteHint;

  /// No description provided for @walletAddPasteSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get walletAddPasteSubmit;

  /// No description provided for @walletAddScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le QR du ticket'**
  String get walletAddScanTitle;

  /// No description provided for @walletAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ticket ajouté à vos tickets.'**
  String get walletAdded;

  /// No description provided for @walletNoQrInImage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun QR lisible dans cette image.'**
  String get walletNoQrInImage;

  /// No description provided for @walletErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code n\'est pas un ticket Tikéo.'**
  String get walletErrorInvalid;

  /// No description provided for @walletErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Ticket inconnu.'**
  String get walletErrorUnknown;

  /// No description provided for @walletErrorRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket a été annulé par l\'organisateur.'**
  String get walletErrorRevoked;

  /// No description provided for @walletErrorClaimed.
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket est déjà dans le compte d\'une autre personne.'**
  String get walletErrorClaimed;

  /// No description provided for @walletErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get walletErrorNetwork;

  /// No description provided for @walletErrorOther.
  ///
  /// In fr, this message translates to:
  /// **'Ajout impossible. Réessayez.'**
  String get walletErrorOther;

  /// No description provided for @walletShowAtEntry.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce QR à l\'entrée. Montez la luminosité de l\'écran.'**
  String get walletShowAtEntry;

  /// No description provided for @walletUsedAt.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé le {date}'**
  String walletUsedAt(String date);

  /// No description provided for @walletRevokedNote.
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket a été annulé : il sera refusé à l\'entrée.'**
  String get walletRevokedNote;

  /// No description provided for @walletOrganizer.
  ///
  /// In fr, this message translates to:
  /// **'Organisé par {name}'**
  String walletOrganizer(String name);

  /// No description provided for @walletRelease.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de mes tickets'**
  String get walletRelease;

  /// No description provided for @walletReleaseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce ticket ?'**
  String get walletReleaseTitle;

  /// No description provided for @walletReleaseBody.
  ///
  /// In fr, this message translates to:
  /// **'Il ne sera plus affiché dans votre compte. Vous pourrez l\'ajouter de nouveau avec son QR, tant qu\'un autre compte ne l\'a pas fait.'**
  String get walletReleaseBody;

  /// No description provided for @walletReleased.
  ///
  /// In fr, this message translates to:
  /// **'Ticket retiré.'**
  String get walletReleased;

  /// No description provided for @walletNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket n\'est plus dans vos tickets.'**
  String get walletNotFound;

  /// No description provided for @auditTicketClaimed.
  ///
  /// In fr, this message translates to:
  /// **'Ticket ajouté par son détenteur'**
  String get auditTicketClaimed;

  /// No description provided for @auditTicketReleased.
  ///
  /// In fr, this message translates to:
  /// **'Ticket retiré par son détenteur'**
  String get auditTicketReleased;

  /// No description provided for @pushOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get pushOpen;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPushSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir les notifications'**
  String get settingsPushSwitch;

  /// No description provided for @settingsPushActive.
  ///
  /// In fr, this message translates to:
  /// **'Réponses du support, annonces importantes, ouverture du contrôle'**
  String get settingsPushActive;

  /// No description provided for @settingsPushDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Coupées sur ce téléphone'**
  String get settingsPushDisabled;

  /// No description provided for @settingsPushDenied.
  ///
  /// In fr, this message translates to:
  /// **'Refusées dans les réglages du téléphone : autorisez Tikéo dans Réglages › Notifications.'**
  String get settingsPushDenied;

  /// No description provided for @settingsPushUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponibles dans cette version de l\'application'**
  String get settingsPushUnavailable;

  /// No description provided for @settingsPushTest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une notification de test'**
  String get settingsPushTest;

  /// No description provided for @settingsPushTestHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie la réception sur ce téléphone, application fermée.'**
  String get settingsPushTestHint;

  /// No description provided for @settingsPushTestSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoi dans 8 secondes : mettez Tikéo en arrière-plan (bouton Accueil) pour voir la notification.'**
  String get settingsPushTestSent;

  /// No description provided for @settingsPushTestNoDevice.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone n\'est pas encore enregistré. Fermez et rouvrez Tikéo, puis réessayez.'**
  String get settingsPushTestNoDevice;

  /// No description provided for @settingsPushTestRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais : réessayez dans une heure.'**
  String get settingsPushTestRateLimited;

  /// No description provided for @settingsPushTestNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Envoi impossible. Vérifiez votre connexion et réessayez.'**
  String get settingsPushTestNetwork;

  /// No description provided for @verdictHolder.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire : {name}'**
  String verdictHolder(String name);

  /// No description provided for @scannerSearch.
  ///
  /// In fr, this message translates to:
  /// **'QR perdu ? Rechercher'**
  String get scannerSearch;

  /// No description provided for @doorSearchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrouver un ticket'**
  String get doorSearchTitle;

  /// No description provided for @doorSearchIntro.
  ///
  /// In fr, this message translates to:
  /// **'Cherchez par nom, téléphone ou référence, puis validez l\'entrée. Un ticket ne passe qu\'une fois.'**
  String get doorSearchIntro;

  /// No description provided for @doorSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, téléphone ou référence'**
  String get doorSearchHint;

  /// No description provided for @doorSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket trouvé.'**
  String get doorSearchEmpty;

  /// No description provided for @doorSearchTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 3 caractères.'**
  String get doorSearchTooShort;

  /// No description provided for @doorSearchRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de recherches : réessayez dans quelques minutes.'**
  String get doorSearchRateLimited;

  /// No description provided for @doorSearchForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Recherche possible seulement quand le contrôle est ouvert, à votre porte.'**
  String get doorSearchForbidden;

  /// No description provided for @doorSearchNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get doorSearchNetwork;

  /// No description provided for @doorSearchValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'entrée'**
  String get doorSearchValidate;

  /// No description provided for @auditScanManual.
  ///
  /// In fr, this message translates to:
  /// **'Entrée validée sans QR (recherche)'**
  String get auditScanManual;

  /// No description provided for @journalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Journal de la structure'**
  String get journalTitle;

  /// No description provided for @journalEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui a émis, annulé, validé ou modifié quoi'**
  String get journalEntrySubtitle;

  /// No description provided for @journalAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get journalAll;

  /// No description provided for @journalEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get journalEvents;

  /// No description provided for @journalTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets'**
  String get journalTickets;

  /// No description provided for @journalControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle'**
  String get journalControl;

  /// No description provided for @journalTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get journalTeam;

  /// No description provided for @journalStructure.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get journalStructure;

  /// No description provided for @journalByTikeo.
  ///
  /// In fr, this message translates to:
  /// **'par l\'équipe Tikéo'**
  String get journalByTikeo;

  /// No description provided for @auditEventDuplicated.
  ///
  /// In fr, this message translates to:
  /// **'Événement dupliqué'**
  String get auditEventDuplicated;

  /// No description provided for @auditFieldResult.
  ///
  /// In fr, this message translates to:
  /// **'résultat'**
  String get auditFieldResult;

  /// No description provided for @auditFieldReason.
  ///
  /// In fr, this message translates to:
  /// **'motif'**
  String get auditFieldReason;

  /// No description provided for @auditFieldBulk.
  ///
  /// In fr, this message translates to:
  /// **'sélection'**
  String get auditFieldBulk;

  /// No description provided for @auditFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'titre'**
  String get auditFieldTitle;

  /// No description provided for @auditValueAccepted.
  ///
  /// In fr, this message translates to:
  /// **'entrée autorisée'**
  String get auditValueAccepted;

  /// No description provided for @auditValueAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'déjà utilisé'**
  String get auditValueAlreadyUsed;

  /// No description provided for @auditValueRefused.
  ///
  /// In fr, this message translates to:
  /// **'refusé'**
  String get auditValueRefused;

  /// No description provided for @ticketScanHere.
  ///
  /// In fr, this message translates to:
  /// **'Scannez ici'**
  String get ticketScanHere;

  /// No description provided for @ticketNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° {number}'**
  String ticketNumber(String number);

  /// No description provided for @templatesEntry.
  ///
  /// In fr, this message translates to:
  /// **'Modèles des tickets'**
  String get templatesEntry;

  /// No description provided for @templatesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèles des tickets'**
  String get templatesTitle;

  /// No description provided for @templatesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Chaque catégorie a son modèle : l\'image envoyée et le PDF le reprennent. Le QR et le contrôle à l\'entrée ne changent pas.'**
  String get templatesIntro;

  /// No description provided for @templatesProposed.
  ///
  /// In fr, this message translates to:
  /// **'Proposé : {theme}'**
  String templatesProposed(String theme);

  /// No description provided for @templatesChosen.
  ///
  /// In fr, this message translates to:
  /// **'Modèle : {theme}'**
  String templatesChosen(String theme);

  /// No description provided for @templatesCustom.
  ///
  /// In fr, this message translates to:
  /// **'Design importé'**
  String get templatesCustom;

  /// No description provided for @templatesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Modèles indisponibles pour le moment.'**
  String get templatesLoadError;

  /// No description provided for @templateEditorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèle — {category}'**
  String templateEditorTitle(String category);

  /// No description provided for @templateBuiltinSection.
  ///
  /// In fr, this message translates to:
  /// **'Modèles Tikéo'**
  String get templateBuiltinSection;

  /// No description provided for @templateSingleFont.
  ///
  /// In fr, this message translates to:
  /// **'Titre en une seule police'**
  String get templateSingleFont;

  /// No description provided for @templateSingleFontHint.
  ///
  /// In fr, this message translates to:
  /// **'Sans écriture manuscrite ni condensée'**
  String get templateSingleFontHint;

  /// No description provided for @templateCustomSection.
  ///
  /// In fr, this message translates to:
  /// **'Votre propre design'**
  String get templateCustomSection;

  /// No description provided for @templateImportHint.
  ///
  /// In fr, this message translates to:
  /// **'Image JPG ou PNG à plat, en bande horizontale (environ 2,4 × 1), avec un espace libre pour le QR.'**
  String get templateImportHint;

  /// No description provided for @templateImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer mon design'**
  String get templateImport;

  /// No description provided for @templateAdjust.
  ///
  /// In fr, this message translates to:
  /// **'Placer le QR'**
  String get templateAdjust;

  /// No description provided for @templateSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get templateSave;

  /// No description provided for @templateSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modèle enregistré'**
  String get templateSaved;

  /// No description provided for @templateReset.
  ///
  /// In fr, this message translates to:
  /// **'Revenir au modèle proposé'**
  String get templateReset;

  /// No description provided for @templateResetDone.
  ///
  /// In fr, this message translates to:
  /// **'Modèle proposé rétabli'**
  String get templateResetDone;

  /// No description provided for @templateErrorQrTooSmall.
  ///
  /// In fr, this message translates to:
  /// **'Le QR doit occuper au moins 35 % de la hauteur du ticket.'**
  String get templateErrorQrTooSmall;

  /// No description provided for @templateErrorImage.
  ///
  /// In fr, this message translates to:
  /// **'Image introuvable : importez-la de nouveau.'**
  String get templateErrorImage;

  /// No description provided for @templateErrorTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Image trop lourde (2 Mo au plus).'**
  String get templateErrorTooLarge;

  /// No description provided for @templateErrorFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format attendu : une image en bande horizontale (environ 2,4 × 1).'**
  String get templateErrorFormat;

  /// No description provided for @templateErrorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Événement clôturé : le modèle ne peut plus changer.'**
  String get templateErrorLocked;

  /// No description provided for @templateErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas les droits pour modifier ce modèle.'**
  String get templateErrorNotFound;

  /// No description provided for @templateErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Placement refusé : le QR doit rester entièrement sur le ticket.'**
  String get templateErrorInvalid;

  /// No description provided for @templateErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Vérifiez votre connexion et réessayez.'**
  String get templateErrorNetwork;

  /// No description provided for @placementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Placer le QR'**
  String get placementTitle;

  /// No description provided for @placementHelp.
  ///
  /// In fr, this message translates to:
  /// **'Faites glisser le QR et le bloc de la référence. Pincez le QR ou utilisez le curseur pour changer sa taille.'**
  String get placementHelp;

  /// No description provided for @placementSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille du QR'**
  String get placementSize;

  /// No description provided for @placementMinReached.
  ///
  /// In fr, this message translates to:
  /// **'Taille minimale atteinte : le QR doit occuper au moins 35 % de la hauteur du ticket pour rester lisible à l\'entrée.'**
  String get placementMinReached;

  /// No description provided for @placementAuto.
  ///
  /// In fr, this message translates to:
  /// **'Placement automatique'**
  String get placementAuto;

  /// No description provided for @placementDone.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get placementDone;

  /// No description provided for @placementFoundSquare.
  ///
  /// In fr, this message translates to:
  /// **'QR posé dans la zone blanche de votre design.'**
  String get placementFoundSquare;

  /// No description provided for @placementFallback.
  ///
  /// In fr, this message translates to:
  /// **'Aucune zone blanche assez grande : le QR est posé sur son propre carré blanc, à droite.'**
  String get placementFallback;

  /// No description provided for @ticketTheme1.
  ///
  /// In fr, this message translates to:
  /// **'Concert'**
  String get ticketTheme1;

  /// No description provided for @ticketTheme2.
  ///
  /// In fr, this message translates to:
  /// **'Festival culturel'**
  String get ticketTheme2;

  /// No description provided for @ticketTheme3.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma'**
  String get ticketTheme3;

  /// No description provided for @ticketTheme4.
  ///
  /// In fr, this message translates to:
  /// **'Match'**
  String get ticketTheme4;

  /// No description provided for @ticketTheme5.
  ///
  /// In fr, this message translates to:
  /// **'Théâtre'**
  String get ticketTheme5;

  /// No description provided for @ticketTheme6.
  ///
  /// In fr, this message translates to:
  /// **'Conférence'**
  String get ticketTheme6;

  /// No description provided for @ticketTheme7.
  ///
  /// In fr, this message translates to:
  /// **'Exposition'**
  String get ticketTheme7;

  /// No description provided for @ticketTheme8.
  ///
  /// In fr, this message translates to:
  /// **'Festival gastronomique'**
  String get ticketTheme8;

  /// No description provided for @ticketTheme9.
  ///
  /// In fr, this message translates to:
  /// **'Atelier jeunes'**
  String get ticketTheme9;

  /// No description provided for @ticketTheme10.
  ///
  /// In fr, this message translates to:
  /// **'Challenge sportif'**
  String get ticketTheme10;

  /// No description provided for @ticketTheme11.
  ///
  /// In fr, this message translates to:
  /// **'Soirée club'**
  String get ticketTheme11;

  /// No description provided for @ticketTheme12.
  ///
  /// In fr, this message translates to:
  /// **'Workshop'**
  String get ticketTheme12;

  /// No description provided for @auditTicketTemplateUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Modèle de ticket modifié'**
  String get auditTicketTemplateUpdated;

  /// No description provided for @auditValueTemplateBuiltin.
  ///
  /// In fr, this message translates to:
  /// **'modèle Tikéo'**
  String get auditValueTemplateBuiltin;

  /// No description provided for @auditValueTemplateCustom.
  ///
  /// In fr, this message translates to:
  /// **'design importé'**
  String get auditValueTemplateCustom;

  /// No description provided for @auditValueTemplateDefault.
  ///
  /// In fr, this message translates to:
  /// **'modèle proposé'**
  String get auditValueTemplateDefault;

  /// No description provided for @auditValueTagline.
  ///
  /// In fr, this message translates to:
  /// **'accroche'**
  String get auditValueTagline;

  /// No description provided for @auditFieldTemplateKind.
  ///
  /// In fr, this message translates to:
  /// **'modèle'**
  String get auditFieldTemplateKind;

  /// No description provided for @ticketsBulkSheet.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer des tickets'**
  String get ticketsBulkSheet;

  /// No description provided for @templateCrop.
  ///
  /// In fr, this message translates to:
  /// **'Cadrer la photo'**
  String get templateCrop;

  /// No description provided for @templateCopy.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ce modèle pour d\'autres catégories'**
  String get templateCopy;

  /// No description provided for @templateCopyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer aussi ce modèle à :'**
  String get templateCopyTitle;

  /// No description provided for @templateCopyConfirm.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Choisissez des catégories} =1{Appliquer à 1 autre catégorie} other{Appliquer à {count} autres catégories}}'**
  String templateCopyConfirm(int count);

  /// No description provided for @templateCopied.
  ///
  /// In fr, this message translates to:
  /// **'Modèle enregistré pour {count} catégories'**
  String templateCopied(int count);

  /// No description provided for @placementSampleHolder.
  ///
  /// In fr, this message translates to:
  /// **'Awa Ouédraogo'**
  String get placementSampleHolder;

  /// No description provided for @placementHolderFree.
  ///
  /// In fr, this message translates to:
  /// **'Placer le nom du titulaire à part'**
  String get placementHolderFree;

  /// No description provided for @placementHolderFreeHint.
  ///
  /// In fr, this message translates to:
  /// **'Sinon, il est écrit sous la référence'**
  String get placementHolderFreeHint;

  /// No description provided for @cropTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cadrer la photo'**
  String get cropTitle;

  /// No description provided for @cropHelp.
  ///
  /// In fr, this message translates to:
  /// **'Faites glisser la photo pour choisir la partie visible, puis réglez le zoom.'**
  String get cropHelp;

  /// No description provided for @cropZoom.
  ///
  /// In fr, this message translates to:
  /// **'Zoom'**
  String get cropZoom;

  /// No description provided for @cropReset.
  ///
  /// In fr, this message translates to:
  /// **'Cadrage par défaut'**
  String get cropReset;

  /// No description provided for @walletLargeQr.
  ///
  /// In fr, this message translates to:
  /// **'À présenter à l\'entrée'**
  String get walletLargeQr;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get settingsLanguageFr;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les tickets, PDF et rapports que vous envoyez suivent aussi cette langue.'**
  String get settingsLanguageHelp;

  /// No description provided for @auditFieldLanguage.
  ///
  /// In fr, this message translates to:
  /// **'langue'**
  String get auditFieldLanguage;

  /// No description provided for @categoryEntriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Entrées par ticket'**
  String get categoryEntriesLabel;

  /// No description provided for @categoryEntriesSingle.
  ///
  /// In fr, this message translates to:
  /// **'Une seule'**
  String get categoryEntriesSingle;

  /// No description provided for @categoryEntriesPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Une par jour'**
  String get categoryEntriesPerDay;

  /// No description provided for @categoryEntriesLimited.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs'**
  String get categoryEntriesLimited;

  /// No description provided for @categoryEntriesHelpSingle.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket est utilisé dès la première entrée.'**
  String get categoryEntriesHelpSingle;

  /// No description provided for @categoryEntriesHelpPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Pass journalier : une entrée par jour, pendant tout l\'événement.'**
  String get categoryEntriesHelpPerDay;

  /// No description provided for @categoryEntriesHelpLimited.
  ///
  /// In fr, this message translates to:
  /// **'Pass : le ticket permet ce nombre d\'entrées au total, sur un ou plusieurs jours.'**
  String get categoryEntriesHelpLimited;

  /// No description provided for @categoryEntriesLocked.
  ///
  /// In fr, this message translates to:
  /// **'Règle figée : des tickets de cette catégorie sont déjà entrés.'**
  String get categoryEntriesLocked;

  /// No description provided for @categoryMaxEntriesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'entrées'**
  String get categoryMaxEntriesLabel;

  /// No description provided for @categoryMaxEntriesError.
  ///
  /// In fr, this message translates to:
  /// **'De {min} à {max} entrées.'**
  String categoryMaxEntriesError(int min, int max);

  /// No description provided for @categoryPassDaily.
  ///
  /// In fr, this message translates to:
  /// **'Pass journalier'**
  String get categoryPassDaily;

  /// No description provided for @categoryPassEntries.
  ///
  /// In fr, this message translates to:
  /// **'Pass {count} entrées'**
  String categoryPassEntries(int count);

  /// No description provided for @setupErrorEntriesInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Règle d\'entrée invalide : un pass compte de 2 à 100 entrées.'**
  String get setupErrorEntriesInvalid;

  /// No description provided for @setupErrorEntriesLocked.
  ///
  /// In fr, this message translates to:
  /// **'Des tickets de cette catégorie sont déjà entrés : la règle d\'entrée ne peut plus changer.'**
  String get setupErrorEntriesLocked;

  /// No description provided for @verdictPassEntry.
  ///
  /// In fr, this message translates to:
  /// **'Entrée {used} sur {max}'**
  String verdictPassEntry(int used, int max);

  /// No description provided for @verdictPassLastEntry.
  ///
  /// In fr, this message translates to:
  /// **'Dernière entrée du pass ({used} sur {max})'**
  String verdictPassLastEntry(int used, int max);

  /// No description provided for @verdictPassExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Pass épuisé : {max} entrées utilisées'**
  String verdictPassExhausted(int max);

  /// No description provided for @verdictPassDay.
  ///
  /// In fr, this message translates to:
  /// **'Pass journalier · jour d\'entrée n° {count}'**
  String verdictPassDay(int count);

  /// No description provided for @verdictPassDayUsed.
  ///
  /// In fr, this message translates to:
  /// **'Pass journalier · déjà entré aujourd\'hui ({count} jours au total)'**
  String verdictPassDayUsed(int count);

  /// No description provided for @verdictEnteredToday.
  ///
  /// In fr, this message translates to:
  /// **'Entré aujourd\'hui à {time}'**
  String verdictEnteredToday(String time);

  /// No description provided for @verdictEnteredTodayAt.
  ///
  /// In fr, this message translates to:
  /// **'Entré aujourd\'hui à {time} · {checkpoint}'**
  String verdictEnteredTodayAt(String time, String checkpoint);

  /// No description provided for @verdictLastEntry.
  ///
  /// In fr, this message translates to:
  /// **'Dernière entrée à {time}'**
  String verdictLastEntry(String time);

  /// No description provided for @verdictLastEntryAt.
  ///
  /// In fr, this message translates to:
  /// **'Dernière entrée à {time} · {checkpoint}'**
  String verdictLastEntryAt(String time, String checkpoint);

  /// No description provided for @dashboardEntriesNote.
  ///
  /// In fr, this message translates to:
  /// **'{entries} entrées au total (pass à plusieurs entrées)'**
  String dashboardEntriesNote(int entries);

  /// No description provided for @auditCategoryEntriesChanged.
  ///
  /// In fr, this message translates to:
  /// **'Règle d\'entrée modifiée'**
  String get auditCategoryEntriesChanged;

  /// No description provided for @auditValueEntrySingle.
  ///
  /// In fr, this message translates to:
  /// **'une seule entrée'**
  String get auditValueEntrySingle;

  /// No description provided for @auditValueEntryPerDay.
  ///
  /// In fr, this message translates to:
  /// **'une par jour'**
  String get auditValueEntryPerDay;

  /// No description provided for @auditValueEntryLimited.
  ///
  /// In fr, this message translates to:
  /// **'plusieurs entrées'**
  String get auditValueEntryLimited;

  /// No description provided for @auditFieldEntryPolicy.
  ///
  /// In fr, this message translates to:
  /// **'entrées'**
  String get auditFieldEntryPolicy;

  /// No description provided for @auditFieldMaxEntries.
  ///
  /// In fr, this message translates to:
  /// **'nombre d\'entrées'**
  String get auditFieldMaxEntries;

  /// No description provided for @settingsReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels avant l\'événement'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersHint.
  ///
  /// In fr, this message translates to:
  /// **'La veille et 2 h avant, pour les tickets ajoutés à « Mes tickets ».'**
  String get settingsRemindersHint;

  /// No description provided for @settingsRemindersError.
  ///
  /// In fr, this message translates to:
  /// **'Réglage non enregistré. Vérifiez la connexion et réessayez.'**
  String get settingsRemindersError;

  /// No description provided for @summaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get summaryTitle;

  /// No description provided for @summaryHeadline.
  ///
  /// In fr, this message translates to:
  /// **'En bref'**
  String get summaryHeadline;

  /// No description provided for @summaryPeopleLine.
  ///
  /// In fr, this message translates to:
  /// **'{admitted} personnes entrées sur {issued} tickets'**
  String summaryPeopleLine(int admitted, int issued);

  /// No description provided for @summaryAverageOthers.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne de vos {count} derniers événements : {rate}'**
  String summaryAverageOthers(int count, String rate);

  /// No description provided for @summaryPassLine.
  ///
  /// In fr, this message translates to:
  /// **'{entries} entrées avec {passes} pass'**
  String summaryPassLine(int entries, int passes);

  /// No description provided for @summarySpan.
  ///
  /// In fr, this message translates to:
  /// **'Première entrée à {first}, dernière à {last}'**
  String summarySpan(String first, String last);

  /// No description provided for @summaryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée enregistrée pour cet événement.'**
  String get summaryEmpty;

  /// No description provided for @summaryHoursTitle.
  ///
  /// In fr, this message translates to:
  /// **'Heures d\'affluence'**
  String get summaryHoursTitle;

  /// No description provided for @summaryPeak.
  ///
  /// In fr, this message translates to:
  /// **'Heure de pointe : {hour} · {entries} entrées'**
  String summaryPeak(String hour, int entries);

  /// No description provided for @summaryHourRange.
  ///
  /// In fr, this message translates to:
  /// **'{start} h – {end} h'**
  String summaryHourRange(int start, int end);

  /// No description provided for @summaryDaysTitle.
  ///
  /// In fr, this message translates to:
  /// **'Par jour'**
  String get summaryDaysTitle;

  /// No description provided for @summaryDayLine.
  ///
  /// In fr, this message translates to:
  /// **'{people} personnes · {entries} entrées'**
  String summaryDayLine(int people, int entries);

  /// No description provided for @summaryCompareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison avec vos événements'**
  String get summaryCompareTitle;

  /// No description provided for @summaryCompareHint.
  ///
  /// In fr, this message translates to:
  /// **'Taux de présence : personnes entrées sur tickets émis.'**
  String get summaryCompareHint;

  /// No description provided for @summaryThisEvent.
  ///
  /// In fr, this message translates to:
  /// **'{title} (cet événement)'**
  String summaryThisEvent(String title);

  /// No description provided for @summaryErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le bilan.'**
  String get summaryErrorLoad;

  /// No description provided for @summaryColDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get summaryColDay;

  /// No description provided for @summaryColPeople.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get summaryColPeople;

  /// No description provided for @summaryColEntries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get summaryColEntries;

  /// No description provided for @summaryColEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get summaryColEvent;

  /// No description provided for @summaryColDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get summaryColDate;

  /// No description provided for @componentGalleryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Composants Tikéo'**
  String get componentGalleryTitle;

  /// No description provided for @auditBillingInvoiceIssued.
  ///
  /// In fr, this message translates to:
  /// **'Facture à l\'usage émise'**
  String get auditBillingInvoiceIssued;

  /// No description provided for @auditBillingOrganizationDefaultSet.
  ///
  /// In fr, this message translates to:
  /// **'Facturation de la structure choisie'**
  String get auditBillingOrganizationDefaultSet;

  /// No description provided for @auditBillingEventModeSet.
  ///
  /// In fr, this message translates to:
  /// **'Facturation de l\'événement choisie'**
  String get auditBillingEventModeSet;

  /// No description provided for @auditBillingAddonAdded.
  ///
  /// In fr, this message translates to:
  /// **'Supplément ajouté à l\'événement'**
  String get auditBillingAddonAdded;

  /// No description provided for @auditBillingRequestCreated.
  ///
  /// In fr, this message translates to:
  /// **'Demande d\'activation envoyée'**
  String get auditBillingRequestCreated;

  /// No description provided for @auditAdminBillingPackSaved.
  ///
  /// In fr, this message translates to:
  /// **'Pack enregistré'**
  String get auditAdminBillingPackSaved;

  /// No description provided for @auditAdminBillingPackStatusSet.
  ///
  /// In fr, this message translates to:
  /// **'État du pack modifié'**
  String get auditAdminBillingPackStatusSet;

  /// No description provided for @auditAdminBillingSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de paiement modifiés'**
  String get auditAdminBillingSettingsSaved;

  /// No description provided for @auditAdminBillingRequestActivated.
  ///
  /// In fr, this message translates to:
  /// **'Demande validée, paiement reçu'**
  String get auditAdminBillingRequestActivated;

  /// No description provided for @auditAdminBillingRequestRefused.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée'**
  String get auditAdminBillingRequestRefused;

  /// No description provided for @auditAdminBillingSubscriptionGranted.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement offert'**
  String get auditAdminBillingSubscriptionGranted;

  /// No description provided for @auditAdminBillingSubscriptionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement annulé'**
  String get auditAdminBillingSubscriptionCancelled;

  /// No description provided for @auditAdminBillingInvoicePaid.
  ///
  /// In fr, this message translates to:
  /// **'Facture réglée'**
  String get auditAdminBillingInvoicePaid;

  /// No description provided for @auditFieldEntries.
  ///
  /// In fr, this message translates to:
  /// **'entrées'**
  String get auditFieldEntries;

  /// No description provided for @auditFieldAmount.
  ///
  /// In fr, this message translates to:
  /// **'montant (FCFA)'**
  String get auditFieldAmount;

  /// No description provided for @auditFieldBillingSystem.
  ///
  /// In fr, this message translates to:
  /// **'facturation'**
  String get auditFieldBillingSystem;

  /// No description provided for @auditFieldBillingMode.
  ///
  /// In fr, this message translates to:
  /// **'facturation'**
  String get auditFieldBillingMode;

  /// No description provided for @auditFieldOption.
  ///
  /// In fr, this message translates to:
  /// **'option'**
  String get auditFieldOption;

  /// No description provided for @auditFieldUnits.
  ///
  /// In fr, this message translates to:
  /// **'tranches'**
  String get auditFieldUnits;

  /// No description provided for @auditFieldDuration.
  ///
  /// In fr, this message translates to:
  /// **'durée'**
  String get auditFieldDuration;

  /// No description provided for @auditFieldCreated.
  ///
  /// In fr, this message translates to:
  /// **'création'**
  String get auditFieldCreated;

  /// No description provided for @auditFieldAddons.
  ///
  /// In fr, this message translates to:
  /// **'suppléments'**
  String get auditFieldAddons;

  /// No description provided for @auditValueBillingFlat.
  ///
  /// In fr, this message translates to:
  /// **'forfait'**
  String get auditValueBillingFlat;

  /// No description provided for @auditValueBillingUsage.
  ///
  /// In fr, this message translates to:
  /// **'à l\'usage'**
  String get auditValueBillingUsage;

  /// No description provided for @auditValueBillingInherit.
  ///
  /// In fr, this message translates to:
  /// **'comme la structure'**
  String get auditValueBillingInherit;

  /// No description provided for @auditValueDurationMonth.
  ///
  /// In fr, this message translates to:
  /// **'mensuel'**
  String get auditValueDurationMonth;

  /// No description provided for @auditValueDurationQuarter.
  ///
  /// In fr, this message translates to:
  /// **'trimestriel'**
  String get auditValueDurationQuarter;

  /// No description provided for @auditValueDurationSemester.
  ///
  /// In fr, this message translates to:
  /// **'semestriel'**
  String get auditValueDurationSemester;

  /// No description provided for @auditValueDurationYear.
  ///
  /// In fr, this message translates to:
  /// **'annuel'**
  String get auditValueDurationYear;

  /// No description provided for @auditValueDurationEvent.
  ///
  /// In fr, this message translates to:
  /// **'un seul événement'**
  String get auditValueDurationEvent;

  /// No description provided for @auditValueDurationUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'sans fin'**
  String get auditValueDurationUnlimited;

  /// No description provided for @auditValueChannelOrangeMoney.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get auditValueChannelOrangeMoney;

  /// No description provided for @auditValueChannelMoovMoney.
  ///
  /// In fr, this message translates to:
  /// **'Moov Money'**
  String get auditValueChannelMoovMoney;

  /// No description provided for @auditValueChannelOther.
  ///
  /// In fr, this message translates to:
  /// **'autre'**
  String get auditValueChannelOther;

  /// No description provided for @billingOptionStructures.
  ///
  /// In fr, this message translates to:
  /// **'Structures du compte'**
  String get billingOptionStructures;

  /// No description provided for @billingOptionActiveEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements actifs en même temps'**
  String get billingOptionActiveEvents;

  /// No description provided for @billingOptionTicketsPerEvent.
  ///
  /// In fr, this message translates to:
  /// **'Tickets par événement'**
  String get billingOptionTicketsPerEvent;

  /// No description provided for @billingOptionTicketsPerPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Tickets par période'**
  String get billingOptionTicketsPerPeriod;

  /// No description provided for @billingOptionMembersPerStructure.
  ///
  /// In fr, this message translates to:
  /// **'Membres de l\'équipe par structure'**
  String get billingOptionMembersPerStructure;

  /// No description provided for @billingOptionControllersPerEvent.
  ///
  /// In fr, this message translates to:
  /// **'Contrôleurs par événement'**
  String get billingOptionControllersPerEvent;

  /// No description provided for @billingOptionAssistedSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoi assisté'**
  String get billingOptionAssistedSend;

  /// No description provided for @billingOptionBulkSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en série'**
  String get billingOptionBulkSend;

  /// No description provided for @billingOptionImport.
  ///
  /// In fr, this message translates to:
  /// **'Import Excel / CSV'**
  String get billingOptionImport;

  /// No description provided for @billingOptionExport.
  ///
  /// In fr, this message translates to:
  /// **'Export (CSV, rapports, PDF)'**
  String get billingOptionExport;

  /// No description provided for @billingOptionPrintSheet.
  ///
  /// In fr, this message translates to:
  /// **'Planche d\'impression A4'**
  String get billingOptionPrintSheet;

  /// No description provided for @billingOptionCustomDesign.
  ///
  /// In fr, this message translates to:
  /// **'Design de ticket importé'**
  String get billingOptionCustomDesign;

  /// No description provided for @billingOptionNamedTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets nominatifs'**
  String get billingOptionNamedTickets;

  /// No description provided for @billingOptionLiveDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord en direct'**
  String get billingOptionLiveDashboard;

  /// No description provided for @billingOptionPublicCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue public'**
  String get billingOptionPublicCatalog;

  /// No description provided for @billingOptionPrioritySupport.
  ///
  /// In fr, this message translates to:
  /// **'Support prioritaire'**
  String get billingOptionPrioritySupport;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voici l\'essentiel de vos événements.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeTileEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get homeTileEvents;

  /// No description provided for @homeTileLive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get homeTileLive;

  /// No description provided for @homeTileUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get homeTileUpcoming;

  /// No description provided for @homeTileDrafts.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons'**
  String get homeTileDrafts;

  /// No description provided for @homeOrgHint.
  ///
  /// In fr, this message translates to:
  /// **'Structure active'**
  String get homeOrgHint;

  /// No description provided for @exploreHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les événements'**
  String get exploreHeroTitle;

  /// No description provided for @exploreHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Concerts, conférences, sport… près de chez vous.'**
  String get exploreHeroSubtitle;

  /// No description provided for @exploreSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get exploreSee;

  /// No description provided for @publicEventCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le promoteur'**
  String get publicEventCall;

  /// No description provided for @publicEventCallFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'appel n\'a pas pu s\'ouvrir sur ce téléphone.'**
  String get publicEventCallFailed;

  /// No description provided for @ticketsHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Émettez, envoyez et suivez vos tickets.'**
  String get ticketsHeroSubtitle;

  /// No description provided for @teamHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon équipe'**
  String get teamHeroTitle;

  /// No description provided for @teamStatMembers.
  ///
  /// In fr, this message translates to:
  /// **'membres actifs'**
  String get teamStatMembers;

  /// No description provided for @teamStatManagers.
  ///
  /// In fr, this message translates to:
  /// **'gestionnaires'**
  String get teamStatManagers;

  /// No description provided for @teamStatControllers.
  ///
  /// In fr, this message translates to:
  /// **'contrôleurs'**
  String get teamStatControllers;

  /// No description provided for @teamMembersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Membres de l\'équipe} other{Membres de l\'équipe ({count})}}'**
  String teamMembersCount(int count);

  /// No description provided for @profileHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profileHeroTitle;

  /// No description provided for @signInHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Heureux de vous revoir.'**
  String get signInHeroSubtitle;

  /// No description provided for @signInEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.bf'**
  String get signInEmailHint;

  /// No description provided for @signUpHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques secondes pour commencer.'**
  String get signUpHeroSubtitle;

  /// No description provided for @signUpPasswordRules.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins, avec des lettres et des chiffres'**
  String get signUpPasswordRules;

  /// No description provided for @forgotHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevez un lien pour en choisir un nouveau.'**
  String get forgotHeroSubtitle;

  /// No description provided for @forgotSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lien envoyé'**
  String get forgotSentTitle;

  /// No description provided for @forgotNothingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien reçu ?'**
  String get forgotNothingTitle;

  /// No description provided for @forgotNothingBody.
  ///
  /// In fr, this message translates to:
  /// **'Regardez dans les courriers indésirables, puis renvoyez le lien si besoin.'**
  String get forgotNothingBody;

  /// No description provided for @forgotResendLink.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le lien'**
  String get forgotResendLink;

  /// No description provided for @authOpenMailbox.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir ma messagerie'**
  String get authOpenMailbox;

  /// No description provided for @authOpenMailboxFailed.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez votre messagerie pour trouver l\'e-mail de Tikéo.'**
  String get authOpenMailboxFailed;

  /// No description provided for @authResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'e-mail'**
  String get authResend;

  /// No description provided for @authResendIn.
  ///
  /// In fr, this message translates to:
  /// **'{action} dans {seconds} s'**
  String authResendIn(String action, int seconds);

  /// No description provided for @authResent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail renvoyé.'**
  String get authResent;

  /// No description provided for @confirmEmailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre adresse'**
  String get confirmEmailTitle;

  /// No description provided for @confirmEmailBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons envoyé un lien de confirmation à :'**
  String get confirmEmailBody;

  /// No description provided for @confirmEmailStep1.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'e-mail de Tikéo.'**
  String get confirmEmailStep1;

  /// No description provided for @confirmEmailStep2.
  ///
  /// In fr, this message translates to:
  /// **'Touchez le lien de confirmation.'**
  String get confirmEmailStep2;

  /// No description provided for @confirmEmailStep3.
  ///
  /// In fr, this message translates to:
  /// **'Revenez ici et connectez-vous.'**
  String get confirmEmailStep3;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthLabel.
  ///
  /// In fr, this message translates to:
  /// **'Solidité du mot de passe : {level}'**
  String passwordStrengthLabel(String level);

  /// No description provided for @newPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez-le, puis vous serez connecté.'**
  String get newPasswordSubtitle;

  /// No description provided for @newPasswordSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le mot de passe'**
  String get newPasswordSubmit;

  /// No description provided for @newPasswordRuleLength.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins'**
  String get newPasswordRuleLength;

  /// No description provided for @newPasswordRuleLetters.
  ///
  /// In fr, this message translates to:
  /// **'Des lettres'**
  String get newPasswordRuleLetters;

  /// No description provided for @newPasswordRuleDigits.
  ///
  /// In fr, this message translates to:
  /// **'Des chiffres'**
  String get newPasswordRuleDigits;

  /// No description provided for @joinHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le code vous a été donné par un promoteur.'**
  String get joinHeroSubtitle;

  /// No description provided for @joinAcceptedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code accepté'**
  String get joinAcceptedTitle;

  /// No description provided for @joinAcceptedBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites maintenant partie de l\'équipe.'**
  String get joinAcceptedBody;

  /// No description provided for @joinStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get joinStart;

  /// No description provided for @welcomeSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace Tikéo'**
  String get welcomeSpaceTitle;

  /// No description provided for @controlHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l\'événement et la porte où vous scannez.'**
  String get controlHeroSubtitle;

  /// No description provided for @controlSummaryOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouverts'**
  String get controlSummaryOpen;

  /// No description provided for @controlSummaryUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get controlSummaryUpcoming;

  /// No description provided for @controlSummaryDoors.
  ///
  /// In fr, this message translates to:
  /// **'Portes'**
  String get controlSummaryDoors;

  /// No description provided for @controlMyPosts.
  ///
  /// In fr, this message translates to:
  /// **'Mes postes'**
  String get controlMyPosts;

  /// No description provided for @scannerAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Entrés'**
  String get scannerAdmitted;

  /// No description provided for @scannerRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusés'**
  String get scannerRefused;

  /// No description provided for @historyHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos vérifications des 7 derniers jours.'**
  String get historyHeroSubtitle;

  /// No description provided for @historyUncertain.
  ///
  /// In fr, this message translates to:
  /// **'Incertains'**
  String get historyUncertain;

  /// No description provided for @eventsHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez, publiez et suivez vos événements.'**
  String get eventsHeroSubtitle;

  /// No description provided for @walletHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos tickets, même sans réseau.'**
  String get walletHeroSubtitle;

  /// No description provided for @walletSummaryValid.
  ///
  /// In fr, this message translates to:
  /// **'Valables'**
  String get walletSummaryValid;

  /// No description provided for @walletSummaryUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'Prochains'**
  String get walletSummaryUpcoming;

  /// No description provided for @walletSummaryPast.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get walletSummaryPast;

  /// No description provided for @supportHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une question, un problème ? L\'équipe Tikéo vous répond ici.'**
  String get supportHeroSubtitle;

  /// No description provided for @settingsHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Apparence, langue, notifications et stockage.'**
  String get settingsHeroSubtitle;

  /// No description provided for @consoleHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Structures, comptes, support et catalogue de la plateforme.'**
  String get consoleHeroSubtitle;

  /// No description provided for @billingActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'abonnement'**
  String get billingActivate;

  /// No description provided for @billingActivateAddons.
  ///
  /// In fr, this message translates to:
  /// **'Activer les suppléments'**
  String get billingActivateAddons;

  /// No description provided for @billingActivatedToast.
  ///
  /// In fr, this message translates to:
  /// **'Paiement enregistré, abonnement activé.'**
  String get billingActivatedToast;

  /// No description provided for @billingAddonLine.
  ///
  /// In fr, this message translates to:
  /// **'+{units} {option}'**
  String billingAddonLine(int units, String option);

  /// No description provided for @billingAddonPrice.
  ///
  /// In fr, this message translates to:
  /// **'{price} par tranche de {step}'**
  String billingAddonPrice(String price, int step);

  /// No description provided for @billingAddonsBody.
  ///
  /// In fr, this message translates to:
  /// **'Les suppléments de l\'abonnement sont remplacés, sans paiement à saisir.'**
  String get billingAddonsBody;

  /// No description provided for @billingAddonsNone.
  ///
  /// In fr, this message translates to:
  /// **'Ce pack ne propose aucun supplément.'**
  String get billingAddonsNone;

  /// No description provided for @billingAddonsSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les suppléments'**
  String get billingAddonsSave;

  /// No description provided for @billingAddonsSavedToast.
  ///
  /// In fr, this message translates to:
  /// **'Suppléments enregistrés.'**
  String get billingAddonsSavedToast;

  /// No description provided for @billingAddonsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppléments'**
  String get billingAddonsTitle;

  /// No description provided for @billingCancel.
  ///
  /// In fr, this message translates to:
  /// **'Résilier'**
  String get billingCancel;

  /// No description provided for @billingCancelBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'abonnement de {name} prend fin maintenant ; le compte revient au pack gratuit.'**
  String billingCancelBody(String name);

  /// No description provided for @billingCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résilier l\'abonnement ?'**
  String get billingCancelTitle;

  /// No description provided for @billingCancelledToast.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement résilié.'**
  String get billingCancelledToast;

  /// No description provided for @billingChangePack.
  ///
  /// In fr, this message translates to:
  /// **'Changer de pack'**
  String get billingChangePack;

  /// No description provided for @billingChangePackBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'abonnement passe au pack {pack}, aux mêmes dates.'**
  String billingChangePackBody(String pack);

  /// No description provided for @billingChangePackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer de pack'**
  String get billingChangePackTitle;

  /// No description provided for @billingChannelMoov.
  ///
  /// In fr, this message translates to:
  /// **'Moov Money'**
  String get billingChannelMoov;

  /// No description provided for @billingChannelOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get billingChannelOrange;

  /// No description provided for @billingChannelOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get billingChannelOther;

  /// No description provided for @billingCollectCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier et valider'**
  String get billingCollectCheck;

  /// No description provided for @billingCollectDone.
  ///
  /// In fr, this message translates to:
  /// **'Traitées'**
  String get billingCollectDone;

  /// No description provided for @billingCollectEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien à afficher ici.'**
  String get billingCollectEmpty;

  /// No description provided for @billingCollectOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get billingCollectOverdue;

  /// No description provided for @billingCollectTitle.
  ///
  /// In fr, this message translates to:
  /// **'À encaisser'**
  String get billingCollectTitle;

  /// No description provided for @billingCollectToCheck.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get billingCollectToCheck;

  /// No description provided for @billingDates.
  ///
  /// In fr, this message translates to:
  /// **'Du {start} au {end}'**
  String billingDates(String start, String end);

  /// No description provided for @billingDatesEvent.
  ///
  /// In fr, this message translates to:
  /// **'Dès le {start}, jusqu\'à la fin de l\'événement couvert'**
  String billingDatesEvent(String start);

  /// No description provided for @billingDaysSuffix.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get billingDaysSuffix;

  /// No description provided for @billingDeclaredLine.
  ///
  /// In fr, this message translates to:
  /// **'Déclaré : {channel} · {transaction}'**
  String billingDeclaredLine(String channel, String transaction);

  /// No description provided for @billingDueLine.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String billingDueLine(String date);

  /// No description provided for @billingDurationEvent.
  ///
  /// In fr, this message translates to:
  /// **'Un événement'**
  String get billingDurationEvent;

  /// No description provided for @billingDurationMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get billingDurationMonth;

  /// No description provided for @billingDurationQuarter.
  ///
  /// In fr, this message translates to:
  /// **'Trimestriel'**
  String get billingDurationQuarter;

  /// No description provided for @billingDurationSemester.
  ///
  /// In fr, this message translates to:
  /// **'Semestriel'**
  String get billingDurationSemester;

  /// No description provided for @billingDurationUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Sans fin'**
  String get billingDurationUnlimited;

  /// No description provided for @billingDurationYear.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get billingDurationYear;

  /// No description provided for @billingErrorAddons.
  ///
  /// In fr, this message translates to:
  /// **'Supplément impossible avec ce pack (option, tranche ou plafond).'**
  String get billingErrorAddons;

  /// No description provided for @billingErrorChoice.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le forfait, ou un pack à l\'usage.'**
  String get billingErrorChoice;

  /// No description provided for @billingErrorEnd.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit suivre le début de l\'abonnement.'**
  String get billingErrorEnd;

  /// No description provided for @billingErrorInvoiceExists.
  ///
  /// In fr, this message translates to:
  /// **'Une facture a déjà été émise pour cet événement.'**
  String get billingErrorInvoiceExists;

  /// No description provided for @billingErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get billingErrorNetwork;

  /// No description provided for @billingErrorNote.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le motif (3 caractères au moins).'**
  String get billingErrorNote;

  /// No description provided for @billingErrorPack.
  ///
  /// In fr, this message translates to:
  /// **'Pack invalide : vérifiez le nom, les prix et les options.'**
  String get billingErrorPack;

  /// No description provided for @billingErrorPackProtected.
  ///
  /// In fr, this message translates to:
  /// **'Le pack Découverte reste publié.'**
  String get billingErrorPackProtected;

  /// No description provided for @billingErrorPayment.
  ///
  /// In fr, this message translates to:
  /// **'Canal, identifiant ou note invalide.'**
  String get billingErrorPayment;

  /// No description provided for @billingErrorProcessed.
  ///
  /// In fr, this message translates to:
  /// **'Déjà traité, ou introuvable.'**
  String get billingErrorProcessed;

  /// No description provided for @billingErrorSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages invalides : vérifiez les nombres.'**
  String get billingErrorSettings;

  /// No description provided for @billingEventApply.
  ///
  /// In fr, this message translates to:
  /// **'Changer la facturation'**
  String get billingEventApply;

  /// No description provided for @billingEventChange.
  ///
  /// In fr, this message translates to:
  /// **'Facturation d\'un événement'**
  String get billingEventChange;

  /// No description provided for @billingEventChangeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pour un événement déjà figé au premier ticket. Impossible une fois la facture émise.'**
  String get billingEventChangeHelp;

  /// No description provided for @billingEventChangedToast.
  ///
  /// In fr, this message translates to:
  /// **'Facturation de l\'événement modifiée.'**
  String get billingEventChangedToast;

  /// No description provided for @billingEventLocked.
  ///
  /// In fr, this message translates to:
  /// **'figé'**
  String get billingEventLocked;

  /// No description provided for @billingEventSearch.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'événement ou structure'**
  String get billingEventSearch;

  /// No description provided for @billingExpected.
  ///
  /// In fr, this message translates to:
  /// **'Montant attendu'**
  String get billingExpected;

  /// No description provided for @billingExtend.
  ///
  /// In fr, this message translates to:
  /// **'Prolonger'**
  String get billingExtend;

  /// No description provided for @billingExtendBody.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle fin : {date}.'**
  String billingExtendBody(String date);

  /// No description provided for @billingExtendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prolonger l\'abonnement'**
  String get billingExtendTitle;

  /// No description provided for @billingExtendedToast.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement prolongé.'**
  String get billingExtendedToast;

  /// No description provided for @billingFeatureAddon.
  ///
  /// In fr, this message translates to:
  /// **'Supplément'**
  String get billingFeatureAddon;

  /// No description provided for @billingFeatureIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Incluse'**
  String get billingFeatureIncluded;

  /// No description provided for @billingFeatureUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get billingFeatureUnavailable;

  /// No description provided for @billingFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get billingFilterAll;

  /// No description provided for @billingFormAddonAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Supplément possible'**
  String get billingFormAddonAllowed;

  /// No description provided for @billingFormAddonCap.
  ///
  /// In fr, this message translates to:
  /// **'Plafond'**
  String get billingFormAddonCap;

  /// No description provided for @billingFormAddonPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get billingFormAddonPrice;

  /// No description provided for @billingFormAddonStep.
  ///
  /// In fr, this message translates to:
  /// **'Tranche'**
  String get billingFormAddonStep;

  /// No description provided for @billingFormDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (affichée au promoteur)'**
  String get billingFormDescription;

  /// No description provided for @billingFormDurations.
  ///
  /// In fr, this message translates to:
  /// **'Durées proposées'**
  String get billingFormDurations;

  /// No description provided for @billingFormEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le pack'**
  String get billingFormEditTitle;

  /// No description provided for @billingFormEntryPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix par entrée réelle'**
  String get billingFormEntryPrice;

  /// No description provided for @billingFormFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Fonctions'**
  String get billingFormFeatures;

  /// No description provided for @billingFormFlatInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le prix mensuel et au moins une durée.'**
  String get billingFormFlatInvalid;

  /// No description provided for @billingFormFreeEntries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées offertes'**
  String get billingFormFreeEntries;

  /// No description provided for @billingFormIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Inclus'**
  String get billingFormIncluded;

  /// No description provided for @billingFormMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Prix mensuel'**
  String get billingFormMonthly;

  /// No description provided for @billingFormName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du pack'**
  String get billingFormName;

  /// No description provided for @billingFormNameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit faire de 2 à 60 caractères.'**
  String get billingFormNameInvalid;

  /// No description provided for @billingFormNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau pack'**
  String get billingFormNewTitle;

  /// No description provided for @billingFormNumericHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vide : illimité. Le supplément se paie par tranche, {period}.'**
  String billingFormNumericHelp(String period);

  /// No description provided for @billingFormNumericOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options chiffrées'**
  String get billingFormNumericOptions;

  /// No description provided for @billingFormPaymentDays.
  ///
  /// In fr, this message translates to:
  /// **'Délai de paiement (jours)'**
  String get billingFormPaymentDays;

  /// No description provided for @billingFormPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get billingFormPreview;

  /// No description provided for @billingFormPrices.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get billingFormPrices;

  /// No description provided for @billingFormPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier le pack'**
  String get billingFormPublish;

  /// No description provided for @billingFormSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get billingFormSave;

  /// No description provided for @billingFormSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get billingFormSaveDraft;

  /// No description provided for @billingFormSaved.
  ///
  /// In fr, this message translates to:
  /// **'Pack enregistré.'**
  String get billingFormSaved;

  /// No description provided for @billingFormSortOrder.
  ///
  /// In fr, this message translates to:
  /// **'Ordre d\'affichage'**
  String get billingFormSortOrder;

  /// No description provided for @billingFormSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système de facturation'**
  String get billingFormSystem;

  /// No description provided for @billingFormTierAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un palier'**
  String get billingFormTierAdd;

  /// No description provided for @billingFormTierPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix par entrée'**
  String get billingFormTierPrice;

  /// No description provided for @billingFormTierRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le palier'**
  String get billingFormTierRemove;

  /// No description provided for @billingFormTierUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à (entrées)'**
  String get billingFormTierUpTo;

  /// No description provided for @billingFormTiers.
  ///
  /// In fr, this message translates to:
  /// **'Paliers (facultatif)'**
  String get billingFormTiers;

  /// No description provided for @billingFormTiersHelp.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : 150 FCFA jusqu\'à 500 entrées, 100 FCFA au-delà (dernier palier vide).'**
  String get billingFormTiersHelp;

  /// No description provided for @billingFormTrial.
  ///
  /// In fr, this message translates to:
  /// **'Jours d\'essai'**
  String get billingFormTrial;

  /// No description provided for @billingFormUsageInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le prix par entrée ou des paliers.'**
  String get billingFormUsageInvalid;

  /// No description provided for @billingFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get billingFree;

  /// No description provided for @billingGrant.
  ///
  /// In fr, this message translates to:
  /// **'Activer un pack sans demande'**
  String get billingGrant;

  /// No description provided for @billingGrantDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get billingGrantDuration;

  /// No description provided for @billingGrantMissing.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le compte et le pack, et indiquez le motif.'**
  String get billingGrantMissing;

  /// No description provided for @billingGrantPack.
  ///
  /// In fr, this message translates to:
  /// **'Pack'**
  String get billingGrantPack;

  /// No description provided for @billingGrantSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou e-mail du compte'**
  String get billingGrantSearch;

  /// No description provided for @billingGrantSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Activer le pack'**
  String get billingGrantSubmit;

  /// No description provided for @billingGrantedToast.
  ///
  /// In fr, this message translates to:
  /// **'Pack activé pour ce compte.'**
  String get billingGrantedToast;

  /// No description provided for @billingHoursSuffix.
  ///
  /// In fr, this message translates to:
  /// **'heures'**
  String get billingHoursSuffix;

  /// No description provided for @billingInvoiceDetail.
  ///
  /// In fr, this message translates to:
  /// **'{entries} entrées, {free} offertes · entrées {entriesAmount} · suppléments {addonsAmount}'**
  String billingInvoiceDetail(
    int entries,
    int free,
    String entriesAmount,
    String addonsAmount,
  );

  /// No description provided for @billingInvoiceObject.
  ///
  /// In fr, this message translates to:
  /// **'{event} · {entries} entrées réelles'**
  String billingInvoiceObject(String event, int entries);

  /// No description provided for @billingInvoicePaidToast.
  ///
  /// In fr, this message translates to:
  /// **'Facture marquée comme payée.'**
  String get billingInvoicePaidToast;

  /// No description provided for @billingKindActivation.
  ///
  /// In fr, this message translates to:
  /// **'Demande d\'activation'**
  String get billingKindActivation;

  /// No description provided for @billingKindAddons.
  ///
  /// In fr, this message translates to:
  /// **'Suppléments'**
  String get billingKindAddons;

  /// No description provided for @billingKindInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture à l\'usage'**
  String get billingKindInvoice;

  /// No description provided for @billingKindOverdue.
  ///
  /// In fr, this message translates to:
  /// **'Facture en retard'**
  String get billingKindOverdue;

  /// No description provided for @billingMarkPaid.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme payée'**
  String get billingMarkPaid;

  /// No description provided for @billingNoEnd.
  ///
  /// In fr, this message translates to:
  /// **'sans fin'**
  String get billingNoEnd;

  /// No description provided for @billingNotDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Paiement pas encore déclaré par le promoteur'**
  String get billingNotDeclared;

  /// No description provided for @billingPackActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get billingPackActions;

  /// No description provided for @billingPackArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get billingPackArchive;

  /// No description provided for @billingPackArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get billingPackArchived;

  /// No description provided for @billingPackArchivedPlural.
  ///
  /// In fr, this message translates to:
  /// **'Archivés'**
  String get billingPackArchivedPlural;

  /// No description provided for @billingPackArchivedToast.
  ///
  /// In fr, this message translates to:
  /// **'Pack archivé : plus proposé, les abonnements continuent.'**
  String get billingPackArchivedToast;

  /// No description provided for @billingPackChangedToast.
  ///
  /// In fr, this message translates to:
  /// **'Pack de l\'abonnement changé.'**
  String get billingPackChangedToast;

  /// No description provided for @billingPackCopyName.
  ///
  /// In fr, this message translates to:
  /// **'{name} (copie)'**
  String billingPackCopyName(String name);

  /// No description provided for @billingPackDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get billingPackDraft;

  /// No description provided for @billingPackDraftToast.
  ///
  /// In fr, this message translates to:
  /// **'Pack retiré : il n\'est plus proposé.'**
  String get billingPackDraftToast;

  /// No description provided for @billingPackDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get billingPackDuplicate;

  /// No description provided for @billingPackDuplicated.
  ///
  /// In fr, this message translates to:
  /// **'Copie créée en brouillon.'**
  String get billingPackDuplicated;

  /// No description provided for @billingPackEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get billingPackEdit;

  /// No description provided for @billingPackEvents.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun événement} =1{1 événement} other{{count} événements}}'**
  String billingPackEvents(int count);

  /// No description provided for @billingPackFeatured.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé'**
  String get billingPackFeatured;

  /// No description provided for @billingPackNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau pack'**
  String get billingPackNew;

  /// No description provided for @billingPackPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get billingPackPublish;

  /// No description provided for @billingPackPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get billingPackPublished;

  /// No description provided for @billingPackPublishedToast.
  ///
  /// In fr, this message translates to:
  /// **'Pack publié : les promoteurs le voient.'**
  String get billingPackPublishedToast;

  /// No description provided for @billingPackSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun abonnement} =1{1 abonnement} other{{count} abonnements}}'**
  String billingPackSubscriptions(int count);

  /// No description provided for @billingPackUnpublish.
  ///
  /// In fr, this message translates to:
  /// **'Retirer (brouillon)'**
  String get billingPackUnpublish;

  /// No description provided for @billingPacksEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun pack ici.'**
  String get billingPacksEmpty;

  /// No description provided for @billingPacksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Packs'**
  String get billingPacksTitle;

  /// No description provided for @billingPaymentAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get billingPaymentAmount;

  /// No description provided for @billingPaymentDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du paiement'**
  String get billingPaymentDate;

  /// No description provided for @billingPaymentInvoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser une facture'**
  String get billingPaymentInvoiceTitle;

  /// No description provided for @billingPaymentMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Le montant reçu diffère du montant attendu ({expected}) : il sera indiqué dans la note.'**
  String billingPaymentMismatch(String expected);

  /// No description provided for @billingPaymentNote.
  ///
  /// In fr, this message translates to:
  /// **'Note (facultatif)'**
  String get billingPaymentNote;

  /// No description provided for @billingPaymentReceived.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu'**
  String get billingPaymentReceived;

  /// No description provided for @billingPaymentReference.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant de l\'opérateur'**
  String get billingPaymentReference;

  /// No description provided for @billingPaymentRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valider un paiement'**
  String get billingPaymentRequestTitle;

  /// No description provided for @billingPaymentToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get billingPaymentToday;

  /// No description provided for @billingPerEntry.
  ///
  /// In fr, this message translates to:
  /// **'{price} par entrée'**
  String billingPerEntry(String price);

  /// No description provided for @billingPerEventShort.
  ///
  /// In fr, this message translates to:
  /// **'par événement'**
  String get billingPerEventShort;

  /// No description provided for @billingPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'{price} / mois'**
  String billingPerMonth(String price);

  /// No description provided for @billingPerMonthShort.
  ///
  /// In fr, this message translates to:
  /// **'par mois'**
  String get billingPerMonthShort;

  /// No description provided for @billingPreviewAddon.
  ///
  /// In fr, this message translates to:
  /// **'{option} : en supplément ({price})'**
  String billingPreviewAddon(String option, String price);

  /// No description provided for @billingPreviewIncluded.
  ///
  /// In fr, this message translates to:
  /// **'{value} · {option}'**
  String billingPreviewIncluded(String value, String option);

  /// No description provided for @billingPreviewMore.
  ///
  /// In fr, this message translates to:
  /// **'+ {price} par {step} de plus'**
  String billingPreviewMore(String price, int step);

  /// No description provided for @billingPreviewUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'{option} : illimité'**
  String billingPreviewUnlimited(String option);

  /// No description provided for @billingReceivedNote.
  ///
  /// In fr, this message translates to:
  /// **'Reçu : {amount}'**
  String billingReceivedNote(String amount);

  /// No description provided for @billingReferenceLine.
  ///
  /// In fr, this message translates to:
  /// **'Référence {reference} · {date}'**
  String billingReferenceLine(String reference, String date);

  /// No description provided for @billingRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la demande'**
  String get billingRefuse;

  /// No description provided for @billingRefuseBody.
  ///
  /// In fr, this message translates to:
  /// **'La demande est fermée ; le promoteur peut en créer une autre.'**
  String get billingRefuseBody;

  /// No description provided for @billingRefuseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la demande ?'**
  String get billingRefuseTitle;

  /// No description provided for @billingRefusedToast.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée.'**
  String get billingRefusedToast;

  /// No description provided for @billingRequestAddons.
  ///
  /// In fr, this message translates to:
  /// **'Suppléments du pack {pack} : {addons}'**
  String billingRequestAddons(String pack, String addons);

  /// No description provided for @billingRequestPack.
  ///
  /// In fr, this message translates to:
  /// **'Pack {pack} · {duration}'**
  String billingRequestPack(String pack, String duration);

  /// No description provided for @billingSettingsBeneficiary.
  ///
  /// In fr, this message translates to:
  /// **'Nom du bénéficiaire'**
  String get billingSettingsBeneficiary;

  /// No description provided for @billingSettingsDelays.
  ///
  /// In fr, this message translates to:
  /// **'Délais'**
  String get billingSettingsDelays;

  /// No description provided for @billingSettingsGraceDays.
  ///
  /// In fr, this message translates to:
  /// **'Période de grâce après la fin'**
  String get billingSettingsGraceDays;

  /// No description provided for @billingSettingsInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Consigne affichée au promoteur'**
  String get billingSettingsInstructions;

  /// No description provided for @billingSettingsInvoiceHours.
  ///
  /// In fr, this message translates to:
  /// **'Émission de la facture à l\'usage'**
  String get billingSettingsInvoiceHours;

  /// No description provided for @billingSettingsInvoiceHoursHelp.
  ///
  /// In fr, this message translates to:
  /// **'Heures après la fin de l\'événement (ou à la clôture du contrôle).'**
  String get billingSettingsInvoiceHoursHelp;

  /// No description provided for @billingSettingsNumbers.
  ///
  /// In fr, this message translates to:
  /// **'Numéros de paiement de Tikéo'**
  String get billingSettingsNumbers;

  /// No description provided for @billingSettingsPaymentDays.
  ///
  /// In fr, this message translates to:
  /// **'Délai de paiement à l\'usage'**
  String get billingSettingsPaymentDays;

  /// No description provided for @billingSettingsPaymentDaysHelp.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut, si le pack n\'en fixe pas.'**
  String get billingSettingsPaymentDaysHelp;

  /// No description provided for @billingSettingsReminderDays.
  ///
  /// In fr, this message translates to:
  /// **'Rappel avant la fin d\'abonnement'**
  String get billingSettingsReminderDays;

  /// No description provided for @billingSettingsSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les réglages'**
  String get billingSettingsSave;

  /// No description provided for @billingSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de paiement enregistrés.'**
  String get billingSettingsSaved;

  /// No description provided for @billingSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de paiement'**
  String get billingSettingsTitle;

  /// No description provided for @billingStatusActivated.
  ///
  /// In fr, this message translates to:
  /// **'Activée'**
  String get billingStatusActivated;

  /// No description provided for @billingStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get billingStatusCancelled;

  /// No description provided for @billingStatusPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get billingStatusPaid;

  /// No description provided for @billingStatusRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get billingStatusRefused;

  /// No description provided for @billingSubActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get billingSubActive;

  /// No description provided for @billingSubActiveOne.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get billingSubActiveOne;

  /// No description provided for @billingSubEndedOne.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get billingSubEndedOne;

  /// No description provided for @billingSubEndingOne.
  ///
  /// In fr, this message translates to:
  /// **'Expire bientôt'**
  String get billingSubEndingOne;

  /// No description provided for @billingSubEndingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Expirent bientôt'**
  String get billingSubEndingSoon;

  /// No description provided for @billingSubGrace.
  ///
  /// In fr, this message translates to:
  /// **'En grâce'**
  String get billingSubGrace;

  /// No description provided for @billingSubGraceOne.
  ///
  /// In fr, this message translates to:
  /// **'En grâce'**
  String get billingSubGraceOne;

  /// No description provided for @billingSubscriptionsSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nom, e-mail ou pack'**
  String get billingSubscriptionsSearch;

  /// No description provided for @billingSubscriptionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnements'**
  String get billingSubscriptionsTitle;

  /// No description provided for @billingSystemFlat.
  ///
  /// In fr, this message translates to:
  /// **'Forfait'**
  String get billingSystemFlat;

  /// No description provided for @billingSystemUsage.
  ///
  /// In fr, this message translates to:
  /// **'À l\'usage'**
  String get billingSystemUsage;

  /// No description provided for @billingUntil.
  ///
  /// In fr, this message translates to:
  /// **'jusqu\'au {date}'**
  String billingUntil(String date);

  /// No description provided for @consoleNavCollectHint.
  ///
  /// In fr, this message translates to:
  /// **'Demandes d\'activation et factures à l\'usage'**
  String get consoleNavCollectHint;

  /// No description provided for @consoleNavCollectPending.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 paiement à vérifier} other{{count} paiements à vérifier}}'**
  String consoleNavCollectPending(int count);

  /// No description provided for @consoleNavPacksHint.
  ///
  /// In fr, this message translates to:
  /// **'Forfaits et packs à l\'usage, options, suppléments'**
  String get consoleNavPacksHint;

  /// No description provided for @consoleNavPaymentSettingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéros Orange Money et Moov, délais'**
  String get consoleNavPaymentSettingsHint;

  /// No description provided for @consoleNavSubscriptionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Prolonger, changer de pack, offrir un pack'**
  String get consoleNavSubscriptionsHint;

  /// No description provided for @consoleSectionBilling.
  ///
  /// In fr, this message translates to:
  /// **'Facturation'**
  String get consoleSectionBilling;

  /// No description provided for @consoleSectionPlatform.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get consoleSectionPlatform;

  /// No description provided for @auditAdminBillingSubscriptionExtended.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement prolongé'**
  String get auditAdminBillingSubscriptionExtended;

  /// No description provided for @auditAdminBillingSubscriptionPackChanged.
  ///
  /// In fr, this message translates to:
  /// **'Pack d\'un abonnement changé'**
  String get auditAdminBillingSubscriptionPackChanged;

  /// No description provided for @auditAdminBillingSubscriptionAddonsSet.
  ///
  /// In fr, this message translates to:
  /// **'Suppléments d\'un abonnement réglés'**
  String get auditAdminBillingSubscriptionAddonsSet;

  /// No description provided for @auditAdminBillingEventSet.
  ///
  /// In fr, this message translates to:
  /// **'Facturation d\'un événement changée'**
  String get auditAdminBillingEventSet;

  /// No description provided for @billingActivatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pack activé'**
  String get billingActivatedTitle;

  /// No description provided for @billingActivationDelay.
  ///
  /// In fr, this message translates to:
  /// **'Votre pack est activé dès que Tikéo a vérifié le paiement, en général dans la journée.'**
  String get billingActivationDelay;

  /// No description provided for @billingAddonLess.
  ///
  /// In fr, this message translates to:
  /// **'Moins'**
  String get billingAddonLess;

  /// No description provided for @billingAddonMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get billingAddonMore;

  /// No description provided for @billingAddonPricePer.
  ///
  /// In fr, this message translates to:
  /// **'+{step} : {price} {period}'**
  String billingAddonPricePer(int step, String price, String period);

  /// No description provided for @billingAddonsCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement en cours, jusqu\'au {date}'**
  String billingAddonsCurrent(String date);

  /// No description provided for @billingAddonsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Non inclus dans ce pack'**
  String get billingAddonsUnavailable;

  /// No description provided for @billingAmountToPay.
  ///
  /// In fr, this message translates to:
  /// **'Montant à payer'**
  String get billingAmountToPay;

  /// No description provided for @billingAvailableWith.
  ///
  /// In fr, this message translates to:
  /// **'{option} : disponible avec le pack {pack}'**
  String billingAvailableWith(String option, String pack);

  /// No description provided for @billingBackToMyPack.
  ///
  /// In fr, this message translates to:
  /// **'Retour à Mon pack'**
  String get billingBackToMyPack;

  /// No description provided for @billingBeneficiary.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire : {name}'**
  String billingBeneficiary(String name);

  /// No description provided for @billingByStructure.
  ///
  /// In fr, this message translates to:
  /// **'Facturation par structure'**
  String get billingByStructure;

  /// No description provided for @billingCancelRequest.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get billingCancelRequest;

  /// No description provided for @billingCancelledTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande annulée'**
  String get billingCancelledTitle;

  /// No description provided for @billingChoosePack.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un pack'**
  String get billingChoosePack;

  /// No description provided for @billingChooseThis.
  ///
  /// In fr, this message translates to:
  /// **'Choisir ce pack'**
  String get billingChooseThis;

  /// No description provided for @billingContactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get billingContactSupport;

  /// No description provided for @billingContinueToPayment.
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers le paiement'**
  String get billingContinueToPayment;

  /// No description provided for @billingCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié.'**
  String get billingCopied;

  /// No description provided for @billingCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get billingCopy;

  /// No description provided for @billingDueInvoices.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 facture à payer} other{{count} factures à payer}}'**
  String billingDueInvoices(int count);

  /// No description provided for @billingEnterprise.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get billingEnterprise;

  /// No description provided for @billingEnterpriseBody.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs structures, gros volumes : un pack sur devis.'**
  String get billingEnterpriseBody;

  /// No description provided for @billingEnterpriseContact.
  ///
  /// In fr, this message translates to:
  /// **'Demander un devis'**
  String get billingEnterpriseContact;

  /// No description provided for @billingErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifiez la connexion.'**
  String get billingErrorLoad;

  /// No description provided for @billingErrorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Facturation figée dès le premier ticket émis.'**
  String get billingErrorLocked;

  /// No description provided for @billingErrorNoSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement payant en cours.'**
  String get billingErrorNoSubscription;

  /// No description provided for @billingErrorPackUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce pack ou cette durée n\'est plus proposé.'**
  String get billingErrorPackUnavailable;

  /// No description provided for @billingErrorTransaction.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant de transaction invalide (3 à 60 caractères).'**
  String get billingErrorTransaction;

  /// No description provided for @billingFreeEntries.
  ///
  /// In fr, this message translates to:
  /// **'{count} entrées offertes'**
  String billingFreeEntries(int count);

  /// No description provided for @billingGaugeFull.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte : changez de pack pour aller plus loin.'**
  String get billingGaugeFull;

  /// No description provided for @billingGaugeFullAddon.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte : ajoutez un supplément ou changez de pack.'**
  String get billingGaugeFullAddon;

  /// No description provided for @billingGaugeOf.
  ///
  /// In fr, this message translates to:
  /// **'{used} sur {max}'**
  String billingGaugeOf(int used, int max);

  /// No description provided for @billingGaugeUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'{used} · illimité'**
  String billingGaugeUnlimited(int used);

  /// No description provided for @billingIPaid.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai payé'**
  String get billingIPaid;

  /// No description provided for @billingIncludedValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} inclus'**
  String billingIncludedValue(String value);

  /// No description provided for @billingInvoiceEntries.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune entrée} =1{1 entrée réelle} other{{count} entrées réelles}}'**
  String billingInvoiceEntries(int count);

  /// No description provided for @billingInvoiceOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get billingInvoiceOverdue;

  /// No description provided for @billingInvoiceToPay.
  ///
  /// In fr, this message translates to:
  /// **'À payer'**
  String get billingInvoiceToPay;

  /// No description provided for @billingInvoicesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture ni reçu pour l\'instant.'**
  String get billingInvoicesEmpty;

  /// No description provided for @billingInvoicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Factures et reçus'**
  String get billingInvoicesTitle;

  /// No description provided for @billingMyPackSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre pack, votre consommation et vos factures.'**
  String get billingMyPackSubtitle;

  /// No description provided for @billingMyPackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon pack'**
  String get billingMyPackTitle;

  /// No description provided for @billingNoMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Sans minimum'**
  String get billingNoMinimum;

  /// No description provided for @billingNoPacks.
  ///
  /// In fr, this message translates to:
  /// **'Aucun pack proposé pour l\'instant.'**
  String get billingNoPacks;

  /// No description provided for @billingNumberMissing.
  ///
  /// In fr, this message translates to:
  /// **'Numéro pas encore indiqué par Tikéo'**
  String get billingNumberMissing;

  /// No description provided for @billingOverdueBody.
  ///
  /// In fr, this message translates to:
  /// **'Réglez-la pour émettre des tickets sur un nouvel événement à l\'usage.'**
  String get billingOverdueBody;

  /// No description provided for @billingPayStep1.
  ///
  /// In fr, this message translates to:
  /// **'1 · Envoyez le montant à'**
  String get billingPayStep1;

  /// No description provided for @billingPayStep2.
  ///
  /// In fr, this message translates to:
  /// **'2 · Indiquez l\'identifiant reçu par SMS'**
  String get billingPayStep2;

  /// No description provided for @billingPaymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get billingPaymentTitle;

  /// No description provided for @billingPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Référence {reference} · {amount}'**
  String billingPendingBody(String reference, String amount);

  /// No description provided for @billingPendingDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Paiement déclaré : en attente de validation'**
  String get billingPendingDeclared;

  /// No description provided for @billingPendingToPay.
  ///
  /// In fr, this message translates to:
  /// **'Demande en attente de paiement'**
  String get billingPendingToPay;

  /// No description provided for @billingPerMonthEquivalent.
  ///
  /// In fr, this message translates to:
  /// **'soit {price} par mois'**
  String billingPerMonthEquivalent(String price);

  /// No description provided for @billingPlanActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get billingPlanActive;

  /// No description provided for @billingPlanFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get billingPlanFree;

  /// No description provided for @billingPlanFreeHint.
  ///
  /// In fr, this message translates to:
  /// **'Pack gratuit, sans fin'**
  String get billingPlanFreeHint;

  /// No description provided for @billingPlanGrace.
  ///
  /// In fr, this message translates to:
  /// **'En grâce'**
  String get billingPlanGrace;

  /// No description provided for @billingPlanOverline.
  ///
  /// In fr, this message translates to:
  /// **'Votre pack'**
  String get billingPlanOverline;

  /// No description provided for @billingProfileHint.
  ///
  /// In fr, this message translates to:
  /// **'Pack, consommation, factures'**
  String get billingProfileHint;

  /// No description provided for @billingProrataHint.
  ///
  /// In fr, this message translates to:
  /// **'Estimation au prorata des jours restants ; le montant exact est calculé à la demande.'**
  String get billingProrataHint;

  /// No description provided for @billingProrataShort.
  ///
  /// In fr, this message translates to:
  /// **'par mois, au prorata'**
  String get billingProrataShort;

  /// No description provided for @billingReceiptAddons.
  ///
  /// In fr, this message translates to:
  /// **'Reçu · suppléments'**
  String get billingReceiptAddons;

  /// No description provided for @billingReceiptPack.
  ///
  /// In fr, this message translates to:
  /// **'Reçu · pack'**
  String get billingReceiptPack;

  /// No description provided for @billingReferenceToGive.
  ///
  /// In fr, this message translates to:
  /// **'Référence à indiquer dans le paiement'**
  String get billingReferenceToGive;

  /// No description provided for @billingRefusedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée'**
  String get billingRefusedTitle;

  /// No description provided for @billingRequestCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Demande annulée.'**
  String get billingRequestCancelled;

  /// No description provided for @billingRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma demande'**
  String get billingRequestTitle;

  /// No description provided for @billingSimulator.
  ///
  /// In fr, this message translates to:
  /// **'Simulateur'**
  String get billingSimulator;

  /// No description provided for @billingSimulatorEntries.
  ///
  /// In fr, this message translates to:
  /// **'{count} entrées réelles'**
  String billingSimulatorEntries(int count);

  /// No description provided for @billingSimulatorFree.
  ///
  /// In fr, this message translates to:
  /// **'{count} entrées offertes'**
  String billingSimulatorFree(int count);

  /// No description provided for @billingSimulatorHint.
  ///
  /// In fr, this message translates to:
  /// **'Estimation hors suppléments ; seules les entrées acceptées à la porte comptent.'**
  String get billingSimulatorHint;

  /// No description provided for @billingSimulatorTier.
  ///
  /// In fr, this message translates to:
  /// **'Entrées {from} à {to} : {price} chacune'**
  String billingSimulatorTier(int from, int to, String price);

  /// No description provided for @billingStepActivated.
  ///
  /// In fr, this message translates to:
  /// **'Pack activé'**
  String get billingStepActivated;

  /// No description provided for @billingStepChecked.
  ///
  /// In fr, this message translates to:
  /// **'Vérification par Tikéo'**
  String get billingStepChecked;

  /// No description provided for @billingStepCreated.
  ///
  /// In fr, this message translates to:
  /// **'Demande créée'**
  String get billingStepCreated;

  /// No description provided for @billingStepDeclared.
  ///
  /// In fr, this message translates to:
  /// **'Paiement déclaré'**
  String get billingStepDeclared;

  /// No description provided for @billingStructureFlatHint.
  ///
  /// In fr, this message translates to:
  /// **'Les événements utilisent le pack de votre compte.'**
  String get billingStructureFlatHint;

  /// No description provided for @billingStructureHelp.
  ///
  /// In fr, this message translates to:
  /// **'Facturation par défaut des nouveaux événements de cette structure.'**
  String get billingStructureHelp;

  /// No description provided for @billingStructureSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get billingStructureSave;

  /// No description provided for @billingStructureSaved.
  ///
  /// In fr, this message translates to:
  /// **'Facturation de la structure enregistrée.'**
  String get billingStructureSaved;

  /// No description provided for @billingTierBeyond.
  ///
  /// In fr, this message translates to:
  /// **'Au-delà : {price} par entrée'**
  String billingTierBeyond(String price);

  /// No description provided for @billingTierUpTo.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à {count} entrées : {price} par entrée'**
  String billingTierUpTo(int count, String price);

  /// No description provided for @billingTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get billingTotal;

  /// No description provided for @billingTotalEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Total estimé'**
  String get billingTotalEstimate;

  /// No description provided for @billingTransaction.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant de transaction (facultatif)'**
  String get billingTransaction;

  /// No description provided for @billingTransactionHelp.
  ///
  /// In fr, this message translates to:
  /// **'Reçu par SMS après le paiement.'**
  String get billingTransactionHelp;

  /// No description provided for @billingTrialDays.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours d\'essai'**
  String billingTrialDays(int count);

  /// No description provided for @billingUsageChosen.
  ///
  /// In fr, this message translates to:
  /// **'{name} est facturée à l\'usage.'**
  String billingUsageChosen(String name);

  /// No description provided for @billingUsageHow.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche'**
  String get billingUsageHow;

  /// No description provided for @billingUsageStep1.
  ///
  /// In fr, this message translates to:
  /// **'Pas de paiement d\'avance.'**
  String get billingUsageStep1;

  /// No description provided for @billingUsageStep2.
  ///
  /// In fr, this message translates to:
  /// **'Seules les entrées réelles comptent.'**
  String get billingUsageStep2;

  /// No description provided for @billingUsageStep3.
  ///
  /// In fr, this message translates to:
  /// **'La facture arrive à la fin de l\'événement.'**
  String get billingUsageStep3;

  /// No description provided for @billingUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consommation'**
  String get billingUsageTitle;

  /// No description provided for @billingUseForStructure.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser pour ma structure'**
  String get billingUseForStructure;

  /// No description provided for @billingUseForWhich.
  ///
  /// In fr, this message translates to:
  /// **'Pour quelle structure ?'**
  String get billingUseForWhich;

  /// No description provided for @billingWaitingTitle.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get billingWaitingTitle;

  /// No description provided for @billingBlockAdded.
  ///
  /// In fr, this message translates to:
  /// **'Supplément ajouté : vous pouvez réessayer.'**
  String get billingBlockAdded;

  /// No description provided for @billingBlockAddonInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à la facture de fin d\'événement.'**
  String get billingBlockAddonInvoice;

  /// No description provided for @billingBlockAddonOffer.
  ///
  /// In fr, this message translates to:
  /// **'{what} : + {price}'**
  String billingBlockAddonOffer(String what, String price);

  /// No description provided for @billingBlockAskOwner.
  ///
  /// In fr, this message translates to:
  /// **'Demandez au propriétaire de la structure de changer de pack.'**
  String get billingBlockAskOwner;

  /// No description provided for @billingBlockChooseUsagePack.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le pack de l\'événement'**
  String get billingBlockChooseUsagePack;

  /// No description provided for @billingBlockExceed.
  ///
  /// In fr, this message translates to:
  /// **'Dépasser la limite'**
  String get billingBlockExceed;

  /// No description provided for @billingBlockLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get billingBlockLater;

  /// No description provided for @billingBlockLimitBody.
  ///
  /// In fr, this message translates to:
  /// **'Valeur comprise dans votre pack : {limit}.'**
  String billingBlockLimitBody(int limit);

  /// No description provided for @billingBlockLimitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte : {option}'**
  String billingBlockLimitTitle(String option);

  /// No description provided for @billingBlockOptionBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonction n\'est pas comprise dans votre pack.'**
  String get billingBlockOptionBody;

  /// No description provided for @billingBlockOptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'{option} : non compris'**
  String billingBlockOptionTitle(String option);

  /// No description provided for @billingBlockOverdueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facture à l\'usage en retard'**
  String get billingBlockOverdueTitle;

  /// No description provided for @billingBlockSeeInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes factures'**
  String get billingBlockSeeInvoices;

  /// No description provided for @billingBlockSeePacks.
  ///
  /// In fr, this message translates to:
  /// **'Voir les packs'**
  String get billingBlockSeePacks;

  /// No description provided for @billingBlockUsagePackBody.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est facturé à l\'usage : choisissez son pack.'**
  String get billingBlockUsagePackBody;

  /// No description provided for @billingBlockUsagePackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un pack à l\'usage'**
  String get billingBlockUsagePackTitle;

  /// No description provided for @billingDashboardNotInPack.
  ///
  /// In fr, this message translates to:
  /// **'Le tableau de bord en direct n\'est pas compris dans votre pack.'**
  String get billingDashboardNotInPack;

  /// No description provided for @billingDownloadPdf.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le PDF'**
  String get billingDownloadPdf;

  /// No description provided for @billingDueOn.
  ///
  /// In fr, this message translates to:
  /// **'À régler avant le {date}'**
  String billingDueOn(String date);

  /// No description provided for @billingDurationTrial.
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get billingDurationTrial;

  /// No description provided for @billingErrorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé ou événement introuvable.'**
  String get billingErrorForbidden;

  /// No description provided for @billingErrorTrialUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Essai impossible pendant un abonnement payant.'**
  String get billingErrorTrialUnavailable;

  /// No description provided for @billingErrorTrialUsed.
  ///
  /// In fr, this message translates to:
  /// **'Votre essai gratuit a déjà été utilisé.'**
  String get billingErrorTrialUsed;

  /// No description provided for @billingEventChoice.
  ///
  /// In fr, this message translates to:
  /// **'Facturation de l\'événement'**
  String get billingEventChoice;

  /// No description provided for @billingEventEntriesAmount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune entrée facturée} =1{1 entrée facturée} other{{count} entrées facturées}}'**
  String billingEventEntriesAmount(int count);

  /// No description provided for @billingEventEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Estimation en direct'**
  String get billingEventEstimate;

  /// No description provided for @billingEventInherit.
  ///
  /// In fr, this message translates to:
  /// **'Comme la structure'**
  String get billingEventInherit;

  /// No description provided for @billingEventInheritHint.
  ///
  /// In fr, this message translates to:
  /// **'Suit la facturation par défaut de la structure.'**
  String get billingEventInheritHint;

  /// No description provided for @billingEventInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture : {amount}'**
  String billingEventInvoice(String amount);

  /// No description provided for @billingEventInvoiceWhen.
  ///
  /// In fr, this message translates to:
  /// **'La facture est émise après la fin de l\'événement ; seules les entrées acceptées comptent.'**
  String get billingEventInvoiceWhen;

  /// No description provided for @billingEventLimits.
  ///
  /// In fr, this message translates to:
  /// **'Limites de l\'événement'**
  String get billingEventLimits;

  /// No description provided for @billingEventLockHint.
  ///
  /// In fr, this message translates to:
  /// **'Se fige dès le premier ticket émis.'**
  String get billingEventLockHint;

  /// No description provided for @billingEventLockedBanner.
  ///
  /// In fr, this message translates to:
  /// **'Facturation figée : le premier ticket est émis.'**
  String get billingEventLockedBanner;

  /// No description provided for @billingEventSaved.
  ///
  /// In fr, this message translates to:
  /// **'Facturation de l\'événement enregistrée.'**
  String get billingEventSaved;

  /// No description provided for @billingEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facturation'**
  String get billingEventTitle;

  /// No description provided for @billingFilterAllInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get billingFilterAllInvoices;

  /// No description provided for @billingFilterPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payées'**
  String get billingFilterPaid;

  /// No description provided for @billingHowToPay.
  ///
  /// In fr, this message translates to:
  /// **'Comment payer'**
  String get billingHowToPay;

  /// No description provided for @billingInvoiceMissing.
  ///
  /// In fr, this message translates to:
  /// **'Facture introuvable.'**
  String get billingInvoiceMissing;

  /// No description provided for @billingInvoicePayHint.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez le montant avec la référence : Tikéo marque la facture payée dès réception.'**
  String get billingInvoicePayHint;

  /// No description provided for @billingInvoicePdfFooter.
  ///
  /// In fr, this message translates to:
  /// **'Tikéo · facture à l\'usage : seules les entrées acceptées à la porte sont comptées. Paiement Orange Money ou Moov Money, avec la référence de la facture.'**
  String get billingInvoicePdfFooter;

  /// No description provided for @billingInvoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facture'**
  String get billingInvoiceTitle;

  /// No description provided for @billingIssuedOn.
  ///
  /// In fr, this message translates to:
  /// **'émise le {date}'**
  String billingIssuedOn(String date);

  /// No description provided for @billingLineAddon.
  ///
  /// In fr, this message translates to:
  /// **'{option} × {units} à {price}'**
  String billingLineAddon(String option, int units, String price);

  /// No description provided for @billingLineEntries.
  ///
  /// In fr, this message translates to:
  /// **'{count} entrées à {price}'**
  String billingLineEntries(int count, String price);

  /// No description provided for @billingLineTier.
  ///
  /// In fr, this message translates to:
  /// **'Entrées {from} à {to} à {price}'**
  String billingLineTier(int from, int to, String price);

  /// No description provided for @billingPaidOn.
  ///
  /// In fr, this message translates to:
  /// **'Payée le {date}'**
  String billingPaidOn(String date);

  /// No description provided for @billingPlanTrial.
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get billingPlanTrial;

  /// No description provided for @billingSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get billingSeeAll;

  /// No description provided for @billingTrialStarted.
  ///
  /// In fr, this message translates to:
  /// **'Essai de {pack} activé pour {days} jours.'**
  String billingTrialStarted(String pack, int days);

  /// No description provided for @billingTryFree.
  ///
  /// In fr, this message translates to:
  /// **'Essayer {days} jours gratuitement'**
  String billingTryFree(int days);

  /// No description provided for @auditBillingTrialStarted.
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit commencé'**
  String get auditBillingTrialStarted;

  /// No description provided for @welcomeOrganizeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Organisez vos événements'**
  String get welcomeOrganizeTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTitle;

  /// No description provided for @aboutHint.
  ///
  /// In fr, this message translates to:
  /// **'Version, mise à jour, mentions légales'**
  String get aboutHint;

  /// No description provided for @aboutCheckNow.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get aboutCheckNow;

  /// No description provided for @aboutLastCheck.
  ///
  /// In fr, this message translates to:
  /// **'Dernière vérification : {date}'**
  String aboutLastCheck(String date);

  /// No description provided for @aboutLegal.
  ///
  /// In fr, this message translates to:
  /// **'Mentions légales'**
  String get aboutLegal;

  /// No description provided for @aboutContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// No description provided for @profileSupport.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get profileSupport;

  /// No description provided for @updateLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get updateLater;

  /// No description provided for @settingsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsAccount;

  /// No description provided for @billingSettingsSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Réessayez ; si le problème continue, signalez-le à l\'équipe technique.'**
  String get billingSettingsSaveFailed;

  /// No description provided for @featuredErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Seul un événement public à venir peut être mis à la une, avec une fin après le début.'**
  String get featuredErrorInvalid;

  /// No description provided for @featuredErrorExists.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est déjà à la une.'**
  String get featuredErrorExists;

  /// No description provided for @featuredTitle.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get featuredTitle;

  /// No description provided for @featuredNavHint.
  ///
  /// In fr, this message translates to:
  /// **'Événements mis en avant dans Explorer'**
  String get featuredNavHint;

  /// No description provided for @featuredHint.
  ///
  /// In fr, this message translates to:
  /// **'Ordre d\'affichage dans Explorer. Sans mise en avant en cours, Explorer montre les 5 prochains événements publics.'**
  String get featuredHint;

  /// No description provided for @featuredEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement choisi : Explorer montre les 5 prochains.'**
  String get featuredEmpty;

  /// No description provided for @featuredAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get featuredAdd;

  /// No description provided for @featuredAdded.
  ///
  /// In fr, this message translates to:
  /// **'Événement mis à la une.'**
  String get featuredAdded;

  /// No description provided for @featuredRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get featuredRemove;

  /// No description provided for @featuredRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Retiré de la une.'**
  String get featuredRemoved;

  /// No description provided for @featuredUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter'**
  String get featuredUp;

  /// No description provided for @featuredDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre'**
  String get featuredDown;

  /// No description provided for @featuredPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période de mise en avant'**
  String get featuredPeriod;

  /// No description provided for @featuredPeriodSaved.
  ///
  /// In fr, this message translates to:
  /// **'Période enregistrée.'**
  String get featuredPeriodSaved;

  /// No description provided for @featuredPeriodLine.
  ///
  /// In fr, this message translates to:
  /// **'Du {start} au {end}'**
  String featuredPeriodLine(String start, String end);

  /// No description provided for @featuredLive.
  ///
  /// In fr, this message translates to:
  /// **'Affiché'**
  String get featuredLive;

  /// No description provided for @featuredWaiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get featuredWaiting;

  /// No description provided for @featuredEnded.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get featuredEnded;

  /// No description provided for @featuredPick.
  ///
  /// In fr, this message translates to:
  /// **'Événement public à venir'**
  String get featuredPick;

  /// No description provided for @featuredPickEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement public à venir trouvé.'**
  String get featuredPickEmpty;

  /// No description provided for @auditFeaturedAdded.
  ///
  /// In fr, this message translates to:
  /// **'Événement mis à la une'**
  String get auditFeaturedAdded;

  /// No description provided for @auditFeaturedRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Événement retiré de la une'**
  String get auditFeaturedRemoved;

  /// No description provided for @auditFeaturedMoved.
  ///
  /// In fr, this message translates to:
  /// **'Ordre de la une modifié'**
  String get auditFeaturedMoved;

  /// No description provided for @auditFeaturedPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période de la une modifiée'**
  String get auditFeaturedPeriod;

  /// No description provided for @photoSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Image indisponible. Vérifiez la connexion.'**
  String get photoSaveFailed;

  /// No description provided for @photoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Image enregistrée.'**
  String get photoSaved;

  /// No description provided for @photoClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get photoClose;

  /// No description provided for @photoShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get photoShare;

  /// No description provided for @photoDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get photoDownload;

  /// No description provided for @shareImageCta.
  ///
  /// In fr, this message translates to:
  /// **'Obtenez votre ticket sur Tikéo.'**
  String get shareImageCta;

  /// No description provided for @shareImageBanner.
  ///
  /// In fr, this message translates to:
  /// **'Obtenez votre ticket sur l\'application Tikéo'**
  String get shareImageBanner;

  /// No description provided for @shareImageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'événement'**
  String get shareImageTitle;

  /// No description provided for @shareImageStory.
  ///
  /// In fr, this message translates to:
  /// **'Statut 9:16'**
  String get shareImageStory;

  /// No description provided for @shareImagePost.
  ///
  /// In fr, this message translates to:
  /// **'Publication 4:5'**
  String get shareImagePost;

  /// No description provided for @shareImageShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareImageShare;

  /// No description provided for @shareImageSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get shareImageSave;

  /// No description provided for @shareImageTextOnly.
  ///
  /// In fr, this message translates to:
  /// **'Partager le texte seulement'**
  String get shareImageTextOnly;

  /// No description provided for @shareImageFailed.
  ///
  /// In fr, this message translates to:
  /// **'Image impossible à préparer. Réessayez.'**
  String get shareImageFailed;

  /// No description provided for @invitationDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitation'**
  String get invitationDetailsTitle;

  /// No description provided for @invitationStateActive.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get invitationStateActive;

  /// No description provided for @invitationStateExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get invitationStateExpired;

  /// No description provided for @invitationStateRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Révoquée'**
  String get invitationStateRevoked;

  /// No description provided for @invitationStateExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Épuisée'**
  String get invitationStateExhausted;

  /// No description provided for @invitationCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get invitationCodeLabel;

  /// No description provided for @invitationCodeShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le code'**
  String get invitationCodeShow;

  /// No description provided for @invitationCodeHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le code'**
  String get invitationCodeHide;

  /// No description provided for @invitationCodeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Code non récupérable : créez une nouvelle invitation.'**
  String get invitationCodeUnavailable;

  /// No description provided for @invitationErrorInactive.
  ///
  /// In fr, this message translates to:
  /// **'Invitation expirée, révoquée ou épuisée : code non affiché.'**
  String get invitationErrorInactive;

  /// No description provided for @invitationErrorLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'affichages : réessayez dans une heure.'**
  String get invitationErrorLimited;

  /// No description provided for @invitationStructure.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get invitationStructure;

  /// No description provided for @invitationCreatedBy.
  ///
  /// In fr, this message translates to:
  /// **'Créée par'**
  String get invitationCreatedBy;

  /// No description provided for @invitationCreatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Créée le'**
  String get invitationCreatedAt;

  /// No description provided for @invitationValidUntil.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu\'au'**
  String get invitationValidUntil;

  /// No description provided for @invitationUses.
  ///
  /// In fr, this message translates to:
  /// **'Utilisations'**
  String get invitationUses;

  /// No description provided for @invitationUsedBy.
  ///
  /// In fr, this message translates to:
  /// **'Ont rejoint avec ce code'**
  String get invitationUsedBy;

  /// No description provided for @invitationRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer l\'invitation'**
  String get invitationRevoke;

  /// No description provided for @printTitle.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer des tickets'**
  String get printTitle;

  /// No description provided for @printCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ticket à imprimer} other{{count} tickets à imprimer}}'**
  String printCount(int count);

  /// No description provided for @printPerPage.
  ///
  /// In fr, this message translates to:
  /// **'Tickets par feuille A4'**
  String get printPerPage;

  /// No description provided for @printSheets.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 feuille} other{{count} feuilles}}'**
  String printSheets(int count);

  /// No description provided for @printQrSize.
  ///
  /// In fr, this message translates to:
  /// **'QR d\'environ {size} cm'**
  String printQrSize(double size);

  /// No description provided for @printHint.
  ///
  /// In fr, this message translates to:
  /// **'Traits de coupe entre les tickets. Imprimez à 100 %, sans ajuster à la page.'**
  String get printHint;

  /// No description provided for @printGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Générer le PDF'**
  String get printGenerate;

  /// No description provided for @auditInvitationCodeRevealed.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation affiché'**
  String get auditInvitationCodeRevealed;

  /// No description provided for @profileActiveOrgTitle.
  ///
  /// In fr, this message translates to:
  /// **'Structure active'**
  String get profileActiveOrgTitle;

  /// No description provided for @profileMyStructuresTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes structures'**
  String get profileMyStructuresTitle;

  /// No description provided for @profileMyAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get profileMyAccountTitle;

  /// No description provided for @profileOrgInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de la structure'**
  String get profileOrgInfo;

  /// No description provided for @profileOrgTeam.
  ///
  /// In fr, this message translates to:
  /// **'Équipe et invitations'**
  String get profileOrgTeam;

  /// No description provided for @profileOrgDoors.
  ///
  /// In fr, this message translates to:
  /// **'Portes'**
  String get profileOrgDoors;

  /// No description provided for @profileOrgDoorsHint.
  ///
  /// In fr, this message translates to:
  /// **'Postes de contrôle où vous êtes affecté'**
  String get profileOrgDoorsHint;

  /// No description provided for @profileCreateOrg.
  ///
  /// In fr, this message translates to:
  /// **'Créer une structure'**
  String get profileCreateOrg;

  /// No description provided for @profileCreateOrgQuota.
  ///
  /// In fr, this message translates to:
  /// **'{used} sur {max} avec votre pack'**
  String profileCreateOrgQuota(int used, int max);

  /// No description provided for @profileJoinOrg.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre avec un code'**
  String get profileJoinOrg;

  /// No description provided for @profileAccountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profileAccountInfo;

  /// No description provided for @profileAccountInfoHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, photo, téléphone'**
  String get profileAccountInfoHint;

  /// No description provided for @favoritesHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Gardés sur ce téléphone, même sans compte} =1{1 événement gardé sur ce téléphone} other{{count} événements gardés sur ce téléphone}}'**
  String favoritesHeroSubtitle(int count);

  /// No description provided for @favoritesSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans mes favoris'**
  String get favoritesSearchHint;

  /// No description provided for @favoritesFilters.
  ///
  /// In fr, this message translates to:
  /// **'Trier et filtrer'**
  String get favoritesFilters;

  /// No description provided for @favoritesPeriodLabel.
  ///
  /// In fr, this message translates to:
  /// **'{label} ({count})'**
  String favoritesPeriodLabel(String label, int count);

  /// No description provided for @favoritesSortTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get favoritesSortTitle;

  /// No description provided for @favoritesSortNearest.
  ///
  /// In fr, this message translates to:
  /// **'Plus proches'**
  String get favoritesSortNearest;

  /// No description provided for @favoritesSortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Plus récents'**
  String get favoritesSortRecent;

  /// No description provided for @favoritesNoMatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori ne correspond'**
  String get favoritesNoMatchTitle;

  /// No description provided for @favoritesNoMatchBody.
  ///
  /// In fr, this message translates to:
  /// **'Changez la recherche, la période ou les filtres.'**
  String get favoritesNoMatchBody;

  /// No description provided for @favoritesApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get favoritesApply;

  /// No description provided for @favoriteUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get favoriteUndo;

  /// No description provided for @assignTitle.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer une structure'**
  String get assignTitle;

  /// No description provided for @assignCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Structures actuelles'**
  String get assignCurrent;

  /// No description provided for @assignNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune structure pour l\'instant.'**
  String get assignNone;

  /// No description provided for @assignStructure.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get assignStructure;

  /// No description provided for @assignSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la structure (2 lettres au moins)'**
  String get assignSearchHint;

  /// No description provided for @assignNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucune structure trouvée.'**
  String get assignNoResult;

  /// No description provided for @assignOwnerIs.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire : {name}'**
  String assignOwnerIs(String name);

  /// No description provided for @assignChange.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une autre structure'**
  String get assignChange;

  /// No description provided for @assignRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get assignRole;

  /// No description provided for @assignOwnerHint.
  ///
  /// In fr, this message translates to:
  /// **'Transfert : ce compte devient propriétaire, l\'ancien propriétaire reste gestionnaire. Le quota de structures de son pack est vérifié.'**
  String get assignOwnerHint;

  /// No description provided for @assignMemberHint.
  ///
  /// In fr, this message translates to:
  /// **'Le compte rejoint l\'équipe avec ce rôle, ou change de rôle s\'il en fait déjà partie.'**
  String get assignMemberHint;

  /// No description provided for @assignSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer'**
  String get assignSubmit;

  /// No description provided for @assignTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transférer la structure'**
  String get assignTransfer;

  /// No description provided for @assignDone.
  ///
  /// In fr, this message translates to:
  /// **'Compte désormais {role} de « {name} ».'**
  String assignDone(String role, String name);

  /// No description provided for @assignErrorInactive.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est désactivé ou supprimé.'**
  String get assignErrorInactive;

  /// No description provided for @assignErrorAlreadyOwner.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est déjà propriétaire de cette structure.'**
  String get assignErrorAlreadyOwner;

  /// No description provided for @assignErrorOwnerLocked.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est propriétaire : transférez d\'abord la structure à un autre compte.'**
  String get assignErrorOwnerLocked;

  /// No description provided for @assignErrorLimit.
  ///
  /// In fr, this message translates to:
  /// **'Le pack de ce compte ne permet pas une structure de plus.'**
  String get assignErrorLimit;

  /// No description provided for @auditAdminOrganizationAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Structure attribuée par l\'équipe Tikéo'**
  String get auditAdminOrganizationAssigned;

  /// No description provided for @textSizeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get textSizeTitle;

  /// No description provided for @textSizeSmall.
  ///
  /// In fr, this message translates to:
  /// **'Petite'**
  String get textSizeSmall;

  /// No description provided for @textSizeNormal.
  ///
  /// In fr, this message translates to:
  /// **'Normale'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In fr, this message translates to:
  /// **'Grande'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In fr, this message translates to:
  /// **'Très grande'**
  String get textSizeExtraLarge;

  /// No description provided for @textSizePreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Concert de Bobo'**
  String get textSizePreviewTitle;

  /// No description provided for @textSizePreviewBody.
  ///
  /// In fr, this message translates to:
  /// **'Samedi 20:00 · Maison du peuple, Ouagadougou'**
  String get textSizePreviewBody;

  /// No description provided for @textSizeHelp.
  ///
  /// In fr, this message translates to:
  /// **'S\'ajoute à la taille du texte réglée sur le téléphone.'**
  String get textSizeHelp;

  /// No description provided for @devicesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appareils connectés'**
  String get devicesTitle;

  /// No description provided for @devicesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les téléphones où votre compte est ouvert.'**
  String get devicesSubtitle;

  /// No description provided for @devicesRowHint.
  ///
  /// In fr, this message translates to:
  /// **'Voir et déconnecter à distance'**
  String get devicesRowHint;

  /// No description provided for @devicesThis.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil'**
  String get devicesThis;

  /// No description provided for @devicesUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Appareil non identifié'**
  String get devicesUnknown;

  /// No description provided for @devicesActiveNow.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé en ce moment'**
  String get devicesActiveNow;

  /// No description provided for @devicesLastSeen.
  ///
  /// In fr, this message translates to:
  /// **'Dernière activité : {when}'**
  String devicesLastSeen(String when);

  /// No description provided for @devicesSince.
  ///
  /// In fr, this message translates to:
  /// **'Connecté depuis le {when}'**
  String devicesSince(String when);

  /// No description provided for @devicesSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get devicesSignOut;

  /// No description provided for @devicesSignOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter « {name} » ?'**
  String devicesSignOutTitle(String name);

  /// No description provided for @devicesSignOutBody.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil devra se reconnecter avec le mot de passe. Les tickets et données ne sont pas touchés.'**
  String get devicesSignOutBody;

  /// No description provided for @devicesSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » est déconnecté.'**
  String devicesSignedOut(String name);

  /// No description provided for @devicesSignOutOthers.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter les autres appareils'**
  String get devicesSignOutOthers;

  /// No description provided for @devicesSignOutOthersBody.
  ///
  /// In fr, this message translates to:
  /// **'Tous les appareils sauf celui-ci devront se reconnecter.'**
  String get devicesSignOutOthersBody;

  /// No description provided for @devicesSignedOutOthers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun autre appareil à déconnecter.} =1{1 appareil déconnecté.} other{{count} appareils déconnectés.}}'**
  String devicesSignedOutOthers(int count);

  /// No description provided for @devicesOnlyThis.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n\'est ouvert que sur cet appareil.'**
  String get devicesOnlyThis;

  /// No description provided for @devicesRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get devicesRetry;

  /// No description provided for @devicesErrorCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Pour cet appareil, utilisez « Se déconnecter ».'**
  String get devicesErrorCurrent;

  /// No description provided for @devicesErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Appareil introuvable ou déjà déconnecté.'**
  String get devicesErrorNotFound;

  /// No description provided for @devicesErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get devicesErrorNetwork;

  /// No description provided for @devicesErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Impossible pour le moment. Réessayez.'**
  String get devicesErrorUnknown;

  /// No description provided for @devicesRemoteSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil a été déconnecté depuis un autre appareil.'**
  String get devicesRemoteSignedOut;

  /// No description provided for @appLockSetting.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller par empreinte'**
  String get appLockSetting;

  /// No description provided for @appLockSettingHint.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte ou code du téléphone, après 1 minute hors de l\'app'**
  String get appLockSettingHint;

  /// No description provided for @appLockUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune empreinte ni code n\'est configuré sur ce téléphone.'**
  String get appLockUnavailable;

  /// No description provided for @appLockEnableReason.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez pour activer le verrouillage de Tikéo'**
  String get appLockEnableReason;

  /// No description provided for @appLockEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage activé.'**
  String get appLockEnabled;

  /// No description provided for @appLockReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillez Tikéo'**
  String get appLockReason;

  /// No description provided for @appLockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tikéo est verrouillé'**
  String get appLockTitle;

  /// No description provided for @appLockBody.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez votre empreinte ou le code du téléphone.'**
  String get appLockBody;

  /// No description provided for @appLockFailed.
  ///
  /// In fr, this message translates to:
  /// **'Non reconnu. Réessayez, ou déconnectez-vous.'**
  String get appLockFailed;

  /// No description provided for @appLockUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get appLockUnlock;

  /// No description provided for @appLockSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get appLockSignOut;

  /// No description provided for @auditAccountDeviceRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Appareil déconnecté à distance'**
  String get auditAccountDeviceRevoked;

  /// No description provided for @auditAccountDevicesRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Autres appareils déconnectés'**
  String get auditAccountDevicesRevoked;

  /// No description provided for @searchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Événements et tickets de la structure'**
  String get searchSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, téléphone, référence ou événement'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get searchClear;

  /// No description provided for @searchIdleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que cherchez-vous ?'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleBody.
  ///
  /// In fr, this message translates to:
  /// **'Un titulaire (nom ou téléphone), une référence TS-…, ou un événement, sur tous les événements de la structure.'**
  String get searchIdleBody;

  /// No description provided for @searchNoResult.
  ///
  /// In fr, this message translates to:
  /// **'Rien pour « {query} »'**
  String searchNoResult(String query);

  /// No description provided for @searchNoResultBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l\'orthographe, ou cherchez par les 4 derniers chiffres du téléphone.'**
  String get searchNoResultBody;

  /// No description provided for @searchEvents.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 événement} other{{count} événements}}'**
  String searchEvents(int count);

  /// No description provided for @searchTickets.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ticket} other{{count} tickets}}'**
  String searchTickets(int count);

  /// No description provided for @searchError.
  ///
  /// In fr, this message translates to:
  /// **'Recherche impossible pour le moment.'**
  String get searchError;

  /// No description provided for @searchErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion : réessayez.'**
  String get searchErrorNetwork;

  /// No description provided for @bulkCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get bulkCancel;

  /// No description provided for @bulkPartial.
  ///
  /// In fr, this message translates to:
  /// **'Fait pour {done} sur {total}. Les autres n\'ont pas pu être traités : réessayez.'**
  String bulkPartial(int done, int total);

  /// No description provided for @eventsBulkSkipped.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 événement choisi sera laissé de côté.} other{{count} événements choisis seront laissés de côté.}}'**
  String eventsBulkSkipped(int count);

  /// No description provided for @eventsBulkPublic.
  ///
  /// In fr, this message translates to:
  /// **'Rendre public'**
  String get eventsBulkPublic;

  /// No description provided for @eventsBulkPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Rendre privé'**
  String get eventsBulkPrivate;

  /// No description provided for @eventsBulkDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get eventsBulkDuplicate;

  /// No description provided for @eventsBulkArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get eventsBulkArchive;

  /// No description provided for @eventsBulkPublicNone.
  ///
  /// In fr, this message translates to:
  /// **'Les événements choisis sont déjà publics, annulés ou archivés.'**
  String get eventsBulkPublicNone;

  /// No description provided for @eventsBulkPrivateNone.
  ///
  /// In fr, this message translates to:
  /// **'Les événements choisis sont déjà privés.'**
  String get eventsBulkPrivateNone;

  /// No description provided for @eventsBulkArchiveNone.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les événements clôturés ou annulés peuvent être archivés.'**
  String get eventsBulkArchiveNone;

  /// No description provided for @eventsBulkPublicTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Rendre 1 événement public ?} other{Rendre {count} événements publics ?}}'**
  String eventsBulkPublicTitle(int count);

  /// No description provided for @eventsBulkPrivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Rendre 1 événement privé ?} other{Rendre {count} événements privés ?}}'**
  String eventsBulkPrivateTitle(int count);

  /// No description provided for @eventsBulkArchiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Archiver 1 événement ?} other{Archiver {count} événements ?}}'**
  String eventsBulkArchiveTitle(int count);

  /// No description provided for @eventsBulkDuplicateTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Dupliquer 1 événement ?} other{Dupliquer {count} événements ?}}'**
  String eventsBulkDuplicateTitle(int count);

  /// No description provided for @eventsBulkPublicBody.
  ///
  /// In fr, this message translates to:
  /// **'Ils apparaîtront dans l\'Explorer, visibles de tous.'**
  String get eventsBulkPublicBody;

  /// No description provided for @eventsBulkPrivateBody.
  ///
  /// In fr, this message translates to:
  /// **'Ils ne seront plus visibles dans l\'Explorer. Les tickets déjà émis restent valables.'**
  String get eventsBulkPrivateBody;

  /// No description provided for @eventsBulkArchiveBody.
  ///
  /// In fr, this message translates to:
  /// **'Ils passeront en lecture seule. C\'est définitif.'**
  String get eventsBulkArchiveBody;

  /// No description provided for @eventsBulkDuplicateBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque copie est créée en brouillon avec ses catégories, ses portes et son équipe, une semaine plus tard (même jour, même heure). Vous pourrez changer la date ensuite.'**
  String get eventsBulkDuplicateBody;

  /// No description provided for @eventsBulkPublicDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 événement rendu public} other{{count} événements rendus publics}}'**
  String eventsBulkPublicDone(int count);

  /// No description provided for @eventsBulkPrivateDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 événement rendu privé} other{{count} événements rendus privés}}'**
  String eventsBulkPrivateDone(int count);

  /// No description provided for @eventsBulkArchiveDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 événement archivé} other{{count} événements archivés}}'**
  String eventsBulkArchiveDone(int count);

  /// No description provided for @eventsBulkDuplicateDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 copie créée en brouillon} other{{count} copies créées en brouillon}}'**
  String eventsBulkDuplicateDone(int count);

  /// No description provided for @eventsBulkDuplicateTooMany.
  ///
  /// In fr, this message translates to:
  /// **'{max} événements au plus à dupliquer en une fois.'**
  String eventsBulkDuplicateTooMany(int max);

  /// No description provided for @favoritesBulkRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get favoritesBulkRemove;

  /// No description provided for @favoritesBulkRemoved.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 favori retiré} other{{count} favoris retirés}}'**
  String favoritesBulkRemoved(int count);

  /// No description provided for @favoritesSelectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long sur un événement pour en retirer plusieurs'**
  String get favoritesSelectionHint;

  /// No description provided for @bulkSkippedItems.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 élément choisi n\'est pas concerné et sera laissé de côté.} other{{count} éléments choisis ne sont pas concernés et seront laissés de côté.}}'**
  String bulkSkippedItems(int count);

  /// No description provided for @consoleBulkReactivateBody.
  ///
  /// In fr, this message translates to:
  /// **'Ils retrouveront leur accès à Tikéo.'**
  String get consoleBulkReactivateBody;

  /// No description provided for @consoleBulkOrgsSuspendNone.
  ///
  /// In fr, this message translates to:
  /// **'Les structures choisies sont déjà suspendues.'**
  String get consoleBulkOrgsSuspendNone;

  /// No description provided for @consoleBulkOrgsReactivateNone.
  ///
  /// In fr, this message translates to:
  /// **'Les structures choisies sont déjà actives.'**
  String get consoleBulkOrgsReactivateNone;

  /// No description provided for @consoleBulkOrgsSuspendTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Suspendre 1 structure ?} other{Suspendre {count} structures ?}}'**
  String consoleBulkOrgsSuspendTitle(int count);

  /// No description provided for @consoleBulkOrgsReactivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Réactiver 1 structure ?} other{Réactiver {count} structures ?}}'**
  String consoleBulkOrgsReactivateTitle(int count);

  /// No description provided for @consoleBulkOrgsSuspended.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 structure suspendue} other{{count} structures suspendues}}'**
  String consoleBulkOrgsSuspended(int count);

  /// No description provided for @consoleBulkOrgsReactivated.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 structure réactivée} other{{count} structures réactivées}}'**
  String consoleBulkOrgsReactivated(int count);

  /// No description provided for @consoleBulkDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get consoleBulkDisable;

  /// No description provided for @consoleBulkAccountsDisableNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte choisi ne peut être désactivé (déjà désactivé, supprimé, ou le vôtre).'**
  String get consoleBulkAccountsDisableNone;

  /// No description provided for @consoleBulkAccountsReactivateNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte choisi n\'est désactivé.'**
  String get consoleBulkAccountsReactivateNone;

  /// No description provided for @consoleBulkAccountsDisableTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Désactiver 1 compte ?} other{Désactiver {count} comptes ?}}'**
  String consoleBulkAccountsDisableTitle(int count);

  /// No description provided for @consoleBulkAccountsReactivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Réactiver 1 compte ?} other{Réactiver {count} comptes ?}}'**
  String consoleBulkAccountsReactivateTitle(int count);

  /// No description provided for @consoleBulkAccountsDisabled.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 compte désactivé} other{{count} comptes désactivés}}'**
  String consoleBulkAccountsDisabled(int count);

  /// No description provided for @consoleBulkAccountsReactivated.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 compte réactivé} other{{count} comptes réactivés}}'**
  String consoleBulkAccountsReactivated(int count);

  /// No description provided for @consoleBulkSupportClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get consoleBulkSupportClose;

  /// No description provided for @consoleBulkSupportCloseNone.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes choisies sont déjà fermées.'**
  String get consoleBulkSupportCloseNone;

  /// No description provided for @consoleBulkSupportCloseTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Fermer 1 demande ?} other{Fermer {count} demandes ?}}'**
  String consoleBulkSupportCloseTitle(int count);

  /// No description provided for @consoleBulkSupportCloseBody.
  ///
  /// In fr, this message translates to:
  /// **'Le demandeur pourra la rouvrir en répondant.'**
  String get consoleBulkSupportCloseBody;

  /// No description provided for @consoleBulkSupportClosed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 demande fermée} other{{count} demandes fermées}}'**
  String consoleBulkSupportClosed(int count);

  /// No description provided for @eventTeamChooseMembers.
  ///
  /// In fr, this message translates to:
  /// **'Cochez un ou plusieurs membres'**
  String get eventTeamChooseMembers;

  /// No description provided for @eventTeamUncheckAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout décocher'**
  String get eventTeamUncheckAll;

  /// No description provided for @eventTeamAlreadyAssigned.
  ///
  /// In fr, this message translates to:
  /// **'déjà affecté : {doors}'**
  String eventTeamAlreadyAssigned(String doors);

  /// No description provided for @eventTeamAssignMany.
  ///
  /// In fr, this message translates to:
  /// **'Affecter {count} membres'**
  String eventTeamAssignMany(int count);

  /// No description provided for @eventTeamAssignedMany.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre affecté} other{{count} membres affectés}}'**
  String eventTeamAssignedMany(int count);

  /// No description provided for @batchesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lots'**
  String get batchesTitle;

  /// No description provided for @batchesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un lot par génération de tickets (émission rapide, nominative ou import).'**
  String get batchesIntro;

  /// No description provided for @batchesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lot pour cet événement.'**
  String get batchesEmpty;

  /// No description provided for @batchesError.
  ///
  /// In fr, this message translates to:
  /// **'Lots indisponibles : vérifiez la connexion.'**
  String get batchesError;

  /// No description provided for @batchTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Lot {number} · 1 ticket} other{Lot {number} · {count} tickets}}'**
  String batchTitle(int number, int count);

  /// No description provided for @batchCounts.
  ///
  /// In fr, this message translates to:
  /// **'{issued} valables · {redeemed} utilisés · {revoked} annulés'**
  String batchCounts(int issued, int redeemed, int revoked);

  /// No description provided for @batchSelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get batchSelect;

  /// No description provided for @batchPrint.
  ///
  /// In fr, this message translates to:
  /// **'Planche A4'**
  String get batchPrint;

  /// No description provided for @batchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lot {number}'**
  String batchLabel(int number);

  /// No description provided for @batchClear.
  ///
  /// In fr, this message translates to:
  /// **'Tous les lots'**
  String get batchClear;

  /// No description provided for @photoOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir la photo en grand'**
  String get photoOpen;

  /// No description provided for @eventTeamRemoved.
  ///
  /// In fr, this message translates to:
  /// **'{name} n\'est plus affecté(e) à l\'événement'**
  String eventTeamRemoved(String name);

  /// No description provided for @consoleSupportCloseFailed.
  ///
  /// In fr, this message translates to:
  /// **'La demande n\'a pas pu être fermée : réessayez.'**
  String get consoleSupportCloseFailed;

  /// No description provided for @orgSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de la structure'**
  String get orgSettingsTitle;

  /// No description provided for @orgSettingsRowHint.
  ///
  /// In fr, this message translates to:
  /// **'Message d\'envoi, valeurs d\'un nouvel événement'**
  String get orgSettingsRowHint;

  /// No description provided for @orgSettingsMessageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Message d\'envoi'**
  String get orgSettingsMessageTitle;

  /// No description provided for @orgSettingsMessageHelp.
  ///
  /// In fr, this message translates to:
  /// **'Texte envoyé avec le ticket par WhatsApp, SMS ou e-mail, pour toute l\'équipe. Le QR code reste dans la pièce jointe, jamais dans le message.'**
  String get orgSettingsMessageHelp;

  /// No description provided for @orgSettingsTicketLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message pour un ticket'**
  String get orgSettingsTicketLabel;

  /// No description provided for @orgSettingsInvitationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message pour une invitation'**
  String get orgSettingsInvitationLabel;

  /// No description provided for @orgSettingsMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Vide : message par défaut de Tikéo'**
  String get orgSettingsMessageHint;

  /// No description provided for @orgSettingsInsertField.
  ///
  /// In fr, this message translates to:
  /// **'Insérer'**
  String get orgSettingsInsertField;

  /// No description provided for @orgSettingsFieldFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get orgSettingsFieldFirstName;

  /// No description provided for @orgSettingsFieldEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get orgSettingsFieldEvent;

  /// No description provided for @orgSettingsFieldDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get orgSettingsFieldDate;

  /// No description provided for @orgSettingsFieldPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get orgSettingsFieldPlace;

  /// No description provided for @orgSettingsFieldCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get orgSettingsFieldCategory;

  /// No description provided for @orgSettingsPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get orgSettingsPreview;

  /// No description provided for @orgSettingsResetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Revenir au message par défaut'**
  String get orgSettingsResetMessage;

  /// No description provided for @orgSettingsSampleDate.
  ///
  /// In fr, this message translates to:
  /// **'samedi 12 décembre 2026, 20:00'**
  String get orgSettingsSampleDate;

  /// No description provided for @orgSettingsDefaultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get orgSettingsDefaultsTitle;

  /// No description provided for @orgSettingsDefaultsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs proposées à la création d\'un événement ; elles restent modifiables.'**
  String get orgSettingsDefaultsHelp;

  /// No description provided for @orgSettingsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune valeur par défaut'**
  String get orgSettingsNone;

  /// No description provided for @orgSettingsCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories proposées'**
  String get orgSettingsCategories;

  /// No description provided for @orgSettingsAddCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get orgSettingsAddCategory;

  /// No description provided for @orgSettingsEditCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie proposée'**
  String get orgSettingsEditCategory;

  /// No description provided for @orgSettingsCategoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get orgSettingsCategoryName;

  /// No description provided for @orgSettingsCategoryCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Quota (facultatif)'**
  String get orgSettingsCategoryCapacity;

  /// No description provided for @orgSettingsCategoryPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix indicatif en FCFA (facultatif)'**
  String get orgSettingsCategoryPrice;

  /// No description provided for @orgSettingsCategoryInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie d\'invitations'**
  String get orgSettingsCategoryInvitation;

  /// No description provided for @orgSettingsUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Quota illimité'**
  String get orgSettingsUnlimited;

  /// No description provided for @orgSettingsQuota.
  ///
  /// In fr, this message translates to:
  /// **'Quota {count}'**
  String orgSettingsQuota(int count);

  /// No description provided for @orgSettingsPrice.
  ///
  /// In fr, this message translates to:
  /// **'{price} FCFA'**
  String orgSettingsPrice(int price);

  /// No description provided for @orgSettingsInvitationTag.
  ///
  /// In fr, this message translates to:
  /// **'Invitations'**
  String get orgSettingsInvitationTag;

  /// No description provided for @orgSettingsNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce nom est déjà dans la liste.'**
  String get orgSettingsNameTaken;

  /// No description provided for @orgSettingsNameInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Nom de 1 à 60 caractères.'**
  String get orgSettingsNameInvalid;

  /// No description provided for @orgSettingsCapacityInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Quota de 1 à 1 000 000.'**
  String get orgSettingsCapacityInvalid;

  /// No description provided for @orgSettingsPriceInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Prix de 0 à 10 000 000 FCFA.'**
  String get orgSettingsPriceInvalid;

  /// No description provided for @orgSettingsMaxItems.
  ///
  /// In fr, this message translates to:
  /// **'10 au plus.'**
  String get orgSettingsMaxItems;

  /// No description provided for @orgSettingsCheckpoints.
  ///
  /// In fr, this message translates to:
  /// **'Portes proposées'**
  String get orgSettingsCheckpoints;

  /// No description provided for @orgSettingsCheckpointName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la porte'**
  String get orgSettingsCheckpointName;

  /// No description provided for @orgSettingsAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get orgSettingsAdd;

  /// No description provided for @orgSettingsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get orgSettingsRemove;

  /// No description provided for @orgSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réglages enregistrés'**
  String get orgSettingsSaved;

  /// No description provided for @orgSettingsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les réglages de la structure.'**
  String get orgSettingsLoadFailed;

  /// No description provided for @orgSettingsErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get orgSettingsErrorNetwork;

  /// No description provided for @orgSettingsErrorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et les gestionnaires modifient ces réglages.'**
  String get orgSettingsErrorForbidden;

  /// No description provided for @orgSettingsErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message de 600 caractères au plus.'**
  String get orgSettingsErrorMessage;

  /// No description provided for @orgSettingsErrorTimezone.
  ///
  /// In fr, this message translates to:
  /// **'Fuseau horaire inconnu.'**
  String get orgSettingsErrorTimezone;

  /// No description provided for @orgSettingsErrorCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville de 2 à 80 caractères.'**
  String get orgSettingsErrorCity;

  /// No description provided for @orgSettingsErrorCategories.
  ///
  /// In fr, this message translates to:
  /// **'Une catégorie proposée n\'est pas valide.'**
  String get orgSettingsErrorCategories;

  /// No description provided for @orgSettingsErrorCheckpoints.
  ///
  /// In fr, this message translates to:
  /// **'Une porte proposée n\'est pas valide.'**
  String get orgSettingsErrorCheckpoints;

  /// No description provided for @orgSettingsErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Les réglages n\'ont pas pu être enregistrés.'**
  String get orgSettingsErrorUnknown;

  /// No description provided for @eventApplyDefaults.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter les catégories et portes proposées'**
  String get eventApplyDefaults;

  /// No description provided for @eventDefaultsCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories : {names}'**
  String eventDefaultsCategories(String names);

  /// No description provided for @eventDefaultsDoors.
  ///
  /// In fr, this message translates to:
  /// **'Portes : {names}'**
  String eventDefaultsDoors(String names);

  /// No description provided for @eventDefaultsApplyFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement est créé, mais les catégories et portes proposées n\'ont pas été ajoutées.'**
  String get eventDefaultsApplyFailed;

  /// No description provided for @consoleAnnouncementStarted.
  ///
  /// In fr, this message translates to:
  /// **'Cette annonce est déjà diffusée ou retirée : elle ne se modifie plus.'**
  String get consoleAnnouncementStarted;

  /// No description provided for @consoleAnnouncementScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Programmée'**
  String get consoleAnnouncementScheduled;

  /// No description provided for @consoleAnnouncementStartsAt.
  ///
  /// In fr, this message translates to:
  /// **'Début : {date}'**
  String consoleAnnouncementStartsAt(String date);

  /// No description provided for @consoleAnnouncementEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'annonce'**
  String get consoleAnnouncementEdit;

  /// No description provided for @consoleAnnouncementSaved.
  ///
  /// In fr, this message translates to:
  /// **'Annonce modifiée'**
  String get consoleAnnouncementSaved;

  /// No description provided for @consoleAnnouncementStartPast.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un début dans le futur.'**
  String get consoleAnnouncementStartPast;

  /// No description provided for @consoleAnnouncementScheduledToast.
  ///
  /// In fr, this message translates to:
  /// **'Annonce programmée pour le {date}'**
  String consoleAnnouncementScheduledToast(String date);

  /// No description provided for @consoleAnnouncementStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get consoleAnnouncementStart;

  /// No description provided for @consoleAnnouncementStartNow.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get consoleAnnouncementStartNow;

  /// No description provided for @consoleAnnouncementStartLater.
  ///
  /// In fr, this message translates to:
  /// **'Programmer'**
  String get consoleAnnouncementStartLater;

  /// No description provided for @consoleAnnouncementScheduledHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'annonce apparaîtra à cette heure ; vous pouvez la modifier jusque-là.'**
  String get consoleAnnouncementScheduledHint;

  /// No description provided for @consoleAnnouncementScheduledPushHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'annonce apparaîtra et la notification partira à cette heure (à 5 minutes près) ; vous pouvez la modifier jusque-là.'**
  String get consoleAnnouncementScheduledPushHint;

  /// No description provided for @consoleAnnouncementSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Programmer'**
  String get consoleAnnouncementSchedule;

  /// No description provided for @supportTemplatesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réponses types'**
  String get supportTemplatesTitle;

  /// No description provided for @supportTemplatesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réponse type pour le moment.'**
  String get supportTemplatesEmpty;

  /// No description provided for @supportTemplatesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Textes prêts à insérer dans une réponse du support, puis à adapter avant l\'envoi.'**
  String get supportTemplatesHelp;

  /// No description provided for @supportTemplatesManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les réponses types'**
  String get supportTemplatesManage;

  /// No description provided for @supportTemplateNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réponse type'**
  String get supportTemplateNew;

  /// No description provided for @supportTemplateEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la réponse type'**
  String get supportTemplateEdit;

  /// No description provided for @supportTemplateDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supportTemplateDelete;

  /// No description provided for @supportTemplateDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Réponse type supprimée'**
  String get supportTemplateDeleted;

  /// No description provided for @supportTemplateSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réponse type enregistrée'**
  String get supportTemplateSaved;

  /// No description provided for @supportTemplateTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre (pour la retrouver)'**
  String get supportTemplateTitleLabel;

  /// No description provided for @supportTemplateBodyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Texte de la réponse'**
  String get supportTemplateBodyLabel;

  /// No description provided for @supportTemplateTitleInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Titre de 2 à 60 caractères.'**
  String get supportTemplateTitleInvalid;

  /// No description provided for @supportTemplateBodyInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez le texte de la réponse.'**
  String get supportTemplateBodyInvalid;

  /// No description provided for @consoleTrendsTitle.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours'**
  String get consoleTrendsTitle;

  /// No description provided for @consoleTrendsError.
  ///
  /// In fr, this message translates to:
  /// **'Courbes indisponibles.'**
  String get consoleTrendsError;

  /// No description provided for @consoleTrendAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get consoleTrendAccounts;

  /// No description provided for @consoleTrendOrganizations.
  ///
  /// In fr, this message translates to:
  /// **'Structures'**
  String get consoleTrendOrganizations;

  /// No description provided for @consoleTrendEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements publiés'**
  String get consoleTrendEvents;

  /// No description provided for @consoleTrendTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets émis'**
  String get consoleTrendTickets;

  /// No description provided for @consoleTrendEntries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get consoleTrendEntries;

  /// No description provided for @consoleTrendTotal.
  ///
  /// In fr, this message translates to:
  /// **'{total} sur {days} jours'**
  String consoleTrendTotal(int total, int days);

  /// No description provided for @consoleTrendToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui : {count}'**
  String consoleTrendToday(String count);

  /// No description provided for @consoleTrendSemantics.
  ///
  /// In fr, this message translates to:
  /// **'{metric} : {total} sur {days} jours'**
  String consoleTrendSemantics(String metric, int total, int days);

  /// No description provided for @auditAdminAnnouncementUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Annonce programmée modifiée'**
  String get auditAdminAnnouncementUpdated;

  /// No description provided for @auditAdminSupportTemplateSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réponse type enregistrée'**
  String get auditAdminSupportTemplateSaved;

  /// No description provided for @auditAdminSupportTemplateDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Réponse type supprimée'**
  String get auditAdminSupportTemplateDeleted;

  /// No description provided for @auditOrganizationSettingsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de la structure modifiés'**
  String get auditOrganizationSettingsUpdated;

  /// No description provided for @auditEventDefaultsApplied.
  ///
  /// In fr, this message translates to:
  /// **'Catégories et portes proposées ajoutées'**
  String get auditEventDefaultsApplied;

  /// No description provided for @consoleMfaRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code de double authentification pour ouvrir la console.'**
  String get consoleMfaRequired;

  /// No description provided for @mfaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification'**
  String get mfaTitle;

  /// No description provided for @mfaRowOn.
  ///
  /// In fr, this message translates to:
  /// **'Activée pour la console'**
  String get mfaRowOn;

  /// No description provided for @mfaRowOff.
  ///
  /// In fr, this message translates to:
  /// **'Conseillée pour la console'**
  String get mfaRowOff;

  /// No description provided for @mfaErrorCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect : saisissez les 6 chiffres affichés maintenant.'**
  String get mfaErrorCode;

  /// No description provided for @mfaErrorRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais : réessayez dans une heure.'**
  String get mfaErrorRateLimited;

  /// No description provided for @mfaErrorNotEnrolled.
  ///
  /// In fr, this message translates to:
  /// **'La double authentification n\'est pas activée.'**
  String get mfaErrorNotEnrolled;

  /// No description provided for @mfaErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get mfaErrorNetwork;

  /// No description provided for @mfaErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get mfaErrorUnknown;

  /// No description provided for @mfaCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get mfaCodeLabel;

  /// No description provided for @mfaVerify.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get mfaVerify;

  /// No description provided for @mfaConsoleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de double authentification'**
  String get mfaConsoleTitle;

  /// No description provided for @mfaConsoleBody.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez votre application d\'authentification et saisissez le code de Tikéo. Il est demandé une fois par session.'**
  String get mfaConsoleBody;

  /// No description provided for @mfaUseRecovery.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser un code de secours'**
  String get mfaUseRecovery;

  /// No description provided for @mfaRecovered.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification retirée. Réactivez-la depuis Profil › Sécurité.'**
  String get mfaRecovered;

  /// No description provided for @mfaRecoveryBody.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone perdu ? Un code de secours retire la double authentification de votre compte ; vous pourrez la réactiver ensuite.'**
  String get mfaRecoveryBody;

  /// No description provided for @mfaRecoveryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours'**
  String get mfaRecoveryLabel;

  /// No description provided for @mfaRecoveryInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours inconnu ou déjà utilisé.'**
  String get mfaRecoveryInvalid;

  /// No description provided for @mfaEnabledToast.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification activée'**
  String get mfaEnabledToast;

  /// No description provided for @mfaDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get mfaDisable;

  /// No description provided for @mfaDisableBody.
  ///
  /// In fr, this message translates to:
  /// **'La console ne demandera plus de code. Vos codes de secours ne serviront plus.'**
  String get mfaDisableBody;

  /// No description provided for @mfaDisabledToast.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification désactivée'**
  String get mfaDisabledToast;

  /// No description provided for @mfaOffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Protégez la console'**
  String get mfaOffTitle;

  /// No description provided for @mfaOffBody.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif et conseillé : en plus du mot de passe, la console demandera un code à 6 chiffres d\'une application d\'authentification (Google Authenticator, Microsoft Authenticator…), une fois par session.'**
  String get mfaOffBody;

  /// No description provided for @mfaEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get mfaEnable;

  /// No description provided for @mfaOnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activée'**
  String get mfaOnTitle;

  /// No description provided for @mfaCodesLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun code de secours restant} =1{1 code de secours restant} other{{count} codes de secours restants}}'**
  String mfaCodesLeft(int count);

  /// No description provided for @mfaConfirmFirst.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un code pour gérer vos codes de secours ou désactiver.'**
  String get mfaConfirmFirst;

  /// No description provided for @mfaNewCodes.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux codes de secours'**
  String get mfaNewCodes;

  /// No description provided for @mfaEnrollTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la double authentification'**
  String get mfaEnrollTitle;

  /// No description provided for @mfaEnrollStep1.
  ///
  /// In fr, this message translates to:
  /// **'1. Dans votre application d\'authentification, ajoutez un compte en scannant ce QR code.'**
  String get mfaEnrollStep1;

  /// No description provided for @mfaEnrollManual.
  ///
  /// In fr, this message translates to:
  /// **'Ou saisissez cette clé à la main :'**
  String get mfaEnrollManual;

  /// No description provided for @mfaEnrollStep2.
  ///
  /// In fr, this message translates to:
  /// **'2. Saisissez le code à 6 chiffres affiché par l\'application.'**
  String get mfaEnrollStep2;

  /// No description provided for @mfaCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get mfaCopy;

  /// No description provided for @mfaCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié'**
  String get mfaCopied;

  /// No description provided for @mfaCodesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos codes de secours'**
  String get mfaCodesTitle;

  /// No description provided for @mfaCodesBody.
  ///
  /// In fr, this message translates to:
  /// **'Notez-les en lieu sûr : ils ne seront plus affichés. Chacun sert une fois, si vous perdez votre téléphone.'**
  String get mfaCodesBody;

  /// No description provided for @mfaCodesDone.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai noté mes codes'**
  String get mfaCodesDone;

  /// No description provided for @auditAdminMfaCodesGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Codes de secours générés'**
  String get auditAdminMfaCodesGenerated;

  /// No description provided for @auditAdminMfaRecovered.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification retirée par un code de secours'**
  String get auditAdminMfaRecovered;

  /// No description provided for @adminAccountsErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Réessayez.'**
  String get adminAccountsErrorNetwork;

  /// No description provided for @adminAccountsErrorRole.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle d\'administration ne permet pas cette action.'**
  String get adminAccountsErrorRole;

  /// No description provided for @adminAccountsErrorMfaNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Activez la double authentification (Profil › Sécurité) pour cette action.'**
  String get adminAccountsErrorMfaNeeded;

  /// No description provided for @adminAccountsErrorProtected.
  ///
  /// In fr, this message translates to:
  /// **'Seul un super administrateur peut agir sur le compte d\'un administrateur.'**
  String get adminAccountsErrorProtected;

  /// No description provided for @adminAccountsErrorSelf.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez votre Profil pour votre propre compte.'**
  String get adminAccountsErrorSelf;

  /// No description provided for @adminAccountsErrorReason.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le motif (3 caractères au moins).'**
  String get adminAccountsErrorReason;

  /// No description provided for @adminAccountsErrorName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de 2 à 60 caractères.'**
  String get adminAccountsErrorName;

  /// No description provided for @adminAccountsErrorPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get adminAccountsErrorPhone;

  /// No description provided for @adminAccountsErrorEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get adminAccountsErrorEmail;

  /// No description provided for @adminAccountsErrorEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un compte utilise déjà cette adresse e-mail.'**
  String get adminAccountsErrorEmailTaken;

  /// No description provided for @adminAccountsErrorConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez exactement l\'adresse e-mail du compte.'**
  String get adminAccountsErrorConfirmation;

  /// No description provided for @adminAccountsErrorLastSuper.
  ///
  /// In fr, this message translates to:
  /// **'Il faut garder au moins un super administrateur.'**
  String get adminAccountsErrorLastSuper;

  /// No description provided for @adminAccountsErrorNoDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande de suppression pour ce compte.'**
  String get adminAccountsErrorNoDeletion;

  /// No description provided for @adminAccountsErrorIsAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Retirez d\'abord le rôle d\'administration.'**
  String get adminAccountsErrorIsAdmin;

  /// No description provided for @adminAccountsErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Compte introuvable ou supprimé.'**
  String get adminAccountsErrorNotFound;

  /// No description provided for @adminAccountsErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'L\'action n\'a pas abouti. Réessayez.'**
  String get adminAccountsErrorUnknown;

  /// No description provided for @adminRoleSuper.
  ///
  /// In fr, this message translates to:
  /// **'Super administrateur'**
  String get adminRoleSuper;

  /// No description provided for @adminRoleSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get adminRoleSupport;

  /// No description provided for @adminRoleModeration.
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get adminRoleModeration;

  /// No description provided for @adminRoleFinance.
  ///
  /// In fr, this message translates to:
  /// **'Finance'**
  String get adminRoleFinance;

  /// No description provided for @adminRoleSuperHint.
  ///
  /// In fr, this message translates to:
  /// **'Tout, dont les administrateurs et les réglages de la console.'**
  String get adminRoleSuperHint;

  /// No description provided for @adminRoleSupportHint.
  ///
  /// In fr, this message translates to:
  /// **'Comptes, structures, tickets et demandes au support.'**
  String get adminRoleSupportHint;

  /// No description provided for @adminRoleModerationHint.
  ///
  /// In fr, this message translates to:
  /// **'Événements, catalogue, « À la une », annonces, suspension des structures.'**
  String get adminRoleModerationHint;

  /// No description provided for @adminRoleFinanceHint.
  ///
  /// In fr, this message translates to:
  /// **'Packs, paiements, factures et abonnements.'**
  String get adminRoleFinanceHint;

  /// No description provided for @adminAccountsFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire.'**
  String get adminAccountsFieldRequired;

  /// No description provided for @adminAccountsReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (gardé dans l\'historique de la console)'**
  String get adminAccountsReason;

  /// No description provided for @adminAccountsNotify.
  ///
  /// In fr, this message translates to:
  /// **'Prévenir la personne'**
  String get adminAccountsNotify;

  /// No description provided for @adminAccountsNotifyHint.
  ///
  /// In fr, this message translates to:
  /// **'Notification avec le motif.'**
  String get adminAccountsNotifyHint;

  /// No description provided for @adminAccountsTempPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe provisoire'**
  String get adminAccountsTempPasswordTitle;

  /// No description provided for @adminAccountsTempPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Affiché une seule fois. Transmettez-le à la personne : elle choisira son mot de passe à la connexion.'**
  String get adminAccountsTempPasswordHint;

  /// No description provided for @adminAccountsTempPasswordDone.
  ///
  /// In fr, this message translates to:
  /// **'C\'est noté'**
  String get adminAccountsTempPasswordDone;

  /// No description provided for @adminAccountsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get adminAccountsTitle;

  /// No description provided for @adminAccountsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get adminAccountsEdit;

  /// No description provided for @adminAccountsName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get adminAccountsName;

  /// No description provided for @adminAccountsPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get adminAccountsPhone;

  /// No description provided for @adminAccountsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Compte modifié'**
  String get adminAccountsUpdated;

  /// No description provided for @adminAccountsEmailChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer l\'e-mail'**
  String get adminAccountsEmailChange;

  /// No description provided for @adminAccountsEmailChangeHint.
  ///
  /// In fr, this message translates to:
  /// **'La personne se connectera avec la nouvelle adresse.'**
  String get adminAccountsEmailChangeHint;

  /// No description provided for @adminAccountsEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get adminAccountsEmail;

  /// No description provided for @adminAccountsEmailChanged.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail modifiée'**
  String get adminAccountsEmailChanged;

  /// No description provided for @adminAccountsPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe provisoire'**
  String get adminAccountsPassword;

  /// No description provided for @adminAccountsPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau mot de passe est créé et affiché une fois ; la personne est déconnectée et devra le changer à la connexion.'**
  String get adminAccountsPasswordHint;

  /// No description provided for @adminAccountsPasswordConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Créer le mot de passe'**
  String get adminAccountsPasswordConfirm;

  /// No description provided for @adminAccountsSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter partout'**
  String get adminAccountsSignOut;

  /// No description provided for @adminAccountsSignOutHint.
  ///
  /// In fr, this message translates to:
  /// **'Tous les appareils du compte sont déconnectés.'**
  String get adminAccountsSignOutHint;

  /// No description provided for @adminAccountsSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune session ouverte} =1{1 session fermée} other{{count} sessions fermées}}'**
  String adminAccountsSignedOut(int count);

  /// No description provided for @adminAccountsCancelDeletion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get adminAccountsCancelDeletion;

  /// No description provided for @adminAccountsDeletionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Demande de suppression annulée'**
  String get adminAccountsDeletionCancelled;

  /// No description provided for @adminAccountsDeleteNow.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer maintenant'**
  String get adminAccountsDeleteNow;

  /// No description provided for @adminAccountsDeleteNowHint.
  ///
  /// In fr, this message translates to:
  /// **'Compte anonymisé tout de suite, structures du propriétaire suspendues ; tickets et historique gardés. Irréversible. Pour confirmer, saisissez {email}.'**
  String adminAccountsDeleteNowHint(String email);

  /// No description provided for @adminAccountsDeleteConfirmLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail du compte'**
  String get adminAccountsDeleteConfirmLabel;

  /// No description provided for @adminRoleRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Rôle d\'administration retiré'**
  String get adminRoleRemoved;

  /// No description provided for @adminRoleGiven.
  ///
  /// In fr, this message translates to:
  /// **'Rôle donné : {role}'**
  String adminRoleGiven(String role);

  /// No description provided for @adminAccountsRemoveMfa.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la double authentification'**
  String get adminAccountsRemoveMfa;

  /// No description provided for @adminAccountsRemoveMfaHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour un administrateur qui a perdu son téléphone et ses codes de secours. Il pourra la réactiver.'**
  String get adminAccountsRemoveMfaHint;

  /// No description provided for @adminAccountsMfaRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification retirée'**
  String get adminAccountsMfaRemoved;

  /// No description provided for @adminRoleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rôle d\'administration'**
  String get adminRoleTitle;

  /// No description provided for @adminAccountsDeletionRequested.
  ///
  /// In fr, this message translates to:
  /// **'Suppression demandée'**
  String get adminAccountsDeletionRequested;

  /// No description provided for @adminAccountsMustChange.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe à changer'**
  String get adminAccountsMustChange;

  /// No description provided for @adminAccountsDisabledReason.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé : {reason}'**
  String adminAccountsDisabledReason(String reason);

  /// No description provided for @adminAccountsStructures.
  ///
  /// In fr, this message translates to:
  /// **'Structures'**
  String get adminAccountsStructures;

  /// No description provided for @adminAccountsNoStructure.
  ///
  /// In fr, this message translates to:
  /// **'Aucune structure.'**
  String get adminAccountsNoStructure;

  /// No description provided for @adminAccountsMemberInactive.
  ///
  /// In fr, this message translates to:
  /// **'plus membre'**
  String get adminAccountsMemberInactive;

  /// No description provided for @adminAccountsActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get adminAccountsActivity;

  /// No description provided for @adminAccountsWalletTickets.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun ticket dans « Mes tickets »} =1{1 ticket dans « Mes tickets »} other{{count} tickets dans « Mes tickets »}}'**
  String adminAccountsWalletTickets(int count);

  /// No description provided for @adminAccountsSupport.
  ///
  /// In fr, this message translates to:
  /// **'Demandes au support : {total} (ouvertes : {open})'**
  String adminAccountsSupport(int total, int open);

  /// No description provided for @adminAccountsNoDevice.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appareil connecté.'**
  String get adminAccountsNoDevice;

  /// No description provided for @adminAccountsDeviceSeen.
  ///
  /// In fr, this message translates to:
  /// **'Vu le {date}'**
  String adminAccountsDeviceSeen(String date);

  /// No description provided for @adminAccountsHistory.
  ///
  /// In fr, this message translates to:
  /// **'Actions de la console'**
  String get adminAccountsHistory;

  /// No description provided for @adminAccountsNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action de la console sur ce compte.'**
  String get adminAccountsNoHistory;

  /// No description provided for @adminAccountsReasonValue.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String adminAccountsReasonValue(String reason);

  /// No description provided for @adminRoleMfaHint.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification exigée pour changer un rôle.'**
  String get adminRoleMfaHint;

  /// No description provided for @adminRoleNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun (pas administrateur)'**
  String get adminRoleNone;

  /// No description provided for @adminAccountsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get adminAccountsCreate;

  /// No description provided for @adminAccountsCreateHint.
  ///
  /// In fr, this message translates to:
  /// **'Un mot de passe provisoire est affiché une seule fois ; la personne le changera à sa première connexion. La structure se crée ensuite depuis la fiche.'**
  String get adminAccountsCreateHint;

  /// No description provided for @adminAccountsPhoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get adminAccountsPhoneOptional;

  /// No description provided for @adminAccountsOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la fiche'**
  String get adminAccountsOpen;

  /// No description provided for @consoleSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réglage enregistré'**
  String get consoleSettingsSaved;

  /// No description provided for @consoleSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages et administrateurs'**
  String get consoleSettingsTitle;

  /// No description provided for @consoleMyRole.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle : {role}'**
  String consoleMyRole(String role);

  /// No description provided for @consoleSettingsReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Seul un super administrateur modifie ces réglages.'**
  String get consoleSettingsReadOnly;

  /// No description provided for @consoleSettingNotify.
  ///
  /// In fr, this message translates to:
  /// **'Prévenir la personne par défaut'**
  String get consoleSettingNotify;

  /// No description provided for @consoleSettingNotifyHint.
  ///
  /// In fr, this message translates to:
  /// **'Case « Prévenir la personne » cochée d\'avance dans les actions sur un compte (modifiable à chaque action).'**
  String get consoleSettingNotifyHint;

  /// No description provided for @consoleSettingIssue.
  ///
  /// In fr, this message translates to:
  /// **'Émettre des tickets à la place d\'un promoteur'**
  String get consoleSettingIssue;

  /// No description provided for @consoleSettingIssueHint.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé par défaut. Servira à la gestion des événements de la console.'**
  String get consoleSettingIssueHint;

  /// No description provided for @consoleAdminsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Administrateurs'**
  String get consoleAdminsTitle;

  /// No description provided for @consoleAdminsHint.
  ///
  /// In fr, this message translates to:
  /// **'Le rôle se change depuis la fiche du compte (super administrateur).'**
  String get consoleAdminsHint;

  /// No description provided for @consoleNavSettingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Rôles, administrateurs, prévenir les personnes'**
  String get consoleNavSettingsHint;

  /// No description provided for @consoleHeroRole.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle : {role}'**
  String consoleHeroRole(String role);

  /// No description provided for @forcedPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre mot de passe'**
  String get forcedPasswordTitle;

  /// No description provided for @forcedPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre mot de passe actuel est provisoire. Choisissez le vôtre pour continuer.'**
  String get forcedPasswordSubtitle;

  /// No description provided for @auditAdminConsoleSettingsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de la console modifiés'**
  String get auditAdminConsoleSettingsUpdated;

  /// No description provided for @auditAdminAccountUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Compte modifié par la console'**
  String get auditAdminAccountUpdated;

  /// No description provided for @auditAdminAccountSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Compte déconnecté partout'**
  String get auditAdminAccountSignedOut;

  /// No description provided for @auditAdminAccountDeletionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Demande de suppression annulée'**
  String get auditAdminAccountDeletionCancelled;

  /// No description provided for @auditAdminAccountDeletedNow.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé immédiatement'**
  String get auditAdminAccountDeletedNow;

  /// No description provided for @auditAdminAdminRoleChanged.
  ///
  /// In fr, this message translates to:
  /// **'Rôle d\'administration changé'**
  String get auditAdminAdminRoleChanged;

  /// No description provided for @auditAdminAccountMfaRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Double authentification retirée par la console'**
  String get auditAdminAccountMfaRemoved;

  /// No description provided for @auditAdminAccountCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé par la console'**
  String get auditAdminAccountCreated;

  /// No description provided for @auditAdminAccountPasswordReset.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe provisoire donné'**
  String get auditAdminAccountPasswordReset;

  /// No description provided for @auditAdminAccountEmailChanged.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail changée par la console'**
  String get auditAdminAccountEmailChanged;

  /// No description provided for @adminOrgsErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Élément introuvable : actualisez la fiche.'**
  String get adminOrgsErrorNotFound;

  /// No description provided for @adminOrgsErrorClosed.
  ///
  /// In fr, this message translates to:
  /// **'Cette structure est fermée.'**
  String get adminOrgsErrorClosed;

  /// No description provided for @adminOrgsErrorTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Cette structure est à la corbeille : restaurez-la d\'abord.'**
  String get adminOrgsErrorTrashed;

  /// No description provided for @adminOrgsErrorNotTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Cette structure n\'est pas à la corbeille.'**
  String get adminOrgsErrorNotTrashed;

  /// No description provided for @adminOrgsErrorName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de 2 à 120 caractères.'**
  String get adminOrgsErrorName;

  /// No description provided for @adminOrgsErrorCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville de 2 à 80 caractères.'**
  String get adminOrgsErrorCity;

  /// No description provided for @adminOrgsErrorOwner.
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire ne se modifie pas : transférez d\'abord la structure.'**
  String get adminOrgsErrorOwner;

  /// No description provided for @adminOrgsErrorOwnerInactive.
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire est désactivé ou supprimé.'**
  String get adminOrgsErrorOwnerInactive;

  /// No description provided for @adminOrgsErrorAccountInactive.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est désactivé ou supprimé.'**
  String get adminOrgsErrorAccountInactive;

  /// No description provided for @adminOrgsErrorStructureLimit.
  ///
  /// In fr, this message translates to:
  /// **'Le pack du propriétaire ne permet pas une structure de plus.'**
  String get adminOrgsErrorStructureLimit;

  /// No description provided for @adminOrgsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get adminOrgsTitle;

  /// No description provided for @adminOrgsOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la fiche'**
  String get adminOrgsOpen;

  /// No description provided for @adminOrgsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer une structure'**
  String get adminOrgsCreate;

  /// No description provided for @adminOrgsCreateHint.
  ///
  /// In fr, this message translates to:
  /// **'La structure est créée au pack de son propriétaire, qui en reçoit tous les droits.'**
  String get adminOrgsCreateHint;

  /// No description provided for @adminOrgsOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get adminOrgsOwner;

  /// No description provided for @adminOrgsOwnerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le compte propriétaire.'**
  String get adminOrgsOwnerRequired;

  /// No description provided for @adminOrgsFindAccount.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un compte (nom ou e-mail)'**
  String get adminOrgsFindAccount;

  /// No description provided for @adminOrgsNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte actif trouvé.'**
  String get adminOrgsNoAccount;

  /// No description provided for @adminOrgsChangeAccount.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un autre compte'**
  String get adminOrgsChangeAccount;

  /// No description provided for @adminOrgsPickAccount.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un compte.'**
  String get adminOrgsPickAccount;

  /// No description provided for @adminOrgsName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la structure'**
  String get adminOrgsName;

  /// No description provided for @adminOrgsCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get adminOrgsCity;

  /// No description provided for @adminOrgsCityOptional.
  ///
  /// In fr, this message translates to:
  /// **'Ville (facultatif)'**
  String get adminOrgsCityOptional;

  /// No description provided for @adminOrgsPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get adminOrgsPhone;

  /// No description provided for @adminOrgsContactEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de contact'**
  String get adminOrgsContactEmail;

  /// No description provided for @adminOrgsPublicPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp public'**
  String get adminOrgsPublicPhone;

  /// No description provided for @adminOrgsPhoneValue.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone : {phone}'**
  String adminOrgsPhoneValue(String phone);

  /// No description provided for @adminOrgsPublicPhoneValue.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp public : {phone}'**
  String adminOrgsPublicPhoneValue(String phone);

  /// No description provided for @adminOrgsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get adminOrgsEdit;

  /// No description provided for @adminOrgsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Structure modifiée'**
  String get adminOrgsUpdated;

  /// No description provided for @adminOrgsRemoveLogo.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le logo'**
  String get adminOrgsRemoveLogo;

  /// No description provided for @adminOrgsRemoveLogoHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour un logo inapproprié. La structure pourra en mettre un autre.'**
  String get adminOrgsRemoveLogoHint;

  /// No description provided for @adminOrgsLogoRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Logo retiré'**
  String get adminOrgsLogoRemoved;

  /// No description provided for @adminOrgsAddMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un membre'**
  String get adminOrgsAddMember;

  /// No description provided for @adminOrgsMemberAdded.
  ///
  /// In fr, this message translates to:
  /// **'Membre ajouté'**
  String get adminOrgsMemberAdded;

  /// No description provided for @adminOrgsMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get adminOrgsMembers;

  /// No description provided for @adminOrgsNoMember.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre.'**
  String get adminOrgsNoMember;

  /// No description provided for @adminOrgsMakeManager.
  ///
  /// In fr, this message translates to:
  /// **'Passer gestionnaire'**
  String get adminOrgsMakeManager;

  /// No description provided for @adminOrgsMakeController.
  ///
  /// In fr, this message translates to:
  /// **'Passer contrôleur'**
  String get adminOrgsMakeController;

  /// No description provided for @adminOrgsRoleChanged.
  ///
  /// In fr, this message translates to:
  /// **'Rôle modifié'**
  String get adminOrgsRoleChanged;

  /// No description provided for @adminOrgsTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transférer la propriété'**
  String get adminOrgsTransfer;

  /// No description provided for @adminOrgsTransferHint.
  ///
  /// In fr, this message translates to:
  /// **'{name} devient propriétaire ; l\'actuel propriétaire reste gestionnaire.'**
  String adminOrgsTransferHint(String name);

  /// No description provided for @adminOrgsTransferred.
  ///
  /// In fr, this message translates to:
  /// **'Propriété transférée'**
  String get adminOrgsTransferred;

  /// No description provided for @adminOrgsRemoveMember.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la structure'**
  String get adminOrgsRemoveMember;

  /// No description provided for @adminOrgsMemberRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Membre retiré'**
  String get adminOrgsMemberRemoved;

  /// No description provided for @adminOrgsInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Invitations en cours'**
  String get adminOrgsInvitations;

  /// No description provided for @adminOrgsInvitationUntil.
  ///
  /// In fr, this message translates to:
  /// **'valable jusqu\'au {date}'**
  String adminOrgsInvitationUntil(String date);

  /// No description provided for @adminOrgsRevokeInvitation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'invitation'**
  String get adminOrgsRevokeInvitation;

  /// No description provided for @adminOrgsInvitationRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Invitation annulée'**
  String get adminOrgsInvitationRevoked;

  /// No description provided for @adminOrgsEvents.
  ///
  /// In fr, this message translates to:
  /// **'Derniers événements'**
  String get adminOrgsEvents;

  /// No description provided for @adminOrgsNoEvent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement.'**
  String get adminOrgsNoEvent;

  /// No description provided for @adminOrgsEventTickets.
  ///
  /// In fr, this message translates to:
  /// **'{tickets} tickets, {admitted} entrés'**
  String adminOrgsEventTickets(int tickets, int admitted);

  /// No description provided for @adminOrgsEventsCount.
  ///
  /// In fr, this message translates to:
  /// **'Événements : {total} (à venir : {upcoming})'**
  String adminOrgsEventsCount(int total, int upcoming);

  /// No description provided for @adminOrgsTicketsCount.
  ///
  /// In fr, this message translates to:
  /// **'Tickets émis : {issued} (entrés : {admitted})'**
  String adminOrgsTicketsCount(int issued, int admitted);

  /// No description provided for @adminOrgsInvoicesCount.
  ///
  /// In fr, this message translates to:
  /// **'Factures : {total} (à payer : {due})'**
  String adminOrgsInvoicesCount(int total, int due);

  /// No description provided for @adminOrgsOwnerValue.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire : {name}'**
  String adminOrgsOwnerValue(String name);

  /// No description provided for @adminOrgsNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action de la console sur cette structure.'**
  String get adminOrgsNoHistory;

  /// No description provided for @adminOrgsClosedTag.
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get adminOrgsClosedTag;

  /// No description provided for @adminOrgsTrashedTag.
  ///
  /// In fr, this message translates to:
  /// **'À la corbeille'**
  String get adminOrgsTrashedTag;

  /// No description provided for @adminOrgsPurgedTag.
  ///
  /// In fr, this message translates to:
  /// **'Effacée'**
  String get adminOrgsPurgedTag;

  /// No description provided for @adminOrgsPurgeOn.
  ///
  /// In fr, this message translates to:
  /// **'Effacement automatique le {date}'**
  String adminOrgsPurgeOn(String date);

  /// No description provided for @adminOrgsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get adminOrgsDelete;

  /// No description provided for @adminOrgsDeleteTrashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à la corbeille'**
  String get adminOrgsDeleteTrashTitle;

  /// No description provided for @adminOrgsDeleteTrashHint.
  ///
  /// In fr, this message translates to:
  /// **'Structure sans événement : elle part à la corbeille, restaurable pendant 30 jours, puis effacée.'**
  String get adminOrgsDeleteTrashHint;

  /// No description provided for @adminOrgsDeleteCloseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fermer définitivement'**
  String get adminOrgsDeleteCloseTitle;

  /// No description provided for @adminOrgsDeleteCloseHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette structure a servi : elle est fermée pour toujours (membres sans accès, événements passés archivés, factures gardées). Irréversible.'**
  String get adminOrgsDeleteCloseHint;

  /// No description provided for @adminOrgsPreviewEvents.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun événement à venir à annuler.} =1{1 événement à venir annulé.} other{{count} événements à venir annulés.}}'**
  String adminOrgsPreviewEvents(int count);

  /// No description provided for @adminOrgsPreviewTickets.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun ticket à annuler.} =1{1 ticket non entré annulé.} other{{count} tickets non entrés annulés.}}'**
  String adminOrgsPreviewTickets(int count);

  /// No description provided for @adminOrgsPreviewHolders.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun détenteur à prévenir dans l\'app.} =1{1 détenteur prévenu dans l\'app.} other{{count} détenteurs prévenus dans l\'app.}}'**
  String adminOrgsPreviewHolders(int count);

  /// No description provided for @adminOrgsConfirmName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la structure'**
  String get adminOrgsConfirmName;

  /// No description provided for @adminOrgsConfirmNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour confirmer, saisissez : {name}'**
  String adminOrgsConfirmNameHint(String name);

  /// No description provided for @adminOrgsTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Structure mise à la corbeille'**
  String get adminOrgsTrashed;

  /// No description provided for @adminOrgsClosed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Structure fermée} =1{Structure fermée, 1 ticket annulé} other{Structure fermée, {count} tickets annulés}}'**
  String adminOrgsClosed(int count);

  /// No description provided for @adminOrgsRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get adminOrgsRestore;

  /// No description provided for @adminOrgsRestored.
  ///
  /// In fr, this message translates to:
  /// **'Structure restaurée'**
  String get adminOrgsRestored;

  /// No description provided for @adminOrgsPurge.
  ///
  /// In fr, this message translates to:
  /// **'Effacer maintenant'**
  String get adminOrgsPurge;

  /// No description provided for @adminOrgsPurgeHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, coordonnées, membres et invitations effacés tout de suite. Irréversible.'**
  String get adminOrgsPurgeHint;

  /// No description provided for @adminOrgsPurged.
  ///
  /// In fr, this message translates to:
  /// **'Structure effacée'**
  String get adminOrgsPurged;

  /// No description provided for @consoleTrashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Corbeille'**
  String get consoleTrashTitle;

  /// No description provided for @consoleTrashHint.
  ///
  /// In fr, this message translates to:
  /// **'Structures supprimées, restaurables pendant 30 jours, puis effacées automatiquement.'**
  String get consoleTrashHint;

  /// No description provided for @consoleTrashEmpty.
  ///
  /// In fr, this message translates to:
  /// **'La corbeille est vide.'**
  String get consoleTrashEmpty;

  /// No description provided for @consoleTrashDeletedOn.
  ///
  /// In fr, this message translates to:
  /// **'Supprimée le {date}'**
  String consoleTrashDeletedOn(String date);

  /// No description provided for @consoleTrashDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Effacement imminent} =1{Effacement dans 1 jour} other{Effacement dans {count} jours}}'**
  String consoleTrashDaysLeft(int count);

  /// No description provided for @consoleNavTrashHint.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une structure supprimée'**
  String get consoleNavTrashHint;

  /// No description provided for @auditAdminOrganizationCreated.
  ///
  /// In fr, this message translates to:
  /// **'Structure créée par la console'**
  String get auditAdminOrganizationCreated;

  /// No description provided for @auditAdminOrganizationUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Structure modifiée par la console'**
  String get auditAdminOrganizationUpdated;

  /// No description provided for @auditAdminOrganizationLogoRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Logo retiré par la console'**
  String get auditAdminOrganizationLogoRemoved;

  /// No description provided for @auditAdminOrganizationTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Structure mise à la corbeille'**
  String get auditAdminOrganizationTrashed;

  /// No description provided for @auditAdminOrganizationClosed.
  ///
  /// In fr, this message translates to:
  /// **'Structure fermée définitivement'**
  String get auditAdminOrganizationClosed;

  /// No description provided for @auditAdminOrganizationRestored.
  ///
  /// In fr, this message translates to:
  /// **'Structure restaurée'**
  String get auditAdminOrganizationRestored;

  /// No description provided for @auditAdminOrganizationPurged.
  ///
  /// In fr, this message translates to:
  /// **'Structure effacée'**
  String get auditAdminOrganizationPurged;

  /// No description provided for @auditAdminMemberRoleChanged.
  ///
  /// In fr, this message translates to:
  /// **'Rôle d\'un membre changé par la console'**
  String get auditAdminMemberRoleChanged;

  /// No description provided for @auditAdminMemberRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Membre retiré par la console'**
  String get auditAdminMemberRemoved;

  /// No description provided for @auditAdminInvitationRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Invitation annulée par la console'**
  String get auditAdminInvitationRevoked;

  /// No description provided for @auditAdminEventCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Événement annulé à la fermeture de la structure'**
  String get auditAdminEventCancelled;

  /// No description provided for @adminOrgsErrorConfirmName.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez exactement le nom de la structure.'**
  String get adminOrgsErrorConfirmName;

  /// No description provided for @consoleNavEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get consoleNavEvents;

  /// No description provided for @consoleNavEventsHint.
  ///
  /// In fr, this message translates to:
  /// **'Tous les événements : modifier, état, déplacer'**
  String get consoleNavEventsHint;

  /// No description provided for @consoleNavTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets'**
  String get consoleNavTickets;

  /// No description provided for @consoleNavTicketsHint.
  ///
  /// In fr, this message translates to:
  /// **'Retrouver, annuler, changer le titulaire'**
  String get consoleNavTicketsHint;

  /// No description provided for @adminEventsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get adminEventsTitle;

  /// No description provided for @adminEventsSearch.
  ///
  /// In fr, this message translates to:
  /// **'Titre, ville ou structure'**
  String get adminEventsSearch;

  /// No description provided for @adminEventsAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get adminEventsAll;

  /// No description provided for @adminEventsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get adminEventsEdit;

  /// No description provided for @adminEventsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Événement modifié'**
  String get adminEventsUpdated;

  /// No description provided for @adminEventsFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get adminEventsFieldTitle;

  /// No description provided for @adminEventsFieldVenue.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get adminEventsFieldVenue;

  /// No description provided for @adminEventsFieldAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get adminEventsFieldAddress;

  /// No description provided for @adminEventsFieldTagline.
  ///
  /// In fr, this message translates to:
  /// **'Accroche'**
  String get adminEventsFieldTagline;

  /// No description provided for @adminEventsFieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get adminEventsFieldDescription;

  /// No description provided for @adminEventsFieldCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get adminEventsFieldCapacity;

  /// No description provided for @adminEventsCapacityValue.
  ///
  /// In fr, this message translates to:
  /// **'Capacité : {count}'**
  String adminEventsCapacityValue(int count);

  /// No description provided for @adminEventsDates.
  ///
  /// In fr, this message translates to:
  /// **'Changer les dates'**
  String get adminEventsDates;

  /// No description provided for @adminEventsDatesHint.
  ///
  /// In fr, this message translates to:
  /// **'Heure locale de l\'événement ({zone}).'**
  String adminEventsDatesHint(String zone);

  /// No description provided for @adminEventsStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get adminEventsStart;

  /// No description provided for @adminEventsEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get adminEventsEnd;

  /// No description provided for @adminEventsNext.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get adminEventsNext;

  /// No description provided for @adminEventsMakePublic.
  ///
  /// In fr, this message translates to:
  /// **'Rendre public'**
  String get adminEventsMakePublic;

  /// No description provided for @adminEventsMakePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Rendre privé'**
  String get adminEventsMakePrivate;

  /// No description provided for @adminEventsPublic.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get adminEventsPublic;

  /// No description provided for @adminEventsPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get adminEventsPrivate;

  /// No description provided for @adminEventsBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Retiré du catalogue'**
  String get adminEventsBlocked;

  /// No description provided for @adminEventsStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel état : {status}'**
  String adminEventsStatusChanged(String status);

  /// No description provided for @adminEventsCancelled.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Événement annulé} =1{Événement annulé, 1 ticket annulé} other{Événement annulé, {count} tickets annulés}}'**
  String adminEventsCancelled(int count);

  /// No description provided for @adminEventsMove.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers une autre structure'**
  String get adminEventsMove;

  /// No description provided for @adminEventsMoveTo.
  ///
  /// In fr, this message translates to:
  /// **'Structure de destination'**
  String get adminEventsMoveTo;

  /// No description provided for @adminEventsMoveHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement passe à « {name} » avec ses catégories, portes et tickets ; les affectations de l\'ancienne équipe sont retirées.'**
  String adminEventsMoveHint(String name);

  /// No description provided for @adminEventsMoved.
  ///
  /// In fr, this message translates to:
  /// **'Événement déplacé'**
  String get adminEventsMoved;

  /// No description provided for @adminEventsTrash.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à la corbeille'**
  String get adminEventsTrash;

  /// No description provided for @adminEventsTrashHint.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon sans ticket : il disparaît pour la structure, restaurable pendant 30 jours, puis effacé.'**
  String get adminEventsTrashHint;

  /// No description provided for @adminEventsTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon mis à la corbeille'**
  String get adminEventsTrashed;

  /// No description provided for @adminEventsRestored.
  ///
  /// In fr, this message translates to:
  /// **'Événement restauré'**
  String get adminEventsRestored;

  /// No description provided for @adminEventsIssue.
  ///
  /// In fr, this message translates to:
  /// **'Émettre des tickets'**
  String get adminEventsIssue;

  /// No description provided for @adminEventsIssueHint.
  ///
  /// In fr, this message translates to:
  /// **'Tickets anonymes, en un lot visible du promoteur, qui les envoie comme les autres.'**
  String get adminEventsIssueHint;

  /// No description provided for @adminEventsQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Nombre (1 à 1 000)'**
  String get adminEventsQuantity;

  /// No description provided for @adminEventsIssued.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ticket émis} other{{count} tickets émis}}'**
  String adminEventsIssued(int count);

  /// No description provided for @adminEventsTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tickets'**
  String get adminEventsTickets;

  /// No description provided for @adminEventsTicketsCount.
  ///
  /// In fr, this message translates to:
  /// **'Émis : {total} · valables : {valid} · entrés : {admitted} · annulés : {revoked}'**
  String adminEventsTicketsCount(
    int total,
    int valid,
    int admitted,
    int revoked,
  );

  /// No description provided for @adminEventsDoors.
  ///
  /// In fr, this message translates to:
  /// **'Portes : {doors}'**
  String adminEventsDoors(String doors);

  /// No description provided for @adminEventsNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action de la console.'**
  String get adminEventsNoHistory;

  /// No description provided for @adminEventsErrorTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est à la corbeille : restaurez-le d\'abord.'**
  String get adminEventsErrorTrashed;

  /// No description provided for @adminEventsErrorNotTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement n\'est pas à la corbeille.'**
  String get adminEventsErrorNotTrashed;

  /// No description provided for @adminEventsErrorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Événement clôturé, annulé ou archivé : plus modifiable.'**
  String get adminEventsErrorLocked;

  /// No description provided for @adminEventsErrorTransition.
  ///
  /// In fr, this message translates to:
  /// **'Ce changement d\'état n\'est pas possible.'**
  String get adminEventsErrorTransition;

  /// No description provided for @adminEventsErrorEnded.
  ///
  /// In fr, this message translates to:
  /// **'Événement terminé : impossible de le publier.'**
  String get adminEventsErrorEnded;

  /// No description provided for @adminEventsErrorIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Il faut une photo et une ville pour publier.'**
  String get adminEventsErrorIncomplete;

  /// No description provided for @adminEventsErrorHasTickets.
  ///
  /// In fr, this message translates to:
  /// **'Des tickets existent : retour en brouillon impossible.'**
  String get adminEventsErrorHasTickets;

  /// No description provided for @adminEventsErrorNotTrashable.
  ///
  /// In fr, this message translates to:
  /// **'Seul un brouillon sans ticket va à la corbeille : annulez plutôt l\'événement.'**
  String get adminEventsErrorNotTrashable;

  /// No description provided for @adminEventsErrorSameOrg.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement est déjà dans cette structure.'**
  String get adminEventsErrorSameOrg;

  /// No description provided for @adminEventsErrorInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Événement déjà facturé : déplacement impossible.'**
  String get adminEventsErrorInvoice;

  /// No description provided for @adminEventsErrorOrgInactive.
  ///
  /// In fr, this message translates to:
  /// **'La structure de destination est suspendue.'**
  String get adminEventsErrorOrgInactive;

  /// No description provided for @adminEventsErrorFields.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les champs (titre 2 à 160 caractères, dates, capacité).'**
  String get adminEventsErrorFields;

  /// No description provided for @adminEventsErrorTagline.
  ///
  /// In fr, this message translates to:
  /// **'Accroche de 60 caractères au plus.'**
  String get adminEventsErrorTagline;

  /// No description provided for @adminEventsErrorCapacity.
  ///
  /// In fr, this message translates to:
  /// **'La capacité est inférieure aux tickets déjà émis.'**
  String get adminEventsErrorCapacity;

  /// No description provided for @adminEventsErrorEndBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit suivre le début.'**
  String get adminEventsErrorEndBeforeStart;

  /// No description provided for @adminEventsErrorBilling.
  ///
  /// In fr, this message translates to:
  /// **'Le pack de la structure ne le permet pas.'**
  String get adminEventsErrorBilling;

  /// No description provided for @adminTicketsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get adminTicketsTitle;

  /// No description provided for @adminTicketsSearch.
  ///
  /// In fr, this message translates to:
  /// **'Référence, nom ou téléphone'**
  String get adminTicketsSearch;

  /// No description provided for @adminTicketsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Sur toute la plateforme. Le QR n\'est jamais affiché.'**
  String get adminTicketsSearchHint;

  /// No description provided for @adminTicketsErrorSearch.
  ///
  /// In fr, this message translates to:
  /// **'De 3 à 60 caractères.'**
  String get adminTicketsErrorSearch;

  /// No description provided for @adminTicketsErrorLocked.
  ///
  /// In fr, this message translates to:
  /// **'Seul un ticket valable, pas encore utilisé, peut être modifié ou annulé.'**
  String get adminTicketsErrorLocked;

  /// No description provided for @adminTicketsErrorHolder.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire invalide (nom, téléphone ou e-mail).'**
  String get adminTicketsErrorHolder;

  /// No description provided for @adminTicketsErrorIssueOff.
  ///
  /// In fr, this message translates to:
  /// **'Activez « Émettre des tickets à la place d\'un promoteur » dans les réglages.'**
  String get adminTicketsErrorIssueOff;

  /// No description provided for @adminTicketsErrorQuantity.
  ///
  /// In fr, this message translates to:
  /// **'De 1 à 1 000 tickets.'**
  String get adminTicketsErrorQuantity;

  /// No description provided for @adminTicketsNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° {number}'**
  String adminTicketsNumber(int number);

  /// No description provided for @adminTicketsIssuedAt.
  ///
  /// In fr, this message translates to:
  /// **'Émis le {date}'**
  String adminTicketsIssuedAt(String date);

  /// No description provided for @adminTicketsRevokedAt.
  ///
  /// In fr, this message translates to:
  /// **'Annulé le {date}'**
  String adminTicketsRevokedAt(String date);

  /// No description provided for @adminTicketsEntry.
  ///
  /// In fr, this message translates to:
  /// **'Entré le {date} (porte : {door}) · entrées : {count}'**
  String adminTicketsEntry(String date, String door, int count);

  /// No description provided for @adminTicketsHolder.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire'**
  String get adminTicketsHolder;

  /// No description provided for @adminTicketsNoHolder.
  ///
  /// In fr, this message translates to:
  /// **'Sans titulaire'**
  String get adminTicketsNoHolder;

  /// No description provided for @adminTicketsWallet.
  ///
  /// In fr, this message translates to:
  /// **'Dans « Mes tickets » de {name}'**
  String adminTicketsWallet(String name);

  /// No description provided for @adminTicketsHolderChanged.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire modifié'**
  String get adminTicketsHolderChanged;

  /// No description provided for @adminTicketsRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le ticket'**
  String get adminTicketsRevoke;

  /// No description provided for @adminTicketsRevokeHint.
  ///
  /// In fr, this message translates to:
  /// **'Le ticket ne sera plus accepté à l\'entrée. Irréversible.'**
  String get adminTicketsRevokeHint;

  /// No description provided for @adminTicketsRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Ticket annulé'**
  String get adminTicketsRevoked;

  /// No description provided for @adminTicketsDeliveries.
  ///
  /// In fr, this message translates to:
  /// **'Envois'**
  String get adminTicketsDeliveries;

  /// No description provided for @adminTicketsNoDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Aucun envoi enregistré.'**
  String get adminTicketsNoDelivery;

  /// No description provided for @auditAdminEventUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Événement modifié par la console'**
  String get auditAdminEventUpdated;

  /// No description provided for @auditAdminEventStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'État de l\'événement changé par la console'**
  String get auditAdminEventStatusChanged;

  /// No description provided for @auditAdminEventMoved.
  ///
  /// In fr, this message translates to:
  /// **'Événement déplacé vers une autre structure'**
  String get auditAdminEventMoved;

  /// No description provided for @auditAdminEventTrashed.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon mis à la corbeille'**
  String get auditAdminEventTrashed;

  /// No description provided for @auditAdminEventRestored.
  ///
  /// In fr, this message translates to:
  /// **'Événement restauré'**
  String get auditAdminEventRestored;

  /// No description provided for @auditAdminEventPurged.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon effacé'**
  String get auditAdminEventPurged;

  /// No description provided for @auditAdminTicketRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Ticket annulé par la console'**
  String get auditAdminTicketRevoked;

  /// No description provided for @auditAdminTicketHolderUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire changé par la console'**
  String get auditAdminTicketHolderUpdated;

  /// No description provided for @auditAdminTicketsIssued.
  ///
  /// In fr, this message translates to:
  /// **'Tickets émis par la console'**
  String get auditAdminTicketsIssued;

  /// No description provided for @consoleSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Compte, structure, événement, ticket…'**
  String get consoleSearchHint;

  /// No description provided for @consoleSearchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get consoleSearchTitle;

  /// No description provided for @consoleSearchTooShort.
  ///
  /// In fr, this message translates to:
  /// **'De 2 à 60 caractères.'**
  String get consoleSearchTooShort;

  /// No description provided for @consoleSearchIdle.
  ///
  /// In fr, this message translates to:
  /// **'Cherchez par nom, e-mail, titre, ville ou référence (tickets : 3 caractères au moins).'**
  String get consoleSearchIdle;

  /// No description provided for @consoleSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat.'**
  String get consoleSearchEmpty;

  /// No description provided for @adminMessageSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get adminMessageSend;

  /// No description provided for @adminMessageSent.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Message envoyé à 1 personne} other{Message envoyé à {count} personnes}}'**
  String adminMessageSent(int count);

  /// No description provided for @adminMessageErrorInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Titre de 3 caractères au moins, message obligatoire.'**
  String get adminMessageErrorInvalid;

  /// No description provided for @adminMessageErrorNoRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Aucun destinataire : personne n\'est relié (ticket dans « Mes tickets » ou membre actif).'**
  String get adminMessageErrorNoRecipients;

  /// No description provided for @adminMessageHintAccount.
  ///
  /// In fr, this message translates to:
  /// **'{name} le reçoit dans « Support », avec une notification, et peut répondre.'**
  String adminMessageHintAccount(String name);

  /// No description provided for @adminMessageHintOrganization.
  ///
  /// In fr, this message translates to:
  /// **'Les membres actifs de {name} reçoivent une notification et le voient en bandeau dans l\'app.'**
  String adminMessageHintOrganization(String name);

  /// No description provided for @adminMessageHintEvent.
  ///
  /// In fr, this message translates to:
  /// **'Les détenteurs de « {name} » qui ont ajouté leur ticket à « Mes tickets » reçoivent une notification et le voient en bandeau.'**
  String adminMessageHintEvent(String name);

  /// No description provided for @adminMessageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get adminMessageTitle;

  /// No description provided for @adminMessageBody.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get adminMessageBody;

  /// No description provided for @adminMessageDuration.
  ///
  /// In fr, this message translates to:
  /// **'Bandeau affiché pendant'**
  String get adminMessageDuration;

  /// No description provided for @adminMessageDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour} other{{days} jours}}'**
  String adminMessageDays(int days);

  /// No description provided for @adminMessageSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get adminMessageSubmit;

  /// No description provided for @consoleAuditScope.
  ///
  /// In fr, this message translates to:
  /// **'Filtré : {name}'**
  String consoleAuditScope(String name);

  /// No description provided for @consoleAuditScopeClear.
  ///
  /// In fr, this message translates to:
  /// **'Tout le journal'**
  String get consoleAuditScopeClear;

  /// No description provided for @consoleAuditAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get consoleAuditAdmin;

  /// No description provided for @consoleAuditAdminAny.
  ///
  /// In fr, this message translates to:
  /// **'Tous les administrateurs'**
  String get consoleAuditAdminAny;

  /// No description provided for @auditAdminMessageSent.
  ///
  /// In fr, this message translates to:
  /// **'Message envoyé (console)'**
  String get auditAdminMessageSent;

  /// No description provided for @auditFieldRecipients.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get auditFieldRecipients;

  /// No description provided for @auditValueAudienceAccount.
  ///
  /// In fr, this message translates to:
  /// **'un compte'**
  String get auditValueAudienceAccount;

  /// No description provided for @auditValueAudienceMembers.
  ///
  /// In fr, this message translates to:
  /// **'membres d\'une structure'**
  String get auditValueAudienceMembers;

  /// No description provided for @auditValueAudienceHolders.
  ///
  /// In fr, this message translates to:
  /// **'détenteurs d\'un événement'**
  String get auditValueAudienceHolders;

  /// No description provided for @consoleAnnouncementForOrganization.
  ///
  /// In fr, this message translates to:
  /// **'Réservé aux membres de {name}'**
  String consoleAnnouncementForOrganization(String name);

  /// No description provided for @consoleAnnouncementForEvent.
  ///
  /// In fr, this message translates to:
  /// **'Réservé aux détenteurs de « {name} »'**
  String consoleAnnouncementForEvent(String name);

  /// No description provided for @maintenanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance en cours'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceWritesBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Les modifications sont suspendues pour le moment ; les tickets restent valables et le contrôle à l\'entrée continue.'**
  String get maintenanceWritesBlocked;

  /// No description provided for @authErrorSignupsClosed.
  ///
  /// In fr, this message translates to:
  /// **'Les inscriptions sont fermées : il faut un code d\'invitation valable.'**
  String get authErrorSignupsClosed;

  /// No description provided for @signUpClosedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions sur invitation'**
  String get signUpClosedTitle;

  /// No description provided for @signUpClosedBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour le moment, un compte se crée seulement avec le code d\'invitation d\'une structure.'**
  String get signUpClosedBody;

  /// No description provided for @signUpCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation obligatoire.'**
  String get signUpCodeRequired;

  /// No description provided for @consolePlatformTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get consolePlatformTitle;

  /// No description provided for @consoleMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance'**
  String get consoleMaintenance;

  /// No description provided for @consoleMaintenanceHint.
  ///
  /// In fr, this message translates to:
  /// **'Bandeau « Maintenance en cours » pour tous, avec votre message.'**
  String get consoleMaintenanceHint;

  /// No description provided for @consoleMaintenanceMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message (facultatif)'**
  String get consoleMaintenanceMessage;

  /// No description provided for @consoleMaintenanceWrites.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer les modifications'**
  String get consoleMaintenanceWrites;

  /// No description provided for @consoleMaintenanceWritesHint.
  ///
  /// In fr, this message translates to:
  /// **'Sauf pour les administrateurs. Le contrôle à l\'entrée, « Mes tickets » et le support continuent.'**
  String get consoleMaintenanceWritesHint;

  /// No description provided for @consoleSignupsOpen.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions ouvertes'**
  String get consoleSignupsOpen;

  /// No description provided for @consoleSignupsOpenHint.
  ///
  /// In fr, this message translates to:
  /// **'Fermées : un compte se crée seulement avec un code d\'invitation, ou depuis la console.'**
  String get consoleSignupsOpenHint;

  /// No description provided for @consolePlatformSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get consolePlatformSave;

  /// No description provided for @consoleNavExports.
  ///
  /// In fr, this message translates to:
  /// **'Exports'**
  String get consoleNavExports;

  /// No description provided for @consoleNavExportsHint.
  ///
  /// In fr, this message translates to:
  /// **'Comptes, structures, événements, factures, journal pour Excel'**
  String get consoleNavExportsHint;

  /// No description provided for @consoleExportsHint.
  ///
  /// In fr, this message translates to:
  /// **'Fichier CSV pour Excel (50 000 lignes au plus, les plus récentes). Chaque export est inscrit au journal.'**
  String get consoleExportsHint;

  /// No description provided for @consoleExportInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get consoleExportInvoices;

  /// No description provided for @consoleExportForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne permet pas cet export.'**
  String get consoleExportForbidden;

  /// No description provided for @consoleExportDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ligne exportée} other{{count} lignes exportées}}'**
  String consoleExportDone(int count);

  /// No description provided for @consoleExportTruncated.
  ///
  /// In fr, this message translates to:
  /// **'{count} lignes exportées (les plus récentes seulement)'**
  String consoleExportTruncated(int count);

  /// No description provided for @exportColId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get exportColId;

  /// No description provided for @exportColName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get exportColName;

  /// No description provided for @exportColEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get exportColEmail;

  /// No description provided for @exportColPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get exportColPhone;

  /// No description provided for @exportColStatus.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get exportColStatus;

  /// No description provided for @exportColAdminRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle d\'administration'**
  String get exportColAdminRole;

  /// No description provided for @exportColCreatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Créé le'**
  String get exportColCreatedAt;

  /// No description provided for @exportColLastSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Dernière connexion'**
  String get exportColLastSignIn;

  /// No description provided for @exportColDeletionRequested.
  ///
  /// In fr, this message translates to:
  /// **'Suppression demandée le'**
  String get exportColDeletionRequested;

  /// No description provided for @exportColDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé'**
  String get exportColDeleted;

  /// No description provided for @exportColCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get exportColCity;

  /// No description provided for @exportColClosedAt.
  ///
  /// In fr, this message translates to:
  /// **'Fermée le'**
  String get exportColClosedAt;

  /// No description provided for @exportColTrashedAt.
  ///
  /// In fr, this message translates to:
  /// **'À la corbeille le'**
  String get exportColTrashedAt;

  /// No description provided for @exportColOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get exportColOwner;

  /// No description provided for @exportColOwnerEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail du propriétaire'**
  String get exportColOwnerEmail;

  /// No description provided for @exportColMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get exportColMembers;

  /// No description provided for @exportColTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get exportColTitle;

  /// No description provided for @exportColOrganization.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get exportColOrganization;

  /// No description provided for @exportColStartsAt.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get exportColStartsAt;

  /// No description provided for @exportColEndsAt.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get exportColEndsAt;

  /// No description provided for @exportColPublic.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get exportColPublic;

  /// No description provided for @exportColAdmitted.
  ///
  /// In fr, this message translates to:
  /// **'Entrés'**
  String get exportColAdmitted;

  /// No description provided for @exportColIssuedAt.
  ///
  /// In fr, this message translates to:
  /// **'Émise le'**
  String get exportColIssuedAt;

  /// No description provided for @exportColDueAt.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get exportColDueAt;

  /// No description provided for @exportColAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant (FCFA)'**
  String get exportColAmount;

  /// No description provided for @exportColEntries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get exportColEntries;

  /// No description provided for @exportColBillableEntries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées facturées'**
  String get exportColBillableEntries;

  /// No description provided for @exportColAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get exportColAccount;

  /// No description provided for @exportColAccountEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail du compte'**
  String get exportColAccountEmail;

  /// No description provided for @exportColEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get exportColEvent;

  /// No description provided for @exportColPaidAt.
  ///
  /// In fr, this message translates to:
  /// **'Payée le'**
  String get exportColPaidAt;

  /// No description provided for @exportColAction.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get exportColAction;

  /// No description provided for @exportColActor.
  ///
  /// In fr, this message translates to:
  /// **'Auteur'**
  String get exportColActor;

  /// No description provided for @exportColResourceType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get exportColResourceType;

  /// No description provided for @exportColResourceId.
  ///
  /// In fr, this message translates to:
  /// **'Élément'**
  String get exportColResourceId;

  /// No description provided for @exportColDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get exportColDetails;

  /// No description provided for @auditAdminPlatformStatusUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme : maintenance ou inscriptions modifiées'**
  String get auditAdminPlatformStatusUpdated;

  /// No description provided for @auditAdminExport.
  ///
  /// In fr, this message translates to:
  /// **'Export (console)'**
  String get auditAdminExport;

  /// No description provided for @auditFieldMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance'**
  String get auditFieldMaintenance;

  /// No description provided for @auditFieldBlockWrites.
  ///
  /// In fr, this message translates to:
  /// **'Modifications bloquées'**
  String get auditFieldBlockWrites;

  /// No description provided for @auditFieldSignupsOpen.
  ///
  /// In fr, this message translates to:
  /// **'Inscriptions ouvertes'**
  String get auditFieldSignupsOpen;

  /// No description provided for @auditFieldExport.
  ///
  /// In fr, this message translates to:
  /// **'Export'**
  String get auditFieldExport;

  /// No description provided for @exploreOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne, mis à jour {ago}'**
  String exploreOffline(String ago);

  /// No description provided for @exploreOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'La liste se mettra à jour dès le retour du réseau.'**
  String get exploreOfflineBody;

  /// No description provided for @timeAgoNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeAgoNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {minutes} min'**
  String timeAgoMinutes(int minutes);

  /// No description provided for @timeAgoHours.
  ///
  /// In fr, this message translates to:
  /// **'il y a {hours} h'**
  String timeAgoHours(int hours);

  /// No description provided for @timeAgoDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{il y a 1 jour} other{il y a {days} jours}}'**
  String timeAgoDays(int days);

  /// No description provided for @closedOrgsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Structures fermées'**
  String get closedOrgsTitle;

  /// No description provided for @closedOrgsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consultation seule : rien ne peut être modifié.'**
  String get closedOrgsSubtitle;

  /// No description provided for @closedOrgsEntrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Revoir les événements et rapports d\'une structure fermée'**
  String get closedOrgsEntrySubtitle;

  /// No description provided for @closedOrgsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune structure fermée.'**
  String get closedOrgsEmpty;

  /// No description provided for @closedOrgsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifiez la connexion.'**
  String get closedOrgsLoadError;

  /// No description provided for @closedOrgClosedOn.
  ///
  /// In fr, this message translates to:
  /// **'Fermée le {date}'**
  String closedOrgClosedOn(String date);

  /// No description provided for @closedOrgEventCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun événement} =1{1 événement} other{{count} événements}}'**
  String closedOrgEventCount(int count);

  /// No description provided for @closedOrgReadOnlyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Structure fermée le {date} : consultation seule'**
  String closedOrgReadOnlyTitle(String date);

  /// No description provided for @closedOrgReadOnlyBody.
  ///
  /// In fr, this message translates to:
  /// **'Revoyez vos événements et exportez leurs rapports (bilan PDF, liste des tickets). Rien ne peut être créé ni modifié.'**
  String get closedOrgReadOnlyBody;

  /// No description provided for @closedOrgInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get closedOrgInvoices;

  /// No description provided for @closedOrgInvoicesHint.
  ///
  /// In fr, this message translates to:
  /// **'Factures et paiements de votre compte'**
  String get closedOrgInvoicesHint;

  /// No description provided for @closedOrgEventsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get closedOrgEventsTitle;

  /// No description provided for @closedOrgEventsHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un événement pour exporter son bilan ou la liste de ses tickets.'**
  String get closedOrgEventsHint;

  /// No description provided for @closedOrgEventCounts.
  ///
  /// In fr, this message translates to:
  /// **'Tickets : {issued} · Entrés : {admitted} · Annulés : {revoked}'**
  String closedOrgEventCounts(int issued, int admitted, int revoked);

  /// No description provided for @closedOrgNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette structure n\'est plus consultable.'**
  String get closedOrgNotFound;

  /// No description provided for @publicOrgSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir la structure et ses événements'**
  String get publicOrgSeeAll;

  /// No description provided for @publicOrgSince.
  ///
  /// In fr, this message translates to:
  /// **'Sur Tikéo depuis {year}'**
  String publicOrgSince(String year);

  /// No description provided for @publicOrgUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get publicOrgUpcoming;

  /// No description provided for @publicOrgPast.
  ///
  /// In fr, this message translates to:
  /// **'Déjà organisés'**
  String get publicOrgPast;

  /// No description provided for @publicOrgEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements à venir'**
  String get publicOrgEvents;

  /// No description provided for @publicOrgNoEvents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement à venir pour l\'instant.'**
  String get publicOrgNoEvents;

  /// No description provided for @publicOrgContact.
  ///
  /// In fr, this message translates to:
  /// **'Contacter sur WhatsApp'**
  String get publicOrgContact;

  /// No description provided for @publicOrgWhatsAppMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je vous contacte après avoir vu {organization} sur Tikéo.'**
  String publicOrgWhatsAppMessage(String organization);

  /// No description provided for @publicOrgNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette structure n\'est plus visible sur Tikéo.'**
  String get publicOrgNotFound;

  /// No description provided for @publicOrgTitle.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get publicOrgTitle;

  /// No description provided for @publicEventAddCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à mon agenda'**
  String get publicEventAddCalendar;

  /// No description provided for @publicEventCalendarFailed.
  ///
  /// In fr, this message translates to:
  /// **'Aucun agenda trouvé sur ce téléphone.'**
  String get publicEventCalendarFailed;

  /// No description provided for @publicEventDirections.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get publicEventDirections;

  /// No description provided for @publicEventDirectionsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la carte.'**
  String get publicEventDirectionsFailed;

  /// No description provided for @publicEventSameOrganizer.
  ///
  /// In fr, this message translates to:
  /// **'Du même organisateur'**
  String get publicEventSameOrganizer;

  /// No description provided for @publicEventSeeAllOrganizer.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get publicEventSeeAllOrganizer;

  /// No description provided for @walletSeeEvent.
  ///
  /// In fr, this message translates to:
  /// **'Voir la fiche de l\'événement'**
  String get walletSeeEvent;

  /// No description provided for @walletSeeEventHint.
  ///
  /// In fr, this message translates to:
  /// **'Lieu, itinéraire, autres dates'**
  String get walletSeeEventHint;

  /// No description provided for @walletSeeOrganizer.
  ///
  /// In fr, this message translates to:
  /// **'Organisé par {name}'**
  String walletSeeOrganizer(String name);

  /// No description provided for @walletSeeOrganizerHint.
  ///
  /// In fr, this message translates to:
  /// **'Ses autres événements et son contact'**
  String get walletSeeOrganizerHint;

  /// No description provided for @orgErrorLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien invalide : adresse de la page ou nom du compte (ex. @faso.live).'**
  String get orgErrorLink;

  /// No description provided for @orgErrorDescription.
  ///
  /// In fr, this message translates to:
  /// **'La présentation fait 600 caractères au plus.'**
  String get orgErrorDescription;

  /// No description provided for @orgSocialHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de la page ou @nom du compte'**
  String get orgSocialHint;

  /// No description provided for @orgPublicPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Page publique'**
  String get orgPublicPageTitle;

  /// No description provided for @orgPublicPageHelp.
  ///
  /// In fr, this message translates to:
  /// **'Visible par tous depuis la fiche de vos événements.'**
  String get orgPublicPageHelp;

  /// No description provided for @orgDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Présentation'**
  String get orgDescriptionLabel;

  /// No description provided for @orgDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Qui êtes-vous ? Quels événements organisez-vous ?'**
  String get orgDescriptionHint;

  /// No description provided for @orgSeePublicPage.
  ///
  /// In fr, this message translates to:
  /// **'Voir ma page publique'**
  String get orgSeePublicPage;

  /// No description provided for @publicOrgAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos de la structure'**
  String get publicOrgAbout;

  /// No description provided for @publicOrgFollow.
  ///
  /// In fr, this message translates to:
  /// **'Suivre'**
  String get publicOrgFollow;

  /// No description provided for @publicOrgFollowing.
  ///
  /// In fr, this message translates to:
  /// **'Suivie'**
  String get publicOrgFollowing;

  /// No description provided for @publicOrgFollowers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun abonné} =1{1 abonné} other{{count} abonnés}}'**
  String publicOrgFollowers(int count);

  /// No description provided for @publicOrgFollowedToast.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez prévenu de ses nouveaux événements.'**
  String get publicOrgFollowedToast;

  /// No description provided for @publicOrgFollowFailed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible. Vérifiez la connexion.'**
  String get publicOrgFollowFailed;

  /// No description provided for @publicOrgFollowLimit.
  ///
  /// In fr, this message translates to:
  /// **'Vous suivez déjà 300 structures.'**
  String get publicOrgFollowLimit;

  /// No description provided for @publicOrgShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager la structure'**
  String get publicOrgShare;

  /// No description provided for @publicOrgShareText.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez {organization} sur Tikéo.'**
  String publicOrgShareText(String organization);

  /// No description provided for @publicOrgShareUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun événement à venir pour l\'instant.} =1{1 événement à venir :} other{{count} événements à venir :}}'**
  String publicOrgShareUpcoming(int count);

  /// No description provided for @publicOrgShareBanner.
  ///
  /// In fr, this message translates to:
  /// **'Suivez-les sur l\'application Tikéo'**
  String get publicOrgShareBanner;

  /// No description provided for @followedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Structures suivies'**
  String get followedTitle;

  /// No description provided for @followedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Leurs nouveaux événements vous sont signalés.'**
  String get followedSubtitle;

  /// No description provided for @followedEntry.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 structure suivie} other{{count} structures suivies}}'**
  String followedEntry(int count);

  /// No description provided for @followedEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne suivez aucune structure. Touchez « Suivre » sur la page d\'un organisateur.'**
  String get followedEmpty;

  /// No description provided for @followedUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun événement à venir} =1{1 événement à venir} other{{count} événements à venir}}'**
  String followedUpcoming(int count);

  /// No description provided for @memberDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membre de l\'équipe'**
  String get memberDetailTitle;

  /// No description provided for @memberValidated.
  ///
  /// In fr, this message translates to:
  /// **'Entrées validées'**
  String get memberValidated;

  /// No description provided for @memberValidated30d.
  ///
  /// In fr, this message translates to:
  /// **'Sur 30 jours'**
  String get memberValidated30d;

  /// No description provided for @memberEventsWorked.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get memberEventsWorked;

  /// No description provided for @memberLastValidated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière entrée validée : {when}'**
  String memberLastValidated(String when);

  /// No description provided for @memberNeverValidated.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée validée pour l\'instant.'**
  String get memberNeverValidated;

  /// No description provided for @memberAssignmentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Affectations à venir'**
  String get memberAssignmentsTitle;

  /// No description provided for @memberNoAssignments.
  ///
  /// In fr, this message translates to:
  /// **'Aucune affectation à un événement à venir.'**
  String get memberNoAssignments;

  /// No description provided for @memberAllDoors.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les portes'**
  String get memberAllDoors;

  /// No description provided for @memberEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le rôle ou l\'accès'**
  String get memberEdit;

  /// No description provided for @memberActivityError.
  ///
  /// In fr, this message translates to:
  /// **'Activité indisponible. Vérifiez la connexion.'**
  String get memberActivityError;

  /// No description provided for @exploreFollowed.
  ///
  /// In fr, this message translates to:
  /// **'De vos structures suivies'**
  String get exploreFollowed;

  /// No description provided for @exploreFollowedSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get exploreFollowedSeeAll;

  /// No description provided for @walletCountdownDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Dans 1 jour} other{Dans {count} jours}}'**
  String walletCountdownDays(int count);

  /// No description provided for @walletCountdownTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain à {time}'**
  String walletCountdownTomorrow(String time);

  /// No description provided for @walletCountdownToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui à {time}'**
  String walletCountdownToday(String time);

  /// No description provided for @walletCountdownLive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get walletCountdownLive;

  /// No description provided for @walletCountdownEnded.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get walletCountdownEnded;

  /// No description provided for @walletShareEvent.
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'événement'**
  String get walletShareEvent;

  /// No description provided for @walletShareEventHint.
  ///
  /// In fr, this message translates to:
  /// **'Une image ou un texte pour inviter vos proches'**
  String get walletShareEventHint;

  /// No description provided for @walletShareEventFailed.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de l\'événement indisponible. Réessayez.'**
  String get walletShareEventFailed;

  /// No description provided for @flagEventAction.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cet événement'**
  String get flagEventAction;

  /// No description provided for @flagOrganizationAction.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cette structure'**
  String get flagOrganizationAction;

  /// No description provided for @flagEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cet événement'**
  String get flagEventTitle;

  /// No description provided for @flagOrganizationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cette structure'**
  String get flagOrganizationTitle;

  /// No description provided for @flagIntro.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe Tikéo examine chaque signalement. La structure ne sait pas qui l\'a signalée.'**
  String get flagIntro;

  /// No description provided for @flagReasonMisleading.
  ///
  /// In fr, this message translates to:
  /// **'Informations trompeuses'**
  String get flagReasonMisleading;

  /// No description provided for @flagReasonScam.
  ///
  /// In fr, this message translates to:
  /// **'Arnaque ou faux événement'**
  String get flagReasonScam;

  /// No description provided for @flagReasonOffensive.
  ///
  /// In fr, this message translates to:
  /// **'Contenu choquant ou haineux'**
  String get flagReasonOffensive;

  /// No description provided for @flagReasonDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Doublon'**
  String get flagReasonDuplicate;

  /// No description provided for @flagReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre raison'**
  String get flagReasonOther;

  /// No description provided for @flagCommentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Précisez (facultatif)'**
  String get flagCommentLabel;

  /// No description provided for @flagCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'N\'écrivez pas de numéro ni d\'adresse personnelle.'**
  String get flagCommentHint;

  /// No description provided for @flagSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get flagSubmit;

  /// No description provided for @flagSent.
  ///
  /// In fr, this message translates to:
  /// **'Merci, votre signalement a été transmis à l\'équipe Tikéo.'**
  String get flagSent;

  /// No description provided for @flagAlready.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà signalé ce contenu ; il est en cours d\'examen.'**
  String get flagAlready;

  /// No description provided for @flagErrorRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de signalements aujourd\'hui. Réessayez demain.'**
  String get flagErrorRateLimited;

  /// No description provided for @flagErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu n\'est plus en ligne.'**
  String get flagErrorNotFound;

  /// No description provided for @flagErrorComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire trop long (300 caractères au plus).'**
  String get flagErrorComment;

  /// No description provided for @flagErrorFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le signalement n\'a pas pu être envoyé. Réessayez.'**
  String get flagErrorFailed;

  /// No description provided for @consoleReportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signalements'**
  String get consoleReportsTitle;

  /// No description provided for @consoleNavReportsHint.
  ///
  /// In fr, this message translates to:
  /// **'Contenus signalés par les utilisateurs'**
  String get consoleNavReportsHint;

  /// No description provided for @consoleReportsOpen.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{À traiter} =1{1 à traiter} other{{count} à traiter}}'**
  String consoleReportsOpen(int count);

  /// No description provided for @consoleReportsHandled.
  ///
  /// In fr, this message translates to:
  /// **'Traités'**
  String get consoleReportsHandled;

  /// No description provided for @consoleReportsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 signalement} other{{count} signalements}}'**
  String consoleReportsCount(int count);

  /// No description provided for @consoleReportsKindOrg.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get consoleReportsKindOrg;

  /// No description provided for @consoleReportsLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernier signalement le {date}'**
  String consoleReportsLast(String date);

  /// No description provided for @consoleReportsHandledAt.
  ///
  /// In fr, this message translates to:
  /// **'Traité le {date} : {outcome}'**
  String consoleReportsHandledAt(String date, String outcome);

  /// No description provided for @consoleReportsRemoved.
  ///
  /// In fr, this message translates to:
  /// **'retiré du catalogue'**
  String get consoleReportsRemoved;

  /// No description provided for @consoleReportsSuspended.
  ///
  /// In fr, this message translates to:
  /// **'structure suspendue'**
  String get consoleReportsSuspended;

  /// No description provided for @consoleReportsDismissed.
  ///
  /// In fr, this message translates to:
  /// **'classé sans suite'**
  String get consoleReportsDismissed;

  /// No description provided for @consoleReportsOpenFiche.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la fiche'**
  String get consoleReportsOpenFiche;

  /// No description provided for @consoleReportsDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Classer sans suite'**
  String get consoleReportsDismiss;

  /// No description provided for @consoleReportsDismissHint.
  ///
  /// In fr, this message translates to:
  /// **'Les signalements de ce contenu sont classés ; rien ne change pour la structure. Indiquez le motif (gardé dans le journal de la console).'**
  String get consoleReportsDismissHint;

  /// No description provided for @consoleReportsRemoveEvent.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du catalogue'**
  String get consoleReportsRemoveEvent;

  /// No description provided for @consoleReportsRemoveEventHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'événement quitte le catalogue public et ses signalements sont traités. Le promoteur voit le motif du retrait.'**
  String get consoleReportsRemoveEventHint;

  /// No description provided for @consoleReportsSuspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre la structure'**
  String get consoleReportsSuspend;

  /// No description provided for @consoleReportsSuspendHint.
  ///
  /// In fr, this message translates to:
  /// **'La structure est suspendue (ses membres ne peuvent plus rien modifier) et ses signalements sont traités.'**
  String get consoleReportsSuspendHint;

  /// No description provided for @consoleReportsResolved.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 signalement traité} other{{count} signalements traités}}'**
  String consoleReportsResolved(int count);

  /// No description provided for @auditAdminReportsActioned.
  ///
  /// In fr, this message translates to:
  /// **'Signalements traités : contenu retiré (console)'**
  String get auditAdminReportsActioned;

  /// No description provided for @auditAdminReportsDismissed.
  ///
  /// In fr, this message translates to:
  /// **'Signalements classés sans suite (console)'**
  String get auditAdminReportsDismissed;

  /// No description provided for @auditFieldReports.
  ///
  /// In fr, this message translates to:
  /// **'Signalements'**
  String get auditFieldReports;

  /// No description provided for @audienceViewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vues de la fiche publique'**
  String get audienceViewsTitle;

  /// No description provided for @audienceViewsSummary.
  ///
  /// In fr, this message translates to:
  /// **'{recent} sur 7 jours · {total} au total'**
  String audienceViewsSummary(int recent, int total);

  /// No description provided for @audienceViewsHint.
  ///
  /// In fr, this message translates to:
  /// **'Une vue par téléphone et par jour, sur les 30 derniers jours.'**
  String get audienceViewsHint;

  /// No description provided for @audienceViewsPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Événement privé : sa fiche n\'est pas au catalogue, aucune vue n\'est comptée.'**
  String get audienceViewsPrivate;

  /// No description provided for @audienceFollowersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnés de la structure'**
  String get audienceFollowersTitle;

  /// No description provided for @audienceFollowersSummary.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun abonné} =1{1 abonné} other{{count} abonnés}} · +{recent} sur 30 jours'**
  String audienceFollowersSummary(int count, int recent);

  /// No description provided for @audienceFollowersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun abonné} =1{1 abonné} other{{count} abonnés}}'**
  String audienceFollowersCount(int count);

  /// No description provided for @audienceFollowersNew.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun nouvel abonné sur 30 jours} =1{1 nouvel abonné sur 30 jours} other{{count} nouveaux abonnés sur 30 jours}}'**
  String audienceFollowersNew(int count);

  /// No description provided for @audienceFollowersHint.
  ///
  /// In fr, this message translates to:
  /// **'Arrivées par jour des abonnés actuels. Ils sont prévenus de vos nouveaux événements publics.'**
  String get audienceFollowersHint;

  /// No description provided for @audienceLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres indisponibles. Réessayez plus tard.'**
  String get audienceLoadError;

  /// No description provided for @audienceOpenPublicPage.
  ///
  /// In fr, this message translates to:
  /// **'Voir la page publique'**
  String get audienceOpenPublicPage;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
