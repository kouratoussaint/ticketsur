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
  String get orgLoading => 'Chargement de vos structures…';

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
  String get welcomeDiscoverTitle => 'Découvrez les événements';

  @override
  String get welcomeDiscoverBody =>
      'Concerts, conférences, galas, sport… partout au Burkina, sans compte.';

  @override
  String get welcomeDiscoverAll => 'Voir tous les événements';

  @override
  String get welcomeDiscoverEmpty =>
      'Les premiers événements publics arrivent bientôt.';

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
  String get ticketsBulkSheet => 'Planche A4 à imprimer';

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
}
