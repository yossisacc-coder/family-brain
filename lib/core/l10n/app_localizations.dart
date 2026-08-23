import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Brain'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Family Brain'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One calm place for your family to organize tasks, share responsibility, and stay in sync.'**
  String get welcomeSubtitle;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone number'**
  String get continueWithPhone;

  /// No description provided for @demoSignIn.
  ///
  /// In en, this message translates to:
  /// **'Try a demo family'**
  String get demoSignIn;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Development sign-in uses a test phone number. No SMS is sent.'**
  String get demoHint;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a one-time code to verify it’s you.'**
  String get phoneSubtitle;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneHint;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Include country code, for example +1 202 555 0142'**
  String get phoneHelper;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'How your family should see you'**
  String get nameHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type the 6-digit code sent to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @createFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your family'**
  String get createFamilyTitle;

  /// No description provided for @joinFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a family'**
  String get joinFamilyTitle;

  /// No description provided for @familySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your family'**
  String get familySetupTitle;

  /// No description provided for @familySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new family workspace or join one with an invite code.'**
  String get familySetupSubtitle;

  /// No description provided for @createFamily.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamily;

  /// No description provided for @joinFamily.
  ///
  /// In en, this message translates to:
  /// **'Join family'**
  String get joinFamily;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyName;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'The Cohens, Our Home…'**
  String get familyNameHint;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-character code'**
  String get inviteCodeHint;

  /// No description provided for @createFamilyAction.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamilyAction;

  /// No description provided for @joinFamilyAction.
  ///
  /// In en, this message translates to:
  /// **'Join family'**
  String get joinFamilyAction;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @currentFamily.
  ///
  /// In en, this message translates to:
  /// **'Your family'**
  String get currentFamily;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention now'**
  String get needsAttention;

  /// No description provided for @openTasks.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openTasks;

  /// No description provided for @urgentTasks.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentTasks;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get myTasks;

  /// No description provided for @recentlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get recentlyCompleted;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @viewTasks.
  ///
  /// In en, this message translates to:
  /// **'View tasks'**
  String get viewTasks;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family members'**
  String get familyMembers;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get upcomingTasks;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @addFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Add your first task'**
  String get addFirstTask;

  /// No description provided for @emptyTasksMessage.
  ///
  /// In en, this message translates to:
  /// **'When you add something, your family will see it here.'**
  String get emptyTasksMessage;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up'**
  String get noNotifications;

  /// No description provided for @noNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'New assignments and completed tasks will show up here.'**
  String get noNotificationsMessage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrew;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskTitleHint;

  /// No description provided for @taskType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get taskType;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @familyType.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyType;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the family should know'**
  String get notesHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markCompleted;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get changeStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get filterMember;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t reach Family Brain. Check your connection and try again.'**
  String get errorUnavailable;

  /// No description provided for @membersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone in this family can create and complete tasks.'**
  String get membersSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @emptyMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get emptyMembers;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'Family Brain is a simple workspace for families.'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with country code'**
  String get invalidPhone;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'That code doesn’t look right'**
  String get invalidOtp;

  /// No description provided for @invalidInvite.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find a family with that code'**
  String get invalidInvite;

  /// No description provided for @familyCreated.
  ///
  /// In en, this message translates to:
  /// **'Family created'**
  String get familyCreated;

  /// No description provided for @familyJoined.
  ///
  /// In en, this message translates to:
  /// **'You’re in'**
  String get familyJoined;

  /// No description provided for @taskSaved.
  ///
  /// In en, this message translates to:
  /// **'Task saved'**
  String get taskSaved;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @newTaskAssigned.
  ///
  /// In en, this message translates to:
  /// **'New task assigned to you'**
  String get newTaskAssigned;

  /// No description provided for @taskCompletedNotif.
  ///
  /// In en, this message translates to:
  /// **'{name} completed “{title}”'**
  String taskCompletedNotif(String name, String title);

  /// No description provided for @taskDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Your task is due tomorrow'**
  String get taskDueTomorrow;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get taskDetails;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get createTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {phone}'**
  String signedInAs(String phone);

  /// No description provided for @workspaceHint.
  ///
  /// In en, this message translates to:
  /// **'Family is your first workspace.'**
  String get workspaceHint;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @assignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get assignedToYou;

  /// No description provided for @noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing urgent right now. Enjoy the calm.'**
  String get noUpcoming;

  /// No description provided for @seeAllTasks.
  ///
  /// In en, this message translates to:
  /// **'See all tasks'**
  String get seeAllTasks;

  /// No description provided for @personalTasks.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalTasks;

  /// No description provided for @familyTasks.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyTasks;

  /// No description provided for @leaveFamily.
  ///
  /// In en, this message translates to:
  /// **'This is your current family workspace.'**
  String get leaveFamily;
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
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
