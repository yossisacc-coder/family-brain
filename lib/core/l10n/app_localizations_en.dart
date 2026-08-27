// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Brain';

  @override
  String get welcomeTitle => 'Welcome to Family Brain';

  @override
  String get welcomeSubtitle =>
      'One calm place for your family to organize tasks, share responsibility, and stay in sync.';

  @override
  String get continueWithPhone => 'Continue with phone number';

  @override
  String get demoSignIn => 'Development demo login';

  @override
  String get demoHint =>
      'Opens Home, Family, Tasks, and Notifications on this phone. No SMS and no Firebase required. Data stays on the device.';

  @override
  String get demoModeLabel => 'Development / Demo';

  @override
  String get demoModeSettings =>
      'This build uses on-device demo data. Phone/OTP architecture is unchanged for production Firebase.';

  @override
  String get orDivider => 'or';

  @override
  String get phoneTitle => 'Your phone number';

  @override
  String get phoneSubtitle => 'We’ll send a one-time code to verify it’s you.';

  @override
  String get phoneHint => 'Phone number';

  @override
  String get phoneHelper => 'Include country code, for example +1 202 555 0142';

  @override
  String get yourName => 'Your name';

  @override
  String get nameHint => 'How your family should see you';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'Type the 6-digit code sent to $phone';
  }

  @override
  String get verifyCode => 'Verify and continue';

  @override
  String get resendCode => 'Resend code';

  @override
  String get createFamilyTitle => 'Create your family';

  @override
  String get joinFamilyTitle => 'Join a family';

  @override
  String get familySetupTitle => 'Set up your family';

  @override
  String get familySetupSubtitle =>
      'Create a new family workspace or join one with an invite code.';

  @override
  String get createFamily => 'Create family';

  @override
  String get joinFamily => 'Join family';

  @override
  String get familyName => 'Family name';

  @override
  String get familyNameHint => 'The Cohens, Our Home…';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get inviteCodeHint => '6-character code';

  @override
  String get createFamilyAction => 'Create family';

  @override
  String get joinFamilyAction => 'Join family';

  @override
  String get home => 'Home';

  @override
  String get tasks => 'Tasks';

  @override
  String get family => 'Family';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name! 👋';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name! 👋';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name! 👋';
  }

  @override
  String get greetingSubtitle =>
      'Everything is organized, let\'s win the day together 💜';

  @override
  String get currentFamily => 'Your family';

  @override
  String get needsAttention => 'Needs attention now';

  @override
  String get openTasks => 'Open';

  @override
  String get urgentTasks => 'Urgent';

  @override
  String get myTasks => 'Mine';

  @override
  String get recentlyCompleted => 'Done';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get addTask => 'Add task';

  @override
  String get viewTasks => 'View tasks';

  @override
  String get familyMembers => 'Family members';

  @override
  String get upcomingTasks => 'Coming up';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get addFirstTask => 'Add your first task';

  @override
  String get emptyTasksMessage =>
      'When you add something, your family will see it here.';

  @override
  String get noNotifications => 'You’re all caught up';

  @override
  String get noNotificationsMessage =>
      'New assignments and completed tasks will show up here.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get signOut => 'Sign out';

  @override
  String get taskTitle => 'Task title';

  @override
  String get taskTitleHint => 'What needs to be done?';

  @override
  String get taskType => 'Type';

  @override
  String get personal => 'Personal';

  @override
  String get familyType => 'Family';

  @override
  String get assignee => 'Assignee';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get dueDate => 'Due date';

  @override
  String get none => 'None';

  @override
  String get priority => 'Priority';

  @override
  String get low => 'Low';

  @override
  String get normal => 'Normal';

  @override
  String get urgent => 'Urgent';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Anything the family should know';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String get changeStatus => 'Status';

  @override
  String get pending => 'Not started';

  @override
  String get inProgress => 'In progress';

  @override
  String get completed => 'Completed';

  @override
  String get high => 'High';

  @override
  String get dueTime => 'Due time';

  @override
  String get reminder => 'Reminder';

  @override
  String get optionalReminder => 'Optional reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get createdBy => 'Created';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskReopened => 'Task reopened';

  @override
  String get reopenTask => 'Reopen task';

  @override
  String get deleteTask => 'Delete';

  @override
  String get deleteTaskTitle => 'Delete this task?';

  @override
  String get deleteTaskMessage =>
      'The task will be moved to Trash. You can restore it later.';

  @override
  String get moveToTrash => 'Move to Trash';

  @override
  String get taskMovedToTrash => 'Task moved to Trash';

  @override
  String get undo => 'Undo';

  @override
  String get trash => 'Trash';

  @override
  String get emptyTrash => 'Empty Trash';

  @override
  String get emptyTrashTitle => 'Empty Trash?';

  @override
  String get emptyTrashMessage =>
      'This permanently deletes every task in Trash. This cannot be undone.';

  @override
  String get permanentlyDelete => 'Delete forever';

  @override
  String get permanentlyDeleteTitle => 'Delete forever?';

  @override
  String get permanentlyDeleteMessage =>
      'This task will be removed permanently. This cannot be undone.';

  @override
  String get restoreTask => 'Restore';

  @override
  String get taskRestored => 'Task restored';

  @override
  String get taskDeletedForever => 'Task deleted forever';

  @override
  String get trashEmptied => 'Trash emptied';

  @override
  String get noTrashYet => 'Trash is empty';

  @override
  String get noTrashMessage =>
      'Deleted tasks will appear here until you restore or permanently delete them.';

  @override
  String get calendar => 'Calendar';

  @override
  String get mySpace => 'My Space';

  @override
  String get familySpace => 'Family Space';

  @override
  String get noCalendarTasks => 'No dated tasks';

  @override
  String get noCalendarMessage =>
      'Tasks with a due date will appear on the calendar.';

  @override
  String get goToSettings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get familySettings => 'Family';

  @override
  String get appearance => 'Appearance';

  @override
  String get inviteMember => 'Invite a family member';

  @override
  String get inviteMemberMessage =>
      'Share this invite code so someone can join your family workspace.';

  @override
  String get memberDetails => 'Member details';

  @override
  String get sharedFamilyInfo => 'Shared family information';

  @override
  String get privateSpaceHint =>
      'Personal tasks stay in My Space and are not shown as shared family work.';

  @override
  String get openFamilyTasks => 'Open family tasks';

  @override
  String get deleteNotification => 'Delete notification';

  @override
  String get clearNotifications => 'Clear notifications';

  @override
  String get clearNotificationsTitle => 'Clear all notifications?';

  @override
  String get clearNotificationsMessage =>
      'This removes notification messages only. Tasks and family data stay intact.';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get notificationsCleared => 'Notifications cleared';

  @override
  String get unread => 'Unread';

  @override
  String get pickTime => 'Pick a time';

  @override
  String get titleRequired => 'Enter a task title to continue.';

  @override
  String get familyOverview => 'Family overview';

  @override
  String get about => 'About';

  @override
  String get reminderSet => 'Reminder set';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterMember => 'Member';

  @override
  String get all => 'All';

  @override
  String get retry => 'Try again';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorUnavailable =>
      'We couldn’t reach Family Brain. Check your connection and try again.';

  @override
  String get membersSubtitle =>
      'Everyone in this family can create and complete tasks.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get copied => 'Copied';

  @override
  String get noDueDate => 'No due date';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String get overdue => 'Overdue';

  @override
  String get today => 'Today';

  @override
  String get you => 'You';

  @override
  String get emptyMembers => 'No members yet';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get aboutApp => 'Family Brain is a simple workspace for families.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get pickDate => 'Pick a date';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidPhone => 'Enter a valid phone number with country code';

  @override
  String get invalidOtp => 'That code doesn’t look right';

  @override
  String get invalidInvite => 'We couldn’t find a family with that code';

  @override
  String get familyCreated => 'Family created';

  @override
  String get familyJoined => 'You’re in';

  @override
  String get taskSaved => 'Task saved';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get newTaskAssigned => 'New task assigned to you';

  @override
  String taskCompletedNotif(String name, String title) {
    return '$name completed “$title”';
  }

  @override
  String get taskDueTomorrow => 'Your task is due tomorrow';

  @override
  String get taskDetails => 'Task details';

  @override
  String get createTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String signedInAs(String phone) {
    return 'Signed in as $phone';
  }

  @override
  String get workspaceHint => 'Family is your first workspace.';

  @override
  String get loading => 'Loading…';

  @override
  String get continueAction => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get assignedToYou => 'Assigned to you';

  @override
  String get noUpcoming => 'Nothing urgent right now. Enjoy the calm.';

  @override
  String get seeAllTasks => 'Show all';

  @override
  String get personalTasks => 'Personal';

  @override
  String get familyTasks => 'Family';

  @override
  String get leaveFamily => 'This is your current family workspace.';

  @override
  String get jumpTo => 'Go to';

  @override
  String get appearanceHint =>
      'Family Brain uses a clean white theme with purple brand accents on phones and in the browser.';

  @override
  String get notificationsHint =>
      'Notifications are informational events. Reminders stay on tasks and are not removed when you delete a notification.';

  @override
  String get noMySpaceTasks => 'No personal tasks yet';

  @override
  String get noMySpaceMessage =>
      'Personal tasks stay in My Space and are not shown as shared family work.';

  @override
  String get noFamilySpaceTasks => 'No shared family tasks yet';

  @override
  String get noFamilySpaceMessage =>
      'Tasks marked as Family appear here for everyone.';

  @override
  String get memberAssignedTasks => 'Assigned family tasks';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String get sendToFamilyBrain => 'Send to Family Brain';

  @override
  String get statPending => 'Pending';

  @override
  String get statImportant => 'Important';

  @override
  String get statConnected => 'Connected';

  @override
  String get statEventsToday => 'Events today';

  @override
  String get statPendingTasks => 'Pending tasks';

  @override
  String get statImportantReminders => 'Important reminders';

  @override
  String get statFamilyConnected => 'Family connected';

  @override
  String get everyone => 'Everyone';

  @override
  String get quickAccessCalendar => 'Calendar';

  @override
  String get quickAccessTasks => 'Tasks';

  @override
  String get quickAccessMySpace => 'My Space';

  @override
  String get quickAccessFamilySpace => 'Family Space';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get events => 'Events';

  @override
  String get reminders => 'Reminders';

  @override
  String get openRelatedTask => 'Open related task';

  @override
  String get noEvents => 'No events yet';

  @override
  String get noEventsMessage => 'Events with a date will appear here.';

  @override
  String get noReminders => 'No reminders yet';

  @override
  String get noRemindersMessage => 'Reminders you add will appear here.';

  @override
  String get membersLabel => 'Members';

  @override
  String get viewFamily => 'View family';

  @override
  String get addToFamilyBrain => 'Send to Family Brain';

  @override
  String get addToFamilyBrainHint =>
      'Send info and we\'ll turn it into tasks, events, and more…';

  @override
  String get tellFamilyBrain => 'Tell Family Brain…';

  @override
  String get attachInformation => 'Attach';

  @override
  String get voiceInput => 'Voice';

  @override
  String get askAi => 'Ask AI';

  @override
  String get comingSoon => 'This will be available in a later update.';

  @override
  String get messageMember => 'Message';

  @override
  String get callMember => 'Call';

  @override
  String get sharedWithMember => 'Shared information';

  @override
  String get addFamilyMember => 'Add';

  @override
  String get todayActivity => 'Your day';

  @override
  String get phoneNotShared => 'Phone number is not shared';

  @override
  String get confirm => 'Confirm';

  @override
  String get brainUnderstood => 'Family Brain understood';

  @override
  String get brainUnclear =>
      'Family Brain is not sure. Review this before saving.';

  @override
  String get emptyBrainInput => 'Type something for Family Brain first.';

  @override
  String get brainSaved => 'Saved to Family Brain';

  @override
  String get brainType => 'Type';

  @override
  String get brainDate => 'Date';

  @override
  String get brainTime => 'Time';

  @override
  String get brainPerson => 'Person';

  @override
  String get kindTask => 'Task';

  @override
  String get kindEvent => 'Event';

  @override
  String get kindReminder => 'Reminder';

  @override
  String get kindList => 'List';

  @override
  String get kindInformation => 'Information';

  @override
  String brainFoundItems(int count) {
    return 'Family Brain found $count items';
  }

  @override
  String get brainUsingOnDevice =>
      'No internet for AI. Using on-device understanding.';

  @override
  String get brainAiFailed =>
      'AI is unavailable. Using on-device understanding.';

  @override
  String get brainRetry => 'Retry';

  @override
  String get recentBrain => 'Recent Family Brain';

  @override
  String get choosePhotoSource => 'Add a photo';

  @override
  String get photoFromGallery => 'Gallery';

  @override
  String get photoFromCamera => 'Camera';

  @override
  String get brainProcessing => 'Family Brain is understanding…';

  @override
  String get listItems => 'Items';

  @override
  String get listItemsHint => 'One item per line';

  @override
  String get askFamilyBrain => 'Ask Family Brain';

  @override
  String get askFamilyBrainHint =>
      'Ask about tasks, lists, or what is happening.';

  @override
  String get askExample => 'What tasks are due today?';

  @override
  String get askSubmit => 'Ask';

  @override
  String get photoAttached => 'Attached photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get listening => 'Listening…';

  @override
  String get voiceUnavailable => 'Voice input is not available on this device.';

  @override
  String get voiceDenied => 'Microphone permission was denied.';

  @override
  String get voiceFailed => 'Could not understand the speech. Try again.';

  @override
  String get voiceLanguageUnsupported =>
      'Hebrew speech recognition is not available on this device.';

  @override
  String get voiceEmpty => 'No speech was captured. Try again.';

  @override
  String get imageFailed => 'Could not open the photo picker.';

  @override
  String get imageTooLarge => 'That photo is too large. Choose a smaller one.';
}
