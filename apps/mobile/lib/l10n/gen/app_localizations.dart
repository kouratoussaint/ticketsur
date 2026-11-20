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
  /// **'Chargement de vos structures…'**
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
  /// **'Une ligne par participant. Colonnes reconnues : nom (ou prénom et nom), téléphone, e-mail et catégorie. Fichier Excel (.xlsx) ou CSV, 500 lignes au plus.'**
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
  /// **'500 tickets au plus par import : découpez la liste en plusieurs fichiers.'**
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

  /// No description provided for @welcomeDiscoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les événements'**
  String get welcomeDiscoverTitle;

  /// No description provided for @welcomeDiscoverBody.
  ///
  /// In fr, this message translates to:
  /// **'Concerts, conférences, galas, sport… partout au Burkina, sans compte.'**
  String get welcomeDiscoverBody;

  /// No description provided for @welcomeDiscoverAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les événements'**
  String get welcomeDiscoverAll;

  /// No description provided for @welcomeDiscoverEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Les premiers événements publics arrivent bientôt.'**
  String get welcomeDiscoverEmpty;

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
  /// **'Apparence, sons, stockage, version, mentions légales'**
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
