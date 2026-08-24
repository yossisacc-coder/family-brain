# Family Brain AI gateway

Flutter talks to this server. This server talks to Gemini.

Never put `GEMINI_API_KEY` in the Flutter app or commit it.

```bash
export GEMINI_API_KEY=your_google_ai_studio_key
node ai_gateway/server.mjs
```

Then run the app with:

```bash
flutter run --dart-define=AI_BACKEND_URL=http://<host>:8787
```

Gemini 2.0 Flash free-tier is the default model (`GEMINI_MODEL`).
If the gateway is unreachable, Family Brain uses the on-device parser.
