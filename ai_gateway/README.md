# Family Brain AI gateway

Flutter talks to this server. This server talks to Gemini.

Never put `GEMINI_API_KEY` in the Flutter app or commit it.

```bash
export GEMINI_API_KEY=your_google_ai_studio_key
node ai_gateway/server.mjs
```

The Flutter app defaults to the public Render origin:

`https://family-brain-ai.onrender.com`

Override only when needed:

```bash
flutter run --dart-define=AI_BACKEND_URL=https://family-brain-ai.onrender.com
```

Empty `AI_BACKEND_URL` keeps on-device parsing only.

Default model is `gemini-3.5-flash-lite` (`GEMINI_MODEL`), the current
stable Flash-Lite ID on the Gemini API with a free tier, text + image
input, and structured JSON output. Gemini 2.0 Flash was shut down on
June 1, 2026 and must not be used.

If the gateway is unreachable, Family Brain uses the on-device parser.

Flutter maps gateway JSON into a provider-independent schema
(`create_task`, `create_event`, `create_reminder`, `create_list_item`, …)
before the Action Engine writes tasks. Replacing Gemini later means a new
adapter only — not new task models, UI, or persistence.

