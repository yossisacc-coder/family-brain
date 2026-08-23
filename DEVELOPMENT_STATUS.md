# Family Brain — development status

## Current phase

MVP complete for this repository. The Android APK uses an on-device **Development / Demo** login so Home, Family, Tasks, Notifications, and Hebrew/English RTL can be tested on a real phone without SMS or production Firebase. Phone/OTP + Firebase architecture is unchanged.

## Completed phases

1. **Project foundation** — Flutter app for Android, iOS, and web; theme; EN/HE localization; mobile navigation.
2. **Backend** — Firebase Auth + Firestore repositories, emulator configuration, security rules.
3. **Authentication** — Welcome, phone number, OTP, session restore. Development demo login is on-device (no SMS/Firebase). Phone/OTP still uses `FirebaseAuthRepository` when `BACKEND_MODE=firebase`.
4. **Family** — Create family, join with invite code, members list, invite sharing.
5. **Tasks** — Create, list, details, edit, status changes, assignment, filters.
6. **Home** — Greeting, family name, attention cards, quick actions, upcoming tasks, empty states.
7. **Notifications** — In-app notifications for assignment, completion, and due-tomorrow. Push token registration is implemented and degrades safely if FCM is not configured.
8. **Settings / language** — English LTR and Hebrew RTL for the whole interface.
9. **Testing** — `flutter analyze` (no errors), `flutter test` (6 passed), web debug server, debug APK, and a manual Chrome walkthrough of the main flow.

## Current functionality

- Real navigation between all MVP screens
- Persistent shared data through the on-device demo store by default, or Firestore when `BACKEND_MODE=firebase`
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
- **On-device local demo backend by default** so a physical Android APK can sign in without SMS, the Firebase Emulator, or production credentials. Phone/OTP screens and `FirebaseAuthRepository` are unchanged. Firebase/emulator mode is `--dart-define=BACKEND_MODE=firebase`.
- **Firebase Emulator Suite** remains available for the Firebase auth path (`USE_EMULATOR=true`, default when that backend is selected). Production is `--dart-define=BACKEND_MODE=firebase --dart-define=USE_EMULATOR=false` after `flutterfire configure`.
- **Family as the first workspace type** (`workspaceType: family`) so later workspace types do not require a rewrite.
- **All family members have the same permissions** in this MVP.

## Known issues / limits

- Production SMS requires a real Firebase project with Phone Authentication enabled. The APK’s **Development demo login** does not use SMS.
- Push notifications need a production Firebase app + `google-services.json` / APNs. In-app notifications work without that.
- Demo data is stored on the phone and is not shared between devices.
- Download the current Android APK zip from the GitHub repository: `dist/family_brain_android.zip` on this branch (contains `family_brain.apk`).

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

Android (on-device demo login, no emulators required):

```bash
flutter run -d android
```

On the welcome screen, tap **Development demo login**. The app opens a seeded demo family so Home, Family, Tasks, Notifications, and language/RTL can be tested immediately.

Firebase/emulator path (Phone/OTP architecture):

```bash
flutter run -d android --dart-define=BACKEND_MODE=firebase --dart-define=USE_EMULATOR=true
```
