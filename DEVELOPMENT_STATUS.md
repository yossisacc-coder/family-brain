# Family Brain — development status

## Current phase

**Round 1 complete.** The existing Flutter MVP now has consistent Home | Tasks | Family | Settings navigation, a full task create/details/complete/trash flow, notifications that stay separate from reminders, Hebrew RTL / English LTR localization, and a Trash area that is not a bottom-nav item.

Do not start Round 2 automatically.

## Completed phases

1. **Project foundation** — Flutter app for Android, iOS, and web; theme; EN/HE localization; mobile navigation.
2. **Backend** — Firebase Auth + Firestore repositories, emulator configuration, security rules.
3. **Authentication** — Welcome, phone number, OTP, session restore. Development demo login is on-device (no SMS/Firebase). Phone/OTP still uses `FirebaseAuthRepository` when `BACKEND_MODE=firebase`.
4. **Family** — Create family, join with invite code, members list, invite sharing, member details.
5. **Tasks** — Create, list, details, edit, status vs priority, assignment, personal vs family, reminders, complete/reopen, soft-delete to Trash.
6. **Home** — Greeting, family name, attention cards, shortcuts to New Task, All Tasks, Family Members, Calendar, My Space, Family Space, Notifications, and Settings.
7. **Notifications** — View, unread indication, mark one/all read, delete one, clear all. Deleting a notification never deletes the related task.
8. **Settings / language** — Notifications, language, account, family, appearance, Trash, About. English LTR and Hebrew RTL.
9. **Testing** — `flutter analyze` (no errors from Round 1), `flutter test` (21 passed), web preview, debug APK.

## Current functionality

- Material 3 bottom navigation: Home | Tasks | Family | Settings
- Notifications stay in the Home header (not a fifth tab)
- Task create/edit with title, notes, due date/time, priority, status, assignee, personal/family, optional reminder, validation, and cancel
- Complete returns to the previous list/context with “Task completed”; reopen is supported
- Delete confirms, moves to Trash, and offers Undo
- Trash: restore, permanently delete, empty trash with warnings
- Calendar, My Space, and Family Space overlays (Back returns to the previous screen)
- Personal My Space tasks of other members are hidden from shared Family views
- Loading, empty, and error states on major screens
- Android system Back pops overlays first and does not jump unexpectedly to Home

## Important technical decisions

- **Soft-delete via `deletedAt`** so existing local/Firestore documents keep loading without a destructive migration. Missing new fields (`hasDueTime`, `reminderAt`, `deletedAt`, `high` priority) default safely.
- **Status and Priority stay separate enums.** `pending` remains the stored “Not started” value for data compatibility.
- **Personal vs family visibility is enforced in the UI**, not by deleting data. Family Space never shows another member’s My Space tasks.
- **Reminders live on the task.** Notifications are a separate inbox; deleting them never touches tasks.
- **On-device local demo backend by default** so a physical Android APK can sign in without SMS. Phone/OTP + Firebase architecture is unchanged (`--dart-define=BACKEND_MODE=firebase`).
- **Flutter remains the shared codebase** for Android, iOS, and Web. Web stays a phone-style shell.

## Known issues / limits

- Production SMS requires a real Firebase project with Phone Authentication enabled.
- Push notifications need a production Firebase app. In-app notifications work without that.
- Demo data is stored on the phone and is not shared between devices.
- Reminders are stored and displayed; OS-level scheduled reminder notifications are not sent in this round.
- Appearance is a calm light theme; there is no dark-mode toggle yet.

## How to run the current version

Web:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173
```

Then open **http://127.0.0.1:5173**

Android (on-device demo login):

```bash
flutter run -d android
```

On the welcome screen, tap **Development demo login**.
