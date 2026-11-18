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

  @override
  String get orgLoading => 'Chargement de vos organisations…';

  @override
  String get orgLoadError => 'Impossible de charger vos organisations.';

  @override
  String get orgRetry => 'Réessayer';

  @override
  String get orgCreateTitle => 'Créer votre organisation';

  @override
  String get orgCreateIntro =>
      'Votre organisation regroupe vos événements, vos billets et votre équipe. Vous en serez le propriétaire.';

  @override
  String get orgCreateAnotherTitle => 'Nouvelle organisation';

  @override
  String get orgNameLabel => 'Nom de l\'organisation';

  @override
  String get orgNameHint => 'Ex. : Festival des Nuits Sacrées';

  @override
  String get orgNameRequired => 'Saisissez un nom d\'au moins 2 caractères';

  @override
  String get orgCreateSubmit => 'Créer l\'organisation';

  @override
  String get orgErrorInvalidName => 'Nom invalide : entre 2 et 120 caractères.';

  @override
  String get orgErrorLimit => 'Vous avez atteint la limite de 5 organisations.';

  @override
  String orgCreated(String name) {
    return 'Organisation « $name » créée';
  }

  @override
  String get orgSwitchTitle => 'Changer d\'organisation';

  @override
  String get orgSwitchAction => 'Changer';

  @override
  String get orgCreateAction => 'Créer une organisation';

  @override
  String get orgActiveLabel => 'Organisation';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleManager => 'Gestionnaire';

  @override
  String get roleController => 'Contrôleur';

  @override
  String get eventsEmptyTitle => 'Aucun événement pour l\'instant';

  @override
  String get eventsEmptyBody =>
      'Créez votre premier événement : titre, lieu, dates et fuseau horaire. Il reste en brouillon tant que vous ne le publiez pas.';

  @override
  String get eventsEmptyControllerBody =>
      'Les événements auxquels vous êtes affecté apparaîtront ici.';

  @override
  String get eventsFilterEmpty => 'Aucun événement dans cette catégorie.';

  @override
  String get eventsNew => 'Nouvel événement';

  @override
  String get eventsLoadError => 'Impossible de charger les événements.';

  @override
  String get eventsFilterActive => 'À venir';

  @override
  String get eventsFilterDrafts => 'Brouillons';

  @override
  String get eventsFilterPublished => 'Publiés';

  @override
  String get eventsFilterDone => 'Terminés';

  @override
  String get eventsFilterAll => 'Tous';

  @override
  String get eventStatusDraft => 'Brouillon';

  @override
  String get eventStatusPublished => 'Publié';

  @override
  String get eventStatusInProgress => 'En cours';

  @override
  String get eventStatusClosed => 'Clôturé';

  @override
  String get eventStatusArchived => 'Archivé';

  @override
  String get eventStatusCancelled => 'Annulé';

  @override
  String get eventFormCreateTitle => 'Nouvel événement';

  @override
  String get eventFormEditTitle => 'Modifier l\'événement';

  @override
  String get eventTitleLabel => 'Titre';

  @override
  String get eventTitleHint => 'Ex. Concert de la Saint-Sylvestre';

  @override
  String get eventVenueLabel => 'Lieu (facultatif)';

  @override
  String get eventVenueHint => 'Ex. Palais des sports, Ouaga 2000';

  @override
  String get eventTimezoneLabel => 'Fuseau horaire';

  @override
  String get eventTimezoneHelp =>
      'Les heures sont saisies et affichées dans ce fuseau.';

  @override
  String get eventStartsLabel => 'Début';

  @override
  String get eventEndsLabel => 'Fin';

  @override
  String get eventDateLabel => 'Date';

  @override
  String get eventTimeLabel => 'Heure';

  @override
  String get eventCapacityLabel => 'Capacité (facultatif)';

  @override
  String get eventCapacityHint => 'Nombre maximal de participants';

  @override
  String get eventFormSubmitCreate => 'Créer le brouillon';

  @override
  String get eventFormSubmitSave => 'Enregistrer';

  @override
  String eventCreated(String title) {
    return '« $title » créé en brouillon';
  }

  @override
  String get eventSaved => 'Modifications enregistrées';

  @override
  String get eventErrorTitle => 'Saisissez un titre de 2 à 160 caractères.';

  @override
  String get eventErrorVenue => 'Le lieu ne doit pas dépasser 160 caractères.';

  @override
  String get eventErrorDates =>
      'La fin doit suivre le début, sur 31 jours au plus.';

  @override
  String get eventErrorTimezone => 'Fuseau horaire inconnu.';

  @override
  String get eventErrorCapacity =>
      'Saisissez une capacité entre 1 et 1 000 000.';

  @override
  String get eventErrorCapacityBelowIssued =>
      'La capacité ne peut pas être inférieure au nombre de billets déjà émis.';

  @override
  String get eventErrorLocked => 'Cet événement ne peut plus être modifié.';

  @override
  String get eventErrorInvalidTransition =>
      'Ce changement de statut n\'est pas permis.';

  @override
  String get eventErrorHasTickets =>
      'Des billets ont été émis : impossible de repasser en brouillon.';

  @override
  String get eventErrorAlreadyEnded =>
      'Cet événement est déjà terminé : il ne peut pas être publié.';

  @override
  String get eventErrorNotFound =>
      'Événement introuvable ou droits insuffisants.';

  @override
  String get eventErrorNetwork =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get eventErrorUnknown =>
      'Une erreur inattendue est survenue. Réessayez.';

  @override
  String get eventDetailDates => 'Dates';

  @override
  String get eventDetailVenue => 'Lieu';

  @override
  String get eventDetailCapacity => 'Capacité';

  @override
  String eventCapacityValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get eventNoCapacity => 'Non limitée';

  @override
  String get eventNoVenue => 'Non précisé';

  @override
  String eventTimeZoneLine(String zone, String offset) {
    return '$zone ($offset)';
  }

  @override
  String get eventEdit => 'Modifier';

  @override
  String get eventLifecycleTitle => 'Statut';

  @override
  String get eventLifecycleDraft =>
      'Brouillon : invisible des contrôleurs. Publiez-le pour émettre des billets et ouvrir le contrôle.';

  @override
  String get eventLifecyclePublished =>
      'Publié : le contrôle est possible de 3 h avant le début à 6 h après la fin.';

  @override
  String get eventLifecycleInProgress => 'Contrôle en cours aux portes.';

  @override
  String get eventLifecycleClosed =>
      'Clôturé : plus aucune entrée n\'est acceptée.';

  @override
  String get eventLifecycleArchived => 'Archivé : consultation seule.';

  @override
  String get eventLifecycleCancelled =>
      'Annulé : aucune entrée n\'est acceptée.';

  @override
  String get eventActionPublish => 'Publier';

  @override
  String get eventActionStart => 'Démarrer le contrôle';

  @override
  String get eventActionClose => 'Clôturer';

  @override
  String get eventActionArchive => 'Archiver';

  @override
  String get eventActionDraft => 'Repasser en brouillon';

  @override
  String get eventActionCancel => 'Annuler l\'événement';

  @override
  String get eventConfirmPublish =>
      'Les billets pourront être émis et contrôlés aux portes.';

  @override
  String get eventConfirmStart =>
      'Les contrôleurs affectés pourront valider les entrées.';

  @override
  String get eventConfirmClose =>
      'Plus aucune entrée ne sera acceptée. Cette action est définitive.';

  @override
  String get eventConfirmArchive =>
      'L\'événement passera en consultation seule. Cette action est définitive.';

  @override
  String get eventConfirmDraft =>
      'L\'événement redevient modifiable et invisible des contrôleurs.';

  @override
  String get eventConfirmCancel =>
      'Aucune entrée ne sera acceptée. Cette action est définitive.';

  @override
  String get eventConfirmBack => 'Retour';

  @override
  String eventStatusChanged(String status) {
    return 'Statut : $status';
  }

  @override
  String get eventNextTeam => 'Contrôleurs affectés';

  @override
  String get eventNextSoon => 'Bientôt';

  @override
  String get eventNotFoundTitle => 'Événement introuvable';

  @override
  String get homeNextEventTitle => 'Prochain événement';

  @override
  String get homeNoEventBody => 'Aucun événement à venir.';

  @override
  String get homeCreateEvent => 'Créer un événement';

  @override
  String get homeSeeEvents => 'Voir les événements';

  @override
  String get categoriesTitle => 'Catégories de billets';

  @override
  String get categoriesEmpty =>
      'Aucune catégorie. Ajoutez-en une, par exemple Standard, VIP ou Invitation.';

  @override
  String get setupAdd => 'Ajouter';

  @override
  String get setupSave => 'Enregistrer';

  @override
  String get setupCancel => 'Annuler';

  @override
  String get setupLoadError => 'Chargement impossible.';

  @override
  String categoryCounts(int issued, int redeemed) {
    return '$issued émis · $redeemed entrés';
  }

  @override
  String categoryQuota(int capacity) {
    return 'Quota : $capacity';
  }

  @override
  String get categoryNoQuota => 'Sans quota';

  @override
  String categoriesTotal(int issued, int capacity) {
    return '$issued billets émis sur $capacity';
  }

  @override
  String categoriesTotalUnlimited(int issued) {
    return '$issued billets émis, capacité non limitée';
  }

  @override
  String get categoryNewTitle => 'Nouvelle catégorie';

  @override
  String get categoryEditTitle => 'Modifier la catégorie';

  @override
  String get categoryNameLabel => 'Nom';

  @override
  String get categoryNameHint => 'Ex. VIP';

  @override
  String get categoryQuotaLabel => 'Quota (facultatif)';

  @override
  String get categoryQuotaHelp =>
      'Vide : limité seulement par la capacité de l\'événement.';

  @override
  String get categoryDelete => 'Supprimer';

  @override
  String get categoryDeleteTitle => 'Supprimer la catégorie ?';

  @override
  String categoryDeleteBody(String name) {
    return '« $name » sera supprimée. C\'est impossible si des billets y ont été émis.';
  }

  @override
  String get categorySaved => 'Catégorie enregistrée';

  @override
  String get categoryDeleted => 'Catégorie supprimée';

  @override
  String get checkpointsTitle => 'Portes de contrôle';

  @override
  String get checkpointsEmpty =>
      'Aucune porte. Ajoutez les entrées où vos contrôleurs scanneront les billets.';

  @override
  String get checkpointActive => 'Active';

  @override
  String get checkpointInactive => 'Désactivée : scans refusés';

  @override
  String get checkpointNewTitle => 'Nouvelle porte';

  @override
  String get checkpointEditTitle => 'Renommer la porte';

  @override
  String get checkpointNameHint => 'Ex. Entrée principale';

  @override
  String get checkpointDeactivateTitle => 'Désactiver la porte ?';

  @override
  String checkpointDeactivateBody(String name) {
    return 'Les scans à « $name » seront refusés immédiatement, jusqu\'à sa réactivation.';
  }

  @override
  String get checkpointDeactivate => 'Désactiver';

  @override
  String get checkpointSaved => 'Porte enregistrée';

  @override
  String get setupErrorNotFound =>
      'Élément introuvable ou droits insuffisants.';

  @override
  String get setupErrorName => 'Saisissez un nom de 1 à 60 caractères.';

  @override
  String get setupErrorNameTaken =>
      'Ce nom est déjà utilisé pour cet événement.';

  @override
  String get setupErrorCapacity => 'Saisissez un quota entre 1 et 1 000 000.';

  @override
  String get setupErrorCapacityBelowIssued =>
      'Le quota ne peut pas être inférieur aux billets déjà émis.';

  @override
  String get setupErrorHasTickets =>
      'Des billets existent dans cette catégorie : suppression impossible.';

  @override
  String get setupErrorLocked =>
      'Événement clôturé : sa configuration est figée.';
}
