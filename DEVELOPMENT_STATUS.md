# Family Brain — development status

## Current phase

MVP complete for this repository. Production Firebase/SMS still needs the owner’s Firebase project.

## Completed phases

1. **Project foundation** — Flutter app for Android, iOS, and web; theme; EN/HE localization; mobile navigation.
2. **Backend** — Firebase Auth + Firestore repositories, emulator configuration, security rules.
3. **Authentication** — Welcome, phone number, OTP, session restore, development demo sign-in.
4. **Family** — Create family, join with invite code, members list, invite sharing.
5. **Tasks** — Create, list, details, edit, status changes, assignment, filters.
6. **Home** — Greeting, family name, attention cards, quick actions, upcoming tasks, empty states.
7. **Notifications** — In-app notifications for assignment, completion, and due-tomorrow. Push token registration is implemented and degrades safely if FCM is not configured.
8. **Settings / language** — English LTR and Hebrew RTL for the whole interface.
9. **Testing** — `flutter analyze` (no errors), `flutter test` (6 passed), web debug server, debug APK, and a manual Chrome walkthrough of the main flow.

## Current functionality

- Real navigation between all MVP screens
- Persistent shared data through Firestore (emulator by default)
- Mobile-first phone layout, including a phone frame on wide web previews
- Loading, empty, and error states

## What was tested in this environment

- Welcome → demo sign-in → create family “The Cohens” → Home
- Add urgent task “Buy milk” → it appears on Home → mark completed → counts update
- Settings: Hebrew RTL and back to English LTR
- `flutter test`: 6 tests passed
- `flutter build web` succeeded
- `flutter build apk --debug` succeeded (`build/app/outputs/flutter-apk/app-debug.apk`)

## Important technical decisions

- **Flutter** so Android ships first and iOS/web can be added without rebuilding the product.
- **Firebase** (Auth, Firestore, Messaging) as the free-tier cloud backend. UI does not talk to Firestore directly; it uses repositories.
- **Firebase Emulator Suite by default** because this build does not have the owner’s production Firebase credentials or SMS billing. Production is enabled with `--dart-define=USE_EMULATOR=false` after `flutterfire configure`.
- **Family as the first workspace type** (`workspaceType: family`) so later workspace types do not require a rewrite.
- **All family members have the same permissions** in this MVP.

## Known issues / limits

- Production SMS requires a real Firebase project with Phone Authentication enabled.
- Push notifications need a production Firebase app + `google-services.json` / APNs. In-app notifications work without that.
- Emulator data is local to the machine that runs the emulators.
- A 159 MB debug APK was built locally but was not uploaded as a chat artifact (too large for that channel). It is at `build/app/outputs/flutter-apk/app-debug.apk` after a local Android build.

## How to run the current version

On this development machine the interactive preview is already running:

- **App:** http://127.0.0.1:5173
- **Firebase emulator UI:** http://127.0.0.1:4000

On another computer:

```bash
npm install
npm run emulators
# in a second terminal
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173 --dart-define=USE_EMULATOR=true
```

Then open **http://127.0.0.1:5173**

Android:

```bash
flutter run -d android --dart-define=USE_EMULATOR=true
```

On the welcome screen, tap **Try a demo family**, then create a family and add a task.
