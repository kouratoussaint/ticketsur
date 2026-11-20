// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tikéo';

  @override
  String get appSlogan => 'Your event in one click';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get verdictPreviewTitle => 'Verdict screens';

  @override
  String get verdictTitleAdmitted => 'ENTRY ALLOWED';

  @override
  String get verdictTitleRefused => 'ENTRY REFUSED';

  @override
  String get verdictTitleIndeterminate => 'STATUS TO CONFIRM';

  @override
  String get verdictVerifying => 'Checking…';

  @override
  String get verdictVerifyingHint => 'Do not let anyone in before the verdict.';

  @override
  String get verdictReasonAccepted => 'Valid ticket — entry allowed';

  @override
  String get verdictReasonAlreadyUsed => 'Ticket already used';

  @override
  String get verdictReasonRevoked => 'Ticket cancelled';

  @override
  String get verdictReasonExpired => 'Ticket expired';

  @override
  String get verdictReasonNotFound => 'Ticket not found';

  @override
  String get verdictReasonWrongEvent => 'Ticket not valid for this event';

  @override
  String get verdictReasonUnauthorized => 'Check not allowed';

  @override
  String get verdictReasonEventInactive => 'Check unavailable for this event';

  @override
  String get verdictReasonRateLimited => 'Too many attempts, try again';

  @override
  String get verdictReasonPending => 'Confirming validation';

  @override
  String get verdictReasonUnavailable => 'Cannot check — connection required';

  @override
  String verdictFirstPassage(String time) {
    return 'First entry at $time';
  }

  @override
  String verdictFirstPassageAt(String time, String checkpoint) {
    return 'First entry at $time · $checkpoint';
  }

  @override
  String verdictReference(String reference) {
    return 'Ref. $reference';
  }

  @override
  String get verdictIndeterminateAdvice =>
      'Do not let anyone in based on the app alone.';

  @override
  String get verdictNextScan => 'Next scan';

  @override
  String get verdictRetry => 'Check again';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInEmailLabel => 'Email address';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInShowPassword => 'Show password';

  @override
  String get signInHidePassword => 'Hide password';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get signInForgotPassword => 'Forgot password?';

  @override
  String get validationEmailRequired => 'Enter your email address';

  @override
  String get validationEmailInvalid => 'Invalid email address';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get authErrorInvalidCredentials =>
      'Incorrect email address or password.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Email address not confirmed. Open the link you received by email.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Wait a minute before trying again.';

  @override
  String get authErrorNetwork =>
      'Cannot reach the server. Check your network and try again.';

  @override
  String get authErrorUnknown => 'Something went wrong. Try again.';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordIntro =>
      'Enter your account\'s email address. You will receive a link to choose a new password.';

  @override
  String get forgotPasswordSubmit => 'Send the link';

  @override
  String forgotPasswordSent(String email) {
    return 'If an account exists for $email, a reset email has just been sent.';
  }

  @override
  String get forgotPasswordBackToSignIn => 'Back to sign in';

  @override
  String get homeTitle => 'Home';

  @override
  String homeSignedInAs(String email) {
    return 'Signed in: $email';
  }

  @override
  String get homeComingSoon =>
      'The promoter and controller spaces are coming in the next versions.';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get configErrorTitle => 'Missing configuration';

  @override
  String get configErrorHint =>
      'Run the app with --dart-define-from-file=config/staging.json.';

  @override
  String get exitConfirm => 'Press Back again to exit Tikéo';

  @override
  String get navHome => 'Home';

  @override
  String get navEvents => 'Events';

  @override
  String get navTickets => 'Tickets';

  @override
  String get navTeam => 'Team';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeGreeting => 'Welcome to Tikéo';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAccountActive => 'Active account';

  @override
  String get profileAbout => 'About';

  @override
  String get orgLoading => 'Loading your organizations…';

  @override
  String get orgLoadError => 'Could not load your organizations.';

  @override
  String get orgRetry => 'Try again';

  @override
  String get orgCreateTitle => 'Create your organization';

  @override
  String get orgCreateIntro =>
      'Your organization (company, association, collective…) brings together your events, your tickets and your team. You will be its owner.';

  @override
  String get orgCreateAnotherTitle => 'New organization';

  @override
  String get orgNameLabel => 'Organization or company name';

  @override
  String get orgNameHint => 'E.g. Festival des Nuits Sacrées';

  @override
  String get orgNameRequired => 'Enter a name of at least 2 characters';

  @override
  String get orgCreateSubmit => 'Create the organization';

  @override
  String get orgErrorInvalidName =>
      'Invalid name: between 2 and 120 characters.';

  @override
  String get orgErrorLimit => 'You have reached the limit of 5 organizations.';

  @override
  String orgCreated(String name) {
    return 'Organization “$name” created';
  }

  @override
  String get orgSwitchTitle => 'Switch organization';

  @override
  String get orgSwitchAction => 'Switch';

  @override
  String get orgCreateAction => 'Create an organization';

  @override
  String get orgActiveLabel => 'Organization';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleController => 'Controller';

  @override
  String get eventsEmptyTitle => 'No events yet';

  @override
  String get eventsEmptyBody =>
      'Create your first event: title, venue, dates and time zone. It stays a draft until you publish it.';

  @override
  String get eventsEmptyControllerBody =>
      'The events you are assigned to will appear here.';

  @override
  String get eventsFilterEmpty => 'No events in this category.';

  @override
  String get eventsNew => 'New event';

  @override
  String get eventsLoadError => 'Could not load events.';

  @override
  String get eventsFilterActive => 'Upcoming';

  @override
  String get eventsFilterDrafts => 'Drafts';

  @override
  String get eventsFilterPublished => 'Published';

  @override
  String get eventsFilterDone => 'Past';

  @override
  String get eventsFilterAll => 'All';

  @override
  String get eventStatusDraft => 'Draft';

  @override
  String get eventStatusPublished => 'Published';

  @override
  String get eventStatusInProgress => 'In progress';

  @override
  String get eventStatusClosed => 'Closed';

  @override
  String get eventStatusArchived => 'Archived';

  @override
  String get eventStatusCancelled => 'Cancelled';

  @override
  String get eventFormCreateTitle => 'New event';

  @override
  String get eventFormEditTitle => 'Edit the event';

  @override
  String get eventTitleLabel => 'Title';

  @override
  String get eventTitleHint => 'E.g. New Year\'s Eve concert';

  @override
  String get eventVenueLabel => 'Venue (optional)';

  @override
  String get eventVenueHint => 'E.g. Palais des sports, Ouaga 2000';

  @override
  String get eventTimezoneLabel => 'Time zone';

  @override
  String get eventTimezoneHelp =>
      'Times are entered and shown in this time zone.';

  @override
  String get eventStartsLabel => 'Start';

  @override
  String get eventEndsLabel => 'End';

  @override
  String get eventDateLabel => 'Date';

  @override
  String get eventTimeLabel => 'Time';

  @override
  String get eventCapacityLabel => 'Capacity (optional)';

  @override
  String get eventCapacityHint => 'Maximum number of attendees';

  @override
  String get eventFormSubmitCreate => 'Create the draft';

  @override
  String get eventFormSubmitSave => 'Save';

  @override
  String eventCreated(String title) {
    return '“$title” created as a draft';
  }

  @override
  String get eventSaved => 'Changes saved';

  @override
  String get eventErrorTitle => 'Enter a title of 2 to 160 characters.';

  @override
  String get eventErrorVenue => 'The venue must not exceed 160 characters.';

  @override
  String get eventErrorDates =>
      'The end must come after the start, within 31 days.';

  @override
  String get eventErrorTimezone => 'Unknown time zone.';

  @override
  String get eventErrorCapacity => 'Enter a capacity between 1 and 1,000,000.';

  @override
  String get eventErrorCapacityBelowIssued =>
      'The capacity cannot be lower than the number of tickets already issued.';

  @override
  String get eventErrorLocked => 'This event can no longer be edited.';

  @override
  String get eventErrorInvalidTransition =>
      'This status change is not allowed.';

  @override
  String get eventErrorHasTickets =>
      'Tickets have been issued: it cannot go back to draft.';

  @override
  String get eventErrorAlreadyEnded =>
      'This event has already ended: it cannot be published.';

  @override
  String get eventErrorNotFound => 'Event not found or insufficient rights.';

  @override
  String get eventErrorNetwork =>
      'Cannot connect. Check your network and try again.';

  @override
  String get eventErrorUnknown => 'An unexpected error occurred. Try again.';

  @override
  String get eventDetailDates => 'Dates';

  @override
  String get eventDetailVenue => 'Venue';

  @override
  String get eventDetailCapacity => 'Capacity';

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
  String get eventNoCapacity => 'Unlimited';

  @override
  String get eventNoVenue => 'Not specified';

  @override
  String eventTimeZoneLine(String zone, String offset) {
    return '$zone ($offset)';
  }

  @override
  String get eventEdit => 'Edit';

  @override
  String get eventLifecycleTitle => 'Status';

  @override
  String get eventLifecycleDraft =>
      'Draft: hidden from controllers. Publish it to issue tickets.';

  @override
  String get eventLifecyclePublished =>
      'Published: you can issue tickets. Entries will be validated as soon as you start the check.';

  @override
  String get eventLifecycleInProgress =>
      'Check in progress: controllers validate entries until you stop the check.';

  @override
  String get eventLifecycleClosed =>
      'Check stopped: no more entries are accepted.';

  @override
  String get eventLifecycleArchived => 'Archived: read only.';

  @override
  String get eventLifecycleCancelled => 'Cancelled: no entries are accepted.';

  @override
  String get eventActionPublish => 'Publish';

  @override
  String get eventActionStart => 'Start the check';

  @override
  String get eventActionClose => 'Close';

  @override
  String get eventActionArchive => 'Archive';

  @override
  String get eventActionDraft => 'Back to draft';

  @override
  String get eventActionCancel => 'Cancel the event';

  @override
  String get eventConfirmPublish =>
      'Tickets can be issued. The check at the gates will begin when you start it.';

  @override
  String get eventConfirmStart =>
      'Assigned controllers can validate entries right away, whatever the time, until you stop the check.';

  @override
  String get eventConfirmClose =>
      'No more entries will be accepted. This cannot be undone.';

  @override
  String get eventConfirmArchive =>
      'The event will become read only. This cannot be undone.';

  @override
  String get eventConfirmDraft =>
      'The event becomes editable again and hidden from controllers.';

  @override
  String get eventConfirmCancel =>
      'No entries will be accepted. This cannot be undone.';

  @override
  String get eventConfirmBack => 'Back';

  @override
  String eventStatusChanged(String status) {
    return 'Status: $status';
  }

  @override
  String get eventNotFoundTitle => 'Event not found';

  @override
  String get homeNextEventTitle => 'Next event';

  @override
  String get homeNoEventBody => 'No upcoming events.';

  @override
  String get homeCreateEvent => 'Create an event';

  @override
  String get homeSeeEvents => 'See events';

  @override
  String get categoriesTitle => 'Ticket categories';

  @override
  String get categoriesEmpty =>
      'No categories. Add one, for example Standard, VIP or Invitation.';

  @override
  String get setupAdd => 'Add';

  @override
  String get setupSave => 'Save';

  @override
  String get setupCancel => 'Cancel';

  @override
  String get setupLoadError => 'Could not load.';

  @override
  String categoryCounts(int issued, int redeemed) {
    return '$issued issued · $redeemed entered';
  }

  @override
  String categoryQuota(int capacity) {
    return 'Quota: $capacity';
  }

  @override
  String get categoryNoQuota => 'No quota';

  @override
  String categoriesTotal(int issued, int capacity) {
    return '$issued tickets issued out of $capacity';
  }

  @override
  String categoriesTotalUnlimited(int issued) {
    return '$issued tickets issued, unlimited capacity';
  }

  @override
  String get categoryNewTitle => 'New category';

  @override
  String get categoryEditTitle => 'Edit the category';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryNameHint => 'E.g. VIP';

  @override
  String get categoryQuotaLabel => 'Quota (optional)';

  @override
  String get categoryQuotaHelp =>
      'Empty: limited only by the event\'s capacity.';

  @override
  String get categoryDelete => 'Delete';

  @override
  String get categoryDeleteTitle => 'Delete the category?';

  @override
  String categoryDeleteBody(String name) {
    return '“$name” will be deleted. This is not possible if tickets have been issued in it.';
  }

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get checkpointsTitle => 'Check gates';

  @override
  String get checkpointsEmpty =>
      'No gates. Add the entrances where your controllers will scan tickets.';

  @override
  String get checkpointActive => 'Active';

  @override
  String get checkpointInactive => 'Disabled: scans refused';

  @override
  String get checkpointNewTitle => 'New gate';

  @override
  String get checkpointEditTitle => 'Rename the gate';

  @override
  String get checkpointNameHint => 'E.g. Main entrance';

  @override
  String get checkpointDeactivateTitle => 'Disable the gate?';

  @override
  String checkpointDeactivateBody(String name) {
    return 'Scans at “$name” will be refused right away, until it is enabled again.';
  }

  @override
  String get checkpointDeactivate => 'Disable';

  @override
  String get checkpointSaved => 'Gate saved';

  @override
  String get setupErrorNotFound => 'Item not found or insufficient rights.';

  @override
  String get setupErrorName => 'Enter a name of 1 to 60 characters.';

  @override
  String get setupErrorNameTaken => 'This name is already used for this event.';

  @override
  String get setupErrorCapacity => 'Enter a quota between 1 and 1,000,000.';

  @override
  String get setupErrorCapacityBelowIssued =>
      'The quota cannot be lower than the tickets already issued.';

  @override
  String get setupErrorHasTickets =>
      'There are tickets in this category: it cannot be deleted.';

  @override
  String get setupErrorLocked => 'Event closed: its setup is frozen.';

  @override
  String get teamInvite => 'Invite';

  @override
  String get teamMembersTitle => 'Members';

  @override
  String get teamInvitationsTitle => 'Pending invitations';

  @override
  String teamInvitationLine(String role, String hint) {
    return '$role · code …$hint';
  }

  @override
  String teamInvitationDetail(String date, int uses, int max) {
    return 'Expires on $date · $uses of $max';
  }

  @override
  String get teamRevoke => 'Revoke';

  @override
  String get teamRevokeTitle => 'Revoke the invitation?';

  @override
  String teamRevokeBody(String hint) {
    return 'The code ending in $hint will no longer work.';
  }

  @override
  String get teamInactive => 'Disabled';

  @override
  String get teamYou => 'You';

  @override
  String get teamControllerTitle => 'Team managed by the promoters';

  @override
  String teamControllerBody(String org) {
    return 'You are a controller for “$org”. The promoters manage the team and your gate assignments.';
  }

  @override
  String get inviteTitle => 'Invite to the team';

  @override
  String get inviteRoleLabel => 'Role';

  @override
  String get inviteRoleControllerHelp =>
      'Scans tickets at the gates assigned to them.';

  @override
  String get inviteRoleManagerHelp =>
      'Manages events, tickets and controllers.';

  @override
  String get inviteValidity => 'Validity';

  @override
  String inviteDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get inviteUses => 'Number of people';

  @override
  String inviteUsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get inviteCreate => 'Create the code';

  @override
  String get inviteCodeTitle => 'Invitation code';

  @override
  String get inviteCodeHint => 'Share it now: it will never be shown again.';

  @override
  String inviteCodeValid(String date) {
    return 'Valid until $date';
  }

  @override
  String get inviteShare => 'Share';

  @override
  String get inviteCopy => 'Copy';

  @override
  String get inviteCopied => 'Code copied';

  @override
  String inviteShareText(String org, String role, String code, String date) {
    return 'Join “$org” on Tikéo as $role. In the app, tap “Join with a code” and enter $code (valid until $date).';
  }

  @override
  String get inviteDone => 'Done';

  @override
  String get memberRoleLabel => 'Role';

  @override
  String get memberActiveLabel => 'Active access';

  @override
  String get memberActiveHelp =>
      'Disabled: no more actions possible, scans refused right away.';

  @override
  String get memberSaved => 'Access updated';

  @override
  String get teamErrorForbidden => 'Action not allowed for your role.';

  @override
  String get teamErrorInvalid => 'Invalid settings.';

  @override
  String get teamErrorMemberNotFound => 'Member not found or access disabled.';

  @override
  String get teamErrorIsOwner => 'The owner cannot be changed.';

  @override
  String get teamErrorIsSelf => 'You cannot change your own access.';

  @override
  String get teamErrorCheckpoint => 'Unknown gate for this event.';

  @override
  String get joinTitle => 'Join an organization';

  @override
  String get joinIntro =>
      'Enter the code you received from an event promoter. It starts with TSI.';

  @override
  String get joinCodeLabel => 'Invitation code';

  @override
  String get joinSubmit => 'Join';

  @override
  String joinWelcome(String org) {
    return 'Welcome to “$org”';
  }

  @override
  String get joinInvalid =>
      'Unknown or revoked code. Check it with the promoter.';

  @override
  String get joinExpired =>
      'This code has expired or has already been used. Ask for a new one.';

  @override
  String get joinAlreadyMember => 'You are already part of this organization.';

  @override
  String get joinRateLimited =>
      'Too many attempts. Try again in fifteen minutes.';

  @override
  String get joinUnauthorized => 'Your session has expired. Sign in again.';

  @override
  String get joinAction => 'Join with a code';

  @override
  String get joinHaveCode => 'I have an invitation code';

  @override
  String get eventTeamTitle => 'Assigned controllers';

  @override
  String get eventTeamEmpty =>
      'Nobody is assigned. Add the members who will scan at this event.';

  @override
  String get eventTeamAllCheckpoints => 'All gates';

  @override
  String get eventTeamAssignTitle => 'Assign a member';

  @override
  String get eventTeamMemberLabel => 'Member';

  @override
  String get eventTeamCheckpointLabel => 'Gate';

  @override
  String get eventTeamAssign => 'Assign';

  @override
  String get eventTeamRemoveTitle => 'Remove the assignment?';

  @override
  String eventTeamRemoveBody(String name) {
    return '$name will no longer be able to scan at this gate.';
  }

  @override
  String get eventTeamRemove => 'Remove';

  @override
  String get eventTeamNoMembers => 'First invite members from the Team tab.';

  @override
  String get eventTeamMemberInactive => 'Access disabled';

  @override
  String get ticketRevokedStamp => 'Ticket cancelled';

  @override
  String get ticketRedeemedStamp => 'USED';

  @override
  String get ticketQrHidden => 'QR hidden';

  @override
  String get ticketFooter =>
      'Single-use ticket. Do not post it: the first one shown at the entrance counts.';

  @override
  String get ticketsNoEventTitle => 'No published events';

  @override
  String get ticketsNoEventBody => 'Publish an event to issue its tickets.';

  @override
  String get ticketsGoEvents => 'See events';

  @override
  String get ticketsEventLabel => 'Event';

  @override
  String ticketsSummary(int issued, int redeemed) {
    return '$issued issued · $redeemed entered';
  }

  @override
  String get ticketsFilterAll => 'All';

  @override
  String get ticketsFilterValid => 'Valid';

  @override
  String get ticketsFilterRedeemed => 'Used';

  @override
  String get ticketsFilterRevoked => 'Cancelled';

  @override
  String get ticketsSearchHint => 'Reference, category, name or phone';

  @override
  String get ticketsEmpty =>
      'No tickets yet. Tap “Issue” to create the first ones.';

  @override
  String get ticketsEmptyFilter => 'No matching tickets.';

  @override
  String get ticketsLoadMore => 'Show more';

  @override
  String ticketsCount(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String get ticketsIssue => 'Issue';

  @override
  String get ticketsControllerBody =>
      'Tickets are managed by the promoters. You will check them at the entrance.';

  @override
  String get ticketStatusIssued => 'Valid';

  @override
  String get ticketStatusRedeemed => 'Used';

  @override
  String get ticketStatusRevoked => 'Cancelled';

  @override
  String get ticketStatusExpired => 'Expired';

  @override
  String get issueTitle => 'Issue tickets';

  @override
  String get issueCategory => 'Category';

  @override
  String issueRemaining(int count) {
    return '$count left';
  }

  @override
  String get issueUnlimited => 'no quota';

  @override
  String get issueQuantity => 'Number of tickets';

  @override
  String get issueQuantityHelp => 'From 1 to 500 per batch.';

  @override
  String get issueQuantityError => 'Enter a number between 1 and 500.';

  @override
  String issueSubmit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Issue $count tickets',
      one: 'Issue 1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get issueNoCategory => 'First add a category in the event page.';

  @override
  String get issueDraft => 'Publish the event to issue tickets.';

  @override
  String issueDoneTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets issued',
      one: '1 ticket issued',
    );
    return '$_temp0';
  }

  @override
  String get issueDoneBody =>
      'Share them now. You can also download them again later from their page.';

  @override
  String get issueSharePdf => 'Share as PDF';

  @override
  String get issueSeeTickets => 'See tickets';

  @override
  String get ticketErrorNotFound =>
      'Ticket or event not found, or insufficient rights.';

  @override
  String get ticketErrorNotPublished =>
      'Publish the event before issuing tickets.';

  @override
  String get ticketErrorCategoryCapacity => 'Category quota reached.';

  @override
  String get ticketErrorEventCapacity => 'Event capacity reached.';

  @override
  String get ticketErrorInvalid =>
      'Request refused by the server (quantity or category).';

  @override
  String get ticketDetailTitle => 'Ticket';

  @override
  String get ticketShowQr => 'Show the QR';

  @override
  String get ticketShowQrHint =>
      'Downloading it again is recorded in the organization\'s log.';

  @override
  String get ticketShareImage => 'Share the image';

  @override
  String get ticketSharePdf => 'PDF';

  @override
  String ticketShareText(String event) {
    return 'Your ticket for “$event”. Show this QR code at the entrance.';
  }

  @override
  String get ticketRevoke => 'Cancel the ticket';

  @override
  String get ticketRevokeTitle => 'Cancel this ticket?';

  @override
  String ticketRevokeBody(String reference) {
    return 'Ticket $reference will be refused at the entrance. This cannot be undone.';
  }

  @override
  String get ticketRevokeReason => 'Reason (optional)';

  @override
  String get ticketRevoked => 'Ticket cancelled';

  @override
  String get ticketAlreadyRedeemed =>
      'This ticket has already been used: it can no longer be cancelled.';

  @override
  String ticketIssuedAt(String date) {
    return 'Issued on $date';
  }

  @override
  String ticketRedeemedAt(String date, String checkpoint) {
    return 'Used on $date · $checkpoint';
  }

  @override
  String ticketRevokedAt(String date) {
    return 'Cancelled on $date';
  }

  @override
  String get ticketPreparing => 'Preparing…';

  @override
  String get navControl => 'Check';

  @override
  String get navHistory => 'History';

  @override
  String get controlTitle => 'Entry check';

  @override
  String get controlEmptyTitle => 'No post assigned';

  @override
  String get controlEmptyBody =>
      'A promoter must assign you to an event and a gate. Pull down to refresh.';

  @override
  String get controlWindowOpen => 'Check open';

  @override
  String get controlWindowClosed => 'Check stopped';

  @override
  String get controlChooseDoor => 'Choose your gate';

  @override
  String get controlLoadError => 'Could not load your posts.';

  @override
  String get scannerManualLabel => 'Ticket code';

  @override
  String get scannerManualHelp =>
      'Paste or type the ticket code. It starts with TS1.';

  @override
  String get scannerPaste => 'Paste and check';

  @override
  String get scannerValidate => 'Check';

  @override
  String scannerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets checked',
      one: '1 ticket checked',
      zero: 'No tickets checked',
    );
    return '$_temp0';
  }

  @override
  String get scannerOutsideWindow =>
      'Check not started or stopped: the promoter must start it, otherwise entries will be refused.';

  @override
  String get scannerEmptyClipboard => 'The clipboard does not contain text.';

  @override
  String get historyTitle => 'My recent scans';

  @override
  String get historyEmpty => 'No scans in the last 7 days.';

  @override
  String get historyLoadError => 'Could not load the history.';

  @override
  String get homeControlTitle => 'Check entries';

  @override
  String homeControlBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gates are assigned to you',
      one: '1 gate is assigned to you',
    );
    return '$_temp0';
  }

  @override
  String get eventControl => 'Check entries';

  @override
  String get feedbackTitle => 'Sounds and vibrations';

  @override
  String get feedbackScanSounds => 'Check sounds';

  @override
  String get feedbackScanSoundsHelp =>
      'A distinct sound for each verdict: entry allowed, refused, to confirm.';

  @override
  String get feedbackUiSounds => 'Interface sounds';

  @override
  String get feedbackUiSoundsHelp => 'Navigation and confirmations, discreet.';

  @override
  String get feedbackHaptics => 'Vibrations';

  @override
  String get feedbackPreviewAdmitted => 'Listen: entry allowed';

  @override
  String get feedbackPreviewRefused => 'Listen: entry refused';

  @override
  String get feedbackPreviewIndeterminate => 'Listen: to confirm';

  @override
  String get scannerHint => 'Place the QR code in the frame';

  @override
  String get scannerManual => 'Enter the code';

  @override
  String get scannerTorchOn => 'Turn on the flashlight';

  @override
  String get scannerTorchOff => 'Turn off the flashlight';

  @override
  String get scannerLeave => 'Leave the post';

  @override
  String get cameraDeniedTitle => 'Camera access denied';

  @override
  String get cameraDeniedBody =>
      'Allow the camera for Tikéo in the Android settings (Apps › Tikéo › Permissions), then try again. You can also enter the code.';

  @override
  String get cameraErrorTitle => 'Camera unavailable';

  @override
  String get cameraErrorBody =>
      'Close other apps using the camera, then try again. You can also enter the code.';

  @override
  String get cameraRetry => 'Try again';

  @override
  String get homeQuickTitle => 'Quick actions';

  @override
  String get homeQuickNewEvent => 'New event';

  @override
  String get homeQuickIssue => 'Issue tickets';

  @override
  String get homeQuickInvite => 'Invite the team';

  @override
  String get eventErrorIncomplete =>
      'Add a cover photo and a city before publishing.';

  @override
  String get eventErrorCity => 'Enter a city of 2 to 80 characters.';

  @override
  String get eventErrorAddress => 'Address of 200 characters at most.';

  @override
  String get eventErrorDescription =>
      'Description of 2,000 characters at most.';

  @override
  String get eventErrorCover =>
      'Photo refused: choose a JPEG, PNG or WebP image of 2 MB at most.';

  @override
  String get eventKindConcert => 'Concert';

  @override
  String get eventKindConference => 'Conference';

  @override
  String get eventKindWorship => 'Worship';

  @override
  String get eventKindSport => 'Sport';

  @override
  String get eventKindWedding => 'Wedding';

  @override
  String get eventKindTraining => 'Training';

  @override
  String get eventKindGala => 'Gala';

  @override
  String get eventKindOther => 'Other';

  @override
  String get eventStepInfo => 'Details';

  @override
  String get eventStepWhenWhere => 'Date and venue';

  @override
  String get eventStepCover => 'Photo';

  @override
  String get eventStepReview => 'Preview';

  @override
  String eventStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get eventStepNext => 'Next';

  @override
  String get eventStepBack => 'Previous';

  @override
  String get eventKindLabel => 'Event type';

  @override
  String get eventDescriptionLabel => 'Description (optional)';

  @override
  String get eventDescriptionHint => 'Program, artists, access instructions…';

  @override
  String get eventTaglineLabel => 'Tagline (optional)';

  @override
  String get eventTaglineHint => 'A short sentence printed on the ticket';

  @override
  String get eventCityLabel => 'City';

  @override
  String get eventCityHint => 'E.g. Ouagadougou';

  @override
  String get eventCityHelp => 'Required to publish.';

  @override
  String get eventAddressLabel => 'Address (optional)';

  @override
  String get eventAddressHint => 'District, street, landmark';

  @override
  String get eventCoverTitle => 'Cover photo';

  @override
  String get eventCoverHelp =>
      'Landscape format recommended. It appears on the event page, shared tickets and the check screen. Required to publish.';

  @override
  String get eventCoverGallery => 'Gallery';

  @override
  String get eventCoverCamera => 'Camera';

  @override
  String get eventCoverChange => 'Change the photo';

  @override
  String get eventCoverAdd => 'Add a photo';

  @override
  String get eventCoverRemove => 'Remove';

  @override
  String get eventCoverEmpty => 'No photo yet';

  @override
  String get eventCoverSaved => 'Photo saved';

  @override
  String get eventCoverUploadFailed =>
      'Event saved, but the photo could not be sent. Try again from the event page.';

  @override
  String get eventCoverLater =>
      'You can also add it later from the event page.';

  @override
  String get eventReviewTitle => 'Here is your event';

  @override
  String get eventReviewHint =>
      'Check the details, then save. The event stays a draft until you publish it.';

  @override
  String get eventCityMissing => 'City to specify';

  @override
  String get eventToCompleteTitle => 'To complete before publishing';

  @override
  String get eventMissingCover => 'Cover photo';

  @override
  String get eventMissingCity => 'City';

  @override
  String get eventDetailDescription => 'Description';

  @override
  String get eventDetailAddress => 'Address';

  @override
  String get eventDetailKind => 'Type';

  @override
  String get authErrorWeakPassword =>
      'Password too weak: at least 8 characters, with letters and numbers.';

  @override
  String get authErrorSamePassword =>
      'The new password must be different from the current one.';

  @override
  String get authErrorEmailTaken =>
      'This address is already used by another account.';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileEditTitle => 'My profile';

  @override
  String get profileNameLabel => 'Display name';

  @override
  String get profileNameHint => 'First and last name';

  @override
  String get profileNameError => 'Enter a name of 2 to 60 characters.';

  @override
  String get profilePhoneLabel => 'Phone (optional)';

  @override
  String get profilePhoneHint => 'E.g. 70 12 34 56';

  @override
  String get profilePhoneHelp =>
      '8-digit Burkinabe number, or international format (+225…).';

  @override
  String get profilePhoneError => 'Invalid phone number.';

  @override
  String get profileEmailLabel => 'Email address';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profilePhotoChange => 'Change the photo';

  @override
  String get profilePhotoSaved => 'Profile photo saved';

  @override
  String get profilePhotoError =>
      'Photo refused: JPEG, PNG or WebP image of 1 MB at most.';

  @override
  String get profileLoadError => 'Could not load your profile.';

  @override
  String get profileErrorUnknown => 'Could not save. Try again.';

  @override
  String get profileSecurityTitle => 'Security';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileChangeEmail => 'Change email address';

  @override
  String get profileSignOutEverywhere => 'Sign out all devices';

  @override
  String get profileSignOutEverywhereBody =>
      'All your sessions will be closed, including this one. You will need to sign in again.';

  @override
  String get profileCurrentPassword => 'Current password';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileConfirmPassword => 'Confirm the new password';

  @override
  String get profilePasswordTooShort => 'At least 8 characters.';

  @override
  String get profilePasswordMismatch => 'The two passwords differ.';

  @override
  String get profilePasswordRequired => 'Enter your current password.';

  @override
  String get profileWrongPassword => 'Incorrect current password.';

  @override
  String get profilePasswordChanged => 'Password changed';

  @override
  String get profileNewEmail => 'New email address';

  @override
  String get profileEmailHelp =>
      'A confirmation link will be sent to the new address. It will only replace the current one after confirmation.';

  @override
  String get profileEmailSame => 'This is already your address.';

  @override
  String profileEmailSent(String email) {
    return 'Confirmation link sent to $email.';
  }

  @override
  String get profileSend => 'Send the link';

  @override
  String get profileDangerTitle => 'Sensitive area';

  @override
  String get profileDeleteAccount => 'Delete my account';

  @override
  String get profileDeleteBody =>
      'Your account will be deleted in 30 days: your personal data will be erased, tickets already issued stay with your organizations, and the organizations you own will be suspended. You can cancel until then. Type DELETE to confirm.';

  @override
  String get profileDeleteWord => 'DELETE';

  @override
  String get profileDeleteConfirm => 'Schedule the deletion';

  @override
  String profileDeletionPending(String date) {
    return 'Account deletion scheduled on $date.';
  }

  @override
  String get profileDeletionCancel => 'Cancel the deletion';

  @override
  String get profileDeletionCancelled => 'Deletion cancelled';

  @override
  String get profileDeletionRequested => 'Deletion scheduled in 30 days';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileConfirm => 'Confirm';

  @override
  String get orgCardTitle => 'Organization';

  @override
  String get orgEdit => 'Edit the profile';

  @override
  String get orgEditTitle => 'Organization profile';

  @override
  String get orgEditHelp =>
      'This information appears on your tickets and, soon, on the public page of your events.';

  @override
  String get orgPhoneLabel => 'Contact phone (optional)';

  @override
  String get orgEmailLabel => 'Contact email (optional)';

  @override
  String get orgCityLabel => 'City (optional)';

  @override
  String get orgLogoChange => 'Change the logo';

  @override
  String get orgLogoSaved => 'Logo saved';

  @override
  String get orgSaved => 'Profile saved';

  @override
  String get orgLeave => 'Leave the organization';

  @override
  String orgLeaveTitle(String name) {
    return 'Leave “$name”?';
  }

  @override
  String get orgLeaveBody =>
      'You will lose access to its events, tickets and checks. To come back, you will need a new invitation code.';

  @override
  String orgLeft(String name) {
    return 'You left “$name”';
  }

  @override
  String get orgErrorNotFound =>
      'Organization not found or insufficient rights.';

  @override
  String get orgErrorPhone => 'Invalid phone number.';

  @override
  String get orgErrorEmail => 'Invalid email address.';

  @override
  String get orgErrorCity => 'City of 2 to 80 characters.';

  @override
  String get orgErrorLogo =>
      'Logo refused: JPEG, PNG or WebP image of 1 MB at most.';

  @override
  String get orgErrorLastOwner =>
      'You are the last owner: appoint another one before leaving.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardOpen => 'Live dashboard';

  @override
  String get dashboardLive => 'Live';

  @override
  String get dashboardClosed => 'Check closed';

  @override
  String get dashboardStale => 'Not refreshed';

  @override
  String dashboardUpdatedAt(String time) {
    return 'Refreshed at $time';
  }

  @override
  String dashboardStaleBody(String time) {
    return 'Connection lost: figures from $time. Retrying automatically.';
  }

  @override
  String get dashboardRefresh => 'Refresh';

  @override
  String get dashboardAttendance => 'Entry rate';

  @override
  String dashboardAdmittedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString entries',
      one: '1 entry',
      zero: 'No entries',
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
      other: '$countString tickets issued',
      one: '1 ticket issued',
    );
    return 'out of $_temp0';
  }

  @override
  String dashboardCapacityLine(String value) {
    return 'Capacity: $value';
  }

  @override
  String get dashboardKpiAdmitted => 'Entered';

  @override
  String get dashboardKpiRemaining => 'Expected';

  @override
  String get dashboardKpiRefused => 'Refused';

  @override
  String dashboardKpiRate(int minutes) {
    return 'Entries / $minutes min';
  }

  @override
  String get dashboardTimelineTitle => 'Entries over time';

  @override
  String dashboardTimelineStepMinutes(int minutes) {
    return 'Per $minutes-minute slot';
  }

  @override
  String dashboardTimelineStepHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Per $hours-hour slot',
      one: 'Per 1-hour slot',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTimelineEmpty =>
      'Entries will appear here from the first scan.';

  @override
  String get dashboardLegendAdmitted => 'Entries';

  @override
  String get dashboardLegendRefused => 'Refused';

  @override
  String dashboardTimelineSemantics(
    int accepted,
    int refused,
    String from,
    String to,
  ) {
    return '$accepted entries and $refused refusals between $from and $to';
  }

  @override
  String get dashboardRefusalsTitle => 'Refusal reasons';

  @override
  String get dashboardOtherReason => 'Other reason';

  @override
  String get dashboardCategoriesTitle => 'By category';

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
      other: '$admittedString entered',
      one: '1 entered',
      zero: 'None entered',
    );
    return '$_temp0 out of $issuedString';
  }

  @override
  String dashboardQuota(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Quota: $countString';
  }

  @override
  String get dashboardCheckpointsTitle => 'By gate';

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
      other: '$admittedString entries',
      one: '1 entry',
      zero: 'No entries',
    );
    String _temp1 = intl.Intl.pluralLogic(
      refused,
      locale: localeName,
      other: '$refusedString refusals',
      one: '1 refusal',
      zero: 'no refusals',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get dashboardCheckpointInactive => 'Closed';

  @override
  String dashboardLastScan(String time) {
    return 'Last scan at $time';
  }

  @override
  String get dashboardNoScan => 'No scans';

  @override
  String get dashboardControllersTitle => 'Controllers';

  @override
  String dashboardRevokedExpired(int revoked, int expired) {
    final intl.NumberFormat revokedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String revokedString = revokedNumberFormat.format(revoked);
    final intl.NumberFormat expiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String expiredString = expiredNumberFormat.format(expired);

    return 'Tickets cancelled: $revokedString · expired: $expiredString';
  }

  @override
  String get dashboardNoTickets => 'No tickets issued for this event.';

  @override
  String get dashboardIssueTickets => 'Issue tickets';

  @override
  String get dashboardErrorNotFound =>
      'Dashboard unavailable: event not found or insufficient rights.';

  @override
  String get dashboardErrorLoad => 'Could not load the dashboard.';

  @override
  String get homeDashboard => 'Follow entries live';

  @override
  String get holderTitle => 'Holder';

  @override
  String get holderOptional => 'Holder (optional)';

  @override
  String get holderOptionalHint =>
      'The name is printed on the ticket. Without a holder, the ticket belongs to whoever carries it.';

  @override
  String get holderName => 'Full name';

  @override
  String get holderPhone => 'Phone';

  @override
  String get holderPhoneHelp => 'E.g. 70 12 34 56 or +225 07 08 09 10 11';

  @override
  String get holderEmail => 'Email';

  @override
  String get holderNone => 'No holder: bearer ticket';

  @override
  String get holderAdd => 'Add a holder';

  @override
  String get holderEdit => 'Edit the holder';

  @override
  String get holderSave => 'Save';

  @override
  String get holderSaved => 'Holder saved';

  @override
  String get holderErrorName => 'Name of 120 characters at most.';

  @override
  String get holderErrorPhone => 'Invalid phone number.';

  @override
  String get holderErrorEmail => 'Invalid email address.';

  @override
  String get ticketErrorNotEditable =>
      'Only a valid ticket, not yet used, can change holder.';

  @override
  String ticketCardHolder(String name) {
    return 'Holder: $name';
  }

  @override
  String get importTitle => 'Import a list';

  @override
  String get importEntry => 'Import a list (Excel, CSV)';

  @override
  String get importIntro =>
      'One row per attendee. Recognized columns: name (or first and last name), phone, email and category. Excel (.xlsx) or CSV file, 500 rows at most.';

  @override
  String get importPick => 'Choose a file';

  @override
  String get importChange => 'Change file';

  @override
  String get importTemplate => 'Share a template to fill in';

  @override
  String importRowsRead(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows read',
      one: '1 row read',
      zero: 'No rows read',
    );
    return '$_temp0';
  }

  @override
  String get importDefaultCategory => 'Category for rows without a category';

  @override
  String get importNoCategory =>
      'First create a ticket category for this event.';

  @override
  String get importErrorUnsupported =>
      'Unsupported format: choose an Excel (.xlsx) or CSV file.';

  @override
  String get importErrorLegacy =>
      'Old Excel format (.xls): save the file as .xlsx or CSV.';

  @override
  String get importErrorUnreadable => 'Unreadable or damaged file.';

  @override
  String get importErrorTooLarge => 'File too large (5 MB at most).';

  @override
  String get importErrorNoName =>
      'Name column not found: add a “Name” header above the list.';

  @override
  String get importErrorEmpty => 'No rows to import in this file.';

  @override
  String importReady(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows ready',
      one: '1 row ready',
      zero: 'No rows ready',
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
      other: '$countString with errors',
      one: '1 with errors',
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
      other: '$countString to check',
      one: '1 to check',
    );
    return '$_temp0';
  }

  @override
  String get importColumnsTitle => 'Recognized columns';

  @override
  String get importColumnsGuessed =>
      'No header: columns guessed from their content.';

  @override
  String get importColumnName => 'Name';

  @override
  String get importColumnFirstName => 'First name';

  @override
  String get importColumnPhone => 'Phone';

  @override
  String get importColumnEmail => 'Email';

  @override
  String get importColumnCategory => 'Category';

  @override
  String importColumnFrom(String field, String header) {
    return '$field ← “$header”';
  }

  @override
  String importColumnAt(String field, String letter) {
    return '$field ← column $letter';
  }

  @override
  String get importPerCategoryTitle => 'By category';

  @override
  String importQuotaCategory(String category, int wanted, int remaining) {
    return '$category: $wanted requested, $remaining left';
  }

  @override
  String importQuotaEvent(int wanted, int remaining) {
    return 'Event capacity: $wanted requested, $remaining places left';
  }

  @override
  String get importErrorsTitle => 'Rows with errors';

  @override
  String get importWarningsTitle => 'To check';

  @override
  String importLine(int line, String reason) {
    return 'Row $line · $reason';
  }

  @override
  String importMore(int count) {
    return '… and $count more';
  }

  @override
  String get importProblemNameMissing => 'name missing';

  @override
  String get importProblemNameTooLong =>
      'name too long (120 characters at most)';

  @override
  String get importProblemPhone => 'invalid phone';

  @override
  String get importProblemEmail => 'invalid email';

  @override
  String importProblemCategory(String label) {
    return 'unknown category “$label”';
  }

  @override
  String get importProblemNoCategory => 'category missing';

  @override
  String get importWarningPhone => 'same phone as a previous row';

  @override
  String get importWarningEmail => 'same email as a previous row';

  @override
  String get importPreviewTitle => 'Preview';

  @override
  String get importSkipErrors => 'Skip rows with errors';

  @override
  String get importTooMany =>
      '500 tickets at most per import: split the list into several files.';

  @override
  String importSubmit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Issue $countString tickets',
      one: 'Issue 1 ticket',
      zero: 'Issue the tickets',
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
    return 'Hello $name, here is your ticket for “$event”, $date$place. Show the QR code at the entrance. Single-use ticket: do not pass it on to anyone.';
  }

  @override
  String sendMessage(String event, String date, String place) {
    return 'Hello, here is your ticket for “$event”, $date$place. Show the QR code at the entrance. Single-use ticket: do not pass it on to anyone.';
  }

  @override
  String sendSubject(String event) {
    return 'Your ticket: $event';
  }

  @override
  String get sendChannelWhatsApp => 'WhatsApp';

  @override
  String get sendChannelSms => 'SMS';

  @override
  String get sendChannelEmail => 'Email';

  @override
  String get sendTitle => 'Send to the holder';

  @override
  String get sendNoContact =>
      'Add a phone number or email to the holder to send them their ticket.';

  @override
  String get sendConfirmTitle => 'Was the ticket sent?';

  @override
  String sendConfirmBody(String channel) {
    return 'Confirm once the message has been sent by $channel. Only confirmed sends are recorded.';
  }

  @override
  String get sendConfirmYes => 'Yes, sent';

  @override
  String get sendConfirmNo => 'No';

  @override
  String get sendRecorded => 'Send recorded';

  @override
  String get sendMissingWhatsApp => 'WhatsApp is not installed on this phone.';

  @override
  String get sendMissingSms => 'No SMS app available.';

  @override
  String get sendMissingEmail => 'No email app set up on this phone.';

  @override
  String get sendFailed => 'Could not open. Try again.';

  @override
  String sendLast(String channel, String date) {
    return 'Last sent: $channel, $date';
  }

  @override
  String ticketSentVia(String channel, String date) {
    return 'Sent by $channel on $date';
  }

  @override
  String get ticketErrorNotSendable =>
      'Only a valid ticket, not yet used, can be sent.';

  @override
  String get sendBatchTitle => 'Send the tickets';

  @override
  String get sendBatchIntro =>
      'Valid tickets never sent, one by one: the app opens on the right conversation with the ticket attached, you tap Send, then confirm here.';

  @override
  String sendBatchProgress(int current, int total) {
    return 'Ticket $current of $total';
  }

  @override
  String sendBatchStats(int sent, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      sent,
      locale: localeName,
      other: '$sent sent',
      one: '1 sent',
      zero: 'None sent',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped skipped',
      one: '1 skipped',
      zero: 'none skipped',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String sendBatchSend(String channel) {
    return 'Send by $channel';
  }

  @override
  String get sendBatchSkip => 'Skip';

  @override
  String get sendBatchRetry => 'Try again';

  @override
  String get sendBatchNext => 'Yes, sent · next';

  @override
  String sendBatchEmptyTitle(String channel) {
    return 'No tickets to send by $channel';
  }

  @override
  String get sendBatchEmptyPhone =>
      'Only valid tickets, never sent, whose holder has a phone number are offered.';

  @override
  String get sendBatchEmptyEmail =>
      'Only valid tickets, never sent, whose holder has an email address are offered.';

  @override
  String get sendBatchDoneTitle => 'Series finished';

  @override
  String get sendBatchClose => 'Close';

  @override
  String get sendBatchLoadError => 'Could not load the tickets to send.';

  @override
  String get reportAction => 'Report';

  @override
  String get reportSheetTitle => 'Event report';

  @override
  String get reportPdf => 'PDF summary';

  @override
  String get reportPdfHint =>
      'Key figures, entries, categories, gates, refusals and controllers.';

  @override
  String get reportCsv => 'Ticket list (Excel, CSV)';

  @override
  String get reportCsvHint =>
      'One ticket per row, holders included. Each export is recorded in the organization\'s log.';

  @override
  String get reportErrorNotFound =>
      'Report unavailable: event not found or insufficient rights.';

  @override
  String get reportErrorLoad => 'Could not prepare the report. Try again.';

  @override
  String get reportTitle => 'Event report';

  @override
  String reportStatsAt(String date) {
    return 'Figures as of $date';
  }

  @override
  String get reportIssued => 'Tickets issued';

  @override
  String get reportAdmitted => 'Entered';

  @override
  String get reportAttendance => 'Entry rate';

  @override
  String get reportNoShow => 'Expected, not entered';

  @override
  String get reportRevoked => 'Cancelled';

  @override
  String get reportRefused => 'Refused at check';

  @override
  String get reportTimeline => 'Entries over time';

  @override
  String get reportCategories => 'By category';

  @override
  String get reportCheckpoints => 'By gate';

  @override
  String get reportRefusals => 'Refusal reasons';

  @override
  String get reportControllers => 'Controllers';

  @override
  String get reportColCategory => 'Category';

  @override
  String get reportColQuota => 'Quota';

  @override
  String get reportColIssued => 'Issued';

  @override
  String get reportColAdmitted => 'Entered';

  @override
  String get reportColRate => 'Rate';

  @override
  String get reportColCheckpoint => 'Gate';

  @override
  String get reportColRefused => 'Refused';

  @override
  String get reportColLastScan => 'Last scan';

  @override
  String get reportColReason => 'Reason';

  @override
  String get reportColCount => 'Count';

  @override
  String get reportColController => 'Controller';

  @override
  String get reportUnlimited => 'Unlimited';

  @override
  String get reportNone => 'None';

  @override
  String reportPage(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get reportCsvHeader =>
      'Reference;Category;Type;Status;Holder;Phone;Email;Issued on;Entered on;Gate;Cancelled on;Last sent;Sent on';

  @override
  String get categoryInvitationLabel => 'Invitation category';

  @override
  String get categoryInvitationHelp =>
      'Its tickets are presented as invitations (card, PDF, message). The entrance check does not change.';

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
      'Personal single-use invitation. Do not post it: the first one shown at the entrance counts.';

  @override
  String invitationShareText(String event) {
    return 'Your invitation for “$event”. Show this QR code at the entrance.';
  }

  @override
  String invitationMessage(String event, String date, String place) {
    return 'Hello, you are invited to “$event”, $date$place. Your invitation is attached: show the QR code at the entrance. Personal single-use invitation: do not pass it on to anyone.';
  }

  @override
  String invitationMessageNamed(
    String name,
    String event,
    String date,
    String place,
  ) {
    return 'Hello $name, you are invited to “$event”, $date$place. Your invitation is attached: show the QR code at the entrance. Personal single-use invitation: do not pass it on to anyone.';
  }

  @override
  String invitationSubject(String event) {
    return 'Your invitation: $event';
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
    return 'Guests: $admittedString entered out of $_temp0';
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

    return 'Including invitations: $admittedString entries out of $countString.';
  }

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceHelp =>
      'On this device. “System” follows the phone\'s light or dark setting.';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get categoryPriceLabel => 'Indicative price (optional)';

  @override
  String get categoryPriceHelp =>
      'Shown on the event\'s public page. 0 for free entry.';

  @override
  String get categoryPriceError => 'Price from 0 to 10,000,000 FCFA.';

  @override
  String get navExplore => 'Explore';

  @override
  String get navOrganize => 'Organize';

  @override
  String get navAccount => 'Account';

  @override
  String get exploreSearchHint => 'Concert, venue, promoter…';

  @override
  String get exploreSearchLabel => 'Search for an event';

  @override
  String get exploreFilters => 'Filters';

  @override
  String get exploreAllCities => 'All cities';

  @override
  String get exploreCityTitle => 'City';

  @override
  String get exploreAll => 'All';

  @override
  String get exploreFeatured => 'Featured';

  @override
  String get exploreUpcoming => 'Coming soon';

  @override
  String exploreUpcomingIn(String city) {
    return 'Coming soon in $city';
  }

  @override
  String get exploreResults => 'Results';

  @override
  String exploreCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString events',
      one: '1 event',
      zero: 'No events',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyTitle => 'No events found';

  @override
  String get exploreEmptyBody =>
      'Try another category, another city or another word.';

  @override
  String get exploreEmptyCatalogBody =>
      'Promoters have not yet published any event open to the public here.';

  @override
  String get exploreResetFilters => 'Clear filters';

  @override
  String get exploreErrorNetwork =>
      'No connection. Check the network and try again.';

  @override
  String get exploreErrorLoad => 'Could not load events.';

  @override
  String get exploreRetry => 'Try again';

  @override
  String get exploreMore => 'See more events';

  @override
  String exploreFromPrice(String price) {
    return 'From $price';
  }

  @override
  String get exploreFree => 'Free entry';

  @override
  String explorePrice(String amount) {
    return '$amount FCFA';
  }

  @override
  String get exploreKindConcert => 'Concerts';

  @override
  String get exploreKindConference => 'Conferences';

  @override
  String get exploreKindWorship => 'Worship';

  @override
  String get exploreKindSport => 'Sport';

  @override
  String get exploreKindWedding => 'Weddings';

  @override
  String get exploreKindTraining => 'Training';

  @override
  String get exploreKindGala => 'Galas';

  @override
  String get exploreKindOther => 'Other';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersClear => 'Clear all';

  @override
  String get filtersCategory => 'Category';

  @override
  String get filtersWhen => 'When?';

  @override
  String get filtersAnyTime => 'Any date';

  @override
  String get filtersToday => 'Today';

  @override
  String get filtersWeekend => 'This weekend';

  @override
  String get filtersWeek => 'This week';

  @override
  String get filtersFree => 'Free entry only';

  @override
  String get filtersFreeHelp => 'When the promoter says so';

  @override
  String get filtersApply => 'See events';

  @override
  String get publicEventAbout => 'About';

  @override
  String get publicEventTickets => 'Tickets';

  @override
  String get publicEventPriceUnknown => 'Price from the promoter';

  @override
  String get publicEventOrganizer => 'Organized by';

  @override
  String get publicEventGetTicket => 'Get a ticket';

  @override
  String get publicEventNoContact => 'Tickets from the promoter';

  @override
  String publicEventWhatsAppMessage(String event, String date) {
    return 'Hello, I would like a ticket for “$event” ($date). Seen on Tikéo.';
  }

  @override
  String get publicEventWhatsAppFailed =>
      'WhatsApp could not open on this phone.';

  @override
  String get publicEventNotFound => 'This event is no longer visible.';

  @override
  String get publicEventShare => 'Share';

  @override
  String publicEventShareText(String event, String date, String place) {
    return '“$event”, $date — $place. On Tikéo.';
  }

  @override
  String get publicEventOnline => 'Happening now';

  @override
  String get organizeTitle => 'Are you an event promoter?';

  @override
  String get organizeBody =>
      'Create your organization, issue QR tickets, send them by WhatsApp and check entries live.';

  @override
  String get organizePoint1 => 'One ticket = one entry, checked online';

  @override
  String get organizePoint2 => 'Guest lists from Excel';

  @override
  String get organizePoint3 => 'Dashboard and reports';

  @override
  String get eventPublicTitle => 'Visible to the public';

  @override
  String get eventPublicHelp =>
      'The event appears in Tikéo\'s Explore, without an account, once published. Neither tickets nor figures are shown.';

  @override
  String get eventPublicOn => 'Visible in Explore';

  @override
  String get eventPublicOff => 'Private: only your guests have their ticket';

  @override
  String get orgPublicPhoneLabel => 'Public WhatsApp number';

  @override
  String get orgPublicPhoneHelp =>
      'Shown on your public events (“Get a ticket”). Optional.';

  @override
  String get homeAllEvents => 'My events';

  @override
  String homeHello(String name) {
    return 'Hello $name';
  }

  @override
  String get homeHelloPlain => 'Hello';

  @override
  String get homeMyEventsTitle => 'My events';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeStatAdmitted => 'entered';

  @override
  String get homeStatIssued => 'issued';

  @override
  String get homeStatAttendance => 'attendance';

  @override
  String get homeProfileLabel => 'My profile';

  @override
  String get eventErrorBlocked =>
      'This event was removed from the catalog by Tikéo. Contact support.';

  @override
  String get eventPublicBlocked => 'Removed from the catalog by Tikéo. Reason:';

  @override
  String get consoleTitle => 'Tikéo console';

  @override
  String get consoleEntrySubtitle => 'Platform administration';

  @override
  String get consoleForbidden =>
      'This console is reserved for Tikéo administrators.';

  @override
  String get consoleLoadError => 'Could not load. Check the connection.';

  @override
  String get consoleRetry => 'Try again';

  @override
  String consoleUpdatedAt(String time) {
    return 'Figures from $time';
  }

  @override
  String consoleStatLine(String label, String value) {
    return '$label: $value';
  }

  @override
  String get consoleSectionOrganizations => 'Organizations';

  @override
  String get consoleSectionAccounts => 'Accounts';

  @override
  String get consoleSectionEvents => 'Events';

  @override
  String get consoleSectionTickets => 'Tickets issued';

  @override
  String get consoleSectionScans => 'Checks 24 h';

  @override
  String get consoleStatActiveF => 'Active';

  @override
  String get consoleStatDisabledF => 'Suspended';

  @override
  String get consoleStatNew7d => 'Last 7 days';

  @override
  String get consoleStatDisabledM => 'Disabled';

  @override
  String get consoleStatDeletion => 'To delete';

  @override
  String get consoleStatUpcoming => 'Upcoming';

  @override
  String get consoleStatInProgress => 'In progress';

  @override
  String get consoleStatListed => 'In the catalog';

  @override
  String get consoleStatBlocked => 'Removed';

  @override
  String get consoleStatRedeemed => 'Entered';

  @override
  String get consoleStatAccepted => 'Accepted';

  @override
  String get consoleStatRefused => 'Refused';

  @override
  String get consoleNavOrganizations => 'Organizations';

  @override
  String get consoleNavOrganizationsHint => 'Search, suspend or reactivate';

  @override
  String get consoleNavCatalog => 'Public catalog';

  @override
  String get consoleNavCatalogHint => 'Moderate public events';

  @override
  String get consoleNavJournal => 'Audit log';

  @override
  String get consoleNavJournalHint => 'All actions, newest first';

  @override
  String get consoleSearchOrganizations => 'Search for an organization';

  @override
  String get consoleDisabledOnly => 'Suspended only';

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

    return 'Members: $membersString · Events: $eventsString · Tickets: $ticketsString';
  }

  @override
  String consoleOrgOwner(String name) {
    return 'Owner: $name';
  }

  @override
  String consoleOrgCreated(String date) {
    return 'Created on $date';
  }

  @override
  String get consoleSuspended => 'Suspended';

  @override
  String consoleSuspendedSince(String date, String reason) {
    return 'Suspended on $date. Reason: $reason';
  }

  @override
  String get consoleSuspend => 'Suspend the organization';

  @override
  String get consoleSuspendHint =>
      'Its members will no longer be able to issue or check tickets, and its events leave the catalog.';

  @override
  String get consoleReason => 'Reason (required)';

  @override
  String get consoleReasonRequired => 'Enter a reason.';

  @override
  String get consoleConfirmSuspend => 'Suspend';

  @override
  String get consoleReactivate => 'Reactivate the organization';

  @override
  String get consoleSuspendedDone => 'Organization suspended.';

  @override
  String get consoleReactivatedDone => 'Organization reactivated.';

  @override
  String get consoleActionError => 'Action not possible. Try again.';

  @override
  String get consoleEmpty => 'No results.';

  @override
  String get consoleLoadMore => 'See more';

  @override
  String get consoleCancel => 'Cancel';

  @override
  String get consoleSearchEvents => 'Event, organization or city';

  @override
  String get consoleBlockedOnly => 'Removed only';

  @override
  String get consoleListed => 'In the catalog';

  @override
  String get consoleNotListed => 'Not in the catalog';

  @override
  String get consoleBlocked => 'Removed';

  @override
  String consoleBlockedSince(String date, String reason) {
    return 'Removed on $date. Reason: $reason';
  }

  @override
  String get consoleBlock => 'Remove from the catalog';

  @override
  String get consoleBlockHint =>
      'The event leaves the catalog and the promoter can no longer publish it again. They will see the reason.';

  @override
  String get consoleConfirmBlock => 'Remove';

  @override
  String get consoleUnblock => 'Restore';

  @override
  String get consoleUnblockHint =>
      'The promoter will be able to make the event public again.';

  @override
  String get consoleBlockedDone => 'Event removed from the catalog.';

  @override
  String get consoleUnblockedDone => 'Event restored.';

  @override
  String get consoleAuditAll => 'All';

  @override
  String get consoleAuditConsole => 'Console';

  @override
  String get consoleAuditEvents => 'Events';

  @override
  String get consoleAuditTickets => 'Tickets';

  @override
  String get consoleAuditOrganizations => 'Organizations';

  @override
  String consoleAuditBy(String name) {
    return 'by $name';
  }

  @override
  String get auditAdminEventModerated => 'Catalog moderation';

  @override
  String get auditAdminOrganizationStatusChanged =>
      'Organization status changed';

  @override
  String get auditAssignmentAdded => 'Controller assigned';

  @override
  String get auditAssignmentRemoved => 'Controller removed';

  @override
  String get auditCategoryCreated => 'Category created';

  @override
  String get auditCategoryDeleted => 'Category deleted';

  @override
  String get auditCategoryPriceChanged => 'Indicative price changed';

  @override
  String get auditCategoryUpdated => 'Category updated';

  @override
  String get auditCheckpointCreated => 'Gate created';

  @override
  String get auditCheckpointUpdated => 'Gate updated';

  @override
  String get auditEventCoverChanged => 'Event photo changed';

  @override
  String get auditEventCreated => 'Event created';

  @override
  String get auditEventReportExported => 'Report exported';

  @override
  String get auditEventStatusChanged => 'Event status changed';

  @override
  String get auditEventUpdated => 'Event updated';

  @override
  String get auditEventVisibilityChanged => 'Public visibility changed';

  @override
  String get auditInvitationAccepted => 'Team invitation accepted';

  @override
  String get auditInvitationCreated => 'Team invitation created';

  @override
  String get auditInvitationRevoked => 'Team invitation cancelled';

  @override
  String get auditMemberLeft => 'Member left';

  @override
  String get auditMemberUpdated => 'Member updated';

  @override
  String get auditOrganizationCreated => 'Organization created';

  @override
  String get auditOrganizationLogoChanged => 'Logo changed';

  @override
  String get auditOrganizationPublicPhoneChanged => 'Public number changed';

  @override
  String get auditOrganizationUpdated => 'Organization updated';

  @override
  String get auditTicketHolderUpdated => 'Holder changed';

  @override
  String get auditTicketRevoked => 'Ticket cancelled';

  @override
  String get auditTicketsExported => 'Tickets exported';

  @override
  String get auditTicketsIssued => 'Tickets issued';

  @override
  String get auditDetailYes => 'yes';

  @override
  String get auditDetailNo => 'no';

  @override
  String get auditFieldPublic => 'public';

  @override
  String get auditFieldBlocked => 'removed';

  @override
  String get auditFieldStatus => 'status';

  @override
  String get auditFieldQuantity => 'quantity';

  @override
  String get auditFieldCount => 'count';

  @override
  String get auditFieldRemoved => 'deleted';

  @override
  String get auditFieldFrom => 'from';

  @override
  String get auditFieldTo => 'to';

  @override
  String get auditFieldRole => 'role';

  @override
  String get auditFieldCapacity => 'capacity';

  @override
  String get auditFieldFields => 'fields';

  @override
  String get auditFieldInvitation => 'invitation';

  @override
  String get auditFieldRows => 'rows';

  @override
  String get auditFieldChannel => 'channel';

  @override
  String get auditFieldPrice => 'price';

  @override
  String get eventActionStop => 'Stop the check';

  @override
  String get eventConfirmStop =>
      'No more entries will be accepted at the gates. This cannot be undone.';

  @override
  String get controlNotStarted => 'The check has not started yet';

  @override
  String get ticketsTypeAll => 'All types';

  @override
  String ticketsTypeCount(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$name · $countString';
  }

  @override
  String get eventsFilterCurrent => 'In progress';

  @override
  String eventsSectionTitle(String title, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$title ($countString)';
  }

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String get favoriteAdded => 'Added to your favorites';

  @override
  String get favoriteRemoved => 'Removed from your favorites';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get favoritesTitle => 'My favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody =>
      'Tap the heart on an event to find it here, even without an account.';

  @override
  String get favoritesExplore => 'Explore events';

  @override
  String get favoritesUpcoming => 'Upcoming';

  @override
  String get favoritesPast => 'Past';

  @override
  String get welcomeDiscoverTitle => 'Discover events';

  @override
  String get welcomeDiscoverBody =>
      'Concerts, conferences, galas, sport… all over Burkina, no account needed.';

  @override
  String get welcomeDiscoverAll => 'See all events';

  @override
  String get welcomeDiscoverEmpty => 'The first public events are coming soon.';

  @override
  String get welcomeCreateAccount => 'Create an account';

  @override
  String get welcomeHaveCode => 'I have an invitation code';

  @override
  String get signUpTitle => 'Create an account';

  @override
  String get signUpNameLabel => 'Full name';

  @override
  String get signUpNameRequired => 'Enter your name.';

  @override
  String get signUpPasswordHelp => 'At least 8 characters';

  @override
  String get signUpPasswordTooShort => 'At least 8 characters.';

  @override
  String get signUpPromoter => 'I am an event promoter';

  @override
  String get signUpPromoterHint =>
      'Create your organization to publish events, issue tickets and manage your team.';

  @override
  String get signUpStructureRequired => 'Enter your organization\'s name.';

  @override
  String get signUpCodeLabel => 'Invitation code (optional)';

  @override
  String get signUpCodeHelp => 'Received from a promoter to join their team';

  @override
  String get signUpSubmit => 'Create my account';

  @override
  String get signUpHaveAccount => 'Already have an account? Sign in';

  @override
  String get signInNoAccount => 'No account yet? Create one';

  @override
  String get signUpConfirmEmail =>
      'Account created. Confirm your address from the email you received, then sign in.';

  @override
  String signUpWelcome(String name) {
    return 'Welcome to Tikéo, $name!';
  }

  @override
  String signUpStepFailed(String reason) {
    return 'Your account is created, but the next step failed: $reason You can redo it from your profile.';
  }

  @override
  String get profilePromoterTitle => 'Are you an event promoter?';

  @override
  String get profilePromoterBody =>
      'Create your organization to publish your events and issue tickets.';

  @override
  String get profilePromoterAction => 'Create my organization';

  @override
  String get profileJoinAction => 'Join a team with a code';

  @override
  String get consoleNotAllowed => 'Action not possible for this account.';

  @override
  String get consoleStatDue => 'To delete';

  @override
  String get consoleNavAccounts => 'Accounts';

  @override
  String get consoleNavAccountsHint => 'Search, disable, delete when due';

  @override
  String get consoleSearchAccounts => 'Name or email address';

  @override
  String get consoleAccountsAll => 'All';

  @override
  String get consoleAccountsDisabled => 'Disabled';

  @override
  String get consoleAccountsDeletion => 'Deletion requested';

  @override
  String get consoleAccountsDue => 'To delete';

  @override
  String get consoleAccountsDeleted => 'Deleted';

  @override
  String get consoleAccountAdmin => 'Administrator';

  @override
  String get consoleAccountDisabled => 'Disabled';

  @override
  String get consoleAccountDeleted => 'Deleted';

  @override
  String get consoleAccountDue => 'To delete';

  @override
  String consoleAccountCreated(String date) {
    return 'Signed up on $date';
  }

  @override
  String consoleAccountLastSignIn(String date) {
    return 'Last sign-in: $date';
  }

  @override
  String get consoleAccountNeverSignedIn => 'Never signed in';

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

    return 'Organizations: $membershipsString · Owner of $ownedString';
  }

  @override
  String consoleAccountDeletionAt(String date, String due) {
    return 'Deletion requested on $date · due on $due';
  }

  @override
  String consoleAccountDisabledSince(String date, String reason) {
    return 'Disabled on $date. Reason: $reason';
  }

  @override
  String consoleAccountDeletedOn(String date) {
    return 'Deleted on $date';
  }

  @override
  String get consoleDisableAccount => 'Disable the account';

  @override
  String get consoleDisableAccountHint =>
      'The account loses all its rights in its organizations (issuing, checking, team). It can still browse Explore.';

  @override
  String get consoleConfirmDisable => 'Disable';

  @override
  String get consoleReactivateAccount => 'Reactivate the account';

  @override
  String get consoleAccountDisabledDone => 'Account disabled.';

  @override
  String get consoleAccountReactivatedDone => 'Account reactivated.';

  @override
  String get consolePurgeAccount => 'Delete permanently';

  @override
  String get consolePurgeAccountHint =>
      'The profile is anonymized, signing in becomes impossible and the organizations it owns are suspended. Tickets and logs remain. This cannot be undone.';

  @override
  String consolePurgeDone(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Account deleted. Organizations suspended: $countString';
  }

  @override
  String consolePurgeAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString accounts',
      one: '1 account',
    );
    return 'Delete the $_temp0 now due';
  }

  @override
  String get consolePurgeAllHint =>
      'Each account whose deletion was requested at least 30 days ago is anonymized; the organizations it owns are suspended. This cannot be undone.';

  @override
  String consolePurgeAllDone(int accounts, int structures) {
    final intl.NumberFormat accountsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String accountsString = accountsNumberFormat.format(accounts);
    final intl.NumberFormat structuresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String structuresString = structuresNumberFormat.format(structures);

    return 'Accounts deleted: $accountsString · organizations suspended: $structuresString';
  }

  @override
  String get auditAdminAccountStatusChanged => 'Account status changed';

  @override
  String get auditAdminAccountPurged => 'Account permanently deleted';

  @override
  String get auditFieldStructuresSuspended => 'organizations suspended';

  @override
  String get auditFieldCause => 'cause';

  @override
  String get auditValueOwnerDeleted => 'owner\'s account deleted';

  @override
  String get announcementDismiss => 'Hide the announcement';

  @override
  String get supportEntryTitle => 'Help and support';

  @override
  String get supportEntrySubtitle => 'Ask the Tikéo team a question';

  @override
  String supportUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString new replies',
      one: '1 new reply',
    );
    return '$_temp0';
  }

  @override
  String get supportTitle => 'Help and support';

  @override
  String get supportNew => 'New request';

  @override
  String get supportEmptyTitle => 'No requests';

  @override
  String get supportEmptyBody =>
      'A question, a problem? Write to the Tikéo team: the reply comes here.';

  @override
  String get supportLoadError => 'Could not load. Check the connection.';

  @override
  String get supportStatusOpen => 'Waiting';

  @override
  String get supportStatusAnswered => 'Answered';

  @override
  String get supportStatusClosed => 'Closed';

  @override
  String get supportCategoryQuestion => 'Question';

  @override
  String get supportCategoryProblem => 'Problem';

  @override
  String get supportCategoryAccount => 'Account';

  @override
  String get supportCategoryPayment => 'Payment';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportSubjectLabel => 'Subject';

  @override
  String get supportBodyLabel => 'Your message';

  @override
  String get supportCategoryLabel => 'Category';

  @override
  String get supportSend => 'Send';

  @override
  String get supportSent =>
      'Request sent. You will be notified here as soon as there is a reply.';

  @override
  String get supportSubjectInvalid => 'Between 3 and 120 characters.';

  @override
  String get supportBodyInvalid =>
      'Write your message (2,000 characters at most).';

  @override
  String get supportLimit =>
      'Too many open requests or messages: try again later.';

  @override
  String get supportNotFound => 'Request not found.';

  @override
  String get supportError => 'Could not send. Check the connection.';

  @override
  String get supportReplyHint => 'Your reply';

  @override
  String get supportClose => 'Close the request';

  @override
  String get supportClosed => 'Request closed. Write a message to reopen it.';

  @override
  String get supportTeam => 'Tikéo support';

  @override
  String supportLastMessage(String date) {
    return 'Last message on $date';
  }

  @override
  String get consoleNavSupport => 'Support';

  @override
  String get consoleNavSupportHint => 'Reply to user requests';

  @override
  String consoleNavSupportUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unread requests',
      one: '1 unread request',
      zero: 'No unread requests',
    );
    return '$_temp0';
  }

  @override
  String get consoleSupportAll => 'All';

  @override
  String get consoleSupportSearch => 'Subject, name or address';

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
  String get consoleNavAnnouncements => 'Announcements';

  @override
  String get consoleNavAnnouncementsHint => 'Publish a message in the app';

  @override
  String get consoleAnnouncementNew => 'New announcement';

  @override
  String get consoleAnnouncementTitleLabel => 'Title';

  @override
  String get consoleAnnouncementBodyLabel => 'Message';

  @override
  String get consoleAnnouncementAudience => 'Recipients';

  @override
  String get consoleAudienceVisitors => 'Visitors without an account';

  @override
  String get consoleAudienceUsers => 'Regular accounts';

  @override
  String get consoleAudiencePromoters => 'Promoters';

  @override
  String get consoleAudienceControllers => 'Controllers';

  @override
  String get consoleAnnouncementAudienceRequired =>
      'Choose at least one recipient.';

  @override
  String get consoleAnnouncementImportant => 'Important (highlighted)';

  @override
  String get consoleAnnouncementDuration => 'Shown for';

  @override
  String get consoleDuration1d => '24 hours';

  @override
  String get consoleDuration7d => '7 days';

  @override
  String get consoleDuration30d => '30 days';

  @override
  String get consoleDurationNone => 'No end';

  @override
  String get consoleAnnouncementPublish => 'Publish';

  @override
  String get consoleAnnouncementPublished => 'Announcement published.';

  @override
  String get consoleAnnouncementArchive => 'Remove';

  @override
  String get consoleAnnouncementArchived => 'Announcement removed.';

  @override
  String get consoleAnnouncementActive => 'Online';

  @override
  String get consoleAnnouncementInactive => 'Offline';

  @override
  String consoleAnnouncementUntil(String date) {
    return 'Until $date';
  }

  @override
  String get consoleAnnouncementInvalid =>
      'Title of 3 to 80 characters, message of 1,000 characters at most.';

  @override
  String get consoleStatSupportOpen => 'Support waiting';

  @override
  String get auditAdminSupportReplied => 'Support reply';

  @override
  String get auditAdminAnnouncementPublished => 'Announcement published';

  @override
  String get auditAdminAnnouncementArchived => 'Announcement removed';

  @override
  String get auditFieldAudiences => 'recipients';

  @override
  String get auditFieldLevel => 'importance';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsEntrySubtitle =>
      'Appearance, language, sounds, storage, version, legal';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsImageCache => 'Saved images';

  @override
  String settingsImageCacheSize(String size) {
    return '$size on this phone';
  }

  @override
  String get settingsImageCacheEmpty => 'No saved images';

  @override
  String get settingsImageCacheClear => 'Clear';

  @override
  String get settingsImageCacheCleared => 'Images removed from the phone.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(int build) {
    final intl.NumberFormat buildNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String buildString = buildNumberFormat.format(build);

    return 'Pilot version $buildString';
  }

  @override
  String get settingsVersionDev => 'Development version';

  @override
  String get settingsCheckUpdate => 'Check for an update';

  @override
  String get settingsUpToDate => 'You have the latest version.';

  @override
  String get settingsCheckFailed => 'Could not check. Check the connection.';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String get legalPrivacy => 'Privacy policy';

  @override
  String legalUpdated(int version, String date) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Version $versionString of $date';
  }

  @override
  String get legalLoadError => 'Document unavailable. Check the connection.';

  @override
  String get legalRetry => 'Try again';

  @override
  String get signUpLegalPrefix => 'By creating an account, you accept the ';

  @override
  String get signUpLegalAnd => ' and the ';

  @override
  String get updateAvailableTitle => 'New version available';

  @override
  String updateAvailableBody(int build) {
    final intl.NumberFormat buildNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String buildString = buildNumberFormat.format(build);

    return 'Pilot version $buildString is ready. Download it, then install it over the current one: your data is kept.';
  }

  @override
  String get updateDownload => 'Download';

  @override
  String get consoleNavLegal => 'Legal notices';

  @override
  String get consoleNavLegalHint => 'Terms of use and privacy';

  @override
  String consoleLegalVersion(int version, String date) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Version $versionString · $date';
  }

  @override
  String get consoleLegalTitleLabel => 'Title';

  @override
  String get consoleLegalBodyLabel => 'Text';

  @override
  String get consoleLegalBodyHelp =>
      'Blank line between two paragraphs, “##” for a subheading, “-” for a bullet. Fill in the passages in square brackets.';

  @override
  String get consoleLegalEdit => 'Edit';

  @override
  String get consoleLegalPreview => 'Preview';

  @override
  String get consoleLegalSave => 'Publish';

  @override
  String consoleLegalConfirm(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Publish version $versionString?';
  }

  @override
  String get consoleLegalConfirmBody =>
      'The new text is shown right away to all users.';

  @override
  String consoleLegalSaved(int version) {
    final intl.NumberFormat versionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String versionString = versionNumberFormat.format(version);

    return 'Version $versionString published.';
  }

  @override
  String get consoleLegalInvalid =>
      'Title of 3 to 80 characters, text of 20 to 20,000 characters.';

  @override
  String consoleLegalPlaceholders(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString passages in square brackets are still to be filled in.',
      one: '1 passage in square brackets is still to be filled in.',
    );
    return '$_temp0';
  }

  @override
  String get auditAdminLegalUpdated => 'Legal notices changed';

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
      other: '$countString selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get selectionClose => 'Leave the selection';

  @override
  String get selectionAll => 'Select all';

  @override
  String get selectionHint => 'Long-press a ticket to select several';

  @override
  String get ticketsBulkPdf => 'Share as PDF';

  @override
  String get ticketsBulkRevoke => 'Cancel';

  @override
  String ticketsBulkRevokeTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cancel $countString tickets?',
      one: 'Cancel 1 ticket?',
    );
    return '$_temp0';
  }

  @override
  String get ticketsBulkRevokeBody =>
      'They will be refused at the entrance. Tickets already used or cancelled do not change. This cannot be undone.';

  @override
  String ticketsBulkRevoked(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tickets cancelled.',
      one: '1 ticket cancelled.',
      zero: 'No tickets to cancel.',
    );
    return '$_temp0';
  }

  @override
  String get ticketsBulkNothingValid => 'No valid tickets in the selection.';

  @override
  String get ticketsBulkError => 'Action not possible. Check the connection.';

  @override
  String get eventDuplicate => 'Duplicate';

  @override
  String get eventDuplicateTitle => 'Duplicate the event';

  @override
  String get eventDuplicateBody =>
      'Categories, gates and team are copied. Tickets are not. The copy is a draft.';

  @override
  String eventDuplicateName(String title) {
    return '$title (copy)';
  }

  @override
  String get eventDuplicateNameLabel => 'Title of the copy';

  @override
  String get eventDuplicateStart => 'Start';

  @override
  String get eventDuplicateKeepLength =>
      'The duration stays the same as the original.';

  @override
  String get eventDuplicateSubmit => 'Create the copy';

  @override
  String get eventDuplicated => 'Copy created as a draft.';

  @override
  String get eventDuplicateError =>
      'Could not copy. Check the date and the connection.';

  @override
  String get firstStepsTitle => 'First steps';

  @override
  String firstStepsProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString of $totalString';
  }

  @override
  String get firstStepsHide => 'Hide';

  @override
  String get firstStepsEvent => 'Create an event';

  @override
  String get firstStepsCategory => 'Add a ticket type';

  @override
  String get firstStepsPublish => 'Publish the event';

  @override
  String get firstStepsIssue => 'Issue a first ticket';

  @override
  String get firstStepsTeam => 'Invite a controller';

  @override
  String get firstStepsPhone => 'Add the public WhatsApp number';

  @override
  String get firstStepsDone => 'Well done, your organization is ready!';

  @override
  String get navWallet => 'My tickets';

  @override
  String get walletTitle => 'My tickets';

  @override
  String get walletEntrySubtitle =>
      'The tickets you received to attend an event';

  @override
  String get walletAdd => 'Add a ticket';

  @override
  String get walletEmptyTitle => 'No tickets yet';

  @override
  String get walletEmptyBody =>
      'Did you receive a ticket by WhatsApp, SMS or email? Add it here: scan its QR or choose its image.';

  @override
  String get walletUpcoming => 'Upcoming';

  @override
  String get walletPast => 'Past';

  @override
  String walletOffline(String date) {
    return 'Offline: list saved on $date. QR codes remain valid; their status will be checked at the entrance.';
  }

  @override
  String get walletLoadError => 'Could not load. Check the connection.';

  @override
  String get walletRetry => 'Try again';

  @override
  String get walletStatusValid => 'Valid';

  @override
  String get walletStatusUsed => 'Used';

  @override
  String get walletStatusRevoked => 'Cancelled';

  @override
  String get walletStatusExpired => 'Expired';

  @override
  String get walletAddTitle => 'Add a ticket';

  @override
  String get walletAddIntro =>
      'Only the QR proves the ticket is yours: once added, it can no longer go into another account.';

  @override
  String get walletAddScan => 'Scan the QR';

  @override
  String get walletAddScanHint =>
      'With the camera, if the ticket is on another screen or on paper';

  @override
  String get walletAddImage => 'Choose an image';

  @override
  String get walletAddImageHint =>
      'The ticket image received by WhatsApp or saved in the gallery';

  @override
  String get walletAddPaste => 'Paste the code';

  @override
  String get walletAddPasteHint => 'Code starting with TS1.';

  @override
  String get walletAddPasteSubmit => 'Add';

  @override
  String get walletAddScanTitle => 'Scan the ticket\'s QR';

  @override
  String get walletAdded => 'Ticket added to your tickets.';

  @override
  String get walletNoQrInImage => 'No readable QR in this image.';

  @override
  String get walletErrorInvalid => 'This code is not a Tikéo ticket.';

  @override
  String get walletErrorUnknown => 'Unknown ticket.';

  @override
  String get walletErrorRevoked =>
      'This ticket was cancelled by the organizer.';

  @override
  String get walletErrorClaimed =>
      'This ticket is already in someone else\'s account.';

  @override
  String get walletErrorNetwork => 'No connection. Try again.';

  @override
  String get walletErrorOther => 'Could not add. Try again.';

  @override
  String get walletShowAtEntry =>
      'Show this QR at the entrance. Turn up the screen brightness.';

  @override
  String walletUsedAt(String date) {
    return 'Used on $date';
  }

  @override
  String get walletRevokedNote =>
      'This ticket was cancelled: it will be refused at the entrance.';

  @override
  String walletOrganizer(String name) {
    return 'Organized by $name';
  }

  @override
  String get walletRelease => 'Remove from my tickets';

  @override
  String get walletReleaseTitle => 'Remove this ticket?';

  @override
  String get walletReleaseBody =>
      'It will no longer be shown in your account. You can add it again with its QR, as long as another account has not done so.';

  @override
  String get walletReleased => 'Ticket removed.';

  @override
  String get walletNotFound => 'This ticket is no longer in your tickets.';

  @override
  String get auditTicketClaimed => 'Ticket added by its holder';

  @override
  String get auditTicketReleased => 'Ticket removed by its holder';

  @override
  String get pushOpen => 'View';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushSwitch => 'Receive notifications';

  @override
  String get settingsPushActive =>
      'Support replies, important announcements, check opening';

  @override
  String get settingsPushDisabled => 'Turned off on this phone';

  @override
  String get settingsPushDenied =>
      'Denied in the phone settings: allow Tikéo in Settings › Notifications.';

  @override
  String get settingsPushUnavailable =>
      'Unavailable in this version of the app';

  @override
  String get settingsPushTest => 'Send a test notification';

  @override
  String get settingsPushTestHint =>
      'Checks delivery on this phone, with the app closed.';

  @override
  String get settingsPushTestSent =>
      'Sending in 8 seconds: put Tikéo in the background (Home button) to see the notification.';

  @override
  String get settingsPushTestNoDevice =>
      'This phone is not registered yet. Close and reopen Tikéo, then try again.';

  @override
  String get settingsPushTestRateLimited =>
      'Too many attempts: try again in an hour.';

  @override
  String get settingsPushTestNetwork =>
      'Could not send. Check your connection and try again.';

  @override
  String verdictHolder(String name) {
    return 'Holder: $name';
  }

  @override
  String get scannerSearch => 'Lost QR? Search';

  @override
  String get doorSearchTitle => 'Find a ticket';

  @override
  String get doorSearchIntro =>
      'Search by name, phone or reference, then validate the entry. A ticket only goes through once.';

  @override
  String get doorSearchHint => 'Name, phone or reference';

  @override
  String get doorSearchEmpty => 'No tickets found.';

  @override
  String get doorSearchTooShort => 'At least 3 characters.';

  @override
  String get doorSearchRateLimited =>
      'Too many searches: try again in a few minutes.';

  @override
  String get doorSearchForbidden =>
      'Search is only possible when the check is open, at your gate.';

  @override
  String get doorSearchNetwork => 'No connection. Try again.';

  @override
  String get doorSearchValidate => 'Validate the entry';

  @override
  String get auditScanManual => 'Entry validated without QR (search)';

  @override
  String get journalTitle => 'Organization log';

  @override
  String get journalEntrySubtitle =>
      'Who issued, cancelled, validated or changed what';

  @override
  String get journalAll => 'All';

  @override
  String get journalEvents => 'Events';

  @override
  String get journalTickets => 'Tickets';

  @override
  String get journalControl => 'Check';

  @override
  String get journalTeam => 'Team';

  @override
  String get journalStructure => 'Organization';

  @override
  String get journalByTikeo => 'by the Tikéo team';

  @override
  String get auditEventDuplicated => 'Event duplicated';

  @override
  String get auditFieldResult => 'result';

  @override
  String get auditFieldReason => 'reason';

  @override
  String get auditFieldBulk => 'selection';

  @override
  String get auditFieldTitle => 'title';

  @override
  String get auditValueAccepted => 'entry allowed';

  @override
  String get auditValueAlreadyUsed => 'already used';

  @override
  String get auditValueRefused => 'refused';

  @override
  String get ticketScanHere => 'Scan here';

  @override
  String ticketNumber(String number) {
    return 'No. $number';
  }

  @override
  String get templatesEntry => 'Ticket designs';

  @override
  String get templatesTitle => 'Ticket designs';

  @override
  String get templatesIntro =>
      'Each category has its design: the image sent and the PDF use it. The QR and the entrance check do not change.';

  @override
  String templatesProposed(String theme) {
    return 'Suggested: $theme';
  }

  @override
  String templatesChosen(String theme) {
    return 'Design: $theme';
  }

  @override
  String get templatesCustom => 'Imported design';

  @override
  String get templatesLoadError => 'Designs unavailable for now.';

  @override
  String templateEditorTitle(String category) {
    return 'Design — $category';
  }

  @override
  String get templateBuiltinSection => 'Tikéo designs';

  @override
  String get templateSingleFont => 'Title in a single font';

  @override
  String get templateSingleFontHint => 'No handwriting or condensed lettering';

  @override
  String get templateCustomSection => 'Your own design';

  @override
  String get templateImportHint =>
      'Flat JPG or PNG image, as a horizontal strip (about 2.4 × 1), with free space for the QR.';

  @override
  String get templateImport => 'Import my design';

  @override
  String get templateAdjust => 'Place the QR';

  @override
  String get templateSave => 'Save';

  @override
  String get templateSaved => 'Design saved';

  @override
  String get templateReset => 'Back to the suggested design';

  @override
  String get templateResetDone => 'Suggested design restored';

  @override
  String get templateErrorQrTooSmall =>
      'The QR must take up at least 35% of the ticket\'s height.';

  @override
  String get templateErrorImage => 'Image not found: import it again.';

  @override
  String get templateErrorTooLarge => 'Image too heavy (2 MB at most).';

  @override
  String get templateErrorFormat =>
      'Expected format: an image as a horizontal strip (about 2.4 × 1).';

  @override
  String get templateErrorLocked =>
      'Event closed: the design can no longer change.';

  @override
  String get templateErrorNotFound =>
      'You do not have the rights to change this design.';

  @override
  String get templateErrorInvalid =>
      'Placement refused: the QR must stay entirely on the ticket.';

  @override
  String get templateErrorNetwork =>
      'Could not save. Check your connection and try again.';

  @override
  String get placementTitle => 'Place the QR';

  @override
  String get placementHelp =>
      'Drag the QR and the reference block. Pinch the QR or use the slider to change its size.';

  @override
  String get placementSize => 'QR size';

  @override
  String get placementMinReached =>
      'Minimum size reached: the QR must take up at least 35% of the ticket\'s height to stay readable at the entrance.';

  @override
  String get placementAuto => 'Automatic placement';

  @override
  String get placementDone => 'Done';

  @override
  String get placementFoundSquare =>
      'QR placed in the white area of your design.';

  @override
  String get placementFallback =>
      'No white area large enough: the QR is placed on its own white square, on the right.';

  @override
  String get ticketTheme1 => 'Concert';

  @override
  String get ticketTheme2 => 'Cultural festival';

  @override
  String get ticketTheme3 => 'Cinema';

  @override
  String get ticketTheme4 => 'Match';

  @override
  String get ticketTheme5 => 'Theater';

  @override
  String get ticketTheme6 => 'Conference';

  @override
  String get ticketTheme7 => 'Exhibition';

  @override
  String get ticketTheme8 => 'Food festival';

  @override
  String get ticketTheme9 => 'Youth workshop';

  @override
  String get ticketTheme10 => 'Sports challenge';

  @override
  String get ticketTheme11 => 'Club night';

  @override
  String get ticketTheme12 => 'Workshop';

  @override
  String get auditTicketTemplateUpdated => 'Ticket design changed';

  @override
  String get auditValueTemplateBuiltin => 'Tikéo design';

  @override
  String get auditValueTemplateCustom => 'imported design';

  @override
  String get auditValueTemplateDefault => 'suggested design';

  @override
  String get auditValueTagline => 'tagline';

  @override
  String get auditFieldTemplateKind => 'design';

  @override
  String get ticketsBulkSheet => 'A4 sheet to print';

  @override
  String get templateCrop => 'Frame the photo';

  @override
  String get templateCopy => 'Use this design for other categories';

  @override
  String get templateCopyTitle => 'Also apply this design to:';

  @override
  String templateCopyConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Apply to $count other categories',
      one: 'Apply to 1 other category',
      zero: 'Choose categories',
    );
    return '$_temp0';
  }

  @override
  String templateCopied(int count) {
    return 'Design saved for $count categories';
  }

  @override
  String get placementSampleHolder => 'Awa Ouédraogo';

  @override
  String get placementHolderFree => 'Place the holder\'s name separately';

  @override
  String get placementHolderFreeHint =>
      'Otherwise, it is written under the reference';

  @override
  String get cropTitle => 'Frame the photo';

  @override
  String get cropHelp =>
      'Drag the photo to choose the visible part, then adjust the zoom.';

  @override
  String get cropZoom => 'Zoom';

  @override
  String get cropReset => 'Default framing';

  @override
  String get walletLargeQr => 'Show at the entrance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';

  @override
  String get settingsLanguageFr => 'Français';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageHelp =>
      'The tickets, PDFs and reports you send follow this language too.';

  @override
  String get auditFieldLanguage => 'language';

  @override
  String get categoryEntriesLabel => 'Entries per ticket';

  @override
  String get categoryEntriesSingle => 'Once';

  @override
  String get categoryEntriesPerDay => 'Once a day';

  @override
  String get categoryEntriesLimited => 'Several';

  @override
  String get categoryEntriesHelpSingle =>
      'The ticket is used at the first entry.';

  @override
  String get categoryEntriesHelpPerDay =>
      'Daily pass: one entry per day, for the whole event.';

  @override
  String get categoryEntriesHelpLimited =>
      'Pass: the ticket allows this many entries in total, over one or several days.';

  @override
  String get categoryEntriesLocked =>
      'Rule locked: tickets in this category have already been used to enter.';

  @override
  String get categoryMaxEntriesLabel => 'Number of entries';

  @override
  String categoryMaxEntriesError(int min, int max) {
    return 'From $min to $max entries.';
  }

  @override
  String get categoryPassDaily => 'Daily pass';

  @override
  String categoryPassEntries(int count) {
    return '$count-entry pass';
  }

  @override
  String get setupErrorEntriesInvalid =>
      'Invalid entry rule: a pass allows 2 to 100 entries.';

  @override
  String get setupErrorEntriesLocked =>
      'Tickets in this category have already been used to enter: the entry rule can no longer change.';

  @override
  String verdictPassEntry(int used, int max) {
    return 'Entry $used of $max';
  }

  @override
  String verdictPassLastEntry(int used, int max) {
    return 'Last entry on this pass ($used of $max)';
  }

  @override
  String verdictPassExhausted(int max) {
    return 'Pass used up: $max entries used';
  }

  @override
  String verdictPassDay(int count) {
    return 'Daily pass · entry day no. $count';
  }

  @override
  String verdictPassDayUsed(int count) {
    return 'Daily pass · already entered today ($count days in total)';
  }

  @override
  String verdictEnteredToday(String time) {
    return 'Entered today at $time';
  }

  @override
  String verdictEnteredTodayAt(String time, String checkpoint) {
    return 'Entered today at $time · $checkpoint';
  }

  @override
  String verdictLastEntry(String time) {
    return 'Last entry at $time';
  }

  @override
  String verdictLastEntryAt(String time, String checkpoint) {
    return 'Last entry at $time · $checkpoint';
  }

  @override
  String dashboardEntriesNote(int entries) {
    return '$entries entries in total (multi-entry passes)';
  }

  @override
  String get auditCategoryEntriesChanged => 'Entry rule changed';

  @override
  String get auditValueEntrySingle => 'single entry';

  @override
  String get auditValueEntryPerDay => 'once a day';

  @override
  String get auditValueEntryLimited => 'several entries';

  @override
  String get auditFieldEntryPolicy => 'entries';

  @override
  String get auditFieldMaxEntries => 'number of entries';

  @override
  String get settingsReminders => 'Event reminders';

  @override
  String get settingsRemindersHint =>
      'The day before and 2 hours before, for tickets added to “My tickets”.';

  @override
  String get settingsRemindersError =>
      'Setting not saved. Check your connection and try again.';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryHeadline => 'At a glance';

  @override
  String summaryPeopleLine(int admitted, int issued) {
    return '$admitted people entered out of $issued tickets';
  }

  @override
  String summaryAverageOthers(int count, String rate) {
    return 'Average of your last $count events: $rate';
  }

  @override
  String summaryPassLine(int entries, int passes) {
    return '$entries entries with $passes passes';
  }

  @override
  String summarySpan(String first, String last) {
    return 'First entry at $first, last at $last';
  }

  @override
  String get summaryEmpty => 'No entries recorded for this event.';

  @override
  String get summaryHoursTitle => 'Busiest hours';

  @override
  String summaryPeak(String hour, int entries) {
    return 'Peak hour: $hour · $entries entries';
  }

  @override
  String summaryHourRange(int start, int end) {
    return '$start:00–$end:00';
  }

  @override
  String get summaryDaysTitle => 'By day';

  @override
  String summaryDayLine(int people, int entries) {
    return '$people people · $entries entries';
  }

  @override
  String get summaryCompareTitle => 'Compared with your events';

  @override
  String get summaryCompareHint =>
      'Attendance rate: people who entered out of tickets issued.';

  @override
  String summaryThisEvent(String title) {
    return '$title (this event)';
  }

  @override
  String get summaryErrorLoad => 'Could not load the summary.';

  @override
  String get summaryColDay => 'Day';

  @override
  String get summaryColPeople => 'People';

  @override
  String get summaryColEntries => 'Entries';

  @override
  String get summaryColEvent => 'Event';

  @override
  String get summaryColDate => 'Date';

  @override
  String get componentGalleryTitle => 'Tikéo components';

  @override
  String get auditBillingInvoiceIssued => 'Usage invoice issued';

  @override
  String get auditBillingOrganizationDefaultSet =>
      'Organization billing chosen';

  @override
  String get auditBillingEventModeSet => 'Event billing chosen';

  @override
  String get auditBillingAddonAdded => 'Add-on added to the event';

  @override
  String get auditBillingRequestCreated => 'Activation request sent';

  @override
  String get auditAdminBillingPackSaved => 'Plan saved';

  @override
  String get auditAdminBillingPackStatusSet => 'Plan status changed';

  @override
  String get auditAdminBillingSettingsSaved => 'Payment settings changed';

  @override
  String get auditAdminBillingRequestActivated =>
      'Request approved, payment received';

  @override
  String get auditAdminBillingRequestRefused => 'Request refused';

  @override
  String get auditAdminBillingSubscriptionGranted => 'Subscription granted';

  @override
  String get auditAdminBillingSubscriptionCancelled => 'Subscription cancelled';

  @override
  String get auditAdminBillingInvoicePaid => 'Invoice paid';

  @override
  String get auditFieldEntries => 'entries';

  @override
  String get auditFieldAmount => 'amount (FCFA)';

  @override
  String get auditFieldBillingSystem => 'billing';

  @override
  String get auditFieldBillingMode => 'billing';

  @override
  String get auditFieldOption => 'option';

  @override
  String get auditFieldUnits => 'blocks';

  @override
  String get auditFieldDuration => 'duration';

  @override
  String get auditFieldCreated => 'created';

  @override
  String get auditFieldAddons => 'add-ons';

  @override
  String get auditValueBillingFlat => 'flat rate';

  @override
  String get auditValueBillingUsage => 'pay per use';

  @override
  String get auditValueBillingInherit => 'same as the organization';

  @override
  String get auditValueDurationMonth => 'monthly';

  @override
  String get auditValueDurationQuarter => 'quarterly';

  @override
  String get auditValueDurationSemester => 'half-yearly';

  @override
  String get auditValueDurationYear => 'yearly';

  @override
  String get auditValueDurationEvent => 'single event';

  @override
  String get auditValueDurationUnlimited => 'no end date';

  @override
  String get auditValueChannelOrangeMoney => 'Orange Money';

  @override
  String get auditValueChannelMoovMoney => 'Moov Money';

  @override
  String get auditValueChannelOther => 'other';

  @override
  String get billingOptionStructures => 'Organizations on the account';

  @override
  String get billingOptionActiveEvents => 'Active events at the same time';

  @override
  String get billingOptionTicketsPerEvent => 'Tickets per event';

  @override
  String get billingOptionTicketsPerPeriod => 'Tickets per period';

  @override
  String get billingOptionMembersPerStructure =>
      'Team members per organization';

  @override
  String get billingOptionControllersPerEvent => 'Controllers per event';

  @override
  String get billingOptionAssistedSend => 'Assisted sending';

  @override
  String get billingOptionBulkSend => 'Bulk sending';

  @override
  String get billingOptionImport => 'Excel / CSV import';

  @override
  String get billingOptionExport => 'Export (CSV, reports, PDF)';

  @override
  String get billingOptionPrintSheet => 'A4 print sheet';

  @override
  String get billingOptionCustomDesign => 'Imported ticket design';

  @override
  String get billingOptionNamedTickets => 'Named tickets';

  @override
  String get billingOptionLiveDashboard => 'Live dashboard';

  @override
  String get billingOptionPublicCatalog => 'Public catalog';

  @override
  String get billingOptionPrioritySupport => 'Priority support';

  @override
  String get homeHeroSubtitle => 'Here\'s what matters for your events.';

  @override
  String get homeTileEvents => 'Events';

  @override
  String get homeTileLive => 'Live';

  @override
  String get homeTileUpcoming => 'Upcoming';

  @override
  String get homeTileDrafts => 'Drafts';

  @override
  String get homeOrgHint => 'Active organization';

  @override
  String get exploreHeroTitle => 'Discover events';

  @override
  String get exploreHeroSubtitle => 'Concerts, conferences, sport… near you.';

  @override
  String get exploreSee => 'View';

  @override
  String get publicEventCall => 'Call the promoter';

  @override
  String get publicEventCallFailed =>
      'The call could not be opened on this phone.';

  @override
  String get ticketsHeroSubtitle => 'Issue, send and track your tickets.';

  @override
  String get teamHeroTitle => 'My team';

  @override
  String get teamStatMembers => 'active members';

  @override
  String get teamStatManagers => 'managers';

  @override
  String get teamStatControllers => 'controllers';

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Team members ($count)',
      zero: 'Team members',
    );
    return '$_temp0';
  }

  @override
  String get profileHeroTitle => 'My profile';

  @override
  String get signInHeroSubtitle => 'Good to see you again.';

  @override
  String get signInEmailHint => 'you@example.com';

  @override
  String get signUpHeroSubtitle => 'A few seconds to get started.';

  @override
  String get signUpPasswordRules =>
      'At least 8 characters, with letters and numbers';

  @override
  String get forgotHeroSubtitle => 'Get a link to choose a new one.';

  @override
  String get forgotSentTitle => 'Link sent';

  @override
  String get forgotNothingTitle => 'Nothing received?';

  @override
  String get forgotNothingBody =>
      'Check your spam folder, then resend the link if needed.';

  @override
  String get forgotResendLink => 'Resend the link';

  @override
  String get authOpenMailbox => 'Open my email app';

  @override
  String get authOpenMailboxFailed =>
      'Open your email app to find the Tikéo email.';

  @override
  String get authResend => 'Resend the email';

  @override
  String authResendIn(String action, int seconds) {
    return '$action in $seconds s';
  }

  @override
  String get authResent => 'Email sent again.';

  @override
  String get confirmEmailTitle => 'Confirm your address';

  @override
  String get confirmEmailBody => 'We sent a confirmation link to:';

  @override
  String get confirmEmailStep1 => 'Open the email from Tikéo.';

  @override
  String get confirmEmailStep2 => 'Tap the confirmation link.';

  @override
  String get confirmEmailStep3 => 'Come back here and sign in.';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Excellent';

  @override
  String passwordStrengthLabel(String level) {
    return 'Password strength: $level';
  }

  @override
  String get newPasswordTitle => 'New password';

  @override
  String get newPasswordSubtitle => 'Choose it, then you will be signed in.';

  @override
  String get newPasswordSubmit => 'Save the password';

  @override
  String get newPasswordRuleLength => 'At least 8 characters';

  @override
  String get newPasswordRuleLetters => 'Letters';

  @override
  String get newPasswordRuleDigits => 'Numbers';

  @override
  String get joinHeroSubtitle => 'A promoter gave you the code.';

  @override
  String get joinAcceptedTitle => 'Code accepted';

  @override
  String get joinAcceptedBody => 'You are now part of the team.';

  @override
  String get joinStart => 'Get started';

  @override
  String get welcomeSpaceTitle => 'Your Tikéo space';

  @override
  String get controlHeroSubtitle =>
      'Pick the event and the door where you scan.';

  @override
  String get controlSummaryOpen => 'Open';

  @override
  String get controlSummaryUpcoming => 'Upcoming';

  @override
  String get controlSummaryDoors => 'Doors';

  @override
  String get controlMyPosts => 'My posts';

  @override
  String get scannerAdmitted => 'Admitted';

  @override
  String get scannerRefused => 'Refused';

  @override
  String get historyHeroSubtitle => 'Your checks over the last 7 days.';

  @override
  String get historyUncertain => 'Uncertain';

  @override
  String get eventsHeroSubtitle => 'Create, publish and follow your events.';

  @override
  String get walletHeroSubtitle => 'Your tickets, even offline.';

  @override
  String get walletSummaryValid => 'Valid';

  @override
  String get walletSummaryUpcoming => 'Next';

  @override
  String get walletSummaryPast => 'Ended';

  @override
  String get supportHeroSubtitle =>
      'A question or a problem? The Tikéo team answers here.';

  @override
  String get settingsHeroSubtitle =>
      'Appearance, language, notifications and storage.';

  @override
  String get consoleHeroSubtitle =>
      'Platform organizations, accounts, support and catalog.';

  @override
  String get billingActivate => 'Activate the subscription';

  @override
  String get billingActivateAddons => 'Activate the add-ons';

  @override
  String get billingActivatedToast =>
      'Payment recorded, subscription activated.';

  @override
  String billingAddonLine(int units, String option) {
    return '+$units $option';
  }

  @override
  String billingAddonPrice(String price, int step) {
    return '$price per block of $step';
  }

  @override
  String get billingAddonsBody =>
      'The subscription add-ons are replaced, with no payment to record.';

  @override
  String get billingAddonsNone => 'This pack offers no add-on.';

  @override
  String get billingAddonsSave => 'Save the add-ons';

  @override
  String get billingAddonsSavedToast => 'Add-ons saved.';

  @override
  String get billingAddonsTitle => 'Add-ons';

  @override
  String get billingCancel => 'Cancel subscription';

  @override
  String billingCancelBody(String name) {
    return '$name\'s subscription ends now; the account returns to the free pack.';
  }

  @override
  String get billingCancelTitle => 'Cancel the subscription?';

  @override
  String get billingCancelledToast => 'Subscription cancelled.';

  @override
  String get billingChangePack => 'Change pack';

  @override
  String billingChangePackBody(String pack) {
    return 'The subscription moves to the $pack pack, with the same dates.';
  }

  @override
  String get billingChangePackTitle => 'Change pack';

  @override
  String get billingChannelMoov => 'Moov Money';

  @override
  String get billingChannelOrange => 'Orange Money';

  @override
  String get billingChannelOther => 'Other';

  @override
  String get billingCollectCheck => 'Check and confirm';

  @override
  String get billingCollectDone => 'Processed';

  @override
  String get billingCollectEmpty => 'Nothing to show here.';

  @override
  String get billingCollectOverdue => 'Overdue';

  @override
  String get billingCollectTitle => 'To collect';

  @override
  String get billingCollectToCheck => 'To check';

  @override
  String billingDates(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String billingDatesEvent(String start) {
    return 'From $start until the end of the covered event';
  }

  @override
  String get billingDaysSuffix => 'days';

  @override
  String billingDeclaredLine(String channel, String transaction) {
    return 'Declared: $channel · $transaction';
  }

  @override
  String billingDueLine(String date) {
    return 'Due: $date';
  }

  @override
  String get billingDurationEvent => 'One event';

  @override
  String get billingDurationMonth => 'Monthly';

  @override
  String get billingDurationQuarter => 'Quarterly';

  @override
  String get billingDurationSemester => 'Half-yearly';

  @override
  String get billingDurationUnlimited => 'No end';

  @override
  String get billingDurationYear => 'Yearly';

  @override
  String get billingErrorAddons =>
      'Add-on not possible with this pack (option, block or cap).';

  @override
  String get billingErrorChoice => 'Choose flat rate, or a pay-per-use pack.';

  @override
  String get billingErrorEnd =>
      'The end must come after the start of the subscription.';

  @override
  String get billingErrorInvoiceExists =>
      'An invoice has already been issued for this event.';

  @override
  String get billingErrorNetwork => 'No connection. Try again.';

  @override
  String get billingErrorNote => 'Give the reason (at least 3 characters).';

  @override
  String get billingErrorPack =>
      'Invalid pack: check the name, prices and options.';

  @override
  String get billingErrorPackProtected => 'The Discovery pack stays published.';

  @override
  String get billingErrorPayment => 'Invalid channel, reference or note.';

  @override
  String get billingErrorProcessed => 'Already processed, or not found.';

  @override
  String get billingErrorSettings => 'Invalid settings: check the numbers.';

  @override
  String get billingEventApply => 'Change the billing';

  @override
  String get billingEventChange => 'Event billing';

  @override
  String get billingEventChangeHelp =>
      'For an event already locked by its first ticket. Not possible once the invoice is issued.';

  @override
  String get billingEventChangedToast => 'Event billing changed.';

  @override
  String get billingEventLocked => 'locked';

  @override
  String get billingEventSearch => 'Event title or organization';

  @override
  String get billingExpected => 'Expected amount';

  @override
  String get billingExtend => 'Extend';

  @override
  String billingExtendBody(String date) {
    return 'New end: $date.';
  }

  @override
  String get billingExtendTitle => 'Extend the subscription';

  @override
  String get billingExtendedToast => 'Subscription extended.';

  @override
  String get billingFeatureAddon => 'Add-on';

  @override
  String get billingFeatureIncluded => 'Included';

  @override
  String get billingFeatureUnavailable => 'No';

  @override
  String get billingFilterAll => 'All';

  @override
  String get billingFormAddonAllowed => 'Add-on possible';

  @override
  String get billingFormAddonCap => 'Cap';

  @override
  String get billingFormAddonPrice => 'Price';

  @override
  String get billingFormAddonStep => 'Block';

  @override
  String get billingFormDescription => 'Description (shown to promoters)';

  @override
  String get billingFormDurations => 'Durations offered';

  @override
  String get billingFormEditTitle => 'Edit the pack';

  @override
  String get billingFormEntryPrice => 'Price per actual entry';

  @override
  String get billingFormFeatures => 'Features';

  @override
  String get billingFormFlatInvalid =>
      'Enter the monthly price and at least one duration.';

  @override
  String get billingFormFreeEntries => 'Free entries';

  @override
  String get billingFormIncluded => 'Included';

  @override
  String get billingFormMonthly => 'Monthly price';

  @override
  String get billingFormName => 'Pack name';

  @override
  String get billingFormNameInvalid => 'The name must be 2 to 60 characters.';

  @override
  String get billingFormNewTitle => 'New pack';

  @override
  String billingFormNumericHelp(String period) {
    return 'Empty: unlimited. Add-ons are paid per block, $period.';
  }

  @override
  String get billingFormNumericOptions => 'Numbered options';

  @override
  String get billingFormPaymentDays => 'Payment term (days)';

  @override
  String get billingFormPreview => 'Preview';

  @override
  String get billingFormPrices => 'Prices';

  @override
  String get billingFormPublish => 'Publish the pack';

  @override
  String get billingFormSave => 'Save';

  @override
  String get billingFormSaveDraft => 'Save as draft';

  @override
  String get billingFormSaved => 'Pack saved.';

  @override
  String get billingFormSortOrder => 'Display order';

  @override
  String get billingFormSystem => 'Billing system';

  @override
  String get billingFormTierAdd => 'Add a tier';

  @override
  String get billingFormTierPrice => 'Price per entry';

  @override
  String get billingFormTierRemove => 'Remove the tier';

  @override
  String get billingFormTierUpTo => 'Up to (entries)';

  @override
  String get billingFormTiers => 'Tiers (optional)';

  @override
  String get billingFormTiersHelp =>
      'Example: 150 FCFA up to 500 entries, 100 FCFA beyond (last tier empty).';

  @override
  String get billingFormTrial => 'Trial days';

  @override
  String get billingFormUsageInvalid => 'Enter the price per entry or tiers.';

  @override
  String get billingFree => 'Free';

  @override
  String get billingGrant => 'Activate a pack without a request';

  @override
  String get billingGrantDuration => 'Duration';

  @override
  String get billingGrantMissing =>
      'Choose the account and the pack, and give the reason.';

  @override
  String get billingGrantPack => 'Pack';

  @override
  String get billingGrantSearch => 'Account name or email';

  @override
  String get billingGrantSubmit => 'Activate the pack';

  @override
  String get billingGrantedToast => 'Pack activated for this account.';

  @override
  String get billingHoursSuffix => 'hours';

  @override
  String billingInvoiceDetail(
    int entries,
    int free,
    String entriesAmount,
    String addonsAmount,
  ) {
    return '$entries entries, $free free · entries $entriesAmount · add-ons $addonsAmount';
  }

  @override
  String billingInvoiceObject(String event, int entries) {
    return '$event · $entries actual entries';
  }

  @override
  String get billingInvoicePaidToast => 'Invoice marked as paid.';

  @override
  String get billingKindActivation => 'Activation request';

  @override
  String get billingKindAddons => 'Add-ons';

  @override
  String get billingKindInvoice => 'Pay-per-use invoice';

  @override
  String get billingKindOverdue => 'Overdue invoice';

  @override
  String get billingMarkPaid => 'Mark as paid';

  @override
  String get billingNoEnd => 'no end';

  @override
  String get billingNotDeclared => 'Payment not yet declared by the promoter';

  @override
  String get billingPackActions => 'Actions';

  @override
  String get billingPackArchive => 'Archive';

  @override
  String get billingPackArchived => 'Archived';

  @override
  String get billingPackArchivedPlural => 'Archived';

  @override
  String get billingPackArchivedToast =>
      'Pack archived: no longer offered, subscriptions continue.';

  @override
  String get billingPackChangedToast => 'Subscription pack changed.';

  @override
  String billingPackCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get billingPackDraft => 'Draft';

  @override
  String get billingPackDraftToast => 'Pack unpublished: no longer offered.';

  @override
  String get billingPackDuplicate => 'Duplicate';

  @override
  String get billingPackDuplicated => 'Copy created as a draft.';

  @override
  String get billingPackEdit => 'Edit';

  @override
  String billingPackEvents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
      zero: 'No event',
    );
    return '$_temp0';
  }

  @override
  String get billingPackFeatured => 'Recommended';

  @override
  String get billingPackNew => 'New pack';

  @override
  String get billingPackPublish => 'Publish';

  @override
  String get billingPackPublished => 'Published';

  @override
  String get billingPackPublishedToast =>
      'Pack published: promoters can see it.';

  @override
  String billingPackSubscriptions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions',
      one: '1 subscription',
      zero: 'No subscription',
    );
    return '$_temp0';
  }

  @override
  String get billingPackUnpublish => 'Unpublish (draft)';

  @override
  String get billingPacksEmpty => 'No pack here.';

  @override
  String get billingPacksTitle => 'Packs';

  @override
  String get billingPaymentAmount => 'Amount received';

  @override
  String get billingPaymentDate => 'Payment date';

  @override
  String get billingPaymentInvoiceTitle => 'Collect an invoice';

  @override
  String billingPaymentMismatch(String expected) {
    return 'The amount received differs from the expected amount ($expected): it will be noted.';
  }

  @override
  String get billingPaymentNote => 'Note (optional)';

  @override
  String get billingPaymentReceived => 'Payment received';

  @override
  String get billingPaymentReference => 'Operator reference';

  @override
  String get billingPaymentRequestTitle => 'Confirm a payment';

  @override
  String get billingPaymentToday => 'Today';

  @override
  String billingPerEntry(String price) {
    return '$price per entry';
  }

  @override
  String get billingPerEventShort => 'per event';

  @override
  String billingPerMonth(String price) {
    return '$price / month';
  }

  @override
  String get billingPerMonthShort => 'per month';

  @override
  String billingPreviewAddon(String option, String price) {
    return '$option: add-on ($price)';
  }

  @override
  String billingPreviewIncluded(String value, String option) {
    return '$value · $option';
  }

  @override
  String billingPreviewMore(String price, int step) {
    return '+ $price per $step more';
  }

  @override
  String billingPreviewUnlimited(String option) {
    return '$option: unlimited';
  }

  @override
  String billingReceivedNote(String amount) {
    return 'Received: $amount';
  }

  @override
  String billingReferenceLine(String reference, String date) {
    return 'Reference $reference · $date';
  }

  @override
  String get billingRefuse => 'Refuse the request';

  @override
  String get billingRefuseBody =>
      'The request is closed; the promoter can create another one.';

  @override
  String get billingRefuseTitle => 'Refuse the request?';

  @override
  String get billingRefusedToast => 'Request refused.';

  @override
  String billingRequestAddons(String pack, String addons) {
    return 'Add-ons for the $pack pack: $addons';
  }

  @override
  String billingRequestPack(String pack, String duration) {
    return '$pack pack · $duration';
  }

  @override
  String get billingSettingsBeneficiary => 'Beneficiary name';

  @override
  String get billingSettingsDelays => 'Delays';

  @override
  String get billingSettingsGraceDays => 'Grace period after the end';

  @override
  String get billingSettingsInstructions => 'Instructions shown to promoters';

  @override
  String get billingSettingsInvoiceHours => 'Pay-per-use invoice issued';

  @override
  String get billingSettingsInvoiceHoursHelp =>
      'Hours after the event ends (or when check-in is closed).';

  @override
  String get billingSettingsNumbers => 'Tikéo payment numbers';

  @override
  String get billingSettingsPaymentDays => 'Pay-per-use payment term';

  @override
  String get billingSettingsPaymentDaysHelp =>
      'Default, unless the pack sets one.';

  @override
  String get billingSettingsReminderDays =>
      'Reminder before the subscription ends';

  @override
  String get billingSettingsSave => 'Save the settings';

  @override
  String get billingSettingsSaved => 'Payment settings saved.';

  @override
  String get billingSettingsTitle => 'Payment settings';

  @override
  String get billingStatusActivated => 'Activated';

  @override
  String get billingStatusCancelled => 'Cancelled';

  @override
  String get billingStatusPaid => 'Paid';

  @override
  String get billingStatusRefused => 'Refused';

  @override
  String get billingSubActive => 'Active';

  @override
  String get billingSubActiveOne => 'Active';

  @override
  String get billingSubEndedOne => 'Ended';

  @override
  String get billingSubEndingOne => 'Ending soon';

  @override
  String get billingSubEndingSoon => 'Ending soon';

  @override
  String get billingSubGrace => 'In grace';

  @override
  String get billingSubGraceOne => 'In grace';

  @override
  String get billingSubscriptionsSearch => 'Name, email or pack';

  @override
  String get billingSubscriptionsTitle => 'Subscriptions';

  @override
  String get billingSystemFlat => 'Flat rate';

  @override
  String get billingSystemUsage => 'Pay per use';

  @override
  String billingUntil(String date) {
    return 'until $date';
  }

  @override
  String get consoleNavCollectHint =>
      'Activation requests and pay-per-use invoices';

  @override
  String consoleNavCollectPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments to check',
      one: '1 payment to check',
    );
    return '$_temp0';
  }

  @override
  String get consoleNavPacksHint =>
      'Flat-rate and pay-per-use packs, options, add-ons';

  @override
  String get consoleNavPaymentSettingsHint =>
      'Orange Money and Moov numbers, delays';

  @override
  String get consoleNavSubscriptionsHint => 'Extend, change pack, grant a pack';

  @override
  String get consoleSectionBilling => 'Billing';

  @override
  String get consoleSectionPlatform => 'Platform';

  @override
  String get auditAdminBillingSubscriptionExtended => 'Subscription extended';

  @override
  String get auditAdminBillingSubscriptionPackChanged =>
      'Subscription pack changed';

  @override
  String get auditAdminBillingSubscriptionAddonsSet =>
      'Subscription add-ons set';

  @override
  String get auditAdminBillingEventSet => 'Event billing changed';
}
