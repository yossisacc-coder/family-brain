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
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

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
  String get pending => 'Pending';

  @override
  String get inProgress => 'In progress';

  @override
  String get completed => 'Completed';

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
  String get seeAllTasks => 'See all tasks';

  @override
  String get personalTasks => 'Personal';

  @override
  String get familyTasks => 'Family';

  @override
  String get leaveFamily => 'This is your current family workspace.';
}
