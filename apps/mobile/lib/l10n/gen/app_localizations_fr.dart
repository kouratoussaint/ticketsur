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
  String get verdictReasonWrongEvent => 'Ticket non valable pour cet événement';

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
  String get navTickets => 'Tickets';

  @override
  String get navTeam => 'Équipe';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeGreeting => 'Bienvenue sur TicketSûr';

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
      'Votre organisation regroupe vos événements, vos tickets et votre équipe. Vous en serez le propriétaire.';

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
      'La capacité ne peut pas être inférieure au nombre de tickets déjà émis.';

  @override
  String get eventErrorLocked => 'Cet événement ne peut plus être modifié.';

  @override
  String get eventErrorInvalidTransition =>
      'Ce changement de statut n\'est pas permis.';

  @override
  String get eventErrorHasTickets =>
      'Des tickets ont été émis : impossible de repasser en brouillon.';

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
      'Brouillon : invisible des contrôleurs. Publiez-le pour émettre des tickets et ouvrir le contrôle.';

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
      'Les tickets pourront être émis et contrôlés aux portes.';

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
  String get categoriesTitle => 'Catégories de tickets';

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
    return '$issued tickets émis sur $capacity';
  }

  @override
  String categoriesTotalUnlimited(int issued) {
    return '$issued tickets émis, capacité non limitée';
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
    return '« $name » sera supprimée. C\'est impossible si des tickets y ont été émis.';
  }

  @override
  String get categorySaved => 'Catégorie enregistrée';

  @override
  String get categoryDeleted => 'Catégorie supprimée';

  @override
  String get checkpointsTitle => 'Portes de contrôle';

  @override
  String get checkpointsEmpty =>
      'Aucune porte. Ajoutez les entrées où vos contrôleurs scanneront les tickets.';

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
      'Le quota ne peut pas être inférieur aux tickets déjà émis.';

  @override
  String get setupErrorHasTickets =>
      'Des tickets existent dans cette catégorie : suppression impossible.';

  @override
  String get setupErrorLocked =>
      'Événement clôturé : sa configuration est figée.';

  @override
  String get teamInvite => 'Inviter';

  @override
  String get teamMembersTitle => 'Membres';

  @override
  String get teamInvitationsTitle => 'Invitations en cours';

  @override
  String teamInvitationLine(String role, String hint) {
    return '$role · code …$hint';
  }

  @override
  String teamInvitationDetail(String date, int uses, int max) {
    return 'Expire le $date · $uses sur $max';
  }

  @override
  String get teamRevoke => 'Révoquer';

  @override
  String get teamRevokeTitle => 'Révoquer l\'invitation ?';

  @override
  String teamRevokeBody(String hint) {
    return 'Le code se terminant par $hint ne fonctionnera plus.';
  }

  @override
  String get teamInactive => 'Désactivé';

  @override
  String get teamYou => 'Vous';

  @override
  String get teamControllerTitle => 'Équipe gérée par les organisateurs';

  @override
  String teamControllerBody(String org) {
    return 'Vous êtes contrôleur de « $org ». Les organisateurs gèrent l\'équipe et vos affectations aux portes.';
  }

  @override
  String get inviteTitle => 'Inviter dans l\'équipe';

  @override
  String get inviteRoleLabel => 'Rôle';

  @override
  String get inviteRoleControllerHelp =>
      'Scanne les tickets aux portes qui lui sont affectées.';

  @override
  String get inviteRoleManagerHelp =>
      'Gère les événements, les tickets et les contrôleurs.';

  @override
  String get inviteValidity => 'Validité';

  @override
  String inviteDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get inviteUses => 'Nombre de personnes';

  @override
  String inviteUsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return '$_temp0';
  }

  @override
  String get inviteCreate => 'Créer le code';

  @override
  String get inviteCodeTitle => 'Code d\'invitation';

  @override
  String get inviteCodeHint =>
      'Partagez-le maintenant : il ne sera plus jamais affiché.';

  @override
  String inviteCodeValid(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String get inviteShare => 'Partager';

  @override
  String get inviteCopy => 'Copier';

  @override
  String get inviteCopied => 'Code copié';

  @override
  String inviteShareText(String org, String role, String code, String date) {
    return 'Rejoignez « $org » sur TicketSûr en tant que $role. Dans l\'application, touchez « Rejoindre avec un code » et saisissez $code (valable jusqu\'au $date).';
  }

  @override
  String get inviteDone => 'Terminé';

  @override
  String get memberRoleLabel => 'Rôle';

  @override
  String get memberActiveLabel => 'Accès actif';

  @override
  String get memberActiveHelp =>
      'Désactivé : plus aucune action possible, scans refusés immédiatement.';

  @override
  String get memberSaved => 'Accès mis à jour';

  @override
  String get teamErrorForbidden => 'Action non autorisée pour votre rôle.';

  @override
  String get teamErrorInvalid => 'Paramètres invalides.';

  @override
  String get teamErrorMemberNotFound =>
      'Membre introuvable ou accès désactivé.';

  @override
  String get teamErrorIsOwner => 'Le propriétaire ne peut pas être modifié.';

  @override
  String get teamErrorIsSelf =>
      'Vous ne pouvez pas modifier votre propre accès.';

  @override
  String get teamErrorCheckpoint => 'Porte inconnue pour cet événement.';

  @override
  String get joinTitle => 'Rejoindre une organisation';

  @override
  String get joinIntro =>
      'Saisissez le code reçu d\'un organisateur. Il commence par TSI.';

  @override
  String get joinCodeLabel => 'Code d\'invitation';

  @override
  String get joinSubmit => 'Rejoindre';

  @override
  String joinWelcome(String org) {
    return 'Bienvenue dans « $org »';
  }

  @override
  String get joinInvalid =>
      'Code inconnu ou révoqué. Vérifiez-le auprès de l\'organisateur.';

  @override
  String get joinExpired =>
      'Ce code a expiré ou a déjà servi. Demandez-en un nouveau.';

  @override
  String get joinAlreadyMember =>
      'Vous faites déjà partie de cette organisation.';

  @override
  String get joinRateLimited =>
      'Trop d\'essais. Réessayez dans un quart d\'heure.';

  @override
  String get joinUnauthorized => 'Votre session a expiré. Reconnectez-vous.';

  @override
  String get joinAction => 'Rejoindre avec un code';

  @override
  String get joinHaveCode => 'J\'ai un code d\'invitation';

  @override
  String get eventTeamTitle => 'Contrôleurs affectés';

  @override
  String get eventTeamEmpty =>
      'Personne n\'est affecté. Ajoutez les membres qui scanneront à cet événement.';

  @override
  String get eventTeamAllCheckpoints => 'Toutes les portes';

  @override
  String get eventTeamAssignTitle => 'Affecter un membre';

  @override
  String get eventTeamMemberLabel => 'Membre';

  @override
  String get eventTeamCheckpointLabel => 'Porte';

  @override
  String get eventTeamAssign => 'Affecter';

  @override
  String get eventTeamRemoveTitle => 'Retirer l\'affectation ?';

  @override
  String eventTeamRemoveBody(String name) {
    return '$name ne pourra plus scanner à cette porte.';
  }

  @override
  String get eventTeamRemove => 'Retirer';

  @override
  String get eventTeamNoMembers =>
      'Invitez d\'abord des membres depuis l\'onglet Équipe.';

  @override
  String get eventTeamMemberInactive => 'Accès désactivé';

  @override
  String get ticketRevokedStamp => 'Ticket annulé';

  @override
  String get ticketRedeemedStamp => 'UTILISÉ';

  @override
  String get ticketQrHidden => 'QR masqué';

  @override
  String get ticketFooter =>
      'Ticket à usage unique. Ne le publiez pas : la première présentation à l\'entrée fait foi.';

  @override
  String get ticketsNoEventTitle => 'Aucun événement publié';

  @override
  String get ticketsNoEventBody =>
      'Publiez un événement pour émettre ses tickets.';

  @override
  String get ticketsGoEvents => 'Voir les événements';

  @override
  String get ticketsEventLabel => 'Événement';

  @override
  String ticketsSummary(int issued, int redeemed) {
    return '$issued émis · $redeemed entrés';
  }

  @override
  String get ticketsFilterAll => 'Tous';

  @override
  String get ticketsFilterValid => 'Valables';

  @override
  String get ticketsFilterRedeemed => 'Utilisés';

  @override
  String get ticketsFilterRevoked => 'Annulés';

  @override
  String get ticketsSearchHint => 'Référence, catégorie, nom ou téléphone';

  @override
  String get ticketsEmpty =>
      'Aucun ticket pour l\'instant. Touchez « Émettre » pour créer les premiers.';

  @override
  String get ticketsEmptyFilter => 'Aucun ticket ne correspond.';

  @override
  String get ticketsLoadMore => 'Afficher plus';

  @override
  String ticketsCount(int shown, int total) {
    return '$shown sur $total';
  }

  @override
  String get ticketsIssue => 'Émettre';

  @override
  String get ticketsControllerBody =>
      'Les tickets sont gérés par les organisateurs. Vous les contrôlerez à l\'entrée.';

  @override
  String get ticketStatusIssued => 'Valable';

  @override
  String get ticketStatusRedeemed => 'Utilisé';

  @override
  String get ticketStatusRevoked => 'Annulé';

  @override
  String get ticketStatusExpired => 'Expiré';

  @override
  String get issueTitle => 'Émettre des tickets';

  @override
  String get issueCategory => 'Catégorie';

  @override
  String issueRemaining(int count) {
    return '$count restants';
  }

  @override
  String get issueUnlimited => 'sans quota';

  @override
  String get issueQuantity => 'Nombre de tickets';

  @override
  String get issueQuantityHelp => 'De 1 à 500 par lot.';

  @override
  String get issueQuantityError => 'Saisissez un nombre entre 1 et 500.';

  @override
  String issueSubmit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Émettre $count tickets',
      one: 'Émettre 1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get issueNoCategory =>
      'Ajoutez d\'abord une catégorie dans la fiche de l\'événement.';

  @override
  String get issueDraft => 'Publiez l\'événement pour émettre des tickets.';

  @override
  String issueDoneTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets émis',
      one: '1 ticket émis',
    );
    return '$_temp0';
  }

  @override
  String get issueDoneBody =>
      'Partagez-les maintenant. Vous pourrez aussi les retélécharger plus tard depuis leur fiche.';

  @override
  String get issueSharePdf => 'Partager en PDF';

  @override
  String get issueSeeTickets => 'Voir les tickets';

  @override
  String get ticketErrorNotFound =>
      'Ticket ou événement introuvable, ou droits insuffisants.';

  @override
  String get ticketErrorNotPublished =>
      'Publiez l\'événement avant d\'émettre des tickets.';

  @override
  String get ticketErrorCategoryCapacity => 'Quota de la catégorie atteint.';

  @override
  String get ticketErrorEventCapacity => 'Capacité de l\'événement atteinte.';

  @override
  String get ticketErrorInvalid =>
      'Demande refusée par le serveur (quantité ou catégorie).';

  @override
  String get ticketDetailTitle => 'Ticket';

  @override
  String get ticketShowQr => 'Afficher le QR';

  @override
  String get ticketShowQrHint =>
      'Le retéléchargement est inscrit au journal de l\'organisation.';

  @override
  String get ticketShareImage => 'Partager l\'image';

  @override
  String get ticketSharePdf => 'PDF';

  @override
  String ticketShareText(String event) {
    return 'Votre ticket pour « $event ». Présentez ce QR code à l\'entrée.';
  }

  @override
  String get ticketRevoke => 'Annuler le ticket';

  @override
  String get ticketRevokeTitle => 'Annuler ce ticket ?';

  @override
  String ticketRevokeBody(String reference) {
    return 'Le ticket $reference sera refusé à l\'entrée. Cette action est définitive.';
  }

  @override
  String get ticketRevokeReason => 'Motif (facultatif)';

  @override
  String get ticketRevoked => 'Ticket annulé';

  @override
  String get ticketAlreadyRedeemed =>
      'Ce ticket a déjà été utilisé : il ne peut plus être annulé.';

  @override
  String ticketIssuedAt(String date) {
    return 'Émis le $date';
  }

  @override
  String ticketRedeemedAt(String date, String checkpoint) {
    return 'Utilisé le $date · $checkpoint';
  }

  @override
  String ticketRevokedAt(String date) {
    return 'Annulé le $date';
  }

  @override
  String get ticketPreparing => 'Préparation…';

  @override
  String get navControl => 'Contrôle';

  @override
  String get navHistory => 'Historique';

  @override
  String get controlTitle => 'Contrôle des entrées';

  @override
  String get controlEmptyTitle => 'Aucun poste attribué';

  @override
  String get controlEmptyBody =>
      'Un organisateur doit vous affecter à un événement et à une porte. Tirez vers le bas pour actualiser.';

  @override
  String get controlWindowOpen => 'Contrôle ouvert';

  @override
  String controlWindowUpcoming(String date) {
    return 'Ouverture le $date';
  }

  @override
  String get controlWindowClosed => 'Contrôle terminé';

  @override
  String get controlChooseDoor => 'Choisissez votre porte';

  @override
  String get controlLoadError => 'Impossible de charger vos postes.';

  @override
  String get scannerManualLabel => 'Code du ticket';

  @override
  String get scannerManualHelp =>
      'Collez ou saisissez le code du ticket. Il commence par TS1.';

  @override
  String get scannerPaste => 'Coller et vérifier';

  @override
  String get scannerValidate => 'Vérifier';

  @override
  String scannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets vérifiés',
      one: '1 ticket vérifié',
      zero: 'Aucun ticket vérifié',
    );
    return '$_temp0';
  }

  @override
  String get scannerOutsideWindow =>
      'Hors de la fenêtre de contrôle : le serveur refusera les entrées.';

  @override
  String get scannerEmptyClipboard =>
      'Le presse-papiers ne contient pas de texte.';

  @override
  String get historyTitle => 'Mes scans récents';

  @override
  String get historyEmpty => 'Aucun scan ces 7 derniers jours.';

  @override
  String get historyLoadError => 'Impossible de charger l\'historique.';

  @override
  String get homeControlTitle => 'Contrôler les entrées';

  @override
  String homeControlBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portes vous sont attribuées',
      one: '1 porte vous est attribuée',
    );
    return '$_temp0';
  }

  @override
  String get eventControl => 'Contrôler les entrées';

  @override
  String get feedbackTitle => 'Sons et vibrations';

  @override
  String get feedbackScanSounds => 'Sons du contrôle';

  @override
  String get feedbackScanSoundsHelp =>
      'Un son distinct pour chaque verdict : entrée autorisée, refusée, à confirmer.';

  @override
  String get feedbackUiSounds => 'Sons de l\'interface';

  @override
  String get feedbackUiSoundsHelp => 'Navigation et confirmations, discrets.';

  @override
  String get feedbackHaptics => 'Vibrations';

  @override
  String get feedbackPreviewAdmitted => 'Écouter : entrée autorisée';

  @override
  String get feedbackPreviewRefused => 'Écouter : entrée refusée';

  @override
  String get feedbackPreviewIndeterminate => 'Écouter : à confirmer';

  @override
  String get scannerHint => 'Placez le QR code dans le cadre';

  @override
  String get scannerManual => 'Saisir le code';

  @override
  String get scannerTorchOn => 'Allumer la lampe';

  @override
  String get scannerTorchOff => 'Éteindre la lampe';

  @override
  String get scannerLeave => 'Quitter le poste';

  @override
  String get cameraDeniedTitle => 'Accès à la caméra refusé';

  @override
  String get cameraDeniedBody =>
      'Autorisez la caméra pour TicketSûr dans les réglages Android (Applications › TicketSûr › Autorisations), puis réessayez. Vous pouvez aussi saisir le code.';

  @override
  String get cameraErrorTitle => 'Caméra indisponible';

  @override
  String get cameraErrorBody =>
      'Fermez les autres applications qui utilisent la caméra, puis réessayez. Vous pouvez aussi saisir le code.';

  @override
  String get cameraRetry => 'Réessayer';

  @override
  String get homeQuickTitle => 'Actions rapides';

  @override
  String get homeQuickNewEvent => 'Nouvel événement';

  @override
  String get homeQuickIssue => 'Émettre des tickets';

  @override
  String get homeQuickInvite => 'Inviter l\'équipe';

  @override
  String get eventErrorIncomplete =>
      'Ajoutez une photo de couverture et une ville avant de publier.';

  @override
  String get eventErrorCity => 'Indiquez une ville de 2 à 80 caractères.';

  @override
  String get eventErrorAddress => 'Adresse de 200 caractères au plus.';

  @override
  String get eventErrorDescription =>
      'Description de 2 000 caractères au plus.';

  @override
  String get eventErrorCover =>
      'Photo refusée : choisissez une image JPEG, PNG ou WebP de 2 Mo au plus.';

  @override
  String get eventKindConcert => 'Concert';

  @override
  String get eventKindConference => 'Conférence';

  @override
  String get eventKindWorship => 'Culte';

  @override
  String get eventKindSport => 'Sport';

  @override
  String get eventKindWedding => 'Mariage';

  @override
  String get eventKindTraining => 'Formation';

  @override
  String get eventKindGala => 'Gala';

  @override
  String get eventKindOther => 'Autre';

  @override
  String get eventStepInfo => 'Infos';

  @override
  String get eventStepWhenWhere => 'Date et lieu';

  @override
  String get eventStepCover => 'Photo';

  @override
  String get eventStepReview => 'Aperçu';

  @override
  String eventStepCounter(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get eventStepNext => 'Suivant';

  @override
  String get eventStepBack => 'Précédent';

  @override
  String get eventKindLabel => 'Type d\'événement';

  @override
  String get eventDescriptionLabel => 'Description (facultatif)';

  @override
  String get eventDescriptionHint => 'Programme, artistes, consignes d\'accès…';

  @override
  String get eventCityLabel => 'Ville';

  @override
  String get eventCityHint => 'Ex. Ouagadougou';

  @override
  String get eventCityHelp => 'Obligatoire pour publier.';

  @override
  String get eventAddressLabel => 'Adresse (facultatif)';

  @override
  String get eventAddressHint => 'Secteur, rue, point de repère';

  @override
  String get eventCoverTitle => 'Photo de couverture';

  @override
  String get eventCoverHelp =>
      'Format paysage conseillé. Elle apparaît sur la fiche, les tickets partagés et l\'écran de contrôle. Obligatoire pour publier.';

  @override
  String get eventCoverGallery => 'Galerie';

  @override
  String get eventCoverCamera => 'Appareil photo';

  @override
  String get eventCoverChange => 'Changer la photo';

  @override
  String get eventCoverAdd => 'Ajouter une photo';

  @override
  String get eventCoverRemove => 'Retirer';

  @override
  String get eventCoverEmpty => 'Aucune photo pour l\'instant';

  @override
  String get eventCoverSaved => 'Photo enregistrée';

  @override
  String get eventCoverUploadFailed =>
      'Événement enregistré, mais la photo n\'a pas pu être envoyée. Réessayez depuis la fiche.';

  @override
  String get eventCoverLater =>
      'Vous pourrez aussi l\'ajouter plus tard depuis la fiche.';

  @override
  String get eventReviewTitle => 'Voici votre événement';

  @override
  String get eventReviewHint =>
      'Vérifiez les informations, puis enregistrez. L\'événement reste en brouillon tant que vous ne le publiez pas.';

  @override
  String get eventCityMissing => 'Ville à préciser';

  @override
  String get eventToCompleteTitle => 'À compléter avant publication';

  @override
  String get eventMissingCover => 'Photo de couverture';

  @override
  String get eventMissingCity => 'Ville';

  @override
  String get eventDetailDescription => 'Description';

  @override
  String get eventDetailAddress => 'Adresse';

  @override
  String get eventDetailKind => 'Type';

  @override
  String get authErrorWeakPassword =>
      'Mot de passe trop faible : 8 caractères au moins, avec des lettres et des chiffres.';

  @override
  String get authErrorSamePassword =>
      'Le nouveau mot de passe doit être différent de l\'actuel.';

  @override
  String get authErrorEmailTaken =>
      'Cette adresse est déjà utilisée par un autre compte.';

  @override
  String get profileEdit => 'Modifier le profil';

  @override
  String get profileEditTitle => 'Mon profil';

  @override
  String get profileNameLabel => 'Nom affiché';

  @override
  String get profileNameHint => 'Prénom et nom';

  @override
  String get profileNameError => 'Saisissez un nom de 2 à 60 caractères.';

  @override
  String get profilePhoneLabel => 'Téléphone (facultatif)';

  @override
  String get profilePhoneHint => 'Ex. 70 12 34 56';

  @override
  String get profilePhoneHelp =>
      'Numéro burkinabè à 8 chiffres, ou format international (+225…).';

  @override
  String get profilePhoneError => 'Numéro de téléphone invalide.';

  @override
  String get profileEmailLabel => 'Adresse e-mail';

  @override
  String get profileSave => 'Enregistrer';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get profilePhotoChange => 'Changer la photo';

  @override
  String get profilePhotoSaved => 'Photo de profil enregistrée';

  @override
  String get profilePhotoError =>
      'Photo refusée : image JPEG, PNG ou WebP de 1 Mo au plus.';

  @override
  String get profileLoadError => 'Impossible de charger votre profil.';

  @override
  String get profileErrorUnknown => 'Enregistrement impossible. Réessayez.';

  @override
  String get profileSecurityTitle => 'Sécurité';

  @override
  String get profileChangePassword => 'Changer le mot de passe';

  @override
  String get profileChangeEmail => 'Changer d\'adresse e-mail';

  @override
  String get profileSignOutEverywhere => 'Déconnecter tous les appareils';

  @override
  String get profileSignOutEverywhereBody =>
      'Toutes vos sessions seront fermées, y compris celle-ci. Vous devrez vous reconnecter.';

  @override
  String get profileCurrentPassword => 'Mot de passe actuel';

  @override
  String get profileNewPassword => 'Nouveau mot de passe';

  @override
  String get profileConfirmPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get profilePasswordTooShort => '8 caractères au moins.';

  @override
  String get profilePasswordMismatch => 'Les deux mots de passe diffèrent.';

  @override
  String get profilePasswordRequired => 'Saisissez votre mot de passe actuel.';

  @override
  String get profileWrongPassword => 'Mot de passe actuel incorrect.';

  @override
  String get profilePasswordChanged => 'Mot de passe changé';

  @override
  String get profileNewEmail => 'Nouvelle adresse e-mail';

  @override
  String get profileEmailHelp =>
      'Un lien de confirmation sera envoyé à la nouvelle adresse. Elle ne remplacera l\'actuelle qu\'après confirmation.';

  @override
  String get profileEmailSame => 'C\'est déjà votre adresse.';

  @override
  String profileEmailSent(String email) {
    return 'Lien de confirmation envoyé à $email.';
  }

  @override
  String get profileSend => 'Envoyer le lien';

  @override
  String get profileDangerTitle => 'Zone sensible';

  @override
  String get profileDeleteAccount => 'Supprimer mon compte';

  @override
  String get profileDeleteBody =>
      'Votre compte sera supprimé dans 30 jours : vos données personnelles seront effacées, les tickets déjà émis restent à vos organisations. Vous pourrez annuler d\'ici là. Tapez SUPPRIMER pour confirmer.';

  @override
  String get profileDeleteWord => 'SUPPRIMER';

  @override
  String get profileDeleteConfirm => 'Programmer la suppression';

  @override
  String profileDeletionPending(String date) {
    return 'Suppression du compte prévue le $date.';
  }

  @override
  String get profileDeletionCancel => 'Annuler la suppression';

  @override
  String get profileDeletionCancelled => 'Suppression annulée';

  @override
  String get profileDeletionRequested => 'Suppression programmée dans 30 jours';

  @override
  String get profileCancel => 'Annuler';

  @override
  String get profileConfirm => 'Confirmer';

  @override
  String get orgCardTitle => 'Organisation';

  @override
  String get orgEdit => 'Modifier la fiche';

  @override
  String get orgEditTitle => 'Fiche de l\'organisation';

  @override
  String get orgEditHelp =>
      'Ces informations apparaissent sur vos tickets et, bientôt, sur la page publique de vos événements.';

  @override
  String get orgPhoneLabel => 'Téléphone de contact (facultatif)';

  @override
  String get orgEmailLabel => 'E-mail de contact (facultatif)';

  @override
  String get orgCityLabel => 'Ville (facultatif)';

  @override
  String get orgLogoChange => 'Changer le logo';

  @override
  String get orgLogoSaved => 'Logo enregistré';

  @override
  String get orgSaved => 'Fiche enregistrée';

  @override
  String get orgLeave => 'Quitter l\'organisation';

  @override
  String orgLeaveTitle(String name) {
    return 'Quitter « $name » ?';
  }

  @override
  String get orgLeaveBody =>
      'Vous perdrez l\'accès à ses événements, ses tickets et ses contrôles. Pour revenir, il faudra un nouveau code d\'invitation.';

  @override
  String orgLeft(String name) {
    return 'Vous avez quitté « $name »';
  }

  @override
  String get orgErrorNotFound =>
      'Organisation introuvable ou droits insuffisants.';

  @override
  String get orgErrorPhone => 'Numéro de téléphone invalide.';

  @override
  String get orgErrorEmail => 'Adresse e-mail invalide.';

  @override
  String get orgErrorCity => 'Ville de 2 à 80 caractères.';

  @override
  String get orgErrorLogo =>
      'Logo refusé : image JPEG, PNG ou WebP de 1 Mo au plus.';

  @override
  String get orgErrorLastOwner =>
      'Vous êtes le dernier propriétaire : nommez-en un autre avant de partir.';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get dashboardOpen => 'Tableau de bord en direct';

  @override
  String get dashboardLive => 'En direct';

  @override
  String get dashboardClosed => 'Contrôle fermé';

  @override
  String get dashboardStale => 'Non actualisé';

  @override
  String dashboardUpdatedAt(String time) {
    return 'Actualisé à $time';
  }

  @override
  String dashboardStaleBody(String time) {
    return 'Connexion perdue : chiffres de $time. Nouvel essai automatique.';
  }

  @override
  String get dashboardRefresh => 'Actualiser';

  @override
  String get dashboardAttendance => 'Taux d\'entrée';

  @override
  String dashboardAdmittedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString entrées',
      one: '1 entrée',
      zero: 'Aucune entrée',
    );
    return '$_temp0';
  }

  @override
  String dashboardIssuedOf(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tickets émis',
      one: '1 ticket émis',
    );
    return 'sur $_temp0';
  }

  @override
  String dashboardCapacityLine(String value) {
    return 'Capacité : $value';
  }

  @override
  String get dashboardKpiAdmitted => 'Entrés';

  @override
  String get dashboardKpiRemaining => 'Attendus';

  @override
  String get dashboardKpiRefused => 'Refus';

  @override
  String dashboardKpiRate(int minutes) {
    return 'Entrées / $minutes min';
  }

  @override
  String get dashboardTimelineTitle => 'Passages dans le temps';

  @override
  String dashboardTimelineStepMinutes(int minutes) {
    return 'Par tranche de $minutes min';
  }

  @override
  String dashboardTimelineStepHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Par tranche de $hours heures',
      one: 'Par tranche d\'1 heure',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTimelineEmpty =>
      'Les passages apparaîtront ici dès le premier scan.';

  @override
  String get dashboardLegendAdmitted => 'Entrées';

  @override
  String get dashboardLegendRefused => 'Refus';

  @override
  String dashboardTimelineSemantics(
    int accepted,
    int refused,
    String from,
    String to,
  ) {
    return '$accepted entrées et $refused refus entre $from et $to';
  }

  @override
  String get dashboardRefusalsTitle => 'Motifs de refus';

  @override
  String get dashboardOtherReason => 'Autre motif';

  @override
  String get dashboardCategoriesTitle => 'Par catégorie';

  @override
  String dashboardCategoryLine(int admitted, int issued) {
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);
    final intl.NumberFormat issuedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String issuedString = issuedNumberFormat.format(issued);

    String _temp0 = intl.Intl.pluralLogic(
      admitted,
      locale: localeName,
      other: '$admittedString entrés',
      one: '1 entré',
      zero: 'Aucun entré',
    );
    return '$_temp0 sur $issuedString';
  }

  @override
  String dashboardQuota(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Quota : $countString';
  }

  @override
  String get dashboardCheckpointsTitle => 'Par porte';

  @override
  String dashboardCheckpointLine(int admitted, int refused) {
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);
    final intl.NumberFormat refusedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String refusedString = refusedNumberFormat.format(refused);

    String _temp0 = intl.Intl.pluralLogic(
      admitted,
      locale: localeName,
      other: '$admittedString entrées',
      one: '1 entrée',
      zero: 'Aucune entrée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      refused,
      locale: localeName,
      other: '$refusedString refus',
      one: '1 refus',
      zero: 'aucun refus',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get dashboardCheckpointInactive => 'Fermée';

  @override
  String dashboardLastScan(String time) {
    return 'Dernier scan à $time';
  }

  @override
  String get dashboardNoScan => 'Aucun scan';

  @override
  String get dashboardControllersTitle => 'Contrôleurs';

  @override
  String dashboardRevokedExpired(int revoked, int expired) {
    final intl.NumberFormat revokedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String revokedString = revokedNumberFormat.format(revoked);
    final intl.NumberFormat expiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String expiredString = expiredNumberFormat.format(expired);

    return 'Tickets annulés : $revokedString · expirés : $expiredString';
  }

  @override
  String get dashboardNoTickets => 'Aucun ticket émis pour cet événement.';

  @override
  String get dashboardIssueTickets => 'Émettre des tickets';

  @override
  String get dashboardErrorNotFound =>
      'Tableau de bord indisponible : événement introuvable ou droits insuffisants.';

  @override
  String get dashboardErrorLoad => 'Impossible de charger le tableau de bord.';

  @override
  String get homeDashboard => 'Suivre les entrées en direct';

  @override
  String get holderTitle => 'Titulaire';

  @override
  String get holderOptional => 'Titulaire (facultatif)';

  @override
  String get holderOptionalHint =>
      'Le nom est imprimé sur le ticket. Sans titulaire, le ticket est au porteur.';

  @override
  String get holderName => 'Nom et prénom';

  @override
  String get holderPhone => 'Téléphone';

  @override
  String get holderPhoneHelp => 'Ex. : 70 12 34 56 ou +225 07 08 09 10 11';

  @override
  String get holderEmail => 'E-mail';

  @override
  String get holderNone => 'Aucun titulaire : ticket au porteur';

  @override
  String get holderAdd => 'Ajouter un titulaire';

  @override
  String get holderEdit => 'Modifier le titulaire';

  @override
  String get holderSave => 'Enregistrer';

  @override
  String get holderSaved => 'Titulaire enregistré';

  @override
  String get holderErrorName => 'Nom de 120 caractères au plus.';

  @override
  String get holderErrorPhone => 'Numéro de téléphone invalide.';

  @override
  String get holderErrorEmail => 'Adresse e-mail invalide.';

  @override
  String get ticketErrorNotEditable =>
      'Seul un ticket valable, pas encore utilisé, peut changer de titulaire.';

  @override
  String ticketCardHolder(String name) {
    return 'Titulaire : $name';
  }

  @override
  String get importTitle => 'Importer une liste';

  @override
  String get importEntry => 'Importer une liste (Excel, CSV)';

  @override
  String get importIntro =>
      'Une ligne par participant. Colonnes reconnues : nom (ou prénom et nom), téléphone, e-mail et catégorie. Fichier Excel (.xlsx) ou CSV, 500 lignes au plus.';

  @override
  String get importPick => 'Choisir un fichier';

  @override
  String get importChange => 'Changer de fichier';

  @override
  String get importTemplate => 'Partager un modèle à remplir';

  @override
  String importRowsRead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString lignes lues',
      one: '1 ligne lue',
      zero: 'Aucune ligne lue',
    );
    return '$_temp0';
  }

  @override
  String get importDefaultCategory => 'Catégorie des lignes sans catégorie';

  @override
  String get importNoCategory =>
      'Créez d\'abord une catégorie de tickets pour cet événement.';

  @override
  String get importErrorUnsupported =>
      'Format non pris en charge : choisissez un fichier Excel (.xlsx) ou CSV.';

  @override
  String get importErrorLegacy =>
      'Ancien format Excel (.xls) : enregistrez le fichier au format .xlsx ou CSV.';

  @override
  String get importErrorUnreadable => 'Fichier illisible ou endommagé.';

  @override
  String get importErrorTooLarge => 'Fichier trop volumineux (5 Mo au plus).';

  @override
  String get importErrorNoName =>
      'Colonne du nom introuvable : ajoutez un en-tête « Nom » au-dessus de la liste.';

  @override
  String get importErrorEmpty => 'Aucune ligne à importer dans ce fichier.';

  @override
  String importReady(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString lignes prêtes',
      one: '1 ligne prête',
      zero: 'Aucune ligne prête',
    );
    return '$_temp0';
  }

  @override
  String importErrorCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString en erreur',
      one: '1 en erreur',
    );
    return '$_temp0';
  }

  @override
  String importWarningCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString à vérifier',
      one: '1 à vérifier',
    );
    return '$_temp0';
  }

  @override
  String get importColumnsTitle => 'Colonnes reconnues';

  @override
  String get importColumnsGuessed =>
      'Pas d\'en-tête : colonnes devinées d\'après leur contenu.';

  @override
  String get importColumnName => 'Nom';

  @override
  String get importColumnFirstName => 'Prénom';

  @override
  String get importColumnPhone => 'Téléphone';

  @override
  String get importColumnEmail => 'E-mail';

  @override
  String get importColumnCategory => 'Catégorie';

  @override
  String importColumnFrom(String field, String header) {
    return '$field ← « $header »';
  }

  @override
  String importColumnAt(String field, String letter) {
    return '$field ← colonne $letter';
  }

  @override
  String get importPerCategoryTitle => 'Par catégorie';

  @override
  String importQuotaCategory(String category, int wanted, int remaining) {
    return '$category : $wanted demandés, $remaining restants';
  }

  @override
  String importQuotaEvent(int wanted, int remaining) {
    return 'Capacité de l\'événement : $wanted demandés, $remaining places restantes';
  }

  @override
  String get importErrorsTitle => 'Lignes en erreur';

  @override
  String get importWarningsTitle => 'À vérifier';

  @override
  String importLine(int line, String reason) {
    return 'Ligne $line · $reason';
  }

  @override
  String importMore(int count) {
    return '… et $count autres';
  }

  @override
  String get importProblemNameMissing => 'nom manquant';

  @override
  String get importProblemNameTooLong =>
      'nom trop long (120 caractères au plus)';

  @override
  String get importProblemPhone => 'téléphone invalide';

  @override
  String get importProblemEmail => 'e-mail invalide';

  @override
  String importProblemCategory(String label) {
    return 'catégorie « $label » inconnue';
  }

  @override
  String get importProblemNoCategory => 'catégorie manquante';

  @override
  String get importWarningPhone => 'même téléphone qu\'une ligne précédente';

  @override
  String get importWarningEmail => 'même e-mail qu\'une ligne précédente';

  @override
  String get importPreviewTitle => 'Aperçu';

  @override
  String get importSkipErrors => 'Ignorer les lignes en erreur';

  @override
  String get importTooMany =>
      '500 tickets au plus par import : découpez la liste en plusieurs fichiers.';

  @override
  String importSubmit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Émettre $countString tickets',
      one: 'Émettre 1 ticket',
      zero: 'Émettre les tickets',
    );
    return '$_temp0';
  }

  @override
  String sendMessageNamed(
    String name,
    String event,
    String date,
    String place,
  ) {
    return 'Bonjour $name, voici votre ticket pour « $event », $date$place. Présentez le QR code à l\'entrée. Ticket à usage unique : ne le transférez à personne.';
  }

  @override
  String sendMessage(String event, String date, String place) {
    return 'Bonjour, voici votre ticket pour « $event », $date$place. Présentez le QR code à l\'entrée. Ticket à usage unique : ne le transférez à personne.';
  }

  @override
  String sendSubject(String event) {
    return 'Votre ticket : $event';
  }

  @override
  String get sendChannelWhatsApp => 'WhatsApp';

  @override
  String get sendChannelSms => 'SMS';

  @override
  String get sendChannelEmail => 'E-mail';

  @override
  String get sendTitle => 'Envoyer au titulaire';

  @override
  String get sendNoContact =>
      'Ajoutez un téléphone ou un e-mail au titulaire pour lui envoyer son ticket.';

  @override
  String get sendConfirmTitle => 'Le ticket est-il parti ?';

  @override
  String sendConfirmBody(String channel) {
    return 'Confirmez une fois le message envoyé par $channel. Seuls les envois confirmés sont enregistrés.';
  }

  @override
  String get sendConfirmYes => 'Oui, envoyé';

  @override
  String get sendConfirmNo => 'Non';

  @override
  String get sendRecorded => 'Envoi enregistré';

  @override
  String get sendMissingWhatsApp =>
      'WhatsApp n\'est pas installé sur ce téléphone.';

  @override
  String get sendMissingSms => 'Aucune application SMS disponible.';

  @override
  String get sendMissingEmail =>
      'Aucune application d\'e-mail configurée sur ce téléphone.';

  @override
  String get sendFailed => 'Ouverture impossible. Réessayez.';

  @override
  String sendLast(String channel, String date) {
    return 'Dernier envoi : $channel, $date';
  }

  @override
  String ticketSentVia(String channel, String date) {
    return 'Envoyé par $channel le $date';
  }

  @override
  String get ticketErrorNotSendable =>
      'Seul un ticket valable, pas encore utilisé, peut être envoyé.';

  @override
  String get sendBatchTitle => 'Envoyer les tickets';

  @override
  String get sendBatchIntro =>
      'Les tickets valables jamais envoyés, un par un : l\'application s\'ouvre sur la bonne conversation avec le ticket joint, vous appuyez sur Envoyer, puis vous confirmez ici.';

  @override
  String sendBatchProgress(int current, int total) {
    return 'Ticket $current sur $total';
  }

  @override
  String sendBatchStats(int sent, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      sent,
      locale: localeName,
      other: '$sent envoyés',
      one: '1 envoyé',
      zero: 'Aucun envoyé',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped passés',
      one: '1 passé',
      zero: 'aucun passé',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String sendBatchSend(String channel) {
    return 'Envoyer par $channel';
  }

  @override
  String get sendBatchSkip => 'Passer';

  @override
  String get sendBatchRetry => 'Réessayer';

  @override
  String get sendBatchNext => 'Oui, envoyé · suivant';

  @override
  String sendBatchEmptyTitle(String channel) {
    return 'Aucun ticket à envoyer par $channel';
  }

  @override
  String get sendBatchEmptyPhone =>
      'Seuls les tickets valables, jamais envoyés, dont le titulaire a un numéro de téléphone sont proposés.';

  @override
  String get sendBatchEmptyEmail =>
      'Seuls les tickets valables, jamais envoyés, dont le titulaire a une adresse e-mail sont proposés.';

  @override
  String get sendBatchDoneTitle => 'Série terminée';

  @override
  String get sendBatchClose => 'Fermer';

  @override
  String get sendBatchLoadError =>
      'Impossible de charger les tickets à envoyer.';

  @override
  String get reportAction => 'Rapport';

  @override
  String get reportSheetTitle => 'Rapport de l\'événement';

  @override
  String get reportPdf => 'Bilan PDF';

  @override
  String get reportPdfHint =>
      'Chiffres clés, passages, catégories, portes, refus et contrôleurs.';

  @override
  String get reportCsv => 'Liste des tickets (Excel, CSV)';

  @override
  String get reportCsvHint =>
      'Un ticket par ligne, titulaires compris. Chaque export est inscrit au journal de l\'organisation.';

  @override
  String get reportErrorNotFound =>
      'Rapport indisponible : événement introuvable ou droits insuffisants.';

  @override
  String get reportErrorLoad => 'Impossible de préparer le rapport. Réessayez.';

  @override
  String get reportTitle => 'Rapport d\'événement';

  @override
  String reportStatsAt(String date) {
    return 'Chiffres arrêtés le $date';
  }

  @override
  String get reportIssued => 'Tickets émis';

  @override
  String get reportAdmitted => 'Entrés';

  @override
  String get reportAttendance => 'Taux d\'entrée';

  @override
  String get reportNoShow => 'Attendus, pas entrés';

  @override
  String get reportRevoked => 'Annulés';

  @override
  String get reportRefused => 'Refus au contrôle';

  @override
  String get reportTimeline => 'Passages dans le temps';

  @override
  String get reportCategories => 'Par catégorie';

  @override
  String get reportCheckpoints => 'Par porte';

  @override
  String get reportRefusals => 'Motifs de refus';

  @override
  String get reportControllers => 'Contrôleurs';

  @override
  String get reportColCategory => 'Catégorie';

  @override
  String get reportColQuota => 'Quota';

  @override
  String get reportColIssued => 'Émis';

  @override
  String get reportColAdmitted => 'Entrés';

  @override
  String get reportColRate => 'Taux';

  @override
  String get reportColCheckpoint => 'Porte';

  @override
  String get reportColRefused => 'Refus';

  @override
  String get reportColLastScan => 'Dernier scan';

  @override
  String get reportColReason => 'Motif';

  @override
  String get reportColCount => 'Nombre';

  @override
  String get reportColController => 'Contrôleur';

  @override
  String get reportUnlimited => 'Illimité';

  @override
  String get reportNone => 'Aucun';

  @override
  String reportPage(int page, int pages) {
    return 'Page $page sur $pages';
  }

  @override
  String get reportCsvHeader =>
      'Référence;Catégorie;Statut;Titulaire;Téléphone;E-mail;Émis le;Entré le;Porte;Annulé le;Dernier envoi;Envoyé le';
}
