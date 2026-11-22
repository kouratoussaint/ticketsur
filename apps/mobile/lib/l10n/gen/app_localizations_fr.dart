// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Tikéo';

  @override
  String get appSlogan => 'Votre événement en un clic';

  @override
  String get welcomeSignIn => 'Se connecter';

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
      'Les espaces promoteur et contrôleur arrivent dans les prochaines versions.';

  @override
  String get homeSignOut => 'Se déconnecter';

  @override
  String get configErrorTitle => 'Configuration manquante';

  @override
  String get configErrorHint =>
      'Lancez l\'application avec --dart-define-from-file=config/staging.json.';

  @override
  String get exitConfirm => 'Appuyez encore sur Retour pour quitter Tikéo';

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
  String get homeGreeting => 'Bienvenue sur Tikéo';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileAccountActive => 'Compte actif';

  @override
  String get profileAbout => 'À propos';

  @override
  String get orgLoading => 'Chargement…';

  @override
  String get orgLoadError => 'Impossible de charger vos structures.';

  @override
  String get orgRetry => 'Réessayer';

  @override
  String get orgCreateTitle => 'Créer votre structure';

  @override
  String get orgCreateIntro =>
      'Votre structure (entreprise, association, collectif…) regroupe vos événements, vos tickets et votre équipe. Vous en serez le propriétaire.';

  @override
  String get orgCreateAnotherTitle => 'Nouvelle structure';

  @override
  String get orgNameLabel => 'Nom de la structure ou de l\'entreprise';

  @override
  String get orgNameHint => 'Ex. : Festival des Nuits Sacrées';

  @override
  String get orgNameRequired => 'Saisissez un nom d\'au moins 2 caractères';

  @override
  String get orgCreateSubmit => 'Créer la structure';

  @override
  String get orgErrorInvalidName => 'Nom invalide : entre 2 et 120 caractères.';

  @override
  String get orgErrorLimit => 'Vous avez atteint la limite de 5 structures.';

  @override
  String orgCreated(String name) {
    return 'Structure « $name » créée';
  }

  @override
  String get orgSwitchTitle => 'Changer de structure';

  @override
  String get orgSwitchAction => 'Changer';

  @override
  String get orgCreateAction => 'Créer une structure';

  @override
  String get orgActiveLabel => 'Structure';

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
  String get eventsFilterDone => 'Passés';

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
      'Brouillon : invisible des contrôleurs. Publiez-le pour émettre des tickets.';

  @override
  String get eventLifecyclePublished =>
      'Publié : vous pouvez émettre des tickets. Les entrées seront validées dès que vous démarrerez le contrôle.';

  @override
  String get eventLifecycleInProgress =>
      'Contrôle en cours : les contrôleurs valident les entrées jusqu\'à ce que vous arrêtiez le contrôle.';

  @override
  String get eventLifecycleClosed =>
      'Contrôle arrêté : plus aucune entrée n\'est acceptée.';

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
      'Les tickets pourront être émis. Le contrôle aux portes commencera quand vous le démarrerez.';

  @override
  String get eventConfirmStart =>
      'Les contrôleurs affectés peuvent valider les entrées dès maintenant, quelle que soit l\'heure, jusqu\'à ce que vous arrêtiez le contrôle.';

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
  String get teamControllerTitle => 'Équipe gérée par les promoteurs';

  @override
  String teamControllerBody(String org) {
    return 'Vous êtes contrôleur de « $org ». Les promoteurs gèrent l\'équipe et vos affectations aux portes.';
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
      'Partagez-le maintenant. Vous pourrez le retrouver dans les détails de l\'invitation tant qu\'elle est active.';

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
    return 'Rejoignez « $org » sur Tikéo en tant que $role. Dans l\'application, touchez « Rejoindre avec un code » et saisissez $code (valable jusqu\'au $date).';
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
  String get joinTitle => 'Rejoindre une structure';

  @override
  String get joinIntro =>
      'Saisissez le code reçu d\'un promoteur d\'événement. Il commence par TSI.';

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
      'Code inconnu ou révoqué. Vérifiez-le auprès du promoteur.';

  @override
  String get joinExpired =>
      'Ce code a expiré ou a déjà servi. Demandez-en un nouveau.';

  @override
  String get joinAlreadyMember => 'Vous faites déjà partie de cette structure.';

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
      'Les tickets sont gérés par les promoteurs. Vous les contrôlerez à l\'entrée.';

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
  String get issueQuantityHelp => 'De 1 à 1 000 par lot.';

  @override
  String get issueQuantityError => 'Saisissez un nombre entre 1 et 1 000.';

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
      'Le retéléchargement est inscrit au journal de la structure.';

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
      'Un promoteur doit vous affecter à un événement et à une porte. Tirez vers le bas pour actualiser.';

  @override
  String get controlWindowOpen => 'Contrôle ouvert';

  @override
  String get controlWindowClosed => 'Contrôle arrêté';

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
      'Contrôle non démarré ou arrêté : le promoteur doit le démarrer, sinon les entrées seront refusées.';

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
      'Autorisez la caméra pour Tikéo dans les réglages Android (Applications › Tikéo › Autorisations), puis réessayez. Vous pouvez aussi saisir le code.';

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
  String get eventTaglineLabel => 'Accroche (facultatif)';

  @override
  String get eventTaglineHint => 'Une phrase courte imprimée sur le ticket';

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
      'Votre compte sera supprimé dans 30 jours : vos données personnelles seront effacées, les tickets déjà émis restent à vos structures, et les structures dont vous êtes propriétaire seront suspendues. Vous pourrez annuler d\'ici là. Tapez SUPPRIMER pour confirmer.';

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
  String get orgCardTitle => 'Structure';

  @override
  String get orgEdit => 'Modifier la fiche';

  @override
  String get orgEditTitle => 'Fiche de la structure';

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
  String get orgLeave => 'Quitter la structure';

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
      'Structure introuvable ou droits insuffisants.';

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
      'Une ligne par participant. Colonnes reconnues : nom (ou prénom et nom), téléphone, e-mail et catégorie. Fichier Excel (.xlsx) ou CSV, 1 000 lignes au plus.';

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
      '1 000 tickets au plus par import : découpez la liste en plusieurs fichiers.';

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
      'Un ticket par ligne, titulaires compris. Chaque export est inscrit au journal de la structure.';

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
      'Référence;Catégorie;Type;Statut;Titulaire;Téléphone;E-mail;Émis le;Entré le;Porte;Annulé le;Dernier envoi;Envoyé le';

  @override
  String get categoryInvitationLabel => 'Catégorie d\'invitations';

  @override
  String get categoryInvitationHelp =>
      'Ses tickets sont présentés comme des invitations (carte, PDF, message). Le contrôle à l\'entrée ne change pas.';

  @override
  String get categoryInvitationBadge => 'Invitations';

  @override
  String get ticketInvitation => 'Invitation';

  @override
  String ticketInvitationOf(String category) {
    return 'Invitation $category';
  }

  @override
  String get invitationFooter =>
      'Invitation personnelle à usage unique. Ne la publiez pas : la première présentation à l\'entrée fait foi.';

  @override
  String invitationShareText(String event) {
    return 'Votre invitation pour « $event ». Présentez ce QR code à l\'entrée.';
  }

  @override
  String invitationMessage(String event, String date, String place) {
    return 'Bonjour, vous êtes invité(e) à « $event », $date$place. Votre invitation est jointe : présentez le QR code à l\'entrée. Invitation personnelle à usage unique : ne la transférez à personne.';
  }

  @override
  String invitationMessageNamed(
    String name,
    String event,
    String date,
    String place,
  ) {
    return 'Bonjour $name, vous êtes invité(e) à « $event », $date$place. Votre invitation est jointe : présentez le QR code à l\'entrée. Invitation personnelle à usage unique : ne la transférez à personne.';
  }

  @override
  String invitationSubject(String event) {
    return 'Votre invitation : $event';
  }

  @override
  String dashboardInvitations(int admitted, int count) {
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString invitations',
      one: '1 invitation',
    );
    return 'Invités : $admittedString entrés sur $_temp0';
  }

  @override
  String get reportTypeTicket => 'Ticket';

  @override
  String get reportTypeInvitation => 'Invitation';

  @override
  String reportCategoryInvitation(String name) {
    return '$name (invitations)';
  }

  @override
  String reportInvitationsLine(int admitted, int count) {
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Dont invitations : $admittedString entrées sur $countString.';
  }

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceHelp =>
      'Sur cet appareil. « Système » suit le réglage clair ou sombre du téléphone.';

  @override
  String get appearanceSystem => 'Système';

  @override
  String get appearanceLight => 'Clair';

  @override
  String get appearanceDark => 'Sombre';

  @override
  String get categoryPriceLabel => 'Prix indicatif (facultatif)';

  @override
  String get categoryPriceHelp =>
      'Affiché sur la fiche publique de l\'événement. 0 pour une entrée gratuite.';

  @override
  String get categoryPriceError => 'Prix de 0 à 10 000 000 FCFA.';

  @override
  String get navExplore => 'Explorer';

  @override
  String get navOrganize => 'Organiser';

  @override
  String get navAccount => 'Compte';

  @override
  String get exploreSearchHint => 'Concert, lieu, promoteur…';

  @override
  String get exploreSearchLabel => 'Rechercher un événement';

  @override
  String get exploreFilters => 'Filtres';

  @override
  String get exploreAllCities => 'Toutes les villes';

  @override
  String get exploreCityTitle => 'Ville';

  @override
  String get exploreAll => 'Tous';

  @override
  String get exploreFeatured => 'À la une';

  @override
  String get exploreUpcoming => 'Prochainement';

  @override
  String exploreUpcomingIn(String city) {
    return 'Prochainement à $city';
  }

  @override
  String get exploreResults => 'Résultats';

  @override
  String exploreCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements',
      one: '1 événement',
      zero: 'Aucun événement',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyTitle => 'Aucun événement trouvé';

  @override
  String get exploreEmptyBody =>
      'Essayez une autre catégorie, une autre ville ou un autre mot.';

  @override
  String get exploreEmptyCatalogBody =>
      'Les promoteurs n\'ont pas encore publié d\'événement ouvert au public ici.';

  @override
  String get exploreResetFilters => 'Effacer les filtres';

  @override
  String get exploreErrorNetwork =>
      'Pas de connexion. Vérifiez le réseau puis réessayez.';

  @override
  String get exploreErrorLoad => 'Impossible de charger les événements.';

  @override
  String get exploreRetry => 'Réessayer';

  @override
  String get exploreMore => 'Voir plus d\'événements';

  @override
  String exploreFromPrice(String price) {
    return 'Dès $price';
  }

  @override
  String get exploreFree => 'Entrée gratuite';

  @override
  String explorePrice(String amount) {
    return '$amount FCFA';
  }

  @override
  String get exploreKindConcert => 'Concerts';

  @override
  String get exploreKindConference => 'Conférences';

  @override
  String get exploreKindWorship => 'Cultes';

  @override
  String get exploreKindSport => 'Sport';

  @override
  String get exploreKindWedding => 'Mariages';

  @override
  String get exploreKindTraining => 'Formations';

  @override
  String get exploreKindGala => 'Galas';

  @override
  String get exploreKindOther => 'Autres';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filtersClear => 'Tout effacer';

  @override
  String get filtersCategory => 'Catégorie';

  @override
  String get filtersWhen => 'Quand ?';

  @override
  String get filtersAnyTime => 'Toutes dates';

  @override
  String get filtersToday => 'Aujourd\'hui';

  @override
  String get filtersWeekend => 'Ce week-end';

  @override
  String get filtersWeek => 'Cette semaine';

  @override
  String get filtersFree => 'Entrée gratuite seulement';

  @override
  String get filtersFreeHelp => 'Quand le promoteur l\'indique';

  @override
  String get filtersApply => 'Voir les événements';

  @override
  String get publicEventAbout => 'À propos';

  @override
  String get publicEventTickets => 'Tickets';

  @override
  String get publicEventPriceUnknown => 'Prix auprès du promoteur';

  @override
  String get publicEventOrganizer => 'Organisé par';

  @override
  String get publicEventGetTicket => 'Obtenir un ticket';

  @override
  String get publicEventNoContact => 'Tickets auprès du promoteur';

  @override
  String publicEventWhatsAppMessage(String event, String date) {
    return 'Bonjour, je souhaite obtenir un ticket pour « $event » ($date). Vu sur Tikéo.';
  }

  @override
  String get publicEventWhatsAppFailed =>
      'WhatsApp n\'a pas pu s\'ouvrir sur ce téléphone.';

  @override
  String get publicEventNotFound => 'Cet événement n\'est plus visible.';

  @override
  String get publicEventShare => 'Partager';

  @override
  String publicEventShareText(String event, String date, String place) {
    return '« $event », $date — $place. Sur Tikéo.';
  }

  @override
  String get publicEventOnline => 'En cours';

  @override
  String get organizeTitle => 'Vous êtes promoteur d\'événement ?';

  @override
  String get organizeBody =>
      'Créez votre structure, émettez des tickets QR, envoyez-les par WhatsApp et contrôlez les entrées en direct.';

  @override
  String get organizePoint1 =>
      'Un ticket = une seule entrée, vérifiée en ligne';

  @override
  String get organizePoint2 => 'Listes d\'invités depuis Excel';

  @override
  String get organizePoint3 => 'Tableau de bord et rapports';

  @override
  String get eventPublicTitle => 'Visible par le public';

  @override
  String get eventPublicHelp =>
      'L\'événement apparaît dans l\'Explorer de Tikéo, sans compte, une fois publié. Ni les tickets ni les chiffres ne sont montrés.';

  @override
  String get eventPublicOn => 'Visible dans l\'Explorer';

  @override
  String get eventPublicOff => 'Privé : seuls vos invités ont leur ticket';

  @override
  String get orgPublicPhoneLabel => 'Numéro WhatsApp public';

  @override
  String get orgPublicPhoneHelp =>
      'Affiché sur vos événements publics (« Obtenir un ticket »). Facultatif.';

  @override
  String get homeAllEvents => 'Mes événements';

  @override
  String homeHello(String name) {
    return 'Bonjour $name';
  }

  @override
  String get homeHelloPlain => 'Bonjour';

  @override
  String get homeMyEventsTitle => 'Mes événements';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get homeStatAdmitted => 'entrés';

  @override
  String get homeStatIssued => 'émis';

  @override
  String get homeStatAttendance => 'présence';

  @override
  String get homeProfileLabel => 'Mon profil';

  @override
  String get eventErrorBlocked =>
      'Cet événement a été retiré du catalogue par Tikéo. Contactez le support.';

  @override
  String get eventPublicBlocked => 'Retiré du catalogue par Tikéo. Motif :';

  @override
  String get consoleTitle => 'Console Tikéo';

  @override
  String get consoleEntrySubtitle => 'Administration de la plateforme';

  @override
  String get consoleForbidden =>
      'Cette console est réservée aux administrateurs de Tikéo.';

  @override
  String get consoleLoadError =>
      'Chargement impossible. Vérifiez la connexion.';

  @override
  String get consoleRetry => 'Réessayer';

  @override
  String consoleUpdatedAt(String time) {
    return 'Chiffres de $time';
  }

  @override
  String consoleStatLine(String label, String value) {
    return '$label : $value';
  }

  @override
  String get consoleSectionOrganizations => 'Structures';

  @override
  String get consoleSectionAccounts => 'Comptes';

  @override
  String get consoleSectionEvents => 'Événements';

  @override
  String get consoleSectionTickets => 'Tickets émis';

  @override
  String get consoleSectionScans => 'Contrôles 24 h';

  @override
  String get consoleStatActiveF => 'Actives';

  @override
  String get consoleStatDisabledF => 'Suspendues';

  @override
  String get consoleStatNew7d => 'Sur 7 jours';

  @override
  String get consoleStatDisabledM => 'Désactivés';

  @override
  String get consoleStatDeletion => 'À supprimer';

  @override
  String get consoleStatUpcoming => 'À venir';

  @override
  String get consoleStatInProgress => 'En cours';

  @override
  String get consoleStatListed => 'Au catalogue';

  @override
  String get consoleStatBlocked => 'Retirés';

  @override
  String get consoleStatRedeemed => 'Entrés';

  @override
  String get consoleStatAccepted => 'Acceptés';

  @override
  String get consoleStatRefused => 'Refusés';

  @override
  String get consoleNavOrganizations => 'Structures';

  @override
  String get consoleNavOrganizationsHint =>
      'Rechercher, suspendre ou réactiver';

  @override
  String get consoleNavCatalog => 'Catalogue public';

  @override
  String get consoleNavCatalogHint => 'Modérer les événements publics';

  @override
  String get consoleNavJournal => 'Journal d\'audit';

  @override
  String get consoleNavJournalHint =>
      'Toutes les actions, des plus récentes aux plus anciennes';

  @override
  String get consoleSearchOrganizations => 'Rechercher une structure';

  @override
  String get consoleDisabledOnly => 'Suspendues seulement';

  @override
  String consoleOrgCounts(int members, int events, int tickets) {
    final intl.NumberFormat membersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String membersString = membersNumberFormat.format(members);
    final intl.NumberFormat eventsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String eventsString = eventsNumberFormat.format(events);
    final intl.NumberFormat ticketsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String ticketsString = ticketsNumberFormat.format(tickets);

    return 'Membres : $membersString · Événements : $eventsString · Tickets : $ticketsString';
  }

  @override
  String consoleOrgOwner(String name) {
    return 'Propriétaire : $name';
  }

  @override
  String consoleOrgCreated(String date) {
    return 'Créée le $date';
  }

  @override
  String get consoleSuspended => 'Suspendue';

  @override
  String consoleSuspendedSince(String date, String reason) {
    return 'Suspendue le $date. Motif : $reason';
  }

  @override
  String get consoleSuspend => 'Suspendre la structure';

  @override
  String get consoleSuspendHint =>
      'Ses membres ne pourront plus émettre ni contrôler de tickets, et ses événements quittent le catalogue.';

  @override
  String get consoleReason => 'Motif (obligatoire)';

  @override
  String get consoleReasonRequired => 'Indiquez un motif.';

  @override
  String get consoleConfirmSuspend => 'Suspendre';

  @override
  String get consoleReactivate => 'Réactiver la structure';

  @override
  String get consoleSuspendedDone => 'Structure suspendue.';

  @override
  String get consoleReactivatedDone => 'Structure réactivée.';

  @override
  String get consoleActionError => 'Action impossible. Réessayez.';

  @override
  String get consoleEmpty => 'Aucun résultat.';

  @override
  String get consoleLoadMore => 'Voir plus';

  @override
  String get consoleCancel => 'Annuler';

  @override
  String get consoleSearchEvents => 'Événement, structure ou ville';

  @override
  String get consoleBlockedOnly => 'Retirés seulement';

  @override
  String get consoleListed => 'Au catalogue';

  @override
  String get consoleNotListed => 'Hors catalogue';

  @override
  String get consoleBlocked => 'Retiré';

  @override
  String consoleBlockedSince(String date, String reason) {
    return 'Retiré le $date. Motif : $reason';
  }

  @override
  String get consoleBlock => 'Retirer du catalogue';

  @override
  String get consoleBlockHint =>
      'L\'événement quitte le catalogue et le promoteur ne pourra plus le republier. Il verra le motif.';

  @override
  String get consoleConfirmBlock => 'Retirer';

  @override
  String get consoleUnblock => 'Rétablir';

  @override
  String get consoleUnblockHint =>
      'Le promoteur pourra de nouveau rendre l\'événement public.';

  @override
  String get consoleBlockedDone => 'Événement retiré du catalogue.';

  @override
  String get consoleUnblockedDone => 'Événement rétabli.';

  @override
  String get consoleAuditAll => 'Tout';

  @override
  String get consoleAuditConsole => 'Console';

  @override
  String get consoleAuditEvents => 'Événements';

  @override
  String get consoleAuditTickets => 'Tickets';

  @override
  String get consoleAuditOrganizations => 'Structures';

  @override
  String consoleAuditBy(String name) {
    return 'par $name';
  }

  @override
  String get auditAdminEventModerated => 'Modération du catalogue';

  @override
  String get auditAdminOrganizationStatusChanged =>
      'Statut de structure modifié';

  @override
  String get auditAssignmentAdded => 'Contrôleur affecté';

  @override
  String get auditAssignmentRemoved => 'Contrôleur retiré';

  @override
  String get auditCategoryCreated => 'Catégorie créée';

  @override
  String get auditCategoryDeleted => 'Catégorie supprimée';

  @override
  String get auditCategoryPriceChanged => 'Prix indicatif modifié';

  @override
  String get auditCategoryUpdated => 'Catégorie modifiée';

  @override
  String get auditCheckpointCreated => 'Porte créée';

  @override
  String get auditCheckpointUpdated => 'Porte modifiée';

  @override
  String get auditEventCoverChanged => 'Photo d\'événement modifiée';

  @override
  String get auditEventCreated => 'Événement créé';

  @override
  String get auditEventReportExported => 'Rapport exporté';

  @override
  String get auditEventStatusChanged => 'Statut d\'événement modifié';

  @override
  String get auditEventUpdated => 'Événement modifié';

  @override
  String get auditEventVisibilityChanged => 'Visibilité publique modifiée';

  @override
  String get auditInvitationAccepted => 'Invitation d\'équipe acceptée';

  @override
  String get auditInvitationCreated => 'Invitation d\'équipe créée';

  @override
  String get auditInvitationRevoked => 'Invitation d\'équipe annulée';

  @override
  String get auditMemberLeft => 'Membre parti';

  @override
  String get auditMemberUpdated => 'Membre modifié';

  @override
  String get auditOrganizationCreated => 'Structure créée';

  @override
  String get auditOrganizationLogoChanged => 'Logo modifié';

  @override
  String get auditOrganizationPublicPhoneChanged => 'Numéro public modifié';

  @override
  String get auditOrganizationUpdated => 'Structure modifiée';

  @override
  String get auditTicketHolderUpdated => 'Titulaire modifié';

  @override
  String get auditTicketRevoked => 'Ticket annulé';

  @override
  String get auditTicketsExported => 'Tickets exportés';

  @override
  String get auditTicketsIssued => 'Tickets émis';

  @override
  String get auditDetailYes => 'oui';

  @override
  String get auditDetailNo => 'non';

  @override
  String get auditFieldPublic => 'public';

  @override
  String get auditFieldBlocked => 'retiré';

  @override
  String get auditFieldStatus => 'statut';

  @override
  String get auditFieldQuantity => 'quantité';

  @override
  String get auditFieldCount => 'nombre';

  @override
  String get auditFieldRemoved => 'supprimé';

  @override
  String get auditFieldFrom => 'de';

  @override
  String get auditFieldTo => 'vers';

  @override
  String get auditFieldRole => 'rôle';

  @override
  String get auditFieldCapacity => 'capacité';

  @override
  String get auditFieldFields => 'champs';

  @override
  String get auditFieldInvitation => 'invitation';

  @override
  String get auditFieldRows => 'lignes';

  @override
  String get auditFieldChannel => 'canal';

  @override
  String get auditFieldPrice => 'prix';

  @override
  String get eventActionStop => 'Arrêter le contrôle';

  @override
  String get eventConfirmStop =>
      'Plus aucune entrée ne sera acceptée aux portes. Cette action est définitive.';

  @override
  String get controlNotStarted => 'Le contrôle n\'a pas encore démarré';

  @override
  String get ticketsTypeAll => 'Tous les types';

  @override
  String ticketsTypeCount(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$name · $countString';
  }

  @override
  String get eventsFilterCurrent => 'En cours';

  @override
  String eventsSectionTitle(String title, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$title ($countString)';
  }

  @override
  String get favoriteAdd => 'Ajouter aux favoris';

  @override
  String get favoriteRemove => 'Retirer des favoris';

  @override
  String get favoriteAdded => 'Ajouté à vos favoris';

  @override
  String get favoriteRemoved => 'Retiré de vos favoris';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get favoritesTitle => 'Mes favoris';

  @override
  String get favoritesEmptyTitle => 'Aucun favori pour l\'instant';

  @override
  String get favoritesEmptyBody =>
      'Touchez le cœur d\'un événement pour le retrouver ici, même sans compte.';

  @override
  String get favoritesExplore => 'Explorer les événements';

  @override
  String get favoritesUpcoming => 'À venir';

  @override
  String get favoritesPast => 'Passés';

  @override
  String get welcomeCreateAccount => 'Créer un compte';

  @override
  String get welcomeHaveCode => 'J\'ai un code d\'invitation';

  @override
  String get signUpTitle => 'Créer un compte';

  @override
  String get signUpNameLabel => 'Nom et prénom';

  @override
  String get signUpNameRequired => 'Indiquez votre nom.';

  @override
  String get signUpPasswordHelp => '8 caractères au moins';

  @override
  String get signUpPasswordTooShort => '8 caractères au moins.';

  @override
  String get signUpPromoter => 'Je suis promoteur d\'événement';

  @override
  String get signUpPromoterHint =>
      'Créez votre structure pour publier des événements, émettre des tickets et gérer votre équipe.';

  @override
  String get signUpStructureRequired => 'Indiquez le nom de votre structure.';

  @override
  String get signUpCodeLabel => 'Code d\'invitation (facultatif)';

  @override
  String get signUpCodeHelp => 'Reçu d\'un promoteur pour rejoindre son équipe';

  @override
  String get signUpSubmit => 'Créer mon compte';

  @override
  String get signUpHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get signInNoAccount => 'Pas encore de compte ? Créer un compte';

  @override
  String get signUpConfirmEmail =>
      'Compte créé. Confirmez votre adresse depuis l\'e-mail reçu, puis connectez-vous.';

  @override
  String signUpWelcome(String name) {
    return 'Bienvenue sur Tikéo, $name !';
  }

  @override
  String signUpStepFailed(String reason) {
    return 'Votre compte est créé, mais l\'étape suivante a échoué : $reason Vous pouvez la refaire depuis votre profil.';
  }

  @override
  String get profilePromoterTitle => 'Vous êtes promoteur d\'événement ?';

  @override
  String get profilePromoterBody =>
      'Créez votre structure pour publier vos événements et émettre des tickets.';

  @override
  String get profilePromoterAction => 'Créer ma structure';

  @override
  String get profileJoinAction => 'Rejoindre une équipe avec un code';

  @override
  String get consoleNotAllowed => 'Action impossible pour ce compte.';

  @override
  String get consoleStatDue => 'À supprimer';

  @override
  String get consoleNavAccounts => 'Comptes';

  @override
  String get consoleNavAccountsHint =>
      'Rechercher, désactiver, supprimer à échéance';

  @override
  String get consoleSearchAccounts => 'Nom ou adresse e-mail';

  @override
  String get consoleAccountsAll => 'Tous';

  @override
  String get consoleAccountsDisabled => 'Désactivés';

  @override
  String get consoleAccountsDeletion => 'Suppression demandée';

  @override
  String get consoleAccountsDue => 'À supprimer';

  @override
  String get consoleAccountsDeleted => 'Supprimés';

  @override
  String get consoleAccountAdmin => 'Administrateur';

  @override
  String get consoleAccountDisabled => 'Désactivé';

  @override
  String get consoleAccountDeleted => 'Supprimé';

  @override
  String get consoleAccountDue => 'À supprimer';

  @override
  String consoleAccountCreated(String date) {
    return 'Inscrit le $date';
  }

  @override
  String consoleAccountLastSignIn(String date) {
    return 'Dernière connexion : $date';
  }

  @override
  String get consoleAccountNeverSignedIn => 'Jamais connecté';

  @override
  String consoleAccountCounts(int memberships, int owned) {
    final intl.NumberFormat membershipsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String membershipsString = membershipsNumberFormat.format(
      memberships,
    );
    final intl.NumberFormat ownedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String ownedString = ownedNumberFormat.format(owned);

    return 'Structures : $membershipsString · Propriétaire de $ownedString';
  }

  @override
  String consoleAccountDeletionAt(String date, String due) {
    return 'Suppression demandée le $date · échéance le $due';
  }

  @override
  String consoleAccountDisabledSince(String date, String reason) {
    return 'Désactivé le $date. Motif : $reason';
  }

  @override
  String consoleAccountDeletedOn(String date) {
    return 'Supprimé le $date';
  }

  @override
  String get consoleDisableAccount => 'Désactiver le compte';

  @override
  String get consoleDisableAccountHint =>
      'Le compte perd tous ses droits dans ses structures (émission, contrôle, équipe). Il peut toujours consulter l\'Explorer.';

  @override
  String get consoleConfirmDisable => 'Désactiver';

  @override
  String get consoleReactivateAccount => 'Réactiver le compte';

  @override
  String get consoleAccountDisabledDone => 'Compte désactivé.';

  @override
  String get consoleAccountReactivatedDone => 'Compte réactivé.';

  @override
  String get consolePurgeAccount => 'Supprimer définitivement';

  @override
  String get consolePurgeAccountHint =>
      'Le profil est anonymisé, la connexion devient impossible et les structures dont il est propriétaire sont suspendues. Les tickets et journaux restent. Action définitive.';

  @override
  String consolePurgeDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Compte supprimé. Structures suspendues : $countString';
  }

  @override
  String consolePurgeAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString comptes arrivés',
      one: '1 compte arrivé',
    );
    return 'Supprimer les $_temp0 à échéance';
  }

  @override
  String get consolePurgeAllHint =>
      'Chaque compte dont la suppression a été demandée il y a 30 jours au moins est anonymisé ; les structures dont il est propriétaire sont suspendues. Action définitive.';

  @override
  String consolePurgeAllDone(int accounts, int structures) {
    final intl.NumberFormat accountsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String accountsString = accountsNumberFormat.format(accounts);
    final intl.NumberFormat structuresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String structuresString = structuresNumberFormat.format(structures);

    return 'Comptes supprimés : $accountsString · structures suspendues : $structuresString';
  }

  @override
  String get auditAdminAccountStatusChanged => 'Statut de compte modifié';

  @override
  String get auditAdminAccountPurged => 'Compte supprimé définitivement';

  @override
  String get auditFieldStructuresSuspended => 'structures suspendues';

  @override
  String get auditFieldCause => 'cause';

  @override
  String get auditValueOwnerDeleted => 'compte du propriétaire supprimé';

  @override
  String get announcementDismiss => 'Masquer l\'annonce';

  @override
  String get supportEntryTitle => 'Aide et support';

  @override
  String get supportEntrySubtitle => 'Posez une question à l\'équipe Tikéo';

  @override
  String supportUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString nouvelles réponses',
      one: '1 nouvelle réponse',
    );
    return '$_temp0';
  }

  @override
  String get supportTitle => 'Aide et support';

  @override
  String get supportNew => 'Nouvelle demande';

  @override
  String get supportEmptyTitle => 'Aucune demande';

  @override
  String get supportEmptyBody =>
      'Une question, un problème ? Écrivez à l\'équipe Tikéo : la réponse arrive ici.';

  @override
  String get supportLoadError =>
      'Chargement impossible. Vérifiez la connexion.';

  @override
  String get supportStatusOpen => 'En attente';

  @override
  String get supportStatusAnswered => 'Répondu';

  @override
  String get supportStatusClosed => 'Fermée';

  @override
  String get supportCategoryQuestion => 'Question';

  @override
  String get supportCategoryProblem => 'Problème';

  @override
  String get supportCategoryAccount => 'Compte';

  @override
  String get supportCategoryPayment => 'Paiement';

  @override
  String get supportCategoryOther => 'Autre';

  @override
  String get supportSubjectLabel => 'Sujet';

  @override
  String get supportBodyLabel => 'Votre message';

  @override
  String get supportCategoryLabel => 'Catégorie';

  @override
  String get supportSend => 'Envoyer';

  @override
  String get supportSent =>
      'Demande envoyée. Vous serez prévenu ici dès la réponse.';

  @override
  String get supportSubjectInvalid => 'Entre 3 et 120 caractères.';

  @override
  String get supportBodyInvalid =>
      'Écrivez votre message (2 000 caractères au plus).';

  @override
  String get supportLimit =>
      'Trop de demandes en cours ou de messages : réessayez plus tard.';

  @override
  String get supportNotFound => 'Demande introuvable.';

  @override
  String get supportError => 'Envoi impossible. Vérifiez la connexion.';

  @override
  String get supportReplyHint => 'Votre réponse';

  @override
  String get supportClose => 'Fermer la demande';

  @override
  String get supportClosed =>
      'Demande fermée. Écrivez un message pour la rouvrir.';

  @override
  String get supportTeam => 'Support Tikéo';

  @override
  String supportLastMessage(String date) {
    return 'Dernier message le $date';
  }

  @override
  String get consoleNavSupport => 'Support';

  @override
  String get consoleNavSupportHint => 'Répondre aux demandes des utilisateurs';

  @override
  String consoleNavSupportUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString demandes non lues',
      one: '1 demande non lue',
      zero: 'Aucune demande non lue',
    );
    return '$_temp0';
  }

  @override
  String get consoleSupportAll => 'Toutes';

  @override
  String get consoleSupportSearch => 'Sujet, nom ou adresse';

  @override
  String consoleSupportFrom(String name, String email) {
    return '$name · $email';
  }

  @override
  String consoleSupportMessages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get consoleNavAnnouncements => 'Annonces';

  @override
  String get consoleNavAnnouncementsHint =>
      'Publier un message dans l\'application';

  @override
  String get consoleAnnouncementNew => 'Nouvelle annonce';

  @override
  String get consoleAnnouncementTitleLabel => 'Titre';

  @override
  String get consoleAnnouncementBodyLabel => 'Message';

  @override
  String get consoleAnnouncementAudience => 'Destinataires';

  @override
  String get consoleAudienceVisitors => 'Visiteurs sans compte';

  @override
  String get consoleAudienceUsers => 'Comptes classiques';

  @override
  String get consoleAudiencePromoters => 'Promoteurs';

  @override
  String get consoleAudienceControllers => 'Contrôleurs';

  @override
  String get consoleAnnouncementAudienceRequired =>
      'Choisissez au moins un destinataire.';

  @override
  String get consoleAnnouncementImportant => 'Importante (mise en avant)';

  @override
  String get consoleAnnouncementDuration => 'Affichée pendant';

  @override
  String get consoleDuration1d => '24 heures';

  @override
  String get consoleDuration7d => '7 jours';

  @override
  String get consoleDuration30d => '30 jours';

  @override
  String get consoleDurationNone => 'Sans fin';

  @override
  String get consoleAnnouncementPublish => 'Publier';

  @override
  String get consoleAnnouncementPublished => 'Annonce publiée.';

  @override
  String get consoleAnnouncementArchive => 'Retirer';

  @override
  String get consoleAnnouncementArchived => 'Annonce retirée.';

  @override
  String get consoleAnnouncementActive => 'En ligne';

  @override
  String get consoleAnnouncementInactive => 'Hors ligne';

  @override
  String consoleAnnouncementUntil(String date) {
    return 'Jusqu\'au $date';
  }

  @override
  String get consoleAnnouncementInvalid =>
      'Titre de 3 à 80 caractères, message de 1 000 caractères au plus.';

  @override
  String get consoleStatSupportOpen => 'Support en attente';

  @override
  String get auditAdminSupportReplied => 'Réponse du support';

  @override
  String get auditAdminAnnouncementPublished => 'Annonce publiée';

  @override
  String get auditAdminAnnouncementArchived => 'Annonce retirée';

  @override
  String get auditFieldAudiences => 'destinataires';

  @override
  String get auditFieldLevel => 'importance';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsEntrySubtitle =>
      'Apparence, langue, sons, stockage, version, mentions légales';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsImageCache => 'Images enregistrées';

  @override
  String settingsImageCacheSize(String size) {
    return '$size sur ce téléphone';
  }

  @override
  String get settingsImageCacheEmpty => 'Aucune image enregistrée';

  @override
  String get settingsImageCacheClear => 'Vider';

  @override
  String get settingsImageCacheCleared => 'Images retirées du téléphone.';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsVersion(int build) {
    final intl.NumberFormat buildNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String buildString = buildNumberFormat.format(build);

    return 'Version pilote $buildString';
  }

  @override
  String get settingsVersionDev => 'Version de développement';

  @override
  String get settingsCheckUpdate => 'Rechercher une mise à jour';

  @override
  String get settingsUpToDate => 'Vous avez la dernière version.';

  @override
  String get settingsCheckFailed =>
      'Vérification impossible. Vérifiez la connexion.';

  @override
  String get legalTerms => 'Conditions d\'utilisation';

  @override
  String get legalPrivacy => 'Politique de confidentialité';

  @override
  String legalUpdated(int version, String date) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Version $versionString du $date';
  }

  @override
  String get legalLoadError => 'Document indisponible. Vérifiez la connexion.';

  @override
  String get legalRetry => 'Réessayer';

  @override
  String get signUpLegalPrefix => 'En créant un compte, vous acceptez les ';

  @override
  String get signUpLegalAnd => ' et la ';

  @override
  String get updateAvailableTitle => 'Nouvelle version disponible';

  @override
  String updateAvailableBody(int build) {
    final intl.NumberFormat buildNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String buildString = buildNumberFormat.format(build);

    return 'La version pilote $buildString est prête. Téléchargez-la puis installez-la par-dessus l\'actuelle : vos données sont conservées.';
  }

  @override
  String get updateDownload => 'Télécharger';

  @override
  String get consoleNavLegal => 'Mentions légales';

  @override
  String get consoleNavLegalHint =>
      'Conditions d\'utilisation et confidentialité';

  @override
  String consoleLegalVersion(int version, String date) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Version $versionString · $date';
  }

  @override
  String get consoleLegalTitleLabel => 'Titre';

  @override
  String get consoleLegalBodyLabel => 'Texte';

  @override
  String get consoleLegalBodyHelp =>
      'Ligne vide entre deux paragraphes, « ## » pour un intertitre, « - » pour une puce. Complétez les passages entre crochets.';

  @override
  String get consoleLegalEdit => 'Modifier';

  @override
  String get consoleLegalPreview => 'Aperçu';

  @override
  String get consoleLegalSave => 'Publier';

  @override
  String consoleLegalConfirm(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Publier la version $versionString ?';
  }

  @override
  String get consoleLegalConfirmBody =>
      'Le nouveau texte s\'affiche aussitôt pour tous les utilisateurs.';

  @override
  String consoleLegalSaved(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Version $versionString publiée.';
  }

  @override
  String get consoleLegalInvalid =>
      'Titre de 3 à 80 caractères, texte de 20 à 20 000 caractères.';

  @override
  String consoleLegalPlaceholders(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString passages entre crochets restent à compléter.',
      one: '1 passage entre crochets reste à compléter.',
    );
    return '$_temp0';
  }

  @override
  String get auditAdminLegalUpdated => 'Mentions légales modifiées';

  @override
  String get auditFieldDocument => 'document';

  @override
  String selectionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get selectionClose => 'Quitter la sélection';

  @override
  String get selectionAll => 'Tout sélectionner';

  @override
  String get selectionHint =>
      'Appui long sur un ticket pour en sélectionner plusieurs';

  @override
  String get ticketsBulkPdf => 'Partager en PDF';

  @override
  String get ticketsBulkRevoke => 'Annuler';

  @override
  String ticketsBulkRevokeTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Annuler $countString tickets ?',
      one: 'Annuler 1 ticket ?',
    );
    return '$_temp0';
  }

  @override
  String get ticketsBulkRevokeBody =>
      'Ils seront refusés à l\'entrée. Les tickets déjà utilisés ou annulés ne changent pas. Cette action est définitive.';

  @override
  String ticketsBulkRevoked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tickets annulés.',
      one: '1 ticket annulé.',
      zero: 'Aucun ticket à annuler.',
    );
    return '$_temp0';
  }

  @override
  String get ticketsBulkNothingValid =>
      'Aucun ticket valable dans la sélection.';

  @override
  String get ticketsBulkError => 'Action impossible. Vérifiez la connexion.';

  @override
  String get eventDuplicate => 'Dupliquer';

  @override
  String get eventDuplicateTitle => 'Dupliquer l\'événement';

  @override
  String get eventDuplicateBody =>
      'Catégories, portes et équipe sont recopiées. Les tickets ne le sont pas. La copie est un brouillon.';

  @override
  String eventDuplicateName(String title) {
    return '$title (copie)';
  }

  @override
  String get eventDuplicateNameLabel => 'Titre de la copie';

  @override
  String get eventDuplicateStart => 'Début';

  @override
  String get eventDuplicateKeepLength =>
      'La durée reste la même que celle de l\'original.';

  @override
  String get eventDuplicateSubmit => 'Créer la copie';

  @override
  String get eventDuplicated => 'Copie créée en brouillon.';

  @override
  String get eventDuplicateError =>
      'Copie impossible. Vérifiez la date et la connexion.';

  @override
  String get firstStepsTitle => 'Premiers pas';

  @override
  String firstStepsProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString sur $totalString';
  }

  @override
  String get firstStepsHide => 'Masquer';

  @override
  String get firstStepsEvent => 'Créer un événement';

  @override
  String get firstStepsCategory => 'Ajouter un type de ticket';

  @override
  String get firstStepsPublish => 'Publier l\'événement';

  @override
  String get firstStepsIssue => 'Émettre un premier ticket';

  @override
  String get firstStepsTeam => 'Inviter un contrôleur';

  @override
  String get firstStepsPhone => 'Ajouter le numéro WhatsApp public';

  @override
  String get firstStepsDone => 'Bravo, votre structure est prête !';

  @override
  String get navWallet => 'Mes tickets';

  @override
  String get walletTitle => 'Mes tickets';

  @override
  String get walletEntrySubtitle =>
      'Les tickets que vous avez reçus pour aller à un événement';

  @override
  String get walletAdd => 'Ajouter un ticket';

  @override
  String get walletEmptyTitle => 'Aucun ticket pour l\'instant';

  @override
  String get walletEmptyBody =>
      'Vous avez reçu un ticket par WhatsApp, SMS ou e-mail ? Ajoutez-le ici : scannez son QR ou choisissez son image.';

  @override
  String get walletUpcoming => 'À venir';

  @override
  String get walletPast => 'Passés';

  @override
  String walletOffline(String date) {
    return 'Hors connexion : liste enregistrée le $date. Les QR restent valables ; leur état sera vérifié à l\'entrée.';
  }

  @override
  String get walletLoadError => 'Chargement impossible. Vérifiez la connexion.';

  @override
  String get walletRetry => 'Réessayer';

  @override
  String get walletStatusValid => 'Valable';

  @override
  String get walletStatusUsed => 'Utilisé';

  @override
  String get walletStatusRevoked => 'Annulé';

  @override
  String get walletStatusExpired => 'Expiré';

  @override
  String get walletAddTitle => 'Ajouter un ticket';

  @override
  String get walletAddIntro =>
      'Seul le QR prouve que le ticket est à vous : une fois ajouté, il ne peut plus entrer dans un autre compte.';

  @override
  String get walletAddScan => 'Scanner le QR';

  @override
  String get walletAddScanHint =>
      'Avec l\'appareil photo, si le ticket est sur un autre écran ou sur papier';

  @override
  String get walletAddImage => 'Choisir une image';

  @override
  String get walletAddImageHint =>
      'L\'image du ticket reçue par WhatsApp ou enregistrée dans la galerie';

  @override
  String get walletAddPaste => 'Coller le code';

  @override
  String get walletAddPasteHint => 'Code commençant par TS1.';

  @override
  String get walletAddPasteSubmit => 'Ajouter';

  @override
  String get walletAddScanTitle => 'Scannez le QR du ticket';

  @override
  String get walletAdded => 'Ticket ajouté à vos tickets.';

  @override
  String get walletNoQrInImage => 'Aucun QR lisible dans cette image.';

  @override
  String get walletErrorInvalid => 'Ce code n\'est pas un ticket Tikéo.';

  @override
  String get walletErrorUnknown => 'Ticket inconnu.';

  @override
  String get walletErrorRevoked =>
      'Ce ticket a été annulé par l\'organisateur.';

  @override
  String get walletErrorClaimed =>
      'Ce ticket est déjà dans le compte d\'une autre personne.';

  @override
  String get walletErrorNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get walletErrorOther => 'Ajout impossible. Réessayez.';

  @override
  String get walletShowAtEntry =>
      'Présentez ce QR à l\'entrée. Montez la luminosité de l\'écran.';

  @override
  String walletUsedAt(String date) {
    return 'Utilisé le $date';
  }

  @override
  String get walletRevokedNote =>
      'Ce ticket a été annulé : il sera refusé à l\'entrée.';

  @override
  String walletOrganizer(String name) {
    return 'Organisé par $name';
  }

  @override
  String get walletRelease => 'Retirer de mes tickets';

  @override
  String get walletReleaseTitle => 'Retirer ce ticket ?';

  @override
  String get walletReleaseBody =>
      'Il ne sera plus affiché dans votre compte. Vous pourrez l\'ajouter de nouveau avec son QR, tant qu\'un autre compte ne l\'a pas fait.';

  @override
  String get walletReleased => 'Ticket retiré.';

  @override
  String get walletNotFound => 'Ce ticket n\'est plus dans vos tickets.';

  @override
  String get auditTicketClaimed => 'Ticket ajouté par son détenteur';

  @override
  String get auditTicketReleased => 'Ticket retiré par son détenteur';

  @override
  String get pushOpen => 'Voir';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushSwitch => 'Recevoir les notifications';

  @override
  String get settingsPushActive =>
      'Réponses du support, annonces importantes, ouverture du contrôle';

  @override
  String get settingsPushDisabled => 'Coupées sur ce téléphone';

  @override
  String get settingsPushDenied =>
      'Refusées dans les réglages du téléphone : autorisez Tikéo dans Réglages › Notifications.';

  @override
  String get settingsPushUnavailable =>
      'Indisponibles dans cette version de l\'application';

  @override
  String get settingsPushTest => 'Envoyer une notification de test';

  @override
  String get settingsPushTestHint =>
      'Vérifie la réception sur ce téléphone, application fermée.';

  @override
  String get settingsPushTestSent =>
      'Envoi dans 8 secondes : mettez Tikéo en arrière-plan (bouton Accueil) pour voir la notification.';

  @override
  String get settingsPushTestNoDevice =>
      'Ce téléphone n\'est pas encore enregistré. Fermez et rouvrez Tikéo, puis réessayez.';

  @override
  String get settingsPushTestRateLimited =>
      'Trop d\'essais : réessayez dans une heure.';

  @override
  String get settingsPushTestNetwork =>
      'Envoi impossible. Vérifiez votre connexion et réessayez.';

  @override
  String verdictHolder(String name) {
    return 'Titulaire : $name';
  }

  @override
  String get scannerSearch => 'QR perdu ? Rechercher';

  @override
  String get doorSearchTitle => 'Retrouver un ticket';

  @override
  String get doorSearchIntro =>
      'Cherchez par nom, téléphone ou référence, puis validez l\'entrée. Un ticket ne passe qu\'une fois.';

  @override
  String get doorSearchHint => 'Nom, téléphone ou référence';

  @override
  String get doorSearchEmpty => 'Aucun ticket trouvé.';

  @override
  String get doorSearchTooShort => 'Au moins 3 caractères.';

  @override
  String get doorSearchRateLimited =>
      'Trop de recherches : réessayez dans quelques minutes.';

  @override
  String get doorSearchForbidden =>
      'Recherche possible seulement quand le contrôle est ouvert, à votre porte.';

  @override
  String get doorSearchNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get doorSearchValidate => 'Valider l\'entrée';

  @override
  String get auditScanManual => 'Entrée validée sans QR (recherche)';

  @override
  String get journalTitle => 'Journal de la structure';

  @override
  String get journalEntrySubtitle =>
      'Qui a émis, annulé, validé ou modifié quoi';

  @override
  String get journalAll => 'Tout';

  @override
  String get journalEvents => 'Événements';

  @override
  String get journalTickets => 'Tickets';

  @override
  String get journalControl => 'Contrôle';

  @override
  String get journalTeam => 'Équipe';

  @override
  String get journalStructure => 'Structure';

  @override
  String get journalByTikeo => 'par l\'équipe Tikéo';

  @override
  String get auditEventDuplicated => 'Événement dupliqué';

  @override
  String get auditFieldResult => 'résultat';

  @override
  String get auditFieldReason => 'motif';

  @override
  String get auditFieldBulk => 'sélection';

  @override
  String get auditFieldTitle => 'titre';

  @override
  String get auditValueAccepted => 'entrée autorisée';

  @override
  String get auditValueAlreadyUsed => 'déjà utilisé';

  @override
  String get auditValueRefused => 'refusé';

  @override
  String get ticketScanHere => 'Scannez ici';

  @override
  String ticketNumber(String number) {
    return 'N° $number';
  }

  @override
  String get templatesEntry => 'Modèles des tickets';

  @override
  String get templatesTitle => 'Modèles des tickets';

  @override
  String get templatesIntro =>
      'Chaque catégorie a son modèle : l\'image envoyée et le PDF le reprennent. Le QR et le contrôle à l\'entrée ne changent pas.';

  @override
  String templatesProposed(String theme) {
    return 'Proposé : $theme';
  }

  @override
  String templatesChosen(String theme) {
    return 'Modèle : $theme';
  }

  @override
  String get templatesCustom => 'Design importé';

  @override
  String get templatesLoadError => 'Modèles indisponibles pour le moment.';

  @override
  String templateEditorTitle(String category) {
    return 'Modèle — $category';
  }

  @override
  String get templateBuiltinSection => 'Modèles Tikéo';

  @override
  String get templateSingleFont => 'Titre en une seule police';

  @override
  String get templateSingleFontHint => 'Sans écriture manuscrite ni condensée';

  @override
  String get templateCustomSection => 'Votre propre design';

  @override
  String get templateImportHint =>
      'Image JPG ou PNG à plat, en bande horizontale (environ 2,4 × 1), avec un espace libre pour le QR.';

  @override
  String get templateImport => 'Importer mon design';

  @override
  String get templateAdjust => 'Placer le QR';

  @override
  String get templateSave => 'Enregistrer';

  @override
  String get templateSaved => 'Modèle enregistré';

  @override
  String get templateReset => 'Revenir au modèle proposé';

  @override
  String get templateResetDone => 'Modèle proposé rétabli';

  @override
  String get templateErrorQrTooSmall =>
      'Le QR doit occuper au moins 35 % de la hauteur du ticket.';

  @override
  String get templateErrorImage =>
      'Image introuvable : importez-la de nouveau.';

  @override
  String get templateErrorTooLarge => 'Image trop lourde (2 Mo au plus).';

  @override
  String get templateErrorFormat =>
      'Format attendu : une image en bande horizontale (environ 2,4 × 1).';

  @override
  String get templateErrorLocked =>
      'Événement clôturé : le modèle ne peut plus changer.';

  @override
  String get templateErrorNotFound =>
      'Vous n\'avez pas les droits pour modifier ce modèle.';

  @override
  String get templateErrorInvalid =>
      'Placement refusé : le QR doit rester entièrement sur le ticket.';

  @override
  String get templateErrorNetwork =>
      'Enregistrement impossible. Vérifiez votre connexion et réessayez.';

  @override
  String get placementTitle => 'Placer le QR';

  @override
  String get placementHelp =>
      'Faites glisser le QR et le bloc de la référence. Pincez le QR ou utilisez le curseur pour changer sa taille.';

  @override
  String get placementSize => 'Taille du QR';

  @override
  String get placementMinReached =>
      'Taille minimale atteinte : le QR doit occuper au moins 35 % de la hauteur du ticket pour rester lisible à l\'entrée.';

  @override
  String get placementAuto => 'Placement automatique';

  @override
  String get placementDone => 'Valider';

  @override
  String get placementFoundSquare =>
      'QR posé dans la zone blanche de votre design.';

  @override
  String get placementFallback =>
      'Aucune zone blanche assez grande : le QR est posé sur son propre carré blanc, à droite.';

  @override
  String get ticketTheme1 => 'Concert';

  @override
  String get ticketTheme2 => 'Festival culturel';

  @override
  String get ticketTheme3 => 'Cinéma';

  @override
  String get ticketTheme4 => 'Match';

  @override
  String get ticketTheme5 => 'Théâtre';

  @override
  String get ticketTheme6 => 'Conférence';

  @override
  String get ticketTheme7 => 'Exposition';

  @override
  String get ticketTheme8 => 'Festival gastronomique';

  @override
  String get ticketTheme9 => 'Atelier jeunes';

  @override
  String get ticketTheme10 => 'Challenge sportif';

  @override
  String get ticketTheme11 => 'Soirée club';

  @override
  String get ticketTheme12 => 'Workshop';

  @override
  String get auditTicketTemplateUpdated => 'Modèle de ticket modifié';

  @override
  String get auditValueTemplateBuiltin => 'modèle Tikéo';

  @override
  String get auditValueTemplateCustom => 'design importé';

  @override
  String get auditValueTemplateDefault => 'modèle proposé';

  @override
  String get auditValueTagline => 'accroche';

  @override
  String get auditFieldTemplateKind => 'modèle';

  @override
  String get ticketsBulkSheet => 'Imprimer des tickets';

  @override
  String get templateCrop => 'Cadrer la photo';

  @override
  String get templateCopy => 'Utiliser ce modèle pour d\'autres catégories';

  @override
  String get templateCopyTitle => 'Appliquer aussi ce modèle à :';

  @override
  String templateCopyConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Appliquer à $count autres catégories',
      one: 'Appliquer à 1 autre catégorie',
      zero: 'Choisissez des catégories',
    );
    return '$_temp0';
  }

  @override
  String templateCopied(int count) {
    return 'Modèle enregistré pour $count catégories';
  }

  @override
  String get placementSampleHolder => 'Awa Ouédraogo';

  @override
  String get placementHolderFree => 'Placer le nom du titulaire à part';

  @override
  String get placementHolderFreeHint => 'Sinon, il est écrit sous la référence';

  @override
  String get cropTitle => 'Cadrer la photo';

  @override
  String get cropHelp =>
      'Faites glisser la photo pour choisir la partie visible, puis réglez le zoom.';

  @override
  String get cropZoom => 'Zoom';

  @override
  String get cropReset => 'Cadrage par défaut';

  @override
  String get walletLargeQr => 'À présenter à l\'entrée';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';

  @override
  String get settingsLanguageFr => 'Français';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageHelp =>
      'Les tickets, PDF et rapports que vous envoyez suivent aussi cette langue.';

  @override
  String get auditFieldLanguage => 'langue';

  @override
  String get categoryEntriesLabel => 'Entrées par ticket';

  @override
  String get categoryEntriesSingle => 'Une seule';

  @override
  String get categoryEntriesPerDay => 'Une par jour';

  @override
  String get categoryEntriesLimited => 'Plusieurs';

  @override
  String get categoryEntriesHelpSingle =>
      'Le ticket est utilisé dès la première entrée.';

  @override
  String get categoryEntriesHelpPerDay =>
      'Pass journalier : une entrée par jour, pendant tout l\'événement.';

  @override
  String get categoryEntriesHelpLimited =>
      'Pass : le ticket permet ce nombre d\'entrées au total, sur un ou plusieurs jours.';

  @override
  String get categoryEntriesLocked =>
      'Règle figée : des tickets de cette catégorie sont déjà entrés.';

  @override
  String get categoryMaxEntriesLabel => 'Nombre d\'entrées';

  @override
  String categoryMaxEntriesError(int min, int max) {
    return 'De $min à $max entrées.';
  }

  @override
  String get categoryPassDaily => 'Pass journalier';

  @override
  String categoryPassEntries(int count) {
    return 'Pass $count entrées';
  }

  @override
  String get setupErrorEntriesInvalid =>
      'Règle d\'entrée invalide : un pass compte de 2 à 100 entrées.';

  @override
  String get setupErrorEntriesLocked =>
      'Des tickets de cette catégorie sont déjà entrés : la règle d\'entrée ne peut plus changer.';

  @override
  String verdictPassEntry(int used, int max) {
    return 'Entrée $used sur $max';
  }

  @override
  String verdictPassLastEntry(int used, int max) {
    return 'Dernière entrée du pass ($used sur $max)';
  }

  @override
  String verdictPassExhausted(int max) {
    return 'Pass épuisé : $max entrées utilisées';
  }

  @override
  String verdictPassDay(int count) {
    return 'Pass journalier · jour d\'entrée n° $count';
  }

  @override
  String verdictPassDayUsed(int count) {
    return 'Pass journalier · déjà entré aujourd\'hui ($count jours au total)';
  }

  @override
  String verdictEnteredToday(String time) {
    return 'Entré aujourd\'hui à $time';
  }

  @override
  String verdictEnteredTodayAt(String time, String checkpoint) {
    return 'Entré aujourd\'hui à $time · $checkpoint';
  }

  @override
  String verdictLastEntry(String time) {
    return 'Dernière entrée à $time';
  }

  @override
  String verdictLastEntryAt(String time, String checkpoint) {
    return 'Dernière entrée à $time · $checkpoint';
  }

  @override
  String dashboardEntriesNote(int entries) {
    return '$entries entrées au total (pass à plusieurs entrées)';
  }

  @override
  String get auditCategoryEntriesChanged => 'Règle d\'entrée modifiée';

  @override
  String get auditValueEntrySingle => 'une seule entrée';

  @override
  String get auditValueEntryPerDay => 'une par jour';

  @override
  String get auditValueEntryLimited => 'plusieurs entrées';

  @override
  String get auditFieldEntryPolicy => 'entrées';

  @override
  String get auditFieldMaxEntries => 'nombre d\'entrées';

  @override
  String get settingsReminders => 'Rappels avant l\'événement';

  @override
  String get settingsRemindersHint =>
      'La veille et 2 h avant, pour les tickets ajoutés à « Mes tickets ».';

  @override
  String get settingsRemindersError =>
      'Réglage non enregistré. Vérifiez la connexion et réessayez.';

  @override
  String get summaryTitle => 'Bilan';

  @override
  String get summaryHeadline => 'En bref';

  @override
  String summaryPeopleLine(int admitted, int issued) {
    return '$admitted personnes entrées sur $issued tickets';
  }

  @override
  String summaryAverageOthers(int count, String rate) {
    return 'Moyenne de vos $count derniers événements : $rate';
  }

  @override
  String summaryPassLine(int entries, int passes) {
    return '$entries entrées avec $passes pass';
  }

  @override
  String summarySpan(String first, String last) {
    return 'Première entrée à $first, dernière à $last';
  }

  @override
  String get summaryEmpty => 'Aucune entrée enregistrée pour cet événement.';

  @override
  String get summaryHoursTitle => 'Heures d\'affluence';

  @override
  String summaryPeak(String hour, int entries) {
    return 'Heure de pointe : $hour · $entries entrées';
  }

  @override
  String summaryHourRange(int start, int end) {
    return '$start h – $end h';
  }

  @override
  String get summaryDaysTitle => 'Par jour';

  @override
  String summaryDayLine(int people, int entries) {
    return '$people personnes · $entries entrées';
  }

  @override
  String get summaryCompareTitle => 'Comparaison avec vos événements';

  @override
  String get summaryCompareHint =>
      'Taux de présence : personnes entrées sur tickets émis.';

  @override
  String summaryThisEvent(String title) {
    return '$title (cet événement)';
  }

  @override
  String get summaryErrorLoad => 'Impossible de charger le bilan.';

  @override
  String get summaryColDay => 'Jour';

  @override
  String get summaryColPeople => 'Personnes';

  @override
  String get summaryColEntries => 'Entrées';

  @override
  String get summaryColEvent => 'Événement';

  @override
  String get summaryColDate => 'Date';

  @override
  String get componentGalleryTitle => 'Composants Tikéo';

  @override
  String get auditBillingInvoiceIssued => 'Facture à l\'usage émise';

  @override
  String get auditBillingOrganizationDefaultSet =>
      'Facturation de la structure choisie';

  @override
  String get auditBillingEventModeSet => 'Facturation de l\'événement choisie';

  @override
  String get auditBillingAddonAdded => 'Supplément ajouté à l\'événement';

  @override
  String get auditBillingRequestCreated => 'Demande d\'activation envoyée';

  @override
  String get auditAdminBillingPackSaved => 'Pack enregistré';

  @override
  String get auditAdminBillingPackStatusSet => 'État du pack modifié';

  @override
  String get auditAdminBillingSettingsSaved => 'Réglages de paiement modifiés';

  @override
  String get auditAdminBillingRequestActivated =>
      'Demande validée, paiement reçu';

  @override
  String get auditAdminBillingRequestRefused => 'Demande refusée';

  @override
  String get auditAdminBillingSubscriptionGranted => 'Abonnement offert';

  @override
  String get auditAdminBillingSubscriptionCancelled => 'Abonnement annulé';

  @override
  String get auditAdminBillingInvoicePaid => 'Facture réglée';

  @override
  String get auditFieldEntries => 'entrées';

  @override
  String get auditFieldAmount => 'montant (FCFA)';

  @override
  String get auditFieldBillingSystem => 'facturation';

  @override
  String get auditFieldBillingMode => 'facturation';

  @override
  String get auditFieldOption => 'option';

  @override
  String get auditFieldUnits => 'tranches';

  @override
  String get auditFieldDuration => 'durée';

  @override
  String get auditFieldCreated => 'création';

  @override
  String get auditFieldAddons => 'suppléments';

  @override
  String get auditValueBillingFlat => 'forfait';

  @override
  String get auditValueBillingUsage => 'à l\'usage';

  @override
  String get auditValueBillingInherit => 'comme la structure';

  @override
  String get auditValueDurationMonth => 'mensuel';

  @override
  String get auditValueDurationQuarter => 'trimestriel';

  @override
  String get auditValueDurationSemester => 'semestriel';

  @override
  String get auditValueDurationYear => 'annuel';

  @override
  String get auditValueDurationEvent => 'un seul événement';

  @override
  String get auditValueDurationUnlimited => 'sans fin';

  @override
  String get auditValueChannelOrangeMoney => 'Orange Money';

  @override
  String get auditValueChannelMoovMoney => 'Moov Money';

  @override
  String get auditValueChannelOther => 'autre';

  @override
  String get billingOptionStructures => 'Structures du compte';

  @override
  String get billingOptionActiveEvents => 'Événements actifs en même temps';

  @override
  String get billingOptionTicketsPerEvent => 'Tickets par événement';

  @override
  String get billingOptionTicketsPerPeriod => 'Tickets par période';

  @override
  String get billingOptionMembersPerStructure =>
      'Membres de l\'équipe par structure';

  @override
  String get billingOptionControllersPerEvent => 'Contrôleurs par événement';

  @override
  String get billingOptionAssistedSend => 'Envoi assisté';

  @override
  String get billingOptionBulkSend => 'Envoi en série';

  @override
  String get billingOptionImport => 'Import Excel / CSV';

  @override
  String get billingOptionExport => 'Export (CSV, rapports, PDF)';

  @override
  String get billingOptionPrintSheet => 'Planche d\'impression A4';

  @override
  String get billingOptionCustomDesign => 'Design de ticket importé';

  @override
  String get billingOptionNamedTickets => 'Tickets nominatifs';

  @override
  String get billingOptionLiveDashboard => 'Tableau de bord en direct';

  @override
  String get billingOptionPublicCatalog => 'Catalogue public';

  @override
  String get billingOptionPrioritySupport => 'Support prioritaire';

  @override
  String get homeHeroSubtitle => 'Voici l\'essentiel de vos événements.';

  @override
  String get homeTileEvents => 'Événements';

  @override
  String get homeTileLive => 'En cours';

  @override
  String get homeTileUpcoming => 'À venir';

  @override
  String get homeTileDrafts => 'Brouillons';

  @override
  String get homeOrgHint => 'Structure active';

  @override
  String get exploreHeroTitle => 'Découvrez les événements';

  @override
  String get exploreHeroSubtitle =>
      'Concerts, conférences, sport… près de chez vous.';

  @override
  String get exploreSee => 'Voir';

  @override
  String get publicEventCall => 'Appeler le promoteur';

  @override
  String get publicEventCallFailed =>
      'L\'appel n\'a pas pu s\'ouvrir sur ce téléphone.';

  @override
  String get ticketsHeroSubtitle => 'Émettez, envoyez et suivez vos tickets.';

  @override
  String get teamHeroTitle => 'Mon équipe';

  @override
  String get teamStatMembers => 'membres actifs';

  @override
  String get teamStatManagers => 'gestionnaires';

  @override
  String get teamStatControllers => 'contrôleurs';

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Membres de l\'équipe ($count)',
      zero: 'Membres de l\'équipe',
    );
    return '$_temp0';
  }

  @override
  String get profileHeroTitle => 'Mon profil';

  @override
  String get signInHeroSubtitle => 'Heureux de vous revoir.';

  @override
  String get signInEmailHint => 'vous@exemple.bf';

  @override
  String get signUpHeroSubtitle => 'Quelques secondes pour commencer.';

  @override
  String get signUpPasswordRules =>
      '8 caractères au moins, avec des lettres et des chiffres';

  @override
  String get forgotHeroSubtitle =>
      'Recevez un lien pour en choisir un nouveau.';

  @override
  String get forgotSentTitle => 'Lien envoyé';

  @override
  String get forgotNothingTitle => 'Rien reçu ?';

  @override
  String get forgotNothingBody =>
      'Regardez dans les courriers indésirables, puis renvoyez le lien si besoin.';

  @override
  String get forgotResendLink => 'Renvoyer le lien';

  @override
  String get authOpenMailbox => 'Ouvrir ma messagerie';

  @override
  String get authOpenMailboxFailed =>
      'Ouvrez votre messagerie pour trouver l\'e-mail de Tikéo.';

  @override
  String get authResend => 'Renvoyer l\'e-mail';

  @override
  String authResendIn(String action, int seconds) {
    return '$action dans $seconds s';
  }

  @override
  String get authResent => 'E-mail renvoyé.';

  @override
  String get confirmEmailTitle => 'Confirmez votre adresse';

  @override
  String get confirmEmailBody =>
      'Nous avons envoyé un lien de confirmation à :';

  @override
  String get confirmEmailStep1 => 'Ouvrez l\'e-mail de Tikéo.';

  @override
  String get confirmEmailStep2 => 'Touchez le lien de confirmation.';

  @override
  String get confirmEmailStep3 => 'Revenez ici et connectez-vous.';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthMedium => 'Moyen';

  @override
  String get passwordStrengthGood => 'Bon';

  @override
  String get passwordStrengthStrong => 'Excellent';

  @override
  String passwordStrengthLabel(String level) {
    return 'Solidité du mot de passe : $level';
  }

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordSubtitle => 'Choisissez-le, puis vous serez connecté.';

  @override
  String get newPasswordSubmit => 'Enregistrer le mot de passe';

  @override
  String get newPasswordRuleLength => '8 caractères au moins';

  @override
  String get newPasswordRuleLetters => 'Des lettres';

  @override
  String get newPasswordRuleDigits => 'Des chiffres';

  @override
  String get joinHeroSubtitle => 'Le code vous a été donné par un promoteur.';

  @override
  String get joinAcceptedTitle => 'Code accepté';

  @override
  String get joinAcceptedBody => 'Vous faites maintenant partie de l\'équipe.';

  @override
  String get joinStart => 'Commencer';

  @override
  String get welcomeSpaceTitle => 'Votre espace Tikéo';

  @override
  String get controlHeroSubtitle =>
      'Choisissez l\'événement et la porte où vous scannez.';

  @override
  String get controlSummaryOpen => 'Ouverts';

  @override
  String get controlSummaryUpcoming => 'À venir';

  @override
  String get controlSummaryDoors => 'Portes';

  @override
  String get controlMyPosts => 'Mes postes';

  @override
  String get scannerAdmitted => 'Entrés';

  @override
  String get scannerRefused => 'Refusés';

  @override
  String get historyHeroSubtitle => 'Vos vérifications des 7 derniers jours.';

  @override
  String get historyUncertain => 'Incertains';

  @override
  String get eventsHeroSubtitle => 'Créez, publiez et suivez vos événements.';

  @override
  String get walletHeroSubtitle => 'Vos tickets, même sans réseau.';

  @override
  String get walletSummaryValid => 'Valables';

  @override
  String get walletSummaryUpcoming => 'Prochains';

  @override
  String get walletSummaryPast => 'Terminés';

  @override
  String get supportHeroSubtitle =>
      'Une question, un problème ? L\'équipe Tikéo vous répond ici.';

  @override
  String get settingsHeroSubtitle =>
      'Apparence, langue, notifications et stockage.';

  @override
  String get consoleHeroSubtitle =>
      'Structures, comptes, support et catalogue de la plateforme.';

  @override
  String get billingActivate => 'Activer l\'abonnement';

  @override
  String get billingActivateAddons => 'Activer les suppléments';

  @override
  String get billingActivatedToast => 'Paiement enregistré, abonnement activé.';

  @override
  String billingAddonLine(int units, String option) {
    return '+$units $option';
  }

  @override
  String billingAddonPrice(String price, int step) {
    return '$price par tranche de $step';
  }

  @override
  String get billingAddonsBody =>
      'Les suppléments de l\'abonnement sont remplacés, sans paiement à saisir.';

  @override
  String get billingAddonsNone => 'Ce pack ne propose aucun supplément.';

  @override
  String get billingAddonsSave => 'Enregistrer les suppléments';

  @override
  String get billingAddonsSavedToast => 'Suppléments enregistrés.';

  @override
  String get billingAddonsTitle => 'Suppléments';

  @override
  String get billingCancel => 'Résilier';

  @override
  String billingCancelBody(String name) {
    return 'L\'abonnement de $name prend fin maintenant ; le compte revient au pack gratuit.';
  }

  @override
  String get billingCancelTitle => 'Résilier l\'abonnement ?';

  @override
  String get billingCancelledToast => 'Abonnement résilié.';

  @override
  String get billingChangePack => 'Changer de pack';

  @override
  String billingChangePackBody(String pack) {
    return 'L\'abonnement passe au pack $pack, aux mêmes dates.';
  }

  @override
  String get billingChangePackTitle => 'Changer de pack';

  @override
  String get billingChannelMoov => 'Moov Money';

  @override
  String get billingChannelOrange => 'Orange Money';

  @override
  String get billingChannelOther => 'Autre';

  @override
  String get billingCollectCheck => 'Vérifier et valider';

  @override
  String get billingCollectDone => 'Traitées';

  @override
  String get billingCollectEmpty => 'Rien à afficher ici.';

  @override
  String get billingCollectOverdue => 'En retard';

  @override
  String get billingCollectTitle => 'À encaisser';

  @override
  String get billingCollectToCheck => 'À vérifier';

  @override
  String billingDates(String start, String end) {
    return 'Du $start au $end';
  }

  @override
  String billingDatesEvent(String start) {
    return 'Dès le $start, jusqu\'à la fin de l\'événement couvert';
  }

  @override
  String get billingDaysSuffix => 'jours';

  @override
  String billingDeclaredLine(String channel, String transaction) {
    return 'Déclaré : $channel · $transaction';
  }

  @override
  String billingDueLine(String date) {
    return 'Échéance : $date';
  }

  @override
  String get billingDurationEvent => 'Un événement';

  @override
  String get billingDurationMonth => 'Mensuel';

  @override
  String get billingDurationQuarter => 'Trimestriel';

  @override
  String get billingDurationSemester => 'Semestriel';

  @override
  String get billingDurationUnlimited => 'Sans fin';

  @override
  String get billingDurationYear => 'Annuel';

  @override
  String get billingErrorAddons =>
      'Supplément impossible avec ce pack (option, tranche ou plafond).';

  @override
  String get billingErrorChoice =>
      'Choisissez le forfait, ou un pack à l\'usage.';

  @override
  String get billingErrorEnd => 'La fin doit suivre le début de l\'abonnement.';

  @override
  String get billingErrorInvoiceExists =>
      'Une facture a déjà été émise pour cet événement.';

  @override
  String get billingErrorNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get billingErrorNote => 'Indiquez le motif (3 caractères au moins).';

  @override
  String get billingErrorPack =>
      'Pack invalide : vérifiez le nom, les prix et les options.';

  @override
  String get billingErrorPackProtected => 'Le pack Découverte reste publié.';

  @override
  String get billingErrorPayment => 'Canal, identifiant ou note invalide.';

  @override
  String get billingErrorProcessed => 'Déjà traité, ou introuvable.';

  @override
  String get billingErrorSettings =>
      'Réglages invalides : vérifiez les nombres.';

  @override
  String get billingEventApply => 'Changer la facturation';

  @override
  String get billingEventChange => 'Facturation d\'un événement';

  @override
  String get billingEventChangeHelp =>
      'Pour un événement déjà figé au premier ticket. Impossible une fois la facture émise.';

  @override
  String get billingEventChangedToast =>
      'Facturation de l\'événement modifiée.';

  @override
  String get billingEventLocked => 'figé';

  @override
  String get billingEventSearch => 'Titre de l\'événement ou structure';

  @override
  String get billingExpected => 'Montant attendu';

  @override
  String get billingExtend => 'Prolonger';

  @override
  String billingExtendBody(String date) {
    return 'Nouvelle fin : $date.';
  }

  @override
  String get billingExtendTitle => 'Prolonger l\'abonnement';

  @override
  String get billingExtendedToast => 'Abonnement prolongé.';

  @override
  String get billingFeatureAddon => 'Supplément';

  @override
  String get billingFeatureIncluded => 'Incluse';

  @override
  String get billingFeatureUnavailable => 'Non';

  @override
  String get billingFilterAll => 'Tous';

  @override
  String get billingFormAddonAllowed => 'Supplément possible';

  @override
  String get billingFormAddonCap => 'Plafond';

  @override
  String get billingFormAddonPrice => 'Prix';

  @override
  String get billingFormAddonStep => 'Tranche';

  @override
  String get billingFormDescription => 'Description (affichée au promoteur)';

  @override
  String get billingFormDurations => 'Durées proposées';

  @override
  String get billingFormEditTitle => 'Modifier le pack';

  @override
  String get billingFormEntryPrice => 'Prix par entrée réelle';

  @override
  String get billingFormFeatures => 'Fonctions';

  @override
  String get billingFormFlatInvalid =>
      'Indiquez le prix mensuel et au moins une durée.';

  @override
  String get billingFormFreeEntries => 'Entrées offertes';

  @override
  String get billingFormIncluded => 'Inclus';

  @override
  String get billingFormMonthly => 'Prix mensuel';

  @override
  String get billingFormName => 'Nom du pack';

  @override
  String get billingFormNameInvalid =>
      'Le nom doit faire de 2 à 60 caractères.';

  @override
  String get billingFormNewTitle => 'Nouveau pack';

  @override
  String billingFormNumericHelp(String period) {
    return 'Vide : illimité. Le supplément se paie par tranche, $period.';
  }

  @override
  String get billingFormNumericOptions => 'Options chiffrées';

  @override
  String get billingFormPaymentDays => 'Délai de paiement (jours)';

  @override
  String get billingFormPreview => 'Aperçu';

  @override
  String get billingFormPrices => 'Prix';

  @override
  String get billingFormPublish => 'Publier le pack';

  @override
  String get billingFormSave => 'Enregistrer';

  @override
  String get billingFormSaveDraft => 'Enregistrer le brouillon';

  @override
  String get billingFormSaved => 'Pack enregistré.';

  @override
  String get billingFormSortOrder => 'Ordre d\'affichage';

  @override
  String get billingFormSystem => 'Système de facturation';

  @override
  String get billingFormTierAdd => 'Ajouter un palier';

  @override
  String get billingFormTierPrice => 'Prix par entrée';

  @override
  String get billingFormTierRemove => 'Retirer le palier';

  @override
  String get billingFormTierUpTo => 'Jusqu\'à (entrées)';

  @override
  String get billingFormTiers => 'Paliers (facultatif)';

  @override
  String get billingFormTiersHelp =>
      'Exemple : 150 FCFA jusqu\'à 500 entrées, 100 FCFA au-delà (dernier palier vide).';

  @override
  String get billingFormTrial => 'Jours d\'essai';

  @override
  String get billingFormUsageInvalid =>
      'Indiquez le prix par entrée ou des paliers.';

  @override
  String get billingFree => 'Gratuit';

  @override
  String get billingGrant => 'Activer un pack sans demande';

  @override
  String get billingGrantDuration => 'Durée';

  @override
  String get billingGrantMissing =>
      'Choisissez le compte et le pack, et indiquez le motif.';

  @override
  String get billingGrantPack => 'Pack';

  @override
  String get billingGrantSearch => 'Nom ou e-mail du compte';

  @override
  String get billingGrantSubmit => 'Activer le pack';

  @override
  String get billingGrantedToast => 'Pack activé pour ce compte.';

  @override
  String get billingHoursSuffix => 'heures';

  @override
  String billingInvoiceDetail(
    int entries,
    int free,
    String entriesAmount,
    String addonsAmount,
  ) {
    return '$entries entrées, $free offertes · entrées $entriesAmount · suppléments $addonsAmount';
  }

  @override
  String billingInvoiceObject(String event, int entries) {
    return '$event · $entries entrées réelles';
  }

  @override
  String get billingInvoicePaidToast => 'Facture marquée comme payée.';

  @override
  String get billingKindActivation => 'Demande d\'activation';

  @override
  String get billingKindAddons => 'Suppléments';

  @override
  String get billingKindInvoice => 'Facture à l\'usage';

  @override
  String get billingKindOverdue => 'Facture en retard';

  @override
  String get billingMarkPaid => 'Marquer comme payée';

  @override
  String get billingNoEnd => 'sans fin';

  @override
  String get billingNotDeclared =>
      'Paiement pas encore déclaré par le promoteur';

  @override
  String get billingPackActions => 'Actions';

  @override
  String get billingPackArchive => 'Archiver';

  @override
  String get billingPackArchived => 'Archivé';

  @override
  String get billingPackArchivedPlural => 'Archivés';

  @override
  String get billingPackArchivedToast =>
      'Pack archivé : plus proposé, les abonnements continuent.';

  @override
  String get billingPackChangedToast => 'Pack de l\'abonnement changé.';

  @override
  String billingPackCopyName(String name) {
    return '$name (copie)';
  }

  @override
  String get billingPackDraft => 'Brouillon';

  @override
  String get billingPackDraftToast => 'Pack retiré : il n\'est plus proposé.';

  @override
  String get billingPackDuplicate => 'Dupliquer';

  @override
  String get billingPackDuplicated => 'Copie créée en brouillon.';

  @override
  String get billingPackEdit => 'Modifier';

  @override
  String billingPackEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
      zero: 'Aucun événement',
    );
    return '$_temp0';
  }

  @override
  String get billingPackFeatured => 'Recommandé';

  @override
  String get billingPackNew => 'Nouveau pack';

  @override
  String get billingPackPublish => 'Publier';

  @override
  String get billingPackPublished => 'Publié';

  @override
  String get billingPackPublishedToast =>
      'Pack publié : les promoteurs le voient.';

  @override
  String billingPackSubscriptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnements',
      one: '1 abonnement',
      zero: 'Aucun abonnement',
    );
    return '$_temp0';
  }

  @override
  String get billingPackUnpublish => 'Retirer (brouillon)';

  @override
  String get billingPacksEmpty => 'Aucun pack ici.';

  @override
  String get billingPacksTitle => 'Packs';

  @override
  String get billingPaymentAmount => 'Montant reçu';

  @override
  String get billingPaymentDate => 'Date du paiement';

  @override
  String get billingPaymentInvoiceTitle => 'Encaisser une facture';

  @override
  String billingPaymentMismatch(String expected) {
    return 'Le montant reçu diffère du montant attendu ($expected) : il sera indiqué dans la note.';
  }

  @override
  String get billingPaymentNote => 'Note (facultatif)';

  @override
  String get billingPaymentReceived => 'Paiement reçu';

  @override
  String get billingPaymentReference => 'Identifiant de l\'opérateur';

  @override
  String get billingPaymentRequestTitle => 'Valider un paiement';

  @override
  String get billingPaymentToday => 'Aujourd\'hui';

  @override
  String billingPerEntry(String price) {
    return '$price par entrée';
  }

  @override
  String get billingPerEventShort => 'par événement';

  @override
  String billingPerMonth(String price) {
    return '$price / mois';
  }

  @override
  String get billingPerMonthShort => 'par mois';

  @override
  String billingPreviewAddon(String option, String price) {
    return '$option : en supplément ($price)';
  }

  @override
  String billingPreviewIncluded(String value, String option) {
    return '$value · $option';
  }

  @override
  String billingPreviewMore(String price, int step) {
    return '+ $price par $step de plus';
  }

  @override
  String billingPreviewUnlimited(String option) {
    return '$option : illimité';
  }

  @override
  String billingReceivedNote(String amount) {
    return 'Reçu : $amount';
  }

  @override
  String billingReferenceLine(String reference, String date) {
    return 'Référence $reference · $date';
  }

  @override
  String get billingRefuse => 'Refuser la demande';

  @override
  String get billingRefuseBody =>
      'La demande est fermée ; le promoteur peut en créer une autre.';

  @override
  String get billingRefuseTitle => 'Refuser la demande ?';

  @override
  String get billingRefusedToast => 'Demande refusée.';

  @override
  String billingRequestAddons(String pack, String addons) {
    return 'Suppléments du pack $pack : $addons';
  }

  @override
  String billingRequestPack(String pack, String duration) {
    return 'Pack $pack · $duration';
  }

  @override
  String get billingSettingsBeneficiary => 'Nom du bénéficiaire';

  @override
  String get billingSettingsDelays => 'Délais';

  @override
  String get billingSettingsGraceDays => 'Période de grâce après la fin';

  @override
  String get billingSettingsInstructions => 'Consigne affichée au promoteur';

  @override
  String get billingSettingsInvoiceHours => 'Émission de la facture à l\'usage';

  @override
  String get billingSettingsInvoiceHoursHelp =>
      'Heures après la fin de l\'événement (ou à la clôture du contrôle).';

  @override
  String get billingSettingsNumbers => 'Numéros de paiement de Tikéo';

  @override
  String get billingSettingsPaymentDays => 'Délai de paiement à l\'usage';

  @override
  String get billingSettingsPaymentDaysHelp =>
      'Par défaut, si le pack n\'en fixe pas.';

  @override
  String get billingSettingsReminderDays => 'Rappel avant la fin d\'abonnement';

  @override
  String get billingSettingsSave => 'Enregistrer les réglages';

  @override
  String get billingSettingsSaved => 'Réglages de paiement enregistrés.';

  @override
  String get billingSettingsTitle => 'Réglages de paiement';

  @override
  String get billingStatusActivated => 'Activée';

  @override
  String get billingStatusCancelled => 'Annulée';

  @override
  String get billingStatusPaid => 'Payée';

  @override
  String get billingStatusRefused => 'Refusée';

  @override
  String get billingSubActive => 'Actifs';

  @override
  String get billingSubActiveOne => 'Actif';

  @override
  String get billingSubEndedOne => 'Terminé';

  @override
  String get billingSubEndingOne => 'Expire bientôt';

  @override
  String get billingSubEndingSoon => 'Expirent bientôt';

  @override
  String get billingSubGrace => 'En grâce';

  @override
  String get billingSubGraceOne => 'En grâce';

  @override
  String get billingSubscriptionsSearch => 'Nom, e-mail ou pack';

  @override
  String get billingSubscriptionsTitle => 'Abonnements';

  @override
  String get billingSystemFlat => 'Forfait';

  @override
  String get billingSystemUsage => 'À l\'usage';

  @override
  String billingUntil(String date) {
    return 'jusqu\'au $date';
  }

  @override
  String get consoleNavCollectHint =>
      'Demandes d\'activation et factures à l\'usage';

  @override
  String consoleNavCollectPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements à vérifier',
      one: '1 paiement à vérifier',
    );
    return '$_temp0';
  }

  @override
  String get consoleNavPacksHint =>
      'Forfaits et packs à l\'usage, options, suppléments';

  @override
  String get consoleNavPaymentSettingsHint =>
      'Numéros Orange Money et Moov, délais';

  @override
  String get consoleNavSubscriptionsHint =>
      'Prolonger, changer de pack, offrir un pack';

  @override
  String get consoleSectionBilling => 'Facturation';

  @override
  String get consoleSectionPlatform => 'Plateforme';

  @override
  String get auditAdminBillingSubscriptionExtended => 'Abonnement prolongé';

  @override
  String get auditAdminBillingSubscriptionPackChanged =>
      'Pack d\'un abonnement changé';

  @override
  String get auditAdminBillingSubscriptionAddonsSet =>
      'Suppléments d\'un abonnement réglés';

  @override
  String get auditAdminBillingEventSet => 'Facturation d\'un événement changée';

  @override
  String get billingActivatedTitle => 'Pack activé';

  @override
  String get billingActivationDelay =>
      'Votre pack est activé dès que Tikéo a vérifié le paiement, en général dans la journée.';

  @override
  String get billingAddonLess => 'Moins';

  @override
  String get billingAddonMore => 'Plus';

  @override
  String billingAddonPricePer(int step, String price, String period) {
    return '+$step : $price $period';
  }

  @override
  String billingAddonsCurrent(String date) {
    return 'Abonnement en cours, jusqu\'au $date';
  }

  @override
  String get billingAddonsUnavailable => 'Non inclus dans ce pack';

  @override
  String get billingAmountToPay => 'Montant à payer';

  @override
  String billingAvailableWith(String option, String pack) {
    return '$option : disponible avec le pack $pack';
  }

  @override
  String get billingBackToMyPack => 'Retour à Mon pack';

  @override
  String billingBeneficiary(String name) {
    return 'Bénéficiaire : $name';
  }

  @override
  String get billingByStructure => 'Facturation par structure';

  @override
  String get billingCancelRequest => 'Annuler la demande';

  @override
  String get billingCancelledTitle => 'Demande annulée';

  @override
  String get billingChoosePack => 'Choisir un pack';

  @override
  String get billingChooseThis => 'Choisir ce pack';

  @override
  String get billingContactSupport => 'Contacter le support';

  @override
  String get billingContinueToPayment => 'Continuer vers le paiement';

  @override
  String get billingCopied => 'Copié.';

  @override
  String get billingCopy => 'Copier';

  @override
  String billingDueInvoices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures à payer',
      one: '1 facture à payer',
    );
    return '$_temp0';
  }

  @override
  String get billingEnterprise => 'Entreprise';

  @override
  String get billingEnterpriseBody =>
      'Plusieurs structures, gros volumes : un pack sur devis.';

  @override
  String get billingEnterpriseContact => 'Demander un devis';

  @override
  String get billingErrorLoad =>
      'Chargement impossible. Vérifiez la connexion.';

  @override
  String get billingErrorLocked =>
      'Facturation figée dès le premier ticket émis.';

  @override
  String get billingErrorNoSubscription => 'Aucun abonnement payant en cours.';

  @override
  String get billingErrorPackUnavailable =>
      'Ce pack ou cette durée n\'est plus proposé.';

  @override
  String get billingErrorTransaction =>
      'Identifiant de transaction invalide (3 à 60 caractères).';

  @override
  String billingFreeEntries(int count) {
    return '$count entrées offertes';
  }

  @override
  String get billingGaugeFull =>
      'Limite atteinte : changez de pack pour aller plus loin.';

  @override
  String get billingGaugeFullAddon =>
      'Limite atteinte : ajoutez un supplément ou changez de pack.';

  @override
  String billingGaugeOf(int used, int max) {
    return '$used sur $max';
  }

  @override
  String billingGaugeUnlimited(int used) {
    return '$used · illimité';
  }

  @override
  String get billingIPaid => 'J\'ai payé';

  @override
  String billingIncludedValue(String value) {
    return '$value inclus';
  }

  @override
  String billingInvoiceEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées réelles',
      one: '1 entrée réelle',
      zero: 'Aucune entrée',
    );
    return '$_temp0';
  }

  @override
  String get billingInvoiceOverdue => 'En retard';

  @override
  String get billingInvoiceToPay => 'À payer';

  @override
  String get billingInvoicesEmpty => 'Aucune facture ni reçu pour l\'instant.';

  @override
  String get billingInvoicesTitle => 'Factures et reçus';

  @override
  String get billingMyPackSubtitle =>
      'Votre pack, votre consommation et vos factures.';

  @override
  String get billingMyPackTitle => 'Mon pack';

  @override
  String get billingNoMinimum => 'Sans minimum';

  @override
  String get billingNoPacks => 'Aucun pack proposé pour l\'instant.';

  @override
  String get billingNumberMissing => 'Numéro pas encore indiqué par Tikéo';

  @override
  String get billingOverdueBody =>
      'Réglez-la pour émettre des tickets sur un nouvel événement à l\'usage.';

  @override
  String get billingPayStep1 => '1 · Envoyez le montant à';

  @override
  String get billingPayStep2 => '2 · Indiquez l\'identifiant reçu par SMS';

  @override
  String get billingPaymentTitle => 'Paiement';

  @override
  String billingPendingBody(String reference, String amount) {
    return 'Référence $reference · $amount';
  }

  @override
  String get billingPendingDeclared =>
      'Paiement déclaré : en attente de validation';

  @override
  String get billingPendingToPay => 'Demande en attente de paiement';

  @override
  String billingPerMonthEquivalent(String price) {
    return 'soit $price par mois';
  }

  @override
  String get billingPlanActive => 'Actif';

  @override
  String get billingPlanFree => 'Gratuit';

  @override
  String get billingPlanFreeHint => 'Pack gratuit, sans fin';

  @override
  String get billingPlanGrace => 'En grâce';

  @override
  String get billingPlanOverline => 'Votre pack';

  @override
  String get billingProfileHint => 'Pack, consommation, factures';

  @override
  String get billingProrataHint =>
      'Estimation au prorata des jours restants ; le montant exact est calculé à la demande.';

  @override
  String get billingProrataShort => 'par mois, au prorata';

  @override
  String get billingReceiptAddons => 'Reçu · suppléments';

  @override
  String get billingReceiptPack => 'Reçu · pack';

  @override
  String get billingReferenceToGive => 'Référence à indiquer dans le paiement';

  @override
  String get billingRefusedTitle => 'Demande refusée';

  @override
  String get billingRequestCancelled => 'Demande annulée.';

  @override
  String get billingRequestTitle => 'Ma demande';

  @override
  String get billingSimulator => 'Simulateur';

  @override
  String billingSimulatorEntries(int count) {
    return '$count entrées réelles';
  }

  @override
  String billingSimulatorFree(int count) {
    return '$count entrées offertes';
  }

  @override
  String get billingSimulatorHint =>
      'Estimation hors suppléments ; seules les entrées acceptées à la porte comptent.';

  @override
  String billingSimulatorTier(int from, int to, String price) {
    return 'Entrées $from à $to : $price chacune';
  }

  @override
  String get billingStepActivated => 'Pack activé';

  @override
  String get billingStepChecked => 'Vérification par Tikéo';

  @override
  String get billingStepCreated => 'Demande créée';

  @override
  String get billingStepDeclared => 'Paiement déclaré';

  @override
  String get billingStructureFlatHint =>
      'Les événements utilisent le pack de votre compte.';

  @override
  String get billingStructureHelp =>
      'Facturation par défaut des nouveaux événements de cette structure.';

  @override
  String get billingStructureSave => 'Enregistrer';

  @override
  String get billingStructureSaved =>
      'Facturation de la structure enregistrée.';

  @override
  String billingTierBeyond(String price) {
    return 'Au-delà : $price par entrée';
  }

  @override
  String billingTierUpTo(int count, String price) {
    return 'Jusqu\'à $count entrées : $price par entrée';
  }

  @override
  String get billingTotal => 'Total';

  @override
  String get billingTotalEstimate => 'Total estimé';

  @override
  String get billingTransaction => 'Identifiant de transaction (facultatif)';

  @override
  String get billingTransactionHelp => 'Reçu par SMS après le paiement.';

  @override
  String billingTrialDays(int count) {
    return '$count jours d\'essai';
  }

  @override
  String billingUsageChosen(String name) {
    return '$name est facturée à l\'usage.';
  }

  @override
  String get billingUsageHow => 'Comment ça marche';

  @override
  String get billingUsageStep1 => 'Pas de paiement d\'avance.';

  @override
  String get billingUsageStep2 => 'Seules les entrées réelles comptent.';

  @override
  String get billingUsageStep3 => 'La facture arrive à la fin de l\'événement.';

  @override
  String get billingUsageTitle => 'Consommation';

  @override
  String get billingUseForStructure => 'Utiliser pour ma structure';

  @override
  String get billingUseForWhich => 'Pour quelle structure ?';

  @override
  String get billingWaitingTitle => 'En attente de validation';

  @override
  String get billingBlockAdded => 'Supplément ajouté : vous pouvez réessayer.';

  @override
  String get billingBlockAddonInvoice =>
      'Ajouté à la facture de fin d\'événement.';

  @override
  String billingBlockAddonOffer(String what, String price) {
    return '$what : + $price';
  }

  @override
  String get billingBlockAskOwner =>
      'Demandez au propriétaire de la structure de changer de pack.';

  @override
  String get billingBlockChooseUsagePack => 'Choisir le pack de l\'événement';

  @override
  String get billingBlockExceed => 'Dépasser la limite';

  @override
  String get billingBlockLater => 'Plus tard';

  @override
  String billingBlockLimitBody(int limit) {
    return 'Valeur comprise dans votre pack : $limit.';
  }

  @override
  String billingBlockLimitTitle(String option) {
    return 'Limite atteinte : $option';
  }

  @override
  String get billingBlockOptionBody =>
      'Cette fonction n\'est pas comprise dans votre pack.';

  @override
  String billingBlockOptionTitle(String option) {
    return '$option : non compris';
  }

  @override
  String get billingBlockOverdueTitle => 'Facture à l\'usage en retard';

  @override
  String get billingBlockSeeInvoices => 'Voir mes factures';

  @override
  String get billingBlockSeePacks => 'Voir les packs';

  @override
  String get billingBlockUsagePackBody =>
      'Cet événement est facturé à l\'usage : choisissez son pack.';

  @override
  String get billingBlockUsagePackTitle => 'Choisissez un pack à l\'usage';

  @override
  String get billingDashboardNotInPack =>
      'Le tableau de bord en direct n\'est pas compris dans votre pack.';

  @override
  String get billingDownloadPdf => 'Télécharger le PDF';

  @override
  String billingDueOn(String date) {
    return 'À régler avant le $date';
  }

  @override
  String get billingDurationTrial => 'Essai';

  @override
  String get billingErrorForbidden => 'Accès refusé ou événement introuvable.';

  @override
  String get billingErrorTrialUnavailable =>
      'Essai impossible pendant un abonnement payant.';

  @override
  String get billingErrorTrialUsed => 'Votre essai gratuit a déjà été utilisé.';

  @override
  String get billingEventChoice => 'Facturation de l\'événement';

  @override
  String billingEventEntriesAmount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées facturées',
      one: '1 entrée facturée',
      zero: 'Aucune entrée facturée',
    );
    return '$_temp0';
  }

  @override
  String get billingEventEstimate => 'Estimation en direct';

  @override
  String get billingEventInherit => 'Comme la structure';

  @override
  String get billingEventInheritHint =>
      'Suit la facturation par défaut de la structure.';

  @override
  String billingEventInvoice(String amount) {
    return 'Facture : $amount';
  }

  @override
  String get billingEventInvoiceWhen =>
      'La facture est émise après la fin de l\'événement ; seules les entrées acceptées comptent.';

  @override
  String get billingEventLimits => 'Limites de l\'événement';

  @override
  String get billingEventLockHint => 'Se fige dès le premier ticket émis.';

  @override
  String get billingEventLockedBanner =>
      'Facturation figée : le premier ticket est émis.';

  @override
  String get billingEventSaved => 'Facturation de l\'événement enregistrée.';

  @override
  String get billingEventTitle => 'Facturation';

  @override
  String get billingFilterAllInvoices => 'Toutes';

  @override
  String get billingFilterPaid => 'Payées';

  @override
  String get billingHowToPay => 'Comment payer';

  @override
  String get billingInvoiceMissing => 'Facture introuvable.';

  @override
  String get billingInvoicePayHint =>
      'Envoyez le montant avec la référence : Tikéo marque la facture payée dès réception.';

  @override
  String get billingInvoicePdfFooter =>
      'Tikéo · facture à l\'usage : seules les entrées acceptées à la porte sont comptées. Paiement Orange Money ou Moov Money, avec la référence de la facture.';

  @override
  String get billingInvoiceTitle => 'Facture';

  @override
  String billingIssuedOn(String date) {
    return 'émise le $date';
  }

  @override
  String billingLineAddon(String option, int units, String price) {
    return '$option × $units à $price';
  }

  @override
  String billingLineEntries(int count, String price) {
    return '$count entrées à $price';
  }

  @override
  String billingLineTier(int from, int to, String price) {
    return 'Entrées $from à $to à $price';
  }

  @override
  String billingPaidOn(String date) {
    return 'Payée le $date';
  }

  @override
  String get billingPlanTrial => 'Essai';

  @override
  String get billingSeeAll => 'Tout voir';

  @override
  String billingTrialStarted(String pack, int days) {
    return 'Essai de $pack activé pour $days jours.';
  }

  @override
  String billingTryFree(int days) {
    return 'Essayer $days jours gratuitement';
  }

  @override
  String get auditBillingTrialStarted => 'Essai gratuit commencé';

  @override
  String get welcomeOrganizeTitle => 'Organisez vos événements';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutHint => 'Version, mise à jour, mentions légales';

  @override
  String get aboutCheckNow => 'Vérifier maintenant';

  @override
  String aboutLastCheck(String date) {
    return 'Dernière vérification : $date';
  }

  @override
  String get aboutLegal => 'Mentions légales';

  @override
  String get aboutContact => 'Contact';

  @override
  String get profileSupport => 'Aide et support';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get billingSettingsSaveFailed =>
      'Enregistrement impossible. Réessayez ; si le problème continue, signalez-le à l\'équipe technique.';

  @override
  String get featuredErrorInvalid =>
      'Seul un événement public à venir peut être mis à la une, avec une fin après le début.';

  @override
  String get featuredErrorExists => 'Cet événement est déjà à la une.';

  @override
  String get featuredTitle => 'À la une';

  @override
  String get featuredNavHint => 'Événements mis en avant dans Explorer';

  @override
  String get featuredHint =>
      'Ordre d\'affichage dans Explorer. Sans mise en avant en cours, Explorer montre les 5 prochains événements publics.';

  @override
  String get featuredEmpty =>
      'Aucun événement choisi : Explorer montre les 5 prochains.';

  @override
  String get featuredAdd => 'Ajouter';

  @override
  String get featuredAdded => 'Événement mis à la une.';

  @override
  String get featuredRemove => 'Retirer';

  @override
  String get featuredRemoved => 'Retiré de la une.';

  @override
  String get featuredUp => 'Monter';

  @override
  String get featuredDown => 'Descendre';

  @override
  String get featuredPeriod => 'Période de mise en avant';

  @override
  String get featuredPeriodSaved => 'Période enregistrée.';

  @override
  String featuredPeriodLine(String start, String end) {
    return 'Du $start au $end';
  }

  @override
  String get featuredLive => 'Affiché';

  @override
  String get featuredWaiting => 'En attente';

  @override
  String get featuredEnded => 'Terminé';

  @override
  String get featuredPick => 'Événement public à venir';

  @override
  String get featuredPickEmpty => 'Aucun événement public à venir trouvé.';

  @override
  String get auditFeaturedAdded => 'Événement mis à la une';

  @override
  String get auditFeaturedRemoved => 'Événement retiré de la une';

  @override
  String get auditFeaturedMoved => 'Ordre de la une modifié';

  @override
  String get auditFeaturedPeriod => 'Période de la une modifiée';

  @override
  String get photoSaveFailed => 'Image indisponible. Vérifiez la connexion.';

  @override
  String get photoSaved => 'Image enregistrée.';

  @override
  String get photoClose => 'Fermer';

  @override
  String get photoShare => 'Partager';

  @override
  String get photoDownload => 'Télécharger';

  @override
  String get shareImageCta => 'Obtenez votre ticket sur Tikéo.';

  @override
  String get shareImageBanner =>
      'Obtenez votre ticket sur l\'application Tikéo';

  @override
  String get shareImageTitle => 'Partager l\'événement';

  @override
  String get shareImageStory => 'Statut 9:16';

  @override
  String get shareImagePost => 'Publication 4:5';

  @override
  String get shareImageShare => 'Partager';

  @override
  String get shareImageSave => 'Enregistrer';

  @override
  String get shareImageTextOnly => 'Partager le texte seulement';

  @override
  String get shareImageFailed => 'Image impossible à préparer. Réessayez.';

  @override
  String get invitationDetailsTitle => 'Invitation';

  @override
  String get invitationStateActive => 'Active';

  @override
  String get invitationStateExpired => 'Expirée';

  @override
  String get invitationStateRevoked => 'Révoquée';

  @override
  String get invitationStateExhausted => 'Épuisée';

  @override
  String get invitationCodeLabel => 'Code d\'invitation';

  @override
  String get invitationCodeShow => 'Afficher le code';

  @override
  String get invitationCodeHide => 'Masquer le code';

  @override
  String get invitationCodeUnavailable =>
      'Code non récupérable : créez une nouvelle invitation.';

  @override
  String get invitationErrorInactive =>
      'Invitation expirée, révoquée ou épuisée : code non affiché.';

  @override
  String get invitationErrorLimited =>
      'Trop d\'affichages : réessayez dans une heure.';

  @override
  String get invitationStructure => 'Structure';

  @override
  String get invitationCreatedBy => 'Créée par';

  @override
  String get invitationCreatedAt => 'Créée le';

  @override
  String get invitationValidUntil => 'Valable jusqu\'au';

  @override
  String get invitationUses => 'Utilisations';

  @override
  String get invitationUsedBy => 'Ont rejoint avec ce code';

  @override
  String get invitationRevoke => 'Révoquer l\'invitation';

  @override
  String get printTitle => 'Imprimer des tickets';

  @override
  String printCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets à imprimer',
      one: '1 ticket à imprimer',
    );
    return '$_temp0';
  }

  @override
  String get printPerPage => 'Tickets par feuille A4';

  @override
  String printSheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feuilles',
      one: '1 feuille',
    );
    return '$_temp0';
  }

  @override
  String printQrSize(double size) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String sizeString = sizeNumberFormat.format(size);

    return 'QR d\'environ $sizeString cm';
  }

  @override
  String get printHint =>
      'Traits de coupe entre les tickets. Imprimez à 100 %, sans ajuster à la page.';

  @override
  String get printGenerate => 'Générer le PDF';

  @override
  String get auditInvitationCodeRevealed => 'Code d\'invitation affiché';

  @override
  String get profileActiveOrgTitle => 'Structure active';

  @override
  String get profileMyStructuresTitle => 'Mes structures';

  @override
  String get profileMyAccountTitle => 'Mon compte';

  @override
  String get profileOrgInfo => 'Informations de la structure';

  @override
  String get profileOrgTeam => 'Équipe et invitations';

  @override
  String get profileOrgDoors => 'Portes';

  @override
  String get profileOrgDoorsHint => 'Postes de contrôle où vous êtes affecté';

  @override
  String get profileCreateOrg => 'Créer une structure';

  @override
  String profileCreateOrgQuota(int used, int max) {
    return '$used sur $max avec votre pack';
  }

  @override
  String get profileJoinOrg => 'Rejoindre avec un code';

  @override
  String get profileAccountInfo => 'Informations personnelles';

  @override
  String get profileAccountInfoHint => 'Nom, photo, téléphone';

  @override
  String favoritesHeroSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements gardés sur ce téléphone',
      one: '1 événement gardé sur ce téléphone',
      zero: 'Gardés sur ce téléphone, même sans compte',
    );
    return '$_temp0';
  }

  @override
  String get favoritesSearchHint => 'Rechercher dans mes favoris';

  @override
  String get favoritesFilters => 'Trier et filtrer';

  @override
  String favoritesPeriodLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get favoritesSortTitle => 'Trier par';

  @override
  String get favoritesSortNearest => 'Plus proches';

  @override
  String get favoritesSortRecent => 'Plus récents';

  @override
  String get favoritesNoMatchTitle => 'Aucun favori ne correspond';

  @override
  String get favoritesNoMatchBody =>
      'Changez la recherche, la période ou les filtres.';

  @override
  String get favoritesApply => 'Appliquer';

  @override
  String get favoriteUndo => 'Annuler';

  @override
  String get assignTitle => 'Attribuer une structure';

  @override
  String get assignCurrent => 'Structures actuelles';

  @override
  String get assignNone => 'Aucune structure pour l\'instant.';

  @override
  String get assignStructure => 'Structure';

  @override
  String get assignSearchHint => 'Nom de la structure (2 lettres au moins)';

  @override
  String get assignNoResult => 'Aucune structure trouvée.';

  @override
  String assignOwnerIs(String name) {
    return 'Propriétaire : $name';
  }

  @override
  String get assignChange => 'Choisir une autre structure';

  @override
  String get assignRole => 'Rôle';

  @override
  String get assignOwnerHint =>
      'Transfert : ce compte devient propriétaire, l\'ancien propriétaire reste gestionnaire. Le quota de structures de son pack est vérifié.';

  @override
  String get assignMemberHint =>
      'Le compte rejoint l\'équipe avec ce rôle, ou change de rôle s\'il en fait déjà partie.';

  @override
  String get assignSubmit => 'Attribuer';

  @override
  String get assignTransfer => 'Transférer la structure';

  @override
  String assignDone(String role, String name) {
    return 'Compte désormais $role de « $name ».';
  }

  @override
  String get assignErrorInactive => 'Ce compte est désactivé ou supprimé.';

  @override
  String get assignErrorAlreadyOwner =>
      'Ce compte est déjà propriétaire de cette structure.';

  @override
  String get assignErrorOwnerLocked =>
      'Ce compte est propriétaire : transférez d\'abord la structure à un autre compte.';

  @override
  String get assignErrorLimit =>
      'Le pack de ce compte ne permet pas une structure de plus.';

  @override
  String get auditAdminOrganizationAssigned =>
      'Structure attribuée par l\'équipe Tikéo';

  @override
  String get textSizeTitle => 'Taille du texte';

  @override
  String get textSizeSmall => 'Petite';

  @override
  String get textSizeNormal => 'Normale';

  @override
  String get textSizeLarge => 'Grande';

  @override
  String get textSizeExtraLarge => 'Très grande';

  @override
  String get textSizePreviewTitle => 'Concert de Bobo';

  @override
  String get textSizePreviewBody =>
      'Samedi 20:00 · Maison du peuple, Ouagadougou';

  @override
  String get textSizeHelp =>
      'S\'ajoute à la taille du texte réglée sur le téléphone.';

  @override
  String get devicesTitle => 'Appareils connectés';

  @override
  String get devicesSubtitle => 'Les téléphones où votre compte est ouvert.';

  @override
  String get devicesRowHint => 'Voir et déconnecter à distance';

  @override
  String get devicesThis => 'Cet appareil';

  @override
  String get devicesUnknown => 'Appareil non identifié';

  @override
  String get devicesActiveNow => 'Utilisé en ce moment';

  @override
  String devicesLastSeen(String when) {
    return 'Dernière activité : $when';
  }

  @override
  String devicesSince(String when) {
    return 'Connecté depuis le $when';
  }

  @override
  String get devicesSignOut => 'Déconnecter';

  @override
  String devicesSignOutTitle(String name) {
    return 'Déconnecter « $name » ?';
  }

  @override
  String get devicesSignOutBody =>
      'Cet appareil devra se reconnecter avec le mot de passe. Les tickets et données ne sont pas touchés.';

  @override
  String devicesSignedOut(String name) {
    return '« $name » est déconnecté.';
  }

  @override
  String get devicesSignOutOthers => 'Déconnecter les autres appareils';

  @override
  String get devicesSignOutOthersBody =>
      'Tous les appareils sauf celui-ci devront se reconnecter.';

  @override
  String devicesSignedOutOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils déconnectés.',
      one: '1 appareil déconnecté.',
      zero: 'Aucun autre appareil à déconnecter.',
    );
    return '$_temp0';
  }

  @override
  String get devicesOnlyThis =>
      'Votre compte n\'est ouvert que sur cet appareil.';

  @override
  String get devicesRetry => 'Réessayer';

  @override
  String get devicesErrorCurrent =>
      'Pour cet appareil, utilisez « Se déconnecter ».';

  @override
  String get devicesErrorNotFound => 'Appareil introuvable ou déjà déconnecté.';

  @override
  String get devicesErrorNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get devicesErrorUnknown => 'Impossible pour le moment. Réessayez.';

  @override
  String get devicesRemoteSignedOut =>
      'Cet appareil a été déconnecté depuis un autre appareil.';

  @override
  String get appLockSetting => 'Verrouiller par empreinte';

  @override
  String get appLockSettingHint =>
      'Empreinte ou code du téléphone, après 1 minute hors de l\'app';

  @override
  String get appLockUnavailable =>
      'Aucune empreinte ni code n\'est configuré sur ce téléphone.';

  @override
  String get appLockEnableReason =>
      'Confirmez pour activer le verrouillage de Tikéo';

  @override
  String get appLockEnabled => 'Verrouillage activé.';

  @override
  String get appLockReason => 'Déverrouillez Tikéo';

  @override
  String get appLockTitle => 'Tikéo est verrouillé';

  @override
  String get appLockBody => 'Utilisez votre empreinte ou le code du téléphone.';

  @override
  String get appLockFailed => 'Non reconnu. Réessayez, ou déconnectez-vous.';

  @override
  String get appLockUnlock => 'Déverrouiller';

  @override
  String get appLockSignOut => 'Se déconnecter';

  @override
  String get auditAccountDeviceRevoked => 'Appareil déconnecté à distance';

  @override
  String get auditAccountDevicesRevoked => 'Autres appareils déconnectés';

  @override
  String get searchTitle => 'Rechercher';

  @override
  String get searchSubtitle => 'Événements et tickets de la structure';

  @override
  String get searchHint => 'Nom, téléphone, référence ou événement';

  @override
  String get searchClear => 'Effacer';

  @override
  String get searchIdleTitle => 'Que cherchez-vous ?';

  @override
  String get searchIdleBody =>
      'Un titulaire (nom ou téléphone), une référence TS-…, ou un événement, sur tous les événements de la structure.';

  @override
  String searchNoResult(String query) {
    return 'Rien pour « $query »';
  }

  @override
  String get searchNoResultBody =>
      'Vérifiez l\'orthographe, ou cherchez par les 4 derniers chiffres du téléphone.';

  @override
  String searchEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
    );
    return '$_temp0';
  }

  @override
  String searchTickets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get searchError => 'Recherche impossible pour le moment.';

  @override
  String get searchErrorNetwork => 'Pas de connexion : réessayez.';

  @override
  String get bulkCancel => 'Annuler';

  @override
  String bulkPartial(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Fait pour $doneString sur $totalString. Les autres n\'ont pas pu être traités : réessayez.';
  }

  @override
  String eventsBulkSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements choisis seront laissés de côté.',
      one: '1 événement choisi sera laissé de côté.',
    );
    return '$_temp0';
  }

  @override
  String get eventsBulkPublic => 'Rendre public';

  @override
  String get eventsBulkPrivate => 'Rendre privé';

  @override
  String get eventsBulkDuplicate => 'Dupliquer';

  @override
  String get eventsBulkArchive => 'Archiver';

  @override
  String get eventsBulkPublicNone =>
      'Les événements choisis sont déjà publics, annulés ou archivés.';

  @override
  String get eventsBulkPrivateNone =>
      'Les événements choisis sont déjà privés.';

  @override
  String get eventsBulkArchiveNone =>
      'Seuls les événements clôturés ou annulés peuvent être archivés.';

  @override
  String eventsBulkPublicTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rendre $countString événements publics ?',
      one: 'Rendre 1 événement public ?',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkPrivateTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rendre $countString événements privés ?',
      one: 'Rendre 1 événement privé ?',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkArchiveTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Archiver $countString événements ?',
      one: 'Archiver 1 événement ?',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkDuplicateTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dupliquer $countString événements ?',
      one: 'Dupliquer 1 événement ?',
    );
    return '$_temp0';
  }

  @override
  String get eventsBulkPublicBody =>
      'Ils apparaîtront dans l\'Explorer, visibles de tous.';

  @override
  String get eventsBulkPrivateBody =>
      'Ils ne seront plus visibles dans l\'Explorer. Les tickets déjà émis restent valables.';

  @override
  String get eventsBulkArchiveBody =>
      'Ils passeront en lecture seule. C\'est définitif.';

  @override
  String get eventsBulkDuplicateBody =>
      'Chaque copie est créée en brouillon avec ses catégories, ses portes et son équipe, une semaine plus tard (même jour, même heure). Vous pourrez changer la date ensuite.';

  @override
  String eventsBulkPublicDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements rendus publics',
      one: '1 événement rendu public',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkPrivateDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements rendus privés',
      one: '1 événement rendu privé',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkArchiveDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements archivés',
      one: '1 événement archivé',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkDuplicateDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString copies créées en brouillon',
      one: '1 copie créée en brouillon',
    );
    return '$_temp0';
  }

  @override
  String eventsBulkDuplicateTooMany(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$maxString événements au plus à dupliquer en une fois.';
  }

  @override
  String get favoritesBulkRemove => 'Retirer des favoris';

  @override
  String favoritesBulkRemoved(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString favoris retirés',
      one: '1 favori retiré',
    );
    return '$_temp0';
  }

  @override
  String get favoritesSelectionHint =>
      'Appui long sur un événement pour en retirer plusieurs';

  @override
  String bulkSkippedItems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString éléments choisis ne sont pas concernés et seront laissés de côté.',
      one: '1 élément choisi n\'est pas concerné et sera laissé de côté.',
    );
    return '$_temp0';
  }

  @override
  String get consoleBulkReactivateBody =>
      'Ils retrouveront leur accès à Tikéo.';

  @override
  String get consoleBulkOrgsSuspendNone =>
      'Les structures choisies sont déjà suspendues.';

  @override
  String get consoleBulkOrgsReactivateNone =>
      'Les structures choisies sont déjà actives.';

  @override
  String consoleBulkOrgsSuspendTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suspendre $countString structures ?',
      one: 'Suspendre 1 structure ?',
    );
    return '$_temp0';
  }

  @override
  String consoleBulkOrgsReactivateTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réactiver $countString structures ?',
      one: 'Réactiver 1 structure ?',
    );
    return '$_temp0';
  }

  @override
  String consoleBulkOrgsSuspended(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString structures suspendues',
      one: '1 structure suspendue',
    );
    return '$_temp0';
  }

  @override
  String consoleBulkOrgsReactivated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString structures réactivées',
      one: '1 structure réactivée',
    );
    return '$_temp0';
  }

  @override
  String get consoleBulkDisable => 'Désactiver';

  @override
  String get consoleBulkAccountsDisableNone =>
      'Aucun compte choisi ne peut être désactivé (déjà désactivé, supprimé, ou le vôtre).';

  @override
  String get consoleBulkAccountsReactivateNone =>
      'Aucun compte choisi n\'est désactivé.';

  @override
  String consoleBulkAccountsDisableTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Désactiver $countString comptes ?',
      one: 'Désactiver 1 compte ?',
    );
    return '$_temp0';
  }

  @override
  String consoleBulkAccountsReactivateTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réactiver $countString comptes ?',
      one: 'Réactiver 1 compte ?',
    );
    return '$_temp0';
  }

  @override
  String consoleBulkAccountsDisabled(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString comptes désactivés',
      one: '1 compte désactivé',
    );
    return '$_temp0';
  }

  @override
  String consoleBulkAccountsReactivated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString comptes réactivés',
      one: '1 compte réactivé',
    );
    return '$_temp0';
  }

  @override
  String get consoleBulkSupportClose => 'Fermer';

  @override
  String get consoleBulkSupportCloseNone =>
      'Les demandes choisies sont déjà fermées.';

  @override
  String consoleBulkSupportCloseTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fermer $countString demandes ?',
      one: 'Fermer 1 demande ?',
    );
    return '$_temp0';
  }

  @override
  String get consoleBulkSupportCloseBody =>
      'Le demandeur pourra la rouvrir en répondant.';

  @override
  String consoleBulkSupportClosed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString demandes fermées',
      one: '1 demande fermée',
    );
    return '$_temp0';
  }

  @override
  String get eventTeamChooseMembers => 'Cochez un ou plusieurs membres';

  @override
  String get eventTeamUncheckAll => 'Tout décocher';

  @override
  String eventTeamAlreadyAssigned(String doors) {
    return 'déjà affecté : $doors';
  }

  @override
  String eventTeamAssignMany(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Affecter $countString membres';
  }

  @override
  String eventTeamAssignedMany(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString membres affectés',
      one: '1 membre affecté',
    );
    return '$_temp0';
  }

  @override
  String get batchesTitle => 'Lots';

  @override
  String get batchesIntro =>
      'Un lot par génération de tickets (émission rapide, nominative ou import).';

  @override
  String get batchesEmpty => 'Aucun lot pour cet événement.';

  @override
  String get batchesError => 'Lots indisponibles : vérifiez la connexion.';

  @override
  String batchTitle(int number, int count) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lot $numberString · $countString tickets',
      one: 'Lot $numberString · 1 ticket',
    );
    return '$_temp0';
  }

  @override
  String batchCounts(int issued, int redeemed, int revoked) {
    final intl.NumberFormat issuedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String issuedString = issuedNumberFormat.format(issued);
    final intl.NumberFormat redeemedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String redeemedString = redeemedNumberFormat.format(redeemed);
    final intl.NumberFormat revokedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String revokedString = revokedNumberFormat.format(revoked);

    return '$issuedString valables · $redeemedString utilisés · $revokedString annulés';
  }

  @override
  String get batchSelect => 'Sélectionner';

  @override
  String get batchPrint => 'Planche A4';

  @override
  String batchLabel(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Lot $numberString';
  }

  @override
  String get batchClear => 'Tous les lots';

  @override
  String get photoOpen => 'Voir la photo en grand';

  @override
  String eventTeamRemoved(String name) {
    return '$name n\'est plus affecté(e) à l\'événement';
  }

  @override
  String get consoleSupportCloseFailed =>
      'La demande n\'a pas pu être fermée : réessayez.';

  @override
  String get orgSettingsTitle => 'Réglages de la structure';

  @override
  String get orgSettingsRowHint =>
      'Message d\'envoi, valeurs d\'un nouvel événement';

  @override
  String get orgSettingsMessageTitle => 'Message d\'envoi';

  @override
  String get orgSettingsMessageHelp =>
      'Texte envoyé avec le ticket par WhatsApp, SMS ou e-mail, pour toute l\'équipe. Le QR code reste dans la pièce jointe, jamais dans le message.';

  @override
  String get orgSettingsTicketLabel => 'Message pour un ticket';

  @override
  String get orgSettingsInvitationLabel => 'Message pour une invitation';

  @override
  String get orgSettingsMessageHint => 'Vide : message par défaut de Tikéo';

  @override
  String get orgSettingsInsertField => 'Insérer';

  @override
  String get orgSettingsFieldFirstName => 'Prénom';

  @override
  String get orgSettingsFieldEvent => 'Événement';

  @override
  String get orgSettingsFieldDate => 'Date';

  @override
  String get orgSettingsFieldPlace => 'Lieu';

  @override
  String get orgSettingsFieldCategory => 'Catégorie';

  @override
  String get orgSettingsPreview => 'Aperçu';

  @override
  String get orgSettingsResetMessage => 'Revenir au message par défaut';

  @override
  String get orgSettingsSampleDate => 'samedi 12 décembre 2026, 20:00';

  @override
  String get orgSettingsDefaultsTitle => 'Nouvel événement';

  @override
  String get orgSettingsDefaultsHelp =>
      'Valeurs proposées à la création d\'un événement ; elles restent modifiables.';

  @override
  String get orgSettingsNone => 'Aucune valeur par défaut';

  @override
  String get orgSettingsCategories => 'Catégories proposées';

  @override
  String get orgSettingsAddCategory => 'Ajouter une catégorie';

  @override
  String get orgSettingsEditCategory => 'Catégorie proposée';

  @override
  String get orgSettingsCategoryName => 'Nom';

  @override
  String get orgSettingsCategoryCapacity => 'Quota (facultatif)';

  @override
  String get orgSettingsCategoryPrice => 'Prix indicatif en FCFA (facultatif)';

  @override
  String get orgSettingsCategoryInvitation => 'Catégorie d\'invitations';

  @override
  String get orgSettingsUnlimited => 'Quota illimité';

  @override
  String orgSettingsQuota(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Quota $countString';
  }

  @override
  String orgSettingsPrice(int price) {
    final intl.NumberFormat priceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '$priceString FCFA';
  }

  @override
  String get orgSettingsInvitationTag => 'Invitations';

  @override
  String get orgSettingsNameTaken => 'Ce nom est déjà dans la liste.';

  @override
  String get orgSettingsNameInvalid => 'Nom de 1 à 60 caractères.';

  @override
  String get orgSettingsCapacityInvalid => 'Quota de 1 à 1 000 000.';

  @override
  String get orgSettingsPriceInvalid => 'Prix de 0 à 10 000 000 FCFA.';

  @override
  String get orgSettingsMaxItems => '10 au plus.';

  @override
  String get orgSettingsCheckpoints => 'Portes proposées';

  @override
  String get orgSettingsCheckpointName => 'Nom de la porte';

  @override
  String get orgSettingsAdd => 'Ajouter';

  @override
  String get orgSettingsRemove => 'Retirer';

  @override
  String get orgSettingsSaved => 'Réglages enregistrés';

  @override
  String get orgSettingsLoadFailed =>
      'Impossible de charger les réglages de la structure.';

  @override
  String get orgSettingsErrorNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get orgSettingsErrorForbidden =>
      'Seuls le propriétaire et les gestionnaires modifient ces réglages.';

  @override
  String get orgSettingsErrorMessage => 'Message de 600 caractères au plus.';

  @override
  String get orgSettingsErrorTimezone => 'Fuseau horaire inconnu.';

  @override
  String get orgSettingsErrorCity => 'Ville de 2 à 80 caractères.';

  @override
  String get orgSettingsErrorCategories =>
      'Une catégorie proposée n\'est pas valide.';

  @override
  String get orgSettingsErrorCheckpoints =>
      'Une porte proposée n\'est pas valide.';

  @override
  String get orgSettingsErrorUnknown =>
      'Les réglages n\'ont pas pu être enregistrés.';

  @override
  String get eventApplyDefaults => 'Ajouter les catégories et portes proposées';

  @override
  String eventDefaultsCategories(String names) {
    return 'Catégories : $names';
  }

  @override
  String eventDefaultsDoors(String names) {
    return 'Portes : $names';
  }

  @override
  String get eventDefaultsApplyFailed =>
      'L\'événement est créé, mais les catégories et portes proposées n\'ont pas été ajoutées.';

  @override
  String get consoleAnnouncementStarted =>
      'Cette annonce est déjà diffusée ou retirée : elle ne se modifie plus.';

  @override
  String get consoleAnnouncementScheduled => 'Programmée';

  @override
  String consoleAnnouncementStartsAt(String date) {
    return 'Début : $date';
  }

  @override
  String get consoleAnnouncementEdit => 'Modifier l\'annonce';

  @override
  String get consoleAnnouncementSaved => 'Annonce modifiée';

  @override
  String get consoleAnnouncementStartPast =>
      'Choisissez un début dans le futur.';

  @override
  String consoleAnnouncementScheduledToast(String date) {
    return 'Annonce programmée pour le $date';
  }

  @override
  String get consoleAnnouncementStart => 'Début';

  @override
  String get consoleAnnouncementStartNow => 'Maintenant';

  @override
  String get consoleAnnouncementStartLater => 'Programmer';

  @override
  String get consoleAnnouncementScheduledHint =>
      'L\'annonce apparaîtra à cette heure ; vous pouvez la modifier jusque-là.';

  @override
  String get consoleAnnouncementScheduledPushHint =>
      'L\'annonce apparaîtra et la notification partira à cette heure (à 5 minutes près) ; vous pouvez la modifier jusque-là.';

  @override
  String get consoleAnnouncementSchedule => 'Programmer';

  @override
  String get supportTemplatesTitle => 'Réponses types';

  @override
  String get supportTemplatesEmpty => 'Aucune réponse type pour le moment.';

  @override
  String get supportTemplatesHelp =>
      'Textes prêts à insérer dans une réponse du support, puis à adapter avant l\'envoi.';

  @override
  String get supportTemplatesManage => 'Gérer les réponses types';

  @override
  String get supportTemplateNew => 'Nouvelle réponse type';

  @override
  String get supportTemplateEdit => 'Modifier la réponse type';

  @override
  String get supportTemplateDelete => 'Supprimer';

  @override
  String get supportTemplateDeleted => 'Réponse type supprimée';

  @override
  String get supportTemplateSaved => 'Réponse type enregistrée';

  @override
  String get supportTemplateTitleLabel => 'Titre (pour la retrouver)';

  @override
  String get supportTemplateBodyLabel => 'Texte de la réponse';

  @override
  String get supportTemplateTitleInvalid => 'Titre de 2 à 60 caractères.';

  @override
  String get supportTemplateBodyInvalid => 'Écrivez le texte de la réponse.';

  @override
  String get consoleTrendsTitle => '30 derniers jours';

  @override
  String get consoleTrendsError => 'Courbes indisponibles.';

  @override
  String get consoleTrendAccounts => 'Comptes';

  @override
  String get consoleTrendOrganizations => 'Structures';

  @override
  String get consoleTrendEvents => 'Événements publiés';

  @override
  String get consoleTrendTickets => 'Tickets émis';

  @override
  String get consoleTrendEntries => 'Entrées';

  @override
  String consoleTrendTotal(int total, int days) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$totalString sur $daysString jours';
  }

  @override
  String consoleTrendToday(String count) {
    return 'Aujourd\'hui : $count';
  }

  @override
  String consoleTrendSemantics(String metric, int total, int days) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$metric : $totalString sur $daysString jours';
  }

  @override
  String get auditAdminAnnouncementUpdated => 'Annonce programmée modifiée';

  @override
  String get auditAdminSupportTemplateSaved => 'Réponse type enregistrée';

  @override
  String get auditAdminSupportTemplateDeleted => 'Réponse type supprimée';

  @override
  String get auditOrganizationSettingsUpdated =>
      'Réglages de la structure modifiés';

  @override
  String get auditEventDefaultsApplied =>
      'Catégories et portes proposées ajoutées';

  @override
  String get consoleMfaRequired =>
      'Saisissez le code de double authentification pour ouvrir la console.';

  @override
  String get mfaTitle => 'Double authentification';

  @override
  String get mfaRowOn => 'Activée pour la console';

  @override
  String get mfaRowOff => 'Conseillée pour la console';

  @override
  String get mfaErrorCode =>
      'Code incorrect : saisissez les 6 chiffres affichés maintenant.';

  @override
  String get mfaErrorRateLimited =>
      'Trop d\'essais : réessayez dans une heure.';

  @override
  String get mfaErrorNotEnrolled =>
      'La double authentification n\'est pas activée.';

  @override
  String get mfaErrorNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get mfaErrorUnknown => 'Une erreur est survenue. Réessayez.';

  @override
  String get mfaCodeLabel => 'Code à 6 chiffres';

  @override
  String get mfaVerify => 'Valider';

  @override
  String get mfaConsoleTitle => 'Code de double authentification';

  @override
  String get mfaConsoleBody =>
      'Ouvrez votre application d\'authentification et saisissez le code de Tikéo. Il est demandé une fois par session.';

  @override
  String get mfaUseRecovery => 'Utiliser un code de secours';

  @override
  String get mfaRecovered =>
      'Double authentification retirée. Réactivez-la depuis Profil › Sécurité.';

  @override
  String get mfaRecoveryBody =>
      'Téléphone perdu ? Un code de secours retire la double authentification de votre compte ; vous pourrez la réactiver ensuite.';

  @override
  String get mfaRecoveryLabel => 'Code de secours';

  @override
  String get mfaRecoveryInvalid => 'Code de secours inconnu ou déjà utilisé.';

  @override
  String get mfaEnabledToast => 'Double authentification activée';

  @override
  String get mfaDisable => 'Désactiver';

  @override
  String get mfaDisableBody =>
      'La console ne demandera plus de code. Vos codes de secours ne serviront plus.';

  @override
  String get mfaDisabledToast => 'Double authentification désactivée';

  @override
  String get mfaOffTitle => 'Protégez la console';

  @override
  String get mfaOffBody =>
      'Facultatif et conseillé : en plus du mot de passe, la console demandera un code à 6 chiffres d\'une application d\'authentification (Google Authenticator, Microsoft Authenticator…), une fois par session.';

  @override
  String get mfaEnable => 'Activer';

  @override
  String get mfaOnTitle => 'Activée';

  @override
  String mfaCodesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString codes de secours restants',
      one: '1 code de secours restant',
      zero: 'Aucun code de secours restant',
    );
    return '$_temp0';
  }

  @override
  String get mfaConfirmFirst =>
      'Saisissez un code pour gérer vos codes de secours ou désactiver.';

  @override
  String get mfaNewCodes => 'Nouveaux codes de secours';

  @override
  String get mfaEnrollTitle => 'Activer la double authentification';

  @override
  String get mfaEnrollStep1 =>
      '1. Dans votre application d\'authentification, ajoutez un compte en scannant ce QR code.';

  @override
  String get mfaEnrollManual => 'Ou saisissez cette clé à la main :';

  @override
  String get mfaEnrollStep2 =>
      '2. Saisissez le code à 6 chiffres affiché par l\'application.';

  @override
  String get mfaCopy => 'Copier';

  @override
  String get mfaCopied => 'Copié';

  @override
  String get mfaCodesTitle => 'Vos codes de secours';

  @override
  String get mfaCodesBody =>
      'Notez-les en lieu sûr : ils ne seront plus affichés. Chacun sert une fois, si vous perdez votre téléphone.';

  @override
  String get mfaCodesDone => 'J\'ai noté mes codes';

  @override
  String get auditAdminMfaCodesGenerated => 'Codes de secours générés';

  @override
  String get auditAdminMfaRecovered =>
      'Double authentification retirée par un code de secours';

  @override
  String get adminAccountsErrorNetwork => 'Pas de connexion. Réessayez.';

  @override
  String get adminAccountsErrorRole =>
      'Votre rôle d\'administration ne permet pas cette action.';

  @override
  String get adminAccountsErrorMfaNeeded =>
      'Activez la double authentification (Profil › Sécurité) pour cette action.';

  @override
  String get adminAccountsErrorProtected =>
      'Seul un super administrateur peut agir sur le compte d\'un administrateur.';

  @override
  String get adminAccountsErrorSelf =>
      'Utilisez votre Profil pour votre propre compte.';

  @override
  String get adminAccountsErrorReason =>
      'Indiquez le motif (3 caractères au moins).';

  @override
  String get adminAccountsErrorName => 'Nom de 2 à 60 caractères.';

  @override
  String get adminAccountsErrorPhone => 'Numéro de téléphone invalide.';

  @override
  String get adminAccountsErrorEmail => 'Adresse e-mail invalide.';

  @override
  String get adminAccountsErrorEmailTaken =>
      'Un compte utilise déjà cette adresse e-mail.';

  @override
  String get adminAccountsErrorConfirmation =>
      'Saisissez exactement l\'adresse e-mail du compte.';

  @override
  String get adminAccountsErrorLastSuper =>
      'Il faut garder au moins un super administrateur.';

  @override
  String get adminAccountsErrorNoDeletion =>
      'Aucune demande de suppression pour ce compte.';

  @override
  String get adminAccountsErrorIsAdmin =>
      'Retirez d\'abord le rôle d\'administration.';

  @override
  String get adminAccountsErrorNotFound => 'Compte introuvable ou supprimé.';

  @override
  String get adminAccountsErrorUnknown =>
      'L\'action n\'a pas abouti. Réessayez.';

  @override
  String get adminRoleSuper => 'Super administrateur';

  @override
  String get adminRoleSupport => 'Support';

  @override
  String get adminRoleModeration => 'Modération';

  @override
  String get adminRoleFinance => 'Finance';

  @override
  String get adminRoleSuperHint =>
      'Tout, dont les administrateurs et les réglages de la console.';

  @override
  String get adminRoleSupportHint =>
      'Comptes, structures, tickets et demandes au support.';

  @override
  String get adminRoleModerationHint =>
      'Événements, catalogue, « À la une », annonces, suspension des structures.';

  @override
  String get adminRoleFinanceHint =>
      'Packs, paiements, factures et abonnements.';

  @override
  String get adminAccountsFieldRequired => 'Champ obligatoire.';

  @override
  String get adminAccountsReason =>
      'Motif (gardé dans l\'historique de la console)';

  @override
  String get adminAccountsNotify => 'Prévenir la personne';

  @override
  String get adminAccountsNotifyHint => 'Notification avec le motif.';

  @override
  String get adminAccountsTempPasswordTitle => 'Mot de passe provisoire';

  @override
  String get adminAccountsTempPasswordHint =>
      'Affiché une seule fois. Transmettez-le à la personne : elle choisira son mot de passe à la connexion.';

  @override
  String get adminAccountsTempPasswordDone => 'C\'est noté';

  @override
  String get adminAccountsTitle => 'Compte';

  @override
  String get adminAccountsEdit => 'Modifier';

  @override
  String get adminAccountsName => 'Nom';

  @override
  String get adminAccountsPhone => 'Téléphone';

  @override
  String get adminAccountsUpdated => 'Compte modifié';

  @override
  String get adminAccountsEmailChange => 'Changer l\'e-mail';

  @override
  String get adminAccountsEmailChangeHint =>
      'La personne se connectera avec la nouvelle adresse.';

  @override
  String get adminAccountsEmail => 'Adresse e-mail';

  @override
  String get adminAccountsEmailChanged => 'Adresse e-mail modifiée';

  @override
  String get adminAccountsPassword => 'Mot de passe provisoire';

  @override
  String get adminAccountsPasswordHint =>
      'Un nouveau mot de passe est créé et affiché une fois ; la personne est déconnectée et devra le changer à la connexion.';

  @override
  String get adminAccountsPasswordConfirm => 'Créer le mot de passe';

  @override
  String get adminAccountsSignOut => 'Déconnecter partout';

  @override
  String get adminAccountsSignOutHint =>
      'Tous les appareils du compte sont déconnectés.';

  @override
  String adminAccountsSignedOut(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sessions fermées',
      one: '1 session fermée',
      zero: 'Aucune session ouverte',
    );
    return '$_temp0';
  }

  @override
  String get adminAccountsCancelDeletion => 'Annuler la suppression';

  @override
  String get adminAccountsDeletionCancelled => 'Demande de suppression annulée';

  @override
  String get adminAccountsDeleteNow => 'Supprimer maintenant';

  @override
  String adminAccountsDeleteNowHint(String email) {
    return 'Compte anonymisé tout de suite, structures du propriétaire suspendues ; tickets et historique gardés. Irréversible. Pour confirmer, saisissez $email.';
  }

  @override
  String get adminAccountsDeleteConfirmLabel => 'Adresse e-mail du compte';

  @override
  String get adminRoleRemoved => 'Rôle d\'administration retiré';

  @override
  String adminRoleGiven(String role) {
    return 'Rôle donné : $role';
  }

  @override
  String get adminAccountsRemoveMfa => 'Retirer la double authentification';

  @override
  String get adminAccountsRemoveMfaHint =>
      'Pour un administrateur qui a perdu son téléphone et ses codes de secours. Il pourra la réactiver.';

  @override
  String get adminAccountsMfaRemoved => 'Double authentification retirée';

  @override
  String get adminRoleTitle => 'Rôle d\'administration';

  @override
  String get adminAccountsDeletionRequested => 'Suppression demandée';

  @override
  String get adminAccountsMustChange => 'Mot de passe à changer';

  @override
  String adminAccountsDisabledReason(String reason) {
    return 'Désactivé : $reason';
  }

  @override
  String get adminAccountsStructures => 'Structures';

  @override
  String get adminAccountsNoStructure => 'Aucune structure.';

  @override
  String get adminAccountsMemberInactive => 'plus membre';

  @override
  String get adminAccountsActivity => 'Activité';

  @override
  String adminAccountsWalletTickets(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tickets dans « Mes tickets »',
      one: '1 ticket dans « Mes tickets »',
      zero: 'Aucun ticket dans « Mes tickets »',
    );
    return '$_temp0';
  }

  @override
  String adminAccountsSupport(int total, int open) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat openNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String openString = openNumberFormat.format(open);

    return 'Demandes au support : $totalString (ouvertes : $openString)';
  }

  @override
  String get adminAccountsNoDevice => 'Aucun appareil connecté.';

  @override
  String adminAccountsDeviceSeen(String date) {
    return 'Vu le $date';
  }

  @override
  String get adminAccountsHistory => 'Actions de la console';

  @override
  String get adminAccountsNoHistory =>
      'Aucune action de la console sur ce compte.';

  @override
  String adminAccountsReasonValue(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get adminRoleMfaHint =>
      'Double authentification exigée pour changer un rôle.';

  @override
  String get adminRoleNone => 'Aucun (pas administrateur)';

  @override
  String get adminAccountsCreate => 'Créer un compte';

  @override
  String get adminAccountsCreateHint =>
      'Un mot de passe provisoire est affiché une seule fois ; la personne le changera à sa première connexion. La structure se crée ensuite depuis la fiche.';

  @override
  String get adminAccountsPhoneOptional => 'Téléphone (facultatif)';

  @override
  String get adminAccountsOpen => 'Ouvrir la fiche';

  @override
  String get consoleSettingsSaved => 'Réglage enregistré';

  @override
  String get consoleSettingsTitle => 'Réglages et administrateurs';

  @override
  String consoleMyRole(String role) {
    return 'Votre rôle : $role';
  }

  @override
  String get consoleSettingsReadOnly =>
      'Seul un super administrateur modifie ces réglages.';

  @override
  String get consoleSettingNotify => 'Prévenir la personne par défaut';

  @override
  String get consoleSettingNotifyHint =>
      'Case « Prévenir la personne » cochée d\'avance dans les actions sur un compte (modifiable à chaque action).';

  @override
  String get consoleSettingIssue =>
      'Émettre des tickets à la place d\'un promoteur';

  @override
  String get consoleSettingIssueHint =>
      'Désactivé par défaut. Servira à la gestion des événements de la console.';

  @override
  String get consoleAdminsTitle => 'Administrateurs';

  @override
  String get consoleAdminsHint =>
      'Le rôle se change depuis la fiche du compte (super administrateur).';

  @override
  String get consoleNavSettingsHint =>
      'Rôles, administrateurs, prévenir les personnes';

  @override
  String consoleHeroRole(String role) {
    return 'Votre rôle : $role';
  }

  @override
  String get forcedPasswordTitle => 'Choisissez votre mot de passe';

  @override
  String get forcedPasswordSubtitle =>
      'Votre mot de passe actuel est provisoire. Choisissez le vôtre pour continuer.';

  @override
  String get auditAdminConsoleSettingsUpdated =>
      'Réglages de la console modifiés';

  @override
  String get auditAdminAccountUpdated => 'Compte modifié par la console';

  @override
  String get auditAdminAccountSignedOut => 'Compte déconnecté partout';

  @override
  String get auditAdminAccountDeletionCancelled =>
      'Demande de suppression annulée';

  @override
  String get auditAdminAccountDeletedNow => 'Compte supprimé immédiatement';

  @override
  String get auditAdminAdminRoleChanged => 'Rôle d\'administration changé';

  @override
  String get auditAdminAccountMfaRemoved =>
      'Double authentification retirée par la console';

  @override
  String get auditAdminAccountCreated => 'Compte créé par la console';

  @override
  String get auditAdminAccountPasswordReset => 'Mot de passe provisoire donné';

  @override
  String get auditAdminAccountEmailChanged =>
      'Adresse e-mail changée par la console';

  @override
  String get adminOrgsErrorNotFound =>
      'Élément introuvable : actualisez la fiche.';

  @override
  String get adminOrgsErrorClosed => 'Cette structure est fermée.';

  @override
  String get adminOrgsErrorTrashed =>
      'Cette structure est à la corbeille : restaurez-la d\'abord.';

  @override
  String get adminOrgsErrorNotTrashed =>
      'Cette structure n\'est pas à la corbeille.';

  @override
  String get adminOrgsErrorName => 'Nom de 2 à 120 caractères.';

  @override
  String get adminOrgsErrorCity => 'Ville de 2 à 80 caractères.';

  @override
  String get adminOrgsErrorOwner =>
      'Le propriétaire ne se modifie pas : transférez d\'abord la structure.';

  @override
  String get adminOrgsErrorOwnerInactive =>
      'Le propriétaire est désactivé ou supprimé.';

  @override
  String get adminOrgsErrorAccountInactive =>
      'Ce compte est désactivé ou supprimé.';

  @override
  String get adminOrgsErrorStructureLimit =>
      'Le pack du propriétaire ne permet pas une structure de plus.';

  @override
  String get adminOrgsTitle => 'Structure';

  @override
  String get adminOrgsOpen => 'Ouvrir la fiche';

  @override
  String get adminOrgsCreate => 'Créer une structure';

  @override
  String get adminOrgsCreateHint =>
      'La structure est créée au pack de son propriétaire, qui en reçoit tous les droits.';

  @override
  String get adminOrgsOwner => 'Propriétaire';

  @override
  String get adminOrgsOwnerRequired => 'Choisissez le compte propriétaire.';

  @override
  String get adminOrgsFindAccount => 'Chercher un compte (nom ou e-mail)';

  @override
  String get adminOrgsNoAccount => 'Aucun compte actif trouvé.';

  @override
  String get adminOrgsChangeAccount => 'Choisir un autre compte';

  @override
  String get adminOrgsPickAccount => 'Choisissez un compte.';

  @override
  String get adminOrgsName => 'Nom de la structure';

  @override
  String get adminOrgsCity => 'Ville';

  @override
  String get adminOrgsCityOptional => 'Ville (facultatif)';

  @override
  String get adminOrgsPhone => 'Téléphone';

  @override
  String get adminOrgsContactEmail => 'E-mail de contact';

  @override
  String get adminOrgsPublicPhone => 'Numéro WhatsApp public';

  @override
  String adminOrgsPhoneValue(String phone) {
    return 'Téléphone : $phone';
  }

  @override
  String adminOrgsPublicPhoneValue(String phone) {
    return 'WhatsApp public : $phone';
  }

  @override
  String get adminOrgsEdit => 'Modifier';

  @override
  String get adminOrgsUpdated => 'Structure modifiée';

  @override
  String get adminOrgsRemoveLogo => 'Retirer le logo';

  @override
  String get adminOrgsRemoveLogoHint =>
      'Pour un logo inapproprié. La structure pourra en mettre un autre.';

  @override
  String get adminOrgsLogoRemoved => 'Logo retiré';

  @override
  String get adminOrgsAddMember => 'Ajouter un membre';

  @override
  String get adminOrgsMemberAdded => 'Membre ajouté';

  @override
  String get adminOrgsMembers => 'Membres';

  @override
  String get adminOrgsNoMember => 'Aucun membre.';

  @override
  String get adminOrgsMakeManager => 'Passer gestionnaire';

  @override
  String get adminOrgsMakeController => 'Passer contrôleur';

  @override
  String get adminOrgsRoleChanged => 'Rôle modifié';

  @override
  String get adminOrgsTransfer => 'Transférer la propriété';

  @override
  String adminOrgsTransferHint(String name) {
    return '$name devient propriétaire ; l\'actuel propriétaire reste gestionnaire.';
  }

  @override
  String get adminOrgsTransferred => 'Propriété transférée';

  @override
  String get adminOrgsRemoveMember => 'Retirer de la structure';

  @override
  String get adminOrgsMemberRemoved => 'Membre retiré';

  @override
  String get adminOrgsInvitations => 'Invitations en cours';

  @override
  String adminOrgsInvitationUntil(String date) {
    return 'valable jusqu\'au $date';
  }

  @override
  String get adminOrgsRevokeInvitation => 'Annuler l\'invitation';

  @override
  String get adminOrgsInvitationRevoked => 'Invitation annulée';

  @override
  String get adminOrgsEvents => 'Derniers événements';

  @override
  String get adminOrgsNoEvent => 'Aucun événement.';

  @override
  String adminOrgsEventTickets(int tickets, int admitted) {
    final intl.NumberFormat ticketsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String ticketsString = ticketsNumberFormat.format(tickets);
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);

    return '$ticketsString tickets, $admittedString entrés';
  }

  @override
  String adminOrgsEventsCount(int total, int upcoming) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat upcomingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String upcomingString = upcomingNumberFormat.format(upcoming);

    return 'Événements : $totalString (à venir : $upcomingString)';
  }

  @override
  String adminOrgsTicketsCount(int issued, int admitted) {
    final intl.NumberFormat issuedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String issuedString = issuedNumberFormat.format(issued);
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);

    return 'Tickets émis : $issuedString (entrés : $admittedString)';
  }

  @override
  String adminOrgsInvoicesCount(int total, int due) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat dueNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dueString = dueNumberFormat.format(due);

    return 'Factures : $totalString (à payer : $dueString)';
  }

  @override
  String adminOrgsOwnerValue(String name) {
    return 'Propriétaire : $name';
  }

  @override
  String get adminOrgsNoHistory =>
      'Aucune action de la console sur cette structure.';

  @override
  String get adminOrgsClosedTag => 'Fermée';

  @override
  String get adminOrgsTrashedTag => 'À la corbeille';

  @override
  String get adminOrgsPurgedTag => 'Effacée';

  @override
  String adminOrgsPurgeOn(String date) {
    return 'Effacement automatique le $date';
  }

  @override
  String get adminOrgsDelete => 'Supprimer';

  @override
  String get adminOrgsDeleteTrashTitle => 'Mettre à la corbeille';

  @override
  String get adminOrgsDeleteTrashHint =>
      'Structure sans événement : elle part à la corbeille, restaurable pendant 30 jours, puis effacée.';

  @override
  String get adminOrgsDeleteCloseTitle => 'Fermer définitivement';

  @override
  String get adminOrgsDeleteCloseHint =>
      'Cette structure a servi : elle est fermée pour toujours (membres sans accès, événements passés archivés, factures gardées). Irréversible.';

  @override
  String adminOrgsPreviewEvents(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements à venir annulés.',
      one: '1 événement à venir annulé.',
      zero: 'Aucun événement à venir à annuler.',
    );
    return '$_temp0';
  }

  @override
  String adminOrgsPreviewTickets(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tickets non entrés annulés.',
      one: '1 ticket non entré annulé.',
      zero: 'Aucun ticket à annuler.',
    );
    return '$_temp0';
  }

  @override
  String adminOrgsPreviewHolders(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString détenteurs prévenus dans l\'app.',
      one: '1 détenteur prévenu dans l\'app.',
      zero: 'Aucun détenteur à prévenir dans l\'app.',
    );
    return '$_temp0';
  }

  @override
  String get adminOrgsConfirmName => 'Nom de la structure';

  @override
  String adminOrgsConfirmNameHint(String name) {
    return 'Pour confirmer, saisissez : $name';
  }

  @override
  String get adminOrgsTrashed => 'Structure mise à la corbeille';

  @override
  String adminOrgsClosed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Structure fermée, $countString tickets annulés',
      one: 'Structure fermée, 1 ticket annulé',
      zero: 'Structure fermée',
    );
    return '$_temp0';
  }

  @override
  String get adminOrgsRestore => 'Restaurer';

  @override
  String get adminOrgsRestored => 'Structure restaurée';

  @override
  String get adminOrgsPurge => 'Effacer maintenant';

  @override
  String get adminOrgsPurgeHint =>
      'Nom, coordonnées, membres et invitations effacés tout de suite. Irréversible.';

  @override
  String get adminOrgsPurged => 'Structure effacée';

  @override
  String get consoleTrashTitle => 'Corbeille';

  @override
  String get consoleTrashHint =>
      'Structures supprimées, restaurables pendant 30 jours, puis effacées automatiquement.';

  @override
  String get consoleTrashEmpty => 'La corbeille est vide.';

  @override
  String consoleTrashDeletedOn(String date) {
    return 'Supprimée le $date';
  }

  @override
  String consoleTrashDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Effacement dans $countString jours',
      one: 'Effacement dans 1 jour',
      zero: 'Effacement imminent',
    );
    return '$_temp0';
  }

  @override
  String get consoleNavTrashHint => 'Restaurer une structure supprimée';

  @override
  String get auditAdminOrganizationCreated => 'Structure créée par la console';

  @override
  String get auditAdminOrganizationUpdated =>
      'Structure modifiée par la console';

  @override
  String get auditAdminOrganizationLogoRemoved => 'Logo retiré par la console';

  @override
  String get auditAdminOrganizationTrashed => 'Structure mise à la corbeille';

  @override
  String get auditAdminOrganizationClosed => 'Structure fermée définitivement';

  @override
  String get auditAdminOrganizationRestored => 'Structure restaurée';

  @override
  String get auditAdminOrganizationPurged => 'Structure effacée';

  @override
  String get auditAdminMemberRoleChanged =>
      'Rôle d\'un membre changé par la console';

  @override
  String get auditAdminMemberRemoved => 'Membre retiré par la console';

  @override
  String get auditAdminInvitationRevoked => 'Invitation annulée par la console';

  @override
  String get auditAdminEventCancelled =>
      'Événement annulé à la fermeture de la structure';

  @override
  String get adminOrgsErrorConfirmName =>
      'Saisissez exactement le nom de la structure.';

  @override
  String get consoleNavEvents => 'Événements';

  @override
  String get consoleNavEventsHint =>
      'Tous les événements : modifier, état, déplacer';

  @override
  String get consoleNavTickets => 'Tickets';

  @override
  String get consoleNavTicketsHint =>
      'Retrouver, annuler, changer le titulaire';

  @override
  String get adminEventsTitle => 'Événement';

  @override
  String get adminEventsSearch => 'Titre, ville ou structure';

  @override
  String get adminEventsAll => 'Tous';

  @override
  String get adminEventsEdit => 'Modifier';

  @override
  String get adminEventsUpdated => 'Événement modifié';

  @override
  String get adminEventsFieldTitle => 'Titre';

  @override
  String get adminEventsFieldVenue => 'Lieu';

  @override
  String get adminEventsFieldAddress => 'Adresse';

  @override
  String get adminEventsFieldTagline => 'Accroche';

  @override
  String get adminEventsFieldDescription => 'Description';

  @override
  String get adminEventsFieldCapacity => 'Capacité';

  @override
  String adminEventsCapacityValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Capacité : $countString';
  }

  @override
  String get adminEventsDates => 'Changer les dates';

  @override
  String adminEventsDatesHint(String zone) {
    return 'Heure locale de l\'événement ($zone).';
  }

  @override
  String get adminEventsStart => 'Début';

  @override
  String get adminEventsEnd => 'Fin';

  @override
  String get adminEventsNext => 'Continuer';

  @override
  String get adminEventsMakePublic => 'Rendre public';

  @override
  String get adminEventsMakePrivate => 'Rendre privé';

  @override
  String get adminEventsPublic => 'Public';

  @override
  String get adminEventsPrivate => 'Privé';

  @override
  String get adminEventsBlocked => 'Retiré du catalogue';

  @override
  String adminEventsStatusChanged(String status) {
    return 'Nouvel état : $status';
  }

  @override
  String adminEventsCancelled(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Événement annulé, $countString tickets annulés',
      one: 'Événement annulé, 1 ticket annulé',
      zero: 'Événement annulé',
    );
    return '$_temp0';
  }

  @override
  String get adminEventsMove => 'Déplacer vers une autre structure';

  @override
  String get adminEventsMoveTo => 'Structure de destination';

  @override
  String adminEventsMoveHint(String name) {
    return 'L\'événement passe à « $name » avec ses catégories, portes et tickets ; les affectations de l\'ancienne équipe sont retirées.';
  }

  @override
  String get adminEventsMoved => 'Événement déplacé';

  @override
  String get adminEventsTrash => 'Mettre à la corbeille';

  @override
  String get adminEventsTrashHint =>
      'Brouillon sans ticket : il disparaît pour la structure, restaurable pendant 30 jours, puis effacé.';

  @override
  String get adminEventsTrashed => 'Brouillon mis à la corbeille';

  @override
  String get adminEventsRestored => 'Événement restauré';

  @override
  String get adminEventsIssue => 'Émettre des tickets';

  @override
  String get adminEventsIssueHint =>
      'Tickets anonymes, en un lot visible du promoteur, qui les envoie comme les autres.';

  @override
  String get adminEventsQuantity => 'Nombre (1 à 1 000)';

  @override
  String adminEventsIssued(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tickets émis',
      one: '1 ticket émis',
    );
    return '$_temp0';
  }

  @override
  String get adminEventsTickets => 'Tickets';

  @override
  String adminEventsTicketsCount(
    int total,
    int valid,
    int admitted,
    int revoked,
  ) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat validNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String validString = validNumberFormat.format(valid);
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);
    final intl.NumberFormat revokedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String revokedString = revokedNumberFormat.format(revoked);

    return 'Émis : $totalString · valables : $validString · entrés : $admittedString · annulés : $revokedString';
  }

  @override
  String adminEventsDoors(String doors) {
    return 'Portes : $doors';
  }

  @override
  String get adminEventsNoHistory => 'Aucune action de la console.';

  @override
  String get adminEventsErrorTrashed =>
      'Cet événement est à la corbeille : restaurez-le d\'abord.';

  @override
  String get adminEventsErrorNotTrashed =>
      'Cet événement n\'est pas à la corbeille.';

  @override
  String get adminEventsErrorLocked =>
      'Événement clôturé, annulé ou archivé : plus modifiable.';

  @override
  String get adminEventsErrorTransition =>
      'Ce changement d\'état n\'est pas possible.';

  @override
  String get adminEventsErrorEnded =>
      'Événement terminé : impossible de le publier.';

  @override
  String get adminEventsErrorIncomplete =>
      'Il faut une photo et une ville pour publier.';

  @override
  String get adminEventsErrorHasTickets =>
      'Des tickets existent : retour en brouillon impossible.';

  @override
  String get adminEventsErrorNotTrashable =>
      'Seul un brouillon sans ticket va à la corbeille : annulez plutôt l\'événement.';

  @override
  String get adminEventsErrorSameOrg =>
      'L\'événement est déjà dans cette structure.';

  @override
  String get adminEventsErrorInvoice =>
      'Événement déjà facturé : déplacement impossible.';

  @override
  String get adminEventsErrorOrgInactive =>
      'La structure de destination est suspendue.';

  @override
  String get adminEventsErrorFields =>
      'Vérifiez les champs (titre 2 à 160 caractères, dates, capacité).';

  @override
  String get adminEventsErrorTagline => 'Accroche de 60 caractères au plus.';

  @override
  String get adminEventsErrorCapacity =>
      'La capacité est inférieure aux tickets déjà émis.';

  @override
  String get adminEventsErrorEndBeforeStart => 'La fin doit suivre le début.';

  @override
  String get adminEventsErrorBilling =>
      'Le pack de la structure ne le permet pas.';

  @override
  String get adminTicketsTitle => 'Ticket';

  @override
  String get adminTicketsSearch => 'Référence, nom ou téléphone';

  @override
  String get adminTicketsSearchHint =>
      'Sur toute la plateforme. Le QR n\'est jamais affiché.';

  @override
  String get adminTicketsErrorSearch => 'De 3 à 60 caractères.';

  @override
  String get adminTicketsErrorLocked =>
      'Seul un ticket valable, pas encore utilisé, peut être modifié ou annulé.';

  @override
  String get adminTicketsErrorHolder =>
      'Titulaire invalide (nom, téléphone ou e-mail).';

  @override
  String get adminTicketsErrorIssueOff =>
      'Activez « Émettre des tickets à la place d\'un promoteur » dans les réglages.';

  @override
  String get adminTicketsErrorQuantity => 'De 1 à 1 000 tickets.';

  @override
  String adminTicketsNumber(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'N° $numberString';
  }

  @override
  String adminTicketsIssuedAt(String date) {
    return 'Émis le $date';
  }

  @override
  String adminTicketsRevokedAt(String date) {
    return 'Annulé le $date';
  }

  @override
  String adminTicketsEntry(String date, String door, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Entré le $date (porte : $door) · entrées : $countString';
  }

  @override
  String get adminTicketsHolder => 'Titulaire';

  @override
  String get adminTicketsNoHolder => 'Sans titulaire';

  @override
  String adminTicketsWallet(String name) {
    return 'Dans « Mes tickets » de $name';
  }

  @override
  String get adminTicketsHolderChanged => 'Titulaire modifié';

  @override
  String get adminTicketsRevoke => 'Annuler le ticket';

  @override
  String get adminTicketsRevokeHint =>
      'Le ticket ne sera plus accepté à l\'entrée. Irréversible.';

  @override
  String get adminTicketsRevoked => 'Ticket annulé';

  @override
  String get adminTicketsDeliveries => 'Envois';

  @override
  String get adminTicketsNoDelivery => 'Aucun envoi enregistré.';

  @override
  String get auditAdminEventUpdated => 'Événement modifié par la console';

  @override
  String get auditAdminEventStatusChanged =>
      'État de l\'événement changé par la console';

  @override
  String get auditAdminEventMoved =>
      'Événement déplacé vers une autre structure';

  @override
  String get auditAdminEventTrashed => 'Brouillon mis à la corbeille';

  @override
  String get auditAdminEventRestored => 'Événement restauré';

  @override
  String get auditAdminEventPurged => 'Brouillon effacé';

  @override
  String get auditAdminTicketRevoked => 'Ticket annulé par la console';

  @override
  String get auditAdminTicketHolderUpdated => 'Titulaire changé par la console';

  @override
  String get auditAdminTicketsIssued => 'Tickets émis par la console';

  @override
  String get consoleSearchHint => 'Compte, structure, événement, ticket…';

  @override
  String get consoleSearchTitle => 'Recherche';

  @override
  String get consoleSearchTooShort => 'De 2 à 60 caractères.';

  @override
  String get consoleSearchIdle =>
      'Cherchez par nom, e-mail, titre, ville ou référence (tickets : 3 caractères au moins).';

  @override
  String get consoleSearchEmpty => 'Aucun résultat.';

  @override
  String get adminMessageSend => 'Envoyer un message';

  @override
  String adminMessageSent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Message envoyé à $countString personnes',
      one: 'Message envoyé à 1 personne',
    );
    return '$_temp0';
  }

  @override
  String get adminMessageErrorInvalid =>
      'Titre de 3 caractères au moins, message obligatoire.';

  @override
  String get adminMessageErrorNoRecipients =>
      'Aucun destinataire : personne n\'est relié (ticket dans « Mes tickets » ou membre actif).';

  @override
  String adminMessageHintAccount(String name) {
    return '$name le reçoit dans « Support », avec une notification, et peut répondre.';
  }

  @override
  String adminMessageHintOrganization(String name) {
    return 'Les membres actifs de $name reçoivent une notification et le voient en bandeau dans l\'app.';
  }

  @override
  String adminMessageHintEvent(String name) {
    return 'Les détenteurs de « $name » qui ont ajouté leur ticket à « Mes tickets » reçoivent une notification et le voient en bandeau.';
  }

  @override
  String get adminMessageTitle => 'Titre';

  @override
  String get adminMessageBody => 'Message';

  @override
  String get adminMessageDuration => 'Bandeau affiché pendant';

  @override
  String adminMessageDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get adminMessageSubmit => 'Envoyer';

  @override
  String consoleAuditScope(String name) {
    return 'Filtré : $name';
  }

  @override
  String get consoleAuditScopeClear => 'Tout le journal';

  @override
  String get consoleAuditAdmin => 'Administrateur';

  @override
  String get consoleAuditAdminAny => 'Tous les administrateurs';

  @override
  String get auditAdminMessageSent => 'Message envoyé (console)';

  @override
  String get auditFieldRecipients => 'Personnes';

  @override
  String get auditValueAudienceAccount => 'un compte';

  @override
  String get auditValueAudienceMembers => 'membres d\'une structure';

  @override
  String get auditValueAudienceHolders => 'détenteurs d\'un événement';

  @override
  String consoleAnnouncementForOrganization(String name) {
    return 'Réservé aux membres de $name';
  }

  @override
  String consoleAnnouncementForEvent(String name) {
    return 'Réservé aux détenteurs de « $name »';
  }

  @override
  String get maintenanceTitle => 'Maintenance en cours';

  @override
  String get maintenanceWritesBlocked =>
      'Les modifications sont suspendues pour le moment ; les tickets restent valables et le contrôle à l\'entrée continue.';

  @override
  String get authErrorSignupsClosed =>
      'Les inscriptions sont fermées : il faut un code d\'invitation valable.';

  @override
  String get signUpClosedTitle => 'Inscriptions sur invitation';

  @override
  String get signUpClosedBody =>
      'Pour le moment, un compte se crée seulement avec le code d\'invitation d\'une structure.';

  @override
  String get signUpCodeRequired => 'Code d\'invitation obligatoire.';

  @override
  String get consolePlatformTitle => 'Plateforme';

  @override
  String get consoleMaintenance => 'Maintenance';

  @override
  String get consoleMaintenanceHint =>
      'Bandeau « Maintenance en cours » pour tous, avec votre message.';

  @override
  String get consoleMaintenanceMessage => 'Message (facultatif)';

  @override
  String get consoleMaintenanceWrites => 'Bloquer les modifications';

  @override
  String get consoleMaintenanceWritesHint =>
      'Sauf pour les administrateurs. Le contrôle à l\'entrée, « Mes tickets » et le support continuent.';

  @override
  String get consoleSignupsOpen => 'Inscriptions ouvertes';

  @override
  String get consoleSignupsOpenHint =>
      'Fermées : un compte se crée seulement avec un code d\'invitation, ou depuis la console.';

  @override
  String get consolePlatformSave => 'Enregistrer';

  @override
  String get consoleNavExports => 'Exports';

  @override
  String get consoleNavExportsHint =>
      'Comptes, structures, événements, factures, journal pour Excel';

  @override
  String get consoleExportsHint =>
      'Fichier CSV pour Excel (50 000 lignes au plus, les plus récentes). Chaque export est inscrit au journal.';

  @override
  String get consoleExportInvoices => 'Factures';

  @override
  String get consoleExportForbidden => 'Votre rôle ne permet pas cet export.';

  @override
  String consoleExportDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString lignes exportées',
      one: '1 ligne exportée',
    );
    return '$_temp0';
  }

  @override
  String consoleExportTruncated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString lignes exportées (les plus récentes seulement)';
  }

  @override
  String get exportColId => 'Identifiant';

  @override
  String get exportColName => 'Nom';

  @override
  String get exportColEmail => 'E-mail';

  @override
  String get exportColPhone => 'Téléphone';

  @override
  String get exportColStatus => 'État';

  @override
  String get exportColAdminRole => 'Rôle d\'administration';

  @override
  String get exportColCreatedAt => 'Créé le';

  @override
  String get exportColLastSignIn => 'Dernière connexion';

  @override
  String get exportColDeletionRequested => 'Suppression demandée le';

  @override
  String get exportColDeleted => 'Supprimé';

  @override
  String get exportColCity => 'Ville';

  @override
  String get exportColClosedAt => 'Fermée le';

  @override
  String get exportColTrashedAt => 'À la corbeille le';

  @override
  String get exportColOwner => 'Propriétaire';

  @override
  String get exportColOwnerEmail => 'E-mail du propriétaire';

  @override
  String get exportColMembers => 'Membres';

  @override
  String get exportColTitle => 'Titre';

  @override
  String get exportColOrganization => 'Structure';

  @override
  String get exportColStartsAt => 'Début';

  @override
  String get exportColEndsAt => 'Fin';

  @override
  String get exportColPublic => 'Public';

  @override
  String get exportColAdmitted => 'Entrés';

  @override
  String get exportColIssuedAt => 'Émise le';

  @override
  String get exportColDueAt => 'Échéance';

  @override
  String get exportColAmount => 'Montant (FCFA)';

  @override
  String get exportColEntries => 'Entrées';

  @override
  String get exportColBillableEntries => 'Entrées facturées';

  @override
  String get exportColAccount => 'Compte';

  @override
  String get exportColAccountEmail => 'E-mail du compte';

  @override
  String get exportColEvent => 'Événement';

  @override
  String get exportColPaidAt => 'Payée le';

  @override
  String get exportColAction => 'Action';

  @override
  String get exportColActor => 'Auteur';

  @override
  String get exportColResourceType => 'Type';

  @override
  String get exportColResourceId => 'Élément';

  @override
  String get exportColDetails => 'Détails';

  @override
  String get auditAdminPlatformStatusUpdated =>
      'Plateforme : maintenance ou inscriptions modifiées';

  @override
  String get auditAdminExport => 'Export (console)';

  @override
  String get auditFieldMaintenance => 'Maintenance';

  @override
  String get auditFieldBlockWrites => 'Modifications bloquées';

  @override
  String get auditFieldSignupsOpen => 'Inscriptions ouvertes';

  @override
  String get auditFieldExport => 'Export';

  @override
  String exploreOffline(String ago) {
    return 'Hors ligne, mis à jour $ago';
  }

  @override
  String get exploreOfflineBody =>
      'La liste se mettra à jour dès le retour du réseau.';

  @override
  String get timeAgoNow => 'à l\'instant';

  @override
  String timeAgoMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'il y a $minutesString min';
  }

  @override
  String timeAgoHours(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return 'il y a $hoursString h';
  }

  @override
  String timeAgoDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $daysString jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get closedOrgsTitle => 'Structures fermées';

  @override
  String get closedOrgsSubtitle =>
      'Consultation seule : rien ne peut être modifié.';

  @override
  String get closedOrgsEntrySubtitle =>
      'Revoir les événements et rapports d\'une structure fermée';

  @override
  String get closedOrgsEmpty => 'Aucune structure fermée.';

  @override
  String get closedOrgsLoadError =>
      'Chargement impossible. Vérifiez la connexion.';

  @override
  String closedOrgClosedOn(String date) {
    return 'Fermée le $date';
  }

  @override
  String closedOrgEventCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString événements',
      one: '1 événement',
      zero: 'Aucun événement',
    );
    return '$_temp0';
  }

  @override
  String closedOrgReadOnlyTitle(String date) {
    return 'Structure fermée le $date : consultation seule';
  }

  @override
  String get closedOrgReadOnlyBody =>
      'Revoyez vos événements et exportez leurs rapports (bilan PDF, liste des tickets). Rien ne peut être créé ni modifié.';

  @override
  String get closedOrgInvoices => 'Factures';

  @override
  String get closedOrgInvoicesHint => 'Factures et paiements de votre compte';

  @override
  String get closedOrgEventsTitle => 'Événements';

  @override
  String get closedOrgEventsHint =>
      'Touchez un événement pour exporter son bilan ou la liste de ses tickets.';

  @override
  String closedOrgEventCounts(int issued, int admitted, int revoked) {
    final intl.NumberFormat issuedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String issuedString = issuedNumberFormat.format(issued);
    final intl.NumberFormat admittedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String admittedString = admittedNumberFormat.format(admitted);
    final intl.NumberFormat revokedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String revokedString = revokedNumberFormat.format(revoked);

    return 'Tickets : $issuedString · Entrés : $admittedString · Annulés : $revokedString';
  }

  @override
  String get closedOrgNotFound => 'Cette structure n\'est plus consultable.';

  @override
  String get publicOrgSeeAll => 'Voir la structure et ses événements';

  @override
  String publicOrgSince(String year) {
    return 'Sur Tikéo depuis $year';
  }

  @override
  String get publicOrgUpcoming => 'À venir';

  @override
  String get publicOrgPast => 'Déjà organisés';

  @override
  String get publicOrgEvents => 'Événements à venir';

  @override
  String get publicOrgNoEvents => 'Aucun événement à venir pour l\'instant.';

  @override
  String get publicOrgContact => 'Contacter sur WhatsApp';

  @override
  String publicOrgWhatsAppMessage(String organization) {
    return 'Bonjour, je vous contacte après avoir vu $organization sur Tikéo.';
  }

  @override
  String get publicOrgNotFound =>
      'Cette structure n\'est plus visible sur Tikéo.';

  @override
  String get publicOrgTitle => 'Organisateur';

  @override
  String get publicEventAddCalendar => 'Ajouter à mon agenda';

  @override
  String get publicEventCalendarFailed =>
      'Aucun agenda trouvé sur ce téléphone.';

  @override
  String get publicEventDirections => 'Itinéraire';

  @override
  String get publicEventDirectionsFailed => 'Impossible d\'ouvrir la carte.';

  @override
  String get publicEventSameOrganizer => 'Du même organisateur';

  @override
  String get publicEventSeeAllOrganizer => 'Tout voir';

  @override
  String get walletSeeEvent => 'Voir la fiche de l\'événement';

  @override
  String get walletSeeEventHint => 'Lieu, itinéraire, autres dates';

  @override
  String walletSeeOrganizer(String name) {
    return 'Organisé par $name';
  }

  @override
  String get walletSeeOrganizerHint => 'Ses autres événements et son contact';
}
