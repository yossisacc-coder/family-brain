# Family Brain — Launch Checklist

**Document type:** Project roadmap from the current repository to a real public production launch  
**Inspection date:** 28 August 2026  
**Repository:** https://github.com/yossisacc-coder/family-brain  
**Live website:** https://yossisacc-coder.github.io/family-brain/

This document is based on inspection of the actual source code, configuration, tests, and landing-page files. It does **not** invent features, customers, store listings, or legal clearance.

**Branches inspected**

- Flutter app: `cursor/family-brain-ux-ai-d2d5` (and related MVP worktrees)
- Landing / GitHub Pages: `cursor/family-brain-landing-d2d5` (live site after merge of PR #7)

If something cannot be confirmed from the repository, it is marked **NEEDS MANUAL VERIFICATION**.  
If something requires an external account or Google Play action, it is marked **EXTERNAL ACTION REQUIRED**.  
If something is not required for the first Android public launch, it is marked **FUTURE**.

---

## Status legend

| Mark | Meaning |
|------|---------|
| ✅ DONE | Implemented in the repository and evidenced by source files |
| 🟡 PARTIAL / NEEDS VERIFICATION | Present but incomplete, demo-only, placeholder, or not production-ready |
| 🔴 NOT DONE | Not found in the repository |
| ⚪ FUTURE / OPTIONAL | Not required for the first Android public launch, or later product work |

**Security rule:** This document never contains passwords, API keys, tokens, private keys, or recovery codes. Where a secret is required, it says **SECRET — STORE SECURELY**.

---

## 1. Current product status

Family Brain is an Android-first Flutter app that helps a household turn messages, screenshots, and shared information into tasks, reminders, events, and clear ownership, with an AI helper. The default shipped APK uses an **on-device local demo backend**. Firebase Phone Auth + Firestore exist in code but are not production-configured. The marketing site is live on GitHub Pages. The Android app is **not** published on Google Play.

| Item | Status | Evidence / notes |
|------|--------|------------------|
| Android app | ✅ | Flutter Android app, `applicationId` `com.familybrain.family_brain`, `minSdk` 24 |
| Flutter architecture | ✅ | Feature layout: `lib/core`, `lib/domain`, `lib/data`, `lib/features`; Riverpod + go_router |
| Home | ✅ | `lib/features/home/home_screen.dart` — greeting, stats, composer, shortcuts |
| Tasks | ✅ | Create, edit, details, complete/reopen, assign, personal vs family, trash/undo |
| Calendar | ✅ | Overlay route `/tasks/calendar` (not a bottom-nav tab) |
| Family | ✅ | Members, invite code, join/create, member details |
| Settings | ✅ | Language, appearance, account, family, notifications, trash, about |
| In-app notifications inbox | ✅ | `lib/features/notifications/` — separate from OS reminders |
| Push notifications (FCM) | 🟡 | `firebase_messaging` + `notification_service.dart`; needs a real Firebase app |
| OS local reminders | 🟡 | `LocalReminderScheduler` exists; exact-alarm behavior is permission-dependent. Treat production reliability as **NEEDS MANUAL VERIFICATION** on real devices |
| AI (text understanding) | ✅ | Gemini via Node gateway `ai_gateway/server.mjs`; on-device fallback parser |
| Voice AI | 🟡 | On-device speech-to-text (`speech_to_text`) → same text AI pipeline. Not direct audio-to-model. Production mic quality **NEEDS MANUAL VERIFICATION** |
| Text input | ✅ | Home composer |
| Image / screenshot understanding | 🟡 | Share sheet + picker send image to Gemini gateway; local fallback is text-only |
| Android share sheet | ✅ | `SEND` / `SEND_MULTIPLE` in `AndroidManifest.xml`; `share_intake_controller.dart` |
| Firebase libraries in app | ✅ | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging` |
| Production Firebase project | 🔴 | `lib/firebase_options.dart` uses placeholder `demo-family-brain` / `family-brain-dev`. No `google-services.json` found |
| Authentication (demo) | ✅ | Default `BACKEND_MODE=localDemo`; welcome screen “Development demo login” |
| Authentication (real Phone + OTP) | 🟡 | Screens and `FirebaseAuthRepository` exist; production SMS is **EXTERNAL ACTION REQUIRED** |
| Database (local demo) | ✅ | `LocalJsonStore` on the device (SharedPreferences). Not shared across devices |
| Database (Firestore) | 🟡 | Repositories + `firestore.rules` exist; not wired to a real production project |
| Hebrew RTL (app) | ✅ | `app_he.arb`, locale switch in Settings, Heebo font |
| English LTR (app) | ✅ | `app_en.arb`, default locale |
| Landing page | ✅ | Live at the GitHub Pages URL above |
| Dark / light (website) | ✅ | Landing Personal / Professional theme toggle |
| Dark mode (app) | 🔴 | App palettes are light (`Brightness.light`). `DEVELOPMENT_STATUS.md` states no app dark-mode toggle yet. Dark `ColorScheme` code exists but is not exposed |
| Personal / Professional appearance (app) | ✅ | Settings appearance toggle |
| Demo family members | ✅ | Alex, Maya, David, Noa, Ruth (“The Cohens”); invite `DEMO01` |
| APK build | 🟡 | Debug APK in `dist/family_brain_android.zip`. Release signing still uses **debug keys** |
| Android App Bundle (.aab) | 🔴 | No production bundle found |
| GitHub repository | ✅ | https://github.com/yossisacc-coder/family-brain |
| GitHub Pages website | ✅ | Publishes from branch `cursor/family-brain-landing-d2d5`, path `/` |

**Current version in `pubspec.yaml`:** `1.1.0+4` (`versionName` 1.1.0, `versionCode` 4).

**Default runtime:** on-device demo. Cloud AI default gateway origin in code: `https://family-brain-ai.onrender.com` (public URL only; the Gemini key stays on the server). Whether that Render service is funded, limited, and monitored in production is **NEEDS MANUAL VERIFICATION**.

---

## 2. What we have already completed

Do not treat this as store-ready. It is what the repository actually contains.

### App product

- [x] Flutter Android app with Home, Tasks, Family, Settings
- [x] Calendar, My Space, Family Space, Activity, Notifications, Trash overlays
- [x] Task lifecycle: create, edit, complete, reopen, assign, reminder fields, soft-delete, undo, permanent delete
- [x] Family workspace: create, join with invite, members, roles in data model
- [x] Loading, empty, and error views on major screens
- [x] English + Hebrew localization with RTL/LTR
- [x] Personal vs Professional appearance (light app UI)
- [x] Home composer: text, voice-to-text, photo/screenshot, Android share intake
- [x] AI understand → confirm/ask flow (`brain_confirm_screen`, `brain_ask_screen`)
- [x] On-device AI fallback when the gateway is unavailable
- [x] Demo login and seeded demo family (The Cohens)
- [x] Access plan model exists (`AccessPlan.beta`) but does **not** paywall anything

### Engineering

- [x] Riverpod repositories with `BACKEND_MODE=localDemo` or `firebase`
- [x] Firestore security rules file (`firestore.rules`)
- [x] Firebase emulator config (`firebase.json`, ports 9099 / 8088)
- [x] AI gateway (`ai_gateway/server.mjs`) using Gemini; key from server env `GEMINI_API_KEY`
- [x] Unit + widget tests in `test/` — **152 passing** on the inspected Flutter branch (`flutter test`, 28 August 2026)
- [x] Brand assets under `assets/brand/`
- [x] Debug APK artifact zip under `dist/`

### Website

- [x] GitHub Pages landing at https://yossisacc-coder.github.io/family-brain/
- [x] EN / HE language switch with real `dir` (LTR / RTL)
- [x] Light + dark (Professional) website theme; app phone mockups stay light
- [x] `robots.txt`, `sitemap.xml`, Open Graph / basic SEO metadata
- [x] Google Search Console verification file `googlecda2fd053fafe2a0.html`
- [x] Get Family Brain CTA with empty `data-android-store` / `data-ios-store` placeholders
- [x] Privacy and Terms **placeholder pages** (not full legal documents)

---

## 3. What still needs to be done before public launch

### A. MUST HAVE

| Item | Status | Notes |
|------|--------|-------|
| Production Firebase project | 🔴 | Replace placeholder `firebase_options.dart`; add real `google-services.json`. **EXTERNAL ACTION REQUIRED** |
| Real Phone Authentication | 🟡 | Code exists; enable Phone Auth + billing for SMS. **EXTERNAL ACTION REQUIRED** |
| Disable demo-as-default for store builds | 🔴 | Store builds must not default to `localDemo` / hardcoded OTP `123456` |
| Production Firestore | 🟡 | Deploy rules/indexes to a real project; review create-family rules before launch |
| Security review of rules + gateway | 🔴 | Required before any real user data |
| Production AI gateway config | 🟡 | Confirm Render (or replacement) env, quotas, abuse controls. **NEEDS MANUAL VERIFICATION** |
| AI usage / cost controls | 🔴 | No quota, auth, or per-family rate limit found on the gateway (`Access-Control-Allow-Origin: *`) |
| Crash reporting | 🔴 | No Firebase Crashlytics (or other) in `pubspec.yaml` |
| Privacy policy (real) | 🟡 | Website page is labeled Placeholder |
| Terms of service (real) | 🟡 | Website page is labeled Placeholder |
| Account / data deletion | 🔴 | Sign-out exists; no delete-account / delete-all-user-data flow found |
| Play Data safety form | 🔴 | **EXTERNAL ACTION REQUIRED** |
| Content rating questionnaire | 🔴 | **EXTERNAL ACTION REQUIRED** |
| Target audience / families policy | 🔴 | Family organizer aimed at households; Play Families Policy / target age **NEEDS MANUAL VERIFICATION** against current policy |
| Store listing, icon, screenshots, feature graphic | 🔴 | Icon assets exist in-app; Play listing assets not prepared as store packages. **EXTERNAL ACTION REQUIRED** |
| Production signing key | 🔴 | Release still signs with debug keys (`android/app/build.gradle.kts`) |
| Release Android App Bundle (`.aab`) | 🔴 | |
| Versioning policy for store | 🟡 | `1.1.0+4` exists; store release numbering still needs a conscious production bump |
| Closed testing on Play | 🔴 | **EXTERNAL ACTION REQUIRED** |
| Production access application (new personal accounts) | 🔴 | See section 4. **EXTERNAL ACTION REQUIRED** |
| Reviewer login credentials | 🔴 | If Phone Auth is required, Play reviewers need a working test account |
| Device testing of AI, voice, share, reminders, RTL, Hebrew | 🟡 | Automated tests exist; production-device pass is **NEEDS MANUAL VERIFICATION** |

### B. SHOULD HAVE

- Analytics (none found)
- Global Flutter error handler / crash upload
- Firestore offline persistence policy for production
- Monitoring/alerting on the AI gateway
- Email contact that is not only localStorage waitlist
- Full legal review of privacy/terms (not DIY-only)
- Pre-launch report in Play Console
- Remove or hide “Development demo login” in store builds
- Confirm OS reminder notifications on multiple OEM phones

### C. NICE TO HAVE / FUTURE

- iPhone / App Store
- In-app purchases / subscriptions
- Google Analytics / AdMob (not in repo)
- Custom domain
- App dark-mode toggle
- iOS share sheet (landing already does **not** claim it)
- Cloud Functions, Storage, Hosting (not used)

---

## 4. Google Play launch

Official sources used (28 August 2026):

- Get started with Play Console: https://support.google.com/googleplay/android-developer/answer/6112435
- Testing requirements for new personal accounts: https://support.google.com/googleplay/android-developer/answer/14151465
- Service fees: https://support.google.com/googleplay/android-developer/answer/112622

**New personal Play Console accounts created after 13 November 2023** must run a **closed test** with **at least 12 testers opted in continuously for at least the preceding 14 days**, then **apply for production access** from the Play Console Dashboard. Testers who opt out early do not count. Internal testing does **not** replace this closed-test requirement. Open testing becomes available **after** production access.

Whether the Family Brain Play account is personal vs organization, and created before/after that date, is **NEEDS MANUAL VERIFICATION**.

| Step | Item | Status | Who |
|------|------|--------|-----|
| 1 | Google Play Developer account | 🔴 / NEEDS MANUAL VERIFICATION | **EXTERNAL ACTION REQUIRED** |
| 2 | Identity / contact verification (government ID + payment method under legal name per Play Help) | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 3 | Device / additional account verification if Play Console requests it | 🔴 | **EXTERNAL ACTION REQUIRED** — follow the Console; do not guess extra steps |
| 4 | Create the app in Play Console | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 5 | Store listing (title, short/full description, graphics) | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 6 | App icon (Play high-res icon) | 🟡 | In-app brand mark exists; Play 512×512 listing icon still needed |
| 7 | Screenshots (phone; 7" / 10" if you declare tablets) | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 8 | Description (no unsupported claims) | 🟡 | Landing copy can inform this; listing not written in Console |
| 9 | Privacy policy URL | 🟡 | URL can be the Pages privacy page **after** it is a real policy, not a placeholder |
| 10 | Data safety form | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 11 | Content rating | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 12 | Target audience | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 13 | App access / reviewer credentials | 🔴 | Required if login is needed to use the app |
| 14 | Production build (signed `.aab`) | 🔴 | Code can produce a bundle only after signing is configured |
| 15 | Internal testing | 🔴 | Optional but recommended; **EXTERNAL ACTION REQUIRED** |
| 16 | Closed testing | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 17 | Required tester period (personal accounts after 13 Nov 2023): **12 opted-in testers × 14 continuous days** | 🔴 | **EXTERNAL ACTION REQUIRED** |
| 18 | Apply for production access | 🔴 | Dashboard → Apply for production. Review often ~7 days, can be longer |
| 19 | Submit production release | 🔴 | Only after production access is granted |
| 20 | Review | 🔴 | Google review. **EXTERNAL ACTION REQUIRED** |
| 21 | Publish | 🔴 | **EXTERNAL ACTION REQUIRED** |

**Possible now (engineering):** prepare store copy, screenshots from the real app, privacy/terms, signed AAB once a keystore exists, testers list.  
**Not possible until Play Console actions:** creating the listing, closed test, production access, public publish.

---

## 5. Payments / monetization

**No payment SDK is in the project** (no `in_app_purchase`, Billing, Stripe, RevenueCat, AdMob). Settings show a beta plan; `canUseProduct` is always true.

| Item | Status | What would be required later |
|------|--------|------------------------------|
| A. Free plan | 🟡 | Current product is free/beta by design. A durable free tier needs a written definition (limits, ads or not) |
| B. Premium subscription | 🔴 FUTURE | Product SKUs, Play Billing, entitlement checks replacing `AccessPlan.beta` |
| C. In-app purchases | 🔴 FUTURE | Same Billing stack; not started |
| D. Google Play Billing | 🔴 FUTURE | Play Console billing profile + Billing Library in the app |
| E. Revenue tracking | 🔴 FUTURE | Play reports; optional analytics |
| F. Refund handling | 🔴 FUTURE | Play Console refund tools; support process |
| G. Subscription cancellation | 🔴 FUTURE | Users cancel in Google Play; app must honor entitlement |
| H. Tax / payment setup | 🔴 FUTURE | Play payments profile, tax forms. **EXTERNAL ACTION REQUIRED** |
| I. Developer payment profile | 🔴 FUTURE | **EXTERNAL ACTION REQUIRED** |

Do **not** implement payments until the free Android launch path is stable. First launch can remain free.

---

## 6. Google Play fees

Fees change by country, date, program, and billing method. There is **not** one fee for every transaction. Confirm in Play Console Help before relying on a number.

| Fee | What official docs said on 28 Aug 2026 | Notes |
|-----|----------------------------------------|-------|
| Developer account registration | **US$25 one-time** | https://support.google.com/googleplay/android-developer/answer/6112435 — card payment; fee may not be refunded if identity is invalid |
| Play service fee (EEA / UK / US from 30 Jun 2026) | Split **service fee + billing fee**; first US$1M/year auto-renewing subscriptions **10% + 5% billing** when using Play Billing; other transactions **20% or 25% + 5% billing** depending on new vs existing install | https://support.google.com/googleplay/android-developer/answer/112622 |
| Play service fee (markets not yet on that rollout) | Common structure: **15%** of first US$1M/year, **30%** above; **15%** on auto-renewing subscriptions in that table | Same Help article; **NEEDS MANUAL VERIFICATION** for the country of each user at launch time |
| Alternative / external billing | Reduced or different billing fee in some regions | Do not assume 0% |
| App listing while free | **No per-download fee** | 97% of developers distribute at no charge per the same Help article |

Apple Developer Program (**FUTURE** iPhone): typically a **recurring** annual fee. Confirm at https://developer.apple.com/support/compare-memberships/ before budgeting.

---

## 7. AI costs

**Provider in code:** Google Gemini (Generative Language API).  
**Client:** Flutter `gemini_ai_adapter.dart` POSTs to the gateway `/understand`.  
**Server:** `ai_gateway/server.mjs`. Default model env `GEMINI_MODEL` or `gemini-3.5-flash-lite`.

| Capability | How it works | Status |
|------------|--------------|--------|
| Text AI | Gateway → Gemini `generateContent` | ✅ |
| Image understanding | Image base64 + MIME to the same Gemini call | 🟡 (cloud path only) |
| Voice / speech | On-device STT, then text AI | 🟡 |
| “Ask Family Brain” Q&A | Local rule-based over visible tasks (`family_brain_ask.dart`), not cloud LLM | ✅ |
| Other AI vendors | Not found | 🔴 |

**Before production, configure (do not commit secrets):**

| Need | Status |
|------|--------|
| `GEMINI_API_KEY` on the gateway host | **SECRET — STORE SECURELY** (server env only). 🟡 whether production Render env is set: **NEEDS MANUAL VERIFICATION** |
| Usage limits / billing caps on Google AI / Cloud | 🔴 **EXTERNAL ACTION REQUIRED** |
| Rate limits per IP / family | 🔴 Gateway currently allows CORS `*` and has no app auth |
| Cost monitoring | 🔴 |
| Abuse protection | 🔴 |
| Error handling | 🟡 Gateway returns errors; app has retry + local fallback |
| Production URL via `--dart-define=AI_BACKEND_URL=` | 🟡 default Render URL in `app_config.dart` |

Gemini / Google AI usage is **usage dependent**. Do not invent a monthly dollar amount.

---

## 8. Firebase / server costs

| Service | In project? | Status | Cost note |
|---------|-------------|--------|-----------|
| Authentication (Phone) | Yes (code) | 🟡 | SMS is **usage dependent** (Firebase Auth phone pricing). Demo path sends no SMS |
| Cloud Firestore | Yes (code + rules) | 🟡 | **usage dependent** (reads/writes/storage) |
| Cloud Messaging | Yes (dep + token save) | 🟡 | FCM is generally no-cost for typical notification volume; confirm current Firebase pricing |
| Cloud Functions | No | 🔴 | Not used |
| Cloud Storage | No | 🔴 | Images go to the AI gateway as base64, not Firebase Storage |
| Firebase Hosting | No | 🔴 | Website is GitHub Pages |
| Emulators | Yes | ✅ | Local / free |
| AI gateway host (Render) | Yes (URL in code) | 🟡 | **usage dependent** / plan-dependent. **NEEDS MANUAL VERIFICATION** of the Render plan |

Spark vs Blaze billing for a real Phone Auth + production project is **EXTERNAL ACTION REQUIRED**. Do not invent a monthly Firebase bill.

---

## 9. Website

**Live URL:** https://yossisacc-coder.github.io/family-brain/  
**Publishes from:** GitHub branch `cursor/family-brain-landing-d2d5`, path `/`  
**Custom domain:** none (`cname` is null on GitHub Pages)

| Item | Status |
|------|--------|
| GitHub Pages | ✅ |
| Custom domain | 🔴 FUTURE (optional) |
| Landing page | ✅ |
| Hebrew / English | ✅ |
| RTL / LTR | ✅ |
| Dark / light (site theme) | ✅ |
| SEO metadata | ✅ basic, no unsupported claims |
| `sitemap.xml` | ✅ |
| `robots.txt` | ✅ |
| Privacy | 🟡 placeholder |
| Terms | 🟡 placeholder |
| App download CTA | 🟡 buttons exist; store attributes empty; labeled coming soon |
| Beta waitlist | 🟡 saved in **browser localStorage only**, not a server |

**When Google Play is live:** set `#download` `data-android-store` to the real Play URL (and later `data-ios-store` for App Store). Do not invent a Play URL before the listing exists.

---

## 10. Marketing / user acquisition

⚪ FUTURE / OPTIONAL. Budget is chosen by us; there is no fixed advertising cost.

| Channel | Notes |
|---------|--------|
| Family / friend beta | Should start before Play closed testing |
| Organic search | Landing + Search Console verification file already present |
| Social media | Not implemented in-product |
| Referral | Not implemented |
| Google Ads | Optional; **usage dependent** budget |
| YouTube ads | Optional; **usage dependent** budget |

Do not spend on ads until the store listing and production app are real.

---

## 11. Legal / trust

Family Brain is **not** legally cleared. Trademark and policy clearance need proper verification.

| Item | Status |
|------|--------|
| Privacy policy | 🟡 placeholder page |
| Terms of service | 🟡 placeholder page |
| Data handling description | 🟡 demo data is on-device; Firebase path not production |
| User account deletion | 🔴 required for many store/privacy regimes once accounts exist |
| Data deletion | 🟡 per-task/trash only |
| AI disclosures | 🟡 landing says AI asks instead of guessing; store listing should also be honest |
| Copyright of code/assets | 🟡 **NEEDS MANUAL VERIFICATION** (who owns the logo/code) |
| App name / trademark review | 🔴 **NEEDS MANUAL VERIFICATION** — do not claim the name is cleared |
| Logo / asset licensing | 🟡 brand assets in `assets/brand/` and landing `images/`; licensing **NEEDS MANUAL VERIFICATION** |
| Third-party services | Google (Firebase, Gemini, Play), GitHub, Render |
| Google Play policy compliance | 🔴 **EXTERNAL ACTION REQUIRED** before submit |

---

## 12. Security

**Do not commit secrets. None are printed here.**

| Area | Status | Production action |
|------|--------|-------------------|
| Authentication | 🟡 | Demo OTP and demo phone are in `app_config.dart`. Store builds must not ship demo login |
| Firestore rules | 🟡 | Family-scoped rules exist; `families` create is `if signedIn()` — review for abuse |
| API key handling (Gemini) | ✅ design | Key on server env only |
| Firebase config | 🔴 prod | Placeholder options; no `google-services.json` |
| Production vs development | 🟡 | Dart defines `BACKEND_MODE`, `USE_EMULATOR` (default **true**), `AI_BACKEND_URL` |
| Debug code | 🟡 | Demo banners, emulator `appVerificationDisabledForTesting` when emulator |
| Test accounts | 🟡 | Hardcoded demo user IDs |
| Sensitive data | 🟡 | Family tasks may include personal information once real auth is on |
| Logging | 🟡 | `debugPrint` in places; no Crashlytics |
| Android permissions | ✅ declared | INTERNET, POST_NOTIFICATIONS, RECORD_AUDIO, CAMERA, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, VIBRATE, WAKE_LOCK |
| Notification permission | 🟡 | Requested by local reminder scheduler; production UX **NEEDS MANUAL VERIFICATION** |
| AI gateway CORS `*` | 🔴 risk | Must not stay wide-open without rate limits if the key is paid |

**Must fix before production:** real Firebase config, no debug signing, no default demo OTP, gateway abuse controls, account deletion, real privacy policy, signing keystore stored offline (**SECRET — STORE SECURELY**).

---

## 13. Quality / performance

| Item | Status |
|------|--------|
| App startup speed | 🟡 **NEEDS MANUAL VERIFICATION** on devices |
| AI response speed | 🟡 network + Gemini; fallback if down |
| Firebase queries | 🟡 unused in default demo APK |
| Offline behavior | ✅ demo is local; 🟡 Firebase offline **NEEDS MANUAL VERIFICATION** (`persistenceEnabled: false` on emulator) |
| Loading states | ✅ |
| Error states | ✅ |
| Crashes | 🟡 tests pass; no Crashlytics |
| Memory | 🟡 **NEEDS MANUAL VERIFICATION** (image base64 to gateway can be heavy) |
| Network failures | 🟡 AI fallback exists |
| Slow AI | 🟡 retry helper exists |
| Voice recording | 🟡 **NEEDS MANUAL VERIFICATION** on hardware |
| Image upload | 🟡 share/picker path exists; no Firebase Storage |

---

## 14. Testing

| Layer | Status |
|-------|--------|
| Unit tests | ✅ in `test/` |
| Widget tests | ✅ |
| Integration / `integration_test/` | 🔴 not found |
| `flutter test` on inspected branch | ✅ 152 passed (28 Aug 2026) |
| Real Android devices | 🟡 **NEEDS MANUAL VERIFICATION** |
| Screen sizes | 🟡 some widget coverage; device matrix not documented |
| Hebrew RTL | ✅ app l10n + landing i18n |
| English LTR | ✅ |
| App dark mode | 🔴 no toggle |
| Website dark / light | ✅ |
| Authentication | 🟡 demo covered; real SMS **NEEDS MANUAL VERIFICATION** |
| Tasks / calendar / family | ✅ substantial widget tests |
| AI schema / confirm flow | ✅ architecture tests |
| Voice | 🟡 code present; hardware **NEEDS MANUAL VERIFICATION** |
| Notifications inbox | ✅ |
| Image / screenshot | 🟡 **NEEDS MANUAL VERIFICATION** on device share sheet |
| Delete / undo | ✅ |
| Family members | ✅ demo seeding tests |
| Production Firebase | 🔴 |

---

## 15. Production release

Must produce:

| Deliverable | Status |
|-------------|--------|
| Release `.aab` | 🔴 |
| Upload key / Play App Signing | 🔴 **SECRET — STORE SECURELY** |
| `versionName` / `versionCode` | 🟡 `1.1.0` / `4` today — bump for store |
| Store icon, screenshots, feature graphic | 🔴 |
| Privacy policy URL (real content) | 🟡 |
| Reviewer access | 🔴 |
| Release notes | 🔴 |

**Existing `dist/family_brain_android.zip` is a debug-oriented APK, not a Play production artifact.** Do not upload a debug-signed APK as production.

---

## 16. Monthly cost model

Do **not** invent prices. “Current cost” means what this repo implies, not a bank statement.

| SERVICE | CURRENT COST | FUTURE COST | WHAT CAUSES COST |
|---------|--------------|-------------|------------------|
| GitHub | **NEEDS MANUAL VERIFICATION** (public repo) | Plan-dependent | Private repo / extra Actions minutes |
| GitHub Pages | Typically no extra fee on standard public Pages | Plan-dependent | Bandwidth / custom domain extras |
| Domain | $0 (no custom domain) | Registrar price if you buy one | Annual domain |
| Firebase Auth SMS | $0 on demo path | **usage dependent** | OTP SMS |
| Firestore | $0 on demo path | **usage dependent** | Reads/writes/storage |
| FCM | code only | Usually $0 at small scale; confirm | Push volume |
| Cloud Functions / Storage / Hosting | Not used | N/A unless added | — |
| Gemini / Google AI | **NEEDS MANUAL VERIFICATION** | **usage dependent** | Tokens, image understanding |
| Voice STT | On-device plugin | Device CPU; no cloud STT vendor found | — |
| Image processing | Via Gemini | **usage dependent** | Image tokens |
| Render (AI gateway) | **NEEDS MANUAL VERIFICATION** | Plan / **usage dependent** | Always-on instance, sleep, bandwidth |
| Google Play registration | Not evidenced in repo | US$25 one-time if not already paid | Account creation |
| Google Play service fees | $0 (no IAP) | Percentage of digital sales — **not one rate** | Subscriptions / IAP |
| Payment processing | Not in app | Play billing fee and/or processor | IAP |
| Email / SMS OTP | Demo: none | SMS **usage dependent** | Phone Auth |
| Analytics | Not in app | Vendor **usage dependent** | If added |
| Crash monitoring | Not in app | Vendor **usage dependent** | If Crashlytics/Sentry added |
| YouTube / Google Ads | Not in app | **usage dependent** budget we set | Optional ads |
| Apple Developer | FUTURE | Recurring fee if iOS launches | iPhone |

---

## 17. Launch timeline

Practical sequence (not a calendar estimate):

**PHASE 1 — Finish MVP**  
App screens, demo mode, landing, tests. Largely ✅ with remaining quality gaps (crash reporting, demo-in-release, legal placeholders).

**PHASE 2 — Real production backend**  
Firebase project, Phone Auth, rules deploy, `USE_EMULATOR=false`, production `firebase_options` / `google-services.json`, AI gateway hardening, account deletion.

**PHASE 3 — Beta testing**  
Internal trusted testers on a **Firebase-backed** (or clearly labeled demo) build. Fix crashes. Collect feedback.

**PHASE 4 — Google Play preparation**  
Account, listing assets, real privacy/terms, Data safety, content rating, signed AAB, reviewer credentials.

**PHASE 5 — Closed testing**  
For a new personal account after 13 Nov 2023: **≥12 opted-in testers for 14 continuous days**. Keep them opted in.

**PHASE 6 — Production approval**  
Apply for production access; answer Play’s questionnaire; wait for Google.

**PHASE 7 — Public launch**  
Production track, Play URL on the website, monitor crashes and Gemini spend.

**PHASE 8 — Monetization**  
Only after a stable free app. Play Billing, tax profile, subscription UX.

**PHASE 9 — Marketing**  
Optional paid ads with a budget we control.

**PHASE 10 — iPhone / App Store**  
FUTURE. Separate Apple Developer account, iOS signing, App Store listing, iOS share sheet if claimed.

---

## 18. Final master checklist

### BEFORE BETA

- [ ] Decide: beta on **local demo** (device-only data) vs **real Firebase**
- [ ] If Firebase: create production (or dedicated staging) Firebase project
- [ ] Replace placeholder Firebase options; add `google-services.json` locally (**do not commit secrets**)
- [ ] Enable Phone Auth or keep demo **explicitly labeled**
- [ ] Confirm AI gateway is up, key in server env, billing cap on Google AI
- [ ] Run `flutter test`; smoke-test on at least one physical Android phone
- [ ] Hebrew RTL + English LTR on device
- [ ] Voice, share sheet, screenshot, reminders, trash/undo
- [ ] Hide or clearly mark development demo login if testers might confuse it with production
- [ ] Crash/log plan (even if Crashlytics comes a phase later)

### BEFORE GOOGLE PLAY (closed test)

- [ ] Play Developer account paid and verified — **EXTERNAL ACTION REQUIRED**
- [ ] Production keystore + Play App Signing — **SECRET — STORE SECURELY**
- [ ] Release `.aab` (not debug APK)
- [ ] Real privacy policy and terms URLs
- [ ] Data safety + content rating + target audience
- [ ] Store listing copy without fake claims or fake Play availability
- [ ] Phone screenshots from the real app
- [ ] Reviewer credentials if login is required
- [ ] Account deletion path if accounts exist
- [ ] Closed testing track with instructions for testers
- [ ] Recruit **more than 12** testers so opt-outs do not reset the 14-day clock

### BEFORE PUBLIC LAUNCH

- [ ] 12 testers opted in continuously for 14 days (if the personal-account rule applies)
- [ ] Apply for production access and wait for approval
- [ ] Production release submitted and approved
- [ ] Put the real Play URL in the website `data-android-store`
- [ ] Confirm no demo OTP / emulator flags in the store build
- [ ] Confirm gateway rate limits and Firebase rules
- [ ] Support contact that actually receives mail

### AFTER LAUNCH

- [ ] Watch crashes, Play pre-launch report, and Gemini spend
- [ ] Answer user reviews
- [ ] Plan IAP only if needed
- [ ] Optional ads budget
- [ ] iOS later

---

## 19. Access & management directory

Never put passwords or keys in this file. Use **SECRET — STORE SECURELY**.

### GitHub

| | |
|--|--|
| Login | https://github.com/login |
| Account | GitHub user that owns `yossisacc-coder/family-brain` |
| Used for | Source, PRs, Actions, Pages |
| Settings you may change | Pages source branch, Actions, collaborators, branch protection |
| Cost | Public repo typically $0; extra Actions/private plans **NEEDS MANUAL VERIFICATION** |
| Credentials | Account password + 2FA — **SECRET — STORE SECURELY** |
| Action | Keep Pages on `cursor/family-brain-landing-d2d5` until you intentionally change it |

### GitHub Pages

| | |
|--|--|
| Login | Same GitHub account; site settings: https://github.com/yossisacc-coder/family-brain/settings/pages |
| Used for | Public website |
| Settings | Source branch/folder, custom domain later |
| Cost | Standard Pages on a public repo: typically $0 |
| Action | After Play launch, paste the real store URL into the landing `#download` attributes |

### Cursor

| | |
|--|--|
| Login | https://cursor.com/ |
| Used for | Development |
| Cost | Cursor plan — **NEEDS MANUAL VERIFICATION** of the current subscription |
| Credentials | Cursor account — **SECRET — STORE SECURELY** |
| Action | None for store launch except continued development |

### Google Play Console

| | |
|--|--|
| Login | https://play.google.com/console |
| Account | Google account used as Play developer |
| Used for | App listing, testing tracks, production, Data safety, billing later |
| Settings | App content, testing, releases, users and permissions |
| Cost | US$25 one-time registration (official Help); later **service fees only if you sell** |
| Credentials | Google account + 2FA; later Play App Signing keys — **SECRET — STORE SECURELY** |
| Action | Create account if missing; create app; closed test; production access |

### Firebase Console

| | |
|--|--|
| Login | https://console.firebase.google.com/ |
| Account | Google account with the Firebase project |
| Used for | Auth, Firestore, FCM, later Crashlytics |
| Settings | Phone Auth, authorized domains, quotas, billing |
| Cost | Spark vs Blaze; SMS and Firestore **usage dependent** |
| Credentials | Google account; optional `google-services.json` on the build machine — **SECRET — STORE SECURELY** if it contains restricted keys |
| Action | Create a real project; replace placeholders; deploy `firestore.rules` |

### Google Cloud Console

| | |
|--|--|
| Login | https://console.cloud.google.com/ |
| Used for | The GCP project behind Firebase and (often) Gemini API enablement / billing |
| Settings | APIs, billing account, budgets, IAM |
| Cost | **usage dependent** |
| Credentials | Google Cloud billing + IAM — **SECRET — STORE SECURELY** |
| Action | Budgets/alerts before production AI and SMS |

### Google AI Studio / Gemini API

| | |
|--|--|
| Login | https://aistudio.google.com/ |
| API docs | https://ai.google.dev/ |
| Used for | Gemini API key used **only** on the AI gateway |
| Settings | API key, model access |
| Cost | **usage dependent** |
| Credentials | `GEMINI_API_KEY` — **SECRET — STORE SECURELY** (Render/env, never GitHub) |
| Action | Issue a production key, set quota, rotate if ever leaked |

### Render (AI gateway host)

| | |
|--|--|
| Login | https://dashboard.render.com/ |
| Used for | Hosting `ai_gateway/server.mjs` at the origin referenced in `app_config.dart` |
| Settings | Env vars, instance size, health, custom domain |
| Cost | **usage dependent** / plan-dependent — **NEEDS MANUAL VERIFICATION** |
| Credentials | Render account + `GEMINI_API_KEY` env — **SECRET — STORE SECURELY** |
| Action | Confirm the service is the one you intend for production; set `GEMINI_API_KEY` and `GEMINI_MODEL`; add rate limiting |

### Google Search Console

| | |
|--|--|
| Login | https://search.google.com/search-console |
| Used for | Search indexing of the Pages site (verification file is in the repo) |
| Cost | $0 |
| Action | Confirm property is verified and sitemap submitted — **NEEDS MANUAL VERIFICATION** |

### Google Analytics

| | |
|--|--|
| Login | https://analytics.google.com/ |
| In project? | **Not found** |
| Status | 🔴 NOT DONE / ⚪ FUTURE |

### Google AdMob

| | |
|--|--|
| Login | https://admob.google.com/ |
| In project? | **Not found** |
| Status | 🔴 NOT DONE / ⚪ FUTURE |

### Domain registrar

| | |
|--|--|
| Status | 🔴 no custom domain |
| Action | Only if you buy a domain later; then point DNS at GitHub Pages |

### Payment / subscription system

| | |
|--|--|
| Status | 🔴 not in the app |
| Later | Play Console payments profile + Play Billing |

### SMS / OTP provider

| | |
|--|--|
| In demo | Local hardcoded OTP — not a vendor |
| In Firebase path | Firebase Phone Auth (Google) |
| Login | Firebase Console |
| Cost | **usage dependent** SMS |

### Apple Developer / App Store

| | |
|--|--|
| Login | https://developer.apple.com/account |
| Status | ⚪ FUTURE |
| Cost | Recurring Apple Developer fee — confirm on Apple’s site before paying |

### Google account (general)

| | |
|--|--|
| Login | https://accounts.google.com/ |
| Used for | Play, Firebase, Cloud, Search Console, Gemini |
| Credentials | 2FA + recovery codes — **SECRET — STORE SECURELY** (not in Git) |

---

## 20. What I need to keep safe

Keep these **privately**. Never commit them to GitHub, never paste them into this document, never put them in screenshots of the repo.

- [ ] GitHub password + 2FA / passkeys / recovery codes
- [ ] Cursor account
- [ ] Google account 2FA and recovery codes (Play / Firebase / Cloud / Gemini)
- [ ] Play Console access + any Play App Signing / upload **keystore and passwords**
- [ ] Android release keystore file, alias, and passwords
- [ ] `google-services.json` / real `firebase_options` values if they include restricted keys
- [ ] Firebase / GCP billing account access
- [ ] `GEMINI_API_KEY`
- [ ] Render (or other host) account + gateway env vars
- [ ] Any future App Store Connect / Apple certificates
- [ ] Any future ads or analytics property IDs that are treated as sensitive in your process

If a secret was ever committed historically, **rotate it**. This inspection did not print secrets. Placeholder Firebase `apiKey: demo-family-brain` is not a production secret, but it must be replaced before launch.

---

## Honest launch verdict (from the repo)

| Question | Answer |
|----------|--------|
| Technically ready for a **friends-and-family demo / labeled beta** on Android? | **Yes, with caveats** — the local demo APK and GitHub Pages site exist; testers must understand data stays on-device in demo mode and Play listing is not live |
| Ready for **Google Play production**? | **No** — no production Firebase, no production signing, no real legal pages, no Play Console listing evidenced, no `.aab`, no closed test |

---

*End of document. Update this checklist when Firebase, Play Console, or the AI host actually change — do not update it with planned features that are not in source control.*
