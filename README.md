# Family Brain

A simple digital workspace for families. The first version helps a family organize tasks, assign responsibility, track progress, and stay informed.

This is a real Flutter application (Android first, with iOS and web project support) backed by Firebase Authentication, Cloud Firestore, and Firebase Cloud Messaging.

## What you can do

- Sign in with a phone number and one-time code
- Create a family or join with an invite code
- Add, assign, edit, and complete personal or family tasks
- See a mobile Home screen with what needs attention
- Receive in-app notifications (and push notifications when Firebase is fully configured)
- Switch the whole app between English (LTR) and Hebrew (RTL)

## How to run the current version

### 1. Install Flutter

Use Flutter 3.22 or newer: https://docs.flutter.dev/get-started/install

### 2. Start the local cloud emulators

Default builds use an on-device **Development / Demo** login so you can open the app on a real phone without SMS or production Firebase. Phone/OTP screens and the Firebase auth implementation are still in the project.

```bash
npm install -g firebase-tools
firebase emulators:start --project family-brain-dev
```

Leave that terminal open. The emulators listen on:

- Auth: `127.0.0.1:9099`
- Firestore: `127.0.0.1:8088`
- Emulator UI: http://127.0.0.1:4000

### 3. Run the app

**Interactive web preview (phone layout)**

```bash
flutter pub get
flutter run -d chrome --dart-define=USE_EMULATOR=true
```

Or, without opening Chrome locally:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173 --dart-define=USE_EMULATOR=true
```

Then open **http://127.0.0.1:5173** in a browser. The app is framed like a phone.

**Android APK (physical phone)**

The published debug APK uses on-device demo data. Install `dist/family_brain_android.zip` from this repository (unzip and install `family_brain.apk`). On the welcome screen tap **Development demo login**. No SMS and no Firebase connection are required.

```bash
flutter run -d android
```

To exercise the unchanged Phone/OTP + Firebase path (emulator):

```bash
flutter run -d android --dart-define=BACKEND_MODE=firebase --dart-define=USE_EMULATOR=true
```

On the Android emulator, `127.0.0.1` is remapped to `10.0.2.2` automatically.

### 4. Try it

On the welcome screen, tap **Development demo login**. The app opens a seeded demo family so you can use Home, Family, Tasks, Notifications, and Hebrew/English RTL immediately.

Phone/OTP remains available for the Firebase backend (`BACKEND_MODE=firebase`). With the emulator, open the Auth emulator UI if you need the one-time code.

## Production Firebase

Before a public release:

1. Create a Firebase project on the Spark (free) plan.
2. Enable Authentication (Phone), Cloud Firestore, and Cloud Messaging.
3. Run `flutterfire configure` and replace `lib/firebase_options.dart`.
4. Deploy `firestore.rules`.
5. Run the app with `--dart-define=BACKEND_MODE=firebase --dart-define=USE_EMULATOR=false`.

Phone SMS in production requires a Firebase project with Phone Authentication enabled.

## Project layout

- `lib/core` — theme, routing, reusable UI, localization
- `lib/domain` — models and repository interfaces
- `lib/data` — Firebase implementations plus the on-device local demo store
- `lib/features` — screens and feature controllers
- `landing/` — standalone marketing website (does not modify the Flutter app)
- `DEVELOPMENT_STATUS.md` — current progress and known limits

Family is the first workspace type. Other workspace types are not implemented yet.

## Marketing website

The Family Brain landing page lives in `landing/`. It is static HTML/CSS/JS and can be hosted for free (GitHub Pages, Cloudflare Pages, or Netlify Drop). See `landing/README.md` for local preview and deploy steps.
