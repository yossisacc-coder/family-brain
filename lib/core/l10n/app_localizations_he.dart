// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Family Brain';

  @override
  String get welcomeTitle => 'ברוכים הבאים ל־Family Brain';

  @override
  String get welcomeSubtitle =>
      'מקום אחד, רגוע ופשוט, לארגון משימות משפחתיות, חלוקת אחריות והישארות מסונכרנים.';

  @override
  String get continueWithPhone => 'המשך עם מספר טלפון';

  @override
  String get demoSignIn => 'כניסה למשפחת הדגמה';

  @override
  String get demoHint => 'במצב פיתוח נעשה שימוש במספר בדיקה. לא נשלח SMS.';

  @override
  String get phoneTitle => 'מספר הטלפון שלך';

  @override
  String get phoneSubtitle => 'נשלח קוד חד־פעמי כדי לוודא שזה אתם.';

  @override
  String get phoneHint => 'מספר טלפון';

  @override
  String get phoneHelper => 'כולל קידומת מדינה, למשל ‎+972 50 000 0000';

  @override
  String get yourName => 'השם שלך';

  @override
  String get nameHint => 'איך המשפחה תראה אותך';

  @override
  String get sendCode => 'שלחו קוד';

  @override
  String get otpTitle => 'הזינו את הקוד';

  @override
  String otpSubtitle(String phone) {
    return 'הקלידו את הקוד בן 6 הספרות שנשלח אל $phone';
  }

  @override
  String get verifyCode => 'אימות והמשך';

  @override
  String get resendCode => 'שליחה מחדש';

  @override
  String get createFamilyTitle => 'יצירת משפחה';

  @override
  String get joinFamilyTitle => 'הצטרפות למשפחה';

  @override
  String get familySetupTitle => 'הגדרת המשפחה';

  @override
  String get familySetupSubtitle =>
      'צרו סביבת עבודה משפחתית חדשה או הצטרפו באמצעות קוד הזמנה.';

  @override
  String get createFamily => 'יצירת משפחה';

  @override
  String get joinFamily => 'הצטרפות למשפחה';

  @override
  String get familyName => 'שם המשפחה';

  @override
  String get familyNameHint => 'משפחת כהן, הבית שלנו…';

  @override
  String get inviteCode => 'קוד הזמנה';

  @override
  String get inviteCodeHint => 'קוד בן 6 תווים';

  @override
  String get createFamilyAction => 'יצירת משפחה';

  @override
  String get joinFamilyAction => 'הצטרפות למשפחה';

  @override
  String get home => 'בית';

  @override
  String get tasks => 'משימות';

  @override
  String get family => 'משפחה';

  @override
  String get settings => 'הגדרות';

  @override
  String get notifications => 'התראות';

  @override
  String greetingMorning(String name) {
    return 'בוקר טוב, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'צהריים טובים, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'ערב טוב, $name';
  }

  @override
  String get currentFamily => 'המשפחה שלך';

  @override
  String get needsAttention => 'דורש תשומת לב עכשיו';

  @override
  String get openTasks => 'פתוחות';

  @override
  String get urgentTasks => 'דחופות';

  @override
  String get myTasks => 'שלי';

  @override
  String get recentlyCompleted => 'הושלמו';

  @override
  String get quickActions => 'פעולות מהירות';

  @override
  String get addTask => 'משימה חדשה';

  @override
  String get viewTasks => 'כל המשימות';

  @override
  String get familyMembers => 'בני המשפחה';

  @override
  String get upcomingTasks => 'בקרוב';

  @override
  String get noTasksYet => 'עדיין אין משימות';

  @override
  String get addFirstTask => 'הוסיפו את המשימה הראשונה';

  @override
  String get emptyTasksMessage => 'כשתרשמו משימה, כל המשפחה תראה אותה כאן.';

  @override
  String get noNotifications => 'הכול מעודכן';

  @override
  String get noNotificationsMessage =>
      'שיבוצים חדשים ומשימות שהושלמו יופיעו כאן.';

  @override
  String get language => 'שפה';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get signOut => 'התנתקות';

  @override
  String get taskTitle => 'כותרת המשימה';

  @override
  String get taskTitleHint => 'מה צריך לעשות?';

  @override
  String get taskType => 'סוג';

  @override
  String get personal => 'אישית';

  @override
  String get familyType => 'משפחתית';

  @override
  String get assignee => 'אחראי';

  @override
  String get unassigned => 'ללא שיוך';

  @override
  String get dueDate => 'תאריך יעד';

  @override
  String get none => 'ללא';

  @override
  String get priority => 'עדיפות';

  @override
  String get normal => 'רגילה';

  @override
  String get urgent => 'דחופה';

  @override
  String get notes => 'הערות';

  @override
  String get notesHint => 'משהו שהמשפחה צריכה לדעת';

  @override
  String get save => 'שמירה';

  @override
  String get edit => 'עריכה';

  @override
  String get markCompleted => 'סימון כהושלמה';

  @override
  String get changeStatus => 'סטטוס';

  @override
  String get pending => 'ממתינה';

  @override
  String get inProgress => 'בתהליך';

  @override
  String get completed => 'הושלמה';

  @override
  String get filterStatus => 'סטטוס';

  @override
  String get filterMember => 'בן משפחה';

  @override
  String get all => 'הכול';

  @override
  String get retry => 'נסו שוב';

  @override
  String get errorGeneric => 'משהו השתבש';

  @override
  String get errorUnavailable =>
      'לא הצלחנו להתחבר אל Family Brain. בדקו את החיבור ונסו שוב.';

  @override
  String get membersSubtitle =>
      'כל בני המשפחה יכולים ליצור משימות ולהשלים אותן.';

  @override
  String get inviteCodeLabel => 'קוד הזמנה';

  @override
  String get copied => 'הועתק';

  @override
  String get noDueDate => 'ללא תאריך יעד';

  @override
  String get dueTomorrow => 'למחר';

  @override
  String get overdue => 'באיחור';

  @override
  String get today => 'היום';

  @override
  String get you => 'אתם';

  @override
  String get emptyMembers => 'עדיין אין חברים';

  @override
  String get markAllRead => 'סימון הכול כנקרא';

  @override
  String get aboutApp => 'Family Brain הוא מרחב עבודה פשוט למשפחות.';

  @override
  String version(String version) {
    return 'גרסה $version';
  }

  @override
  String get pickDate => 'בחירת תאריך';

  @override
  String get cancel => 'ביטול';

  @override
  String get done => 'סיום';

  @override
  String get requiredField => 'שדה חובה';

  @override
  String get invalidPhone => 'הזינו מספר טלפון תקין כולל קידומת מדינה';

  @override
  String get invalidOtp => 'הקוד לא נראה נכון';

  @override
  String get invalidInvite => 'לא מצאנו משפחה עם הקוד הזה';

  @override
  String get familyCreated => 'המשפחה נוצרה';

  @override
  String get familyJoined => 'הצטרפתם';

  @override
  String get taskSaved => 'המשימה נשמרה';

  @override
  String get statusUpdated => 'הסטטוס עודכן';

  @override
  String get newTaskAssigned => 'משימה חדשה שובצה אליכם';

  @override
  String taskCompletedNotif(String name, String title) {
    return '$name השלים/ה את “$title”';
  }

  @override
  String get taskDueTomorrow => 'המשימה שלכם היא למחר';

  @override
  String get taskDetails => 'פרטי משימה';

  @override
  String get createTask => 'משימה חדשה';

  @override
  String get editTask => 'עריכת משימה';

  @override
  String signedInAs(String phone) {
    return 'מחוברים כ־$phone';
  }

  @override
  String get workspaceHint => 'משפחה היא סוג סביבת העבודה הראשון.';

  @override
  String get loading => 'טוען…';

  @override
  String get continueAction => 'המשך';

  @override
  String get back => 'חזרה';

  @override
  String get assignedToYou => 'משובץ אליכם';

  @override
  String get noUpcoming => 'אין דברים דחופים כרגע. אפשר לנשום.';

  @override
  String get seeAllTasks => 'כל המשימות';

  @override
  String get personalTasks => 'אישיות';

  @override
  String get familyTasks => 'משפחתיות';

  @override
  String get leaveFamily => 'זו סביבת העבודה המשפחתית הנוכחית שלכם.';
}
