# Family Brain — development status

## Current phase

Phase 9 — full testing and preview in progress after completing phases 1–8 in this repository.

## Completed phases

1. **Project foundation** — Flutter app for Android, iOS, and web; theme; EN/HE localization; mobile navigation.
2. **Backend** — Firebase Auth + Firestore repositories, emulator configuration, security rules.
3. **Authentication** — Welcome, phone number, OTP, session restore, development demo sign-in.
4. **Family** — Create family, join with invite code, members list, invite sharing.
5. **Tasks** — Create, list, details, edit, status changes, assignment, filters.
6. **Home** — Greeting, family name, attention cards, quick actions, upcoming tasks, empty states.
7. **Notifications** — In-app notifications for assignment, completion, and due-tomorrow. Push token registration is implemented and degrades safely if FCM is not configured.
8. **Settings / language** — English LTR and Hebrew RTL for the whole interface.

## Current functionality

- Real navigation between all MVP screens
- Persistent shared data through Firestore (emulator by default)
- Mobile-first phone layout, including a phone frame on wide web previews
- Loading, empty, and error states

## Important technical decisions

- **Flutter** so Android ships first and iOS/web can be added without rebuilding the product.
- **Firebase** (Auth, Firestore, Messaging) as the free-tier cloud backend. UI does not talk to Firestore directly; it uses repositories.
- **Firebase Emulator Suite by default** because this build does not have the owner’s production Firebase credentials or SMS billing. Production is enabled with `--dart-define=USE_EMULATOR=false` after `flutterfire configure`.
- **Family as the first workspace type** (`workspaceType: family`) so later workspace types do not require a rewrite.
- **All family members have the same permissions** in this MVP.

## Known issues / limits

- Production SMS requires a real Firebase project with Phone Authentication enabled. The owner must create that project when they are ready to go live.
- Push notifications need a production Firebase app + `google-services.json` / APNs. In-app notifications work without that.
- Android builds need the Android SDK on the machine that compiles them.
- Emulator data is local to the machine that runs `firebase emulators:start`. It is still a real Auth/Firestore stack, not fake in-memory widgets.

## What remains

- Owner connects a production Firebase project when they want real SMS and multi-device cloud outside the emulator.
- Optional visual polish after the owner reviews the running app.

## How to run the current version

See `README.md`. Short version:

```bash
npm install -g firebase-tools
firebase emulators:start --project family-brain-dev
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173 --dart-define=USE_EMULATOR=true
```

Open **http://127.0.0.1:5173**
