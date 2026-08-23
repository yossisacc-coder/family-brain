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

This first MVP is configured to talk to the Firebase Emulator Suite so the app can be used without paid SMS or a production Firebase project.

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

**Android**

```bash
flutter run -d android --dart-define=USE_EMULATOR=true
```

On the Android emulator, `127.0.0.1` is remapped to `10.0.2.2` automatically.

### 4. Try it

On the welcome screen, tap **Try a demo family** (development only), or enter any name and a phone number with country code. With the emulator, open the Auth emulator UI if you need the one-time code.

Then create a family, add a task, open it, change its status, and switch language in Settings.

## Production Firebase

Before a public release:

1. Create a Firebase project on the Spark (free) plan.
2. Enable Authentication (Phone), Cloud Firestore, and Cloud Messaging.
3. Run `flutterfire configure` and replace `lib/firebase_options.dart`.
4. Deploy `firestore.rules`.
5. Run the app with `--dart-define=USE_EMULATOR=false`.

Phone SMS in production requires a Firebase project with Phone Authentication enabled.

## Project layout

- `lib/core` — theme, routing, reusable UI, localization
- `lib/domain` — models and repository interfaces
- `lib/data` — Firebase implementations
- `lib/features` — screens and feature controllers
- `DEVELOPMENT_STATUS.md` — current progress and known limits

Family is the first workspace type. Other workspace types are not implemented yet.
