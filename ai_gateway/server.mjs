#!/usr/bin/env node
/**
 * Family Brain AI gateway.
 *
 * Flutter → this server → Gemini. The Gemini API key stays in GEMINI_API_KEY
 * on the server and is never sent to the app.
 *
 *   GEMINI_API_KEY=... node ai_gateway/server.mjs
 */
import http from 'node:http';

const PORT = Number(process.env.PORT || 8787);
const MODEL = process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite';

const SYSTEM = `You are Family Brain. Turn messy family messages into structured items.
Return ONLY JSON: {"clarification": null or string, "items": [...]}.
Each item: type (task|event|reminder|list|information), title, description, date (YYYY-MM-DD local calendar date),
time (HH:MM 24h local), endTime, reminderTime, people[], assignee, assigneeId, location, listName, listItems[],
priority (low|normal|high|urgent), status (pending|inProgress|completed), confidence (0-1), explanation,
space (family|personal).
ONE message may become MULTIPLE items. Never dump everything into a single task.
Keep the user's language in titles and list items (Hebrew stays Hebrew).
Infer priority from meaning. Never assign the same priority to everything:
urgent = דחוף / urgent / immediately; high = חשוב / important / בהקדם;
low = כשיהיה זמן / whenever / no rush; otherwise normal.
Interpret dates relative to Now using the provided local timestamp and timezoneOffsetMinutes.
Do not convert to UTC. The date field must be the user's local calendar date.
היום=today, מחר=tomorrow, מחר בבוקר=tomorrow 09:00,
מחר בערב=tomorrow 19:00, tonight/this evening=today 19:00 unless a time is given,
next week=+7 days, Friday=the coming Friday, next Friday=the Friday after this week's Friday if Friday is still ahead,
in two hours=now+2h, at 8 PM=20:00, at 8 AM=08:00.
Hebrew clock words: בשש≈18:00, בארבע≈16:00, בשמונה≈20:00 unless morning is stated.
If the user gives an explicit time, preserve it exactly.
If date/time is genuinely ambiguous, omit those fields and set clarification. Do not invent dates, times, people, or reminders.
Use member names only when they clearly match the provided family members. Copy assigneeId when the match is unique.
If two members could match, omit assignee and ask for clarification. Never invent a new person.
I/me/"I need to"/תזכיר לי/אני צריך = personal space and assign to currentUser.
everyone/the family/כולם/כל המשפחה = family space and no specific assignee.
A named member who needs to do something = assign to that member, family space.
Prefer family space unless the user says it is personal/private/my space or uses first person for their own task.
If the photo/text is too ambiguous, set clarification and keep items empty or low confidence.`;

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function send(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

async function gemini(parts) {
  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    const err = new Error('GEMINI_API_KEY is not set');
    err.status = 503;
    throw err;
  }
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${encodeURIComponent(key)}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: SYSTEM }] },
      generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
      contents: [{ role: 'user', parts }],
    }),
  });
  if (!response.ok) {
    const err = new Error(`Gemini ${response.status}`);
    err.status = 502;
    throw err;
  }
  const data = await response.json();
  const text = data?.candidates?.[0]?.content?.parts?.map((p) => p.text).join('') || '';
  return JSON.parse(text);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    res.end();
    return;
  }
  try {
    if (req.method === 'GET' && req.url === '/health') {
      send(res, 200, { ok: true, provider: 'gemini', model: MODEL });
      return;
    }
    if (req.method === 'POST' && req.url === '/understand') {
      const payload = JSON.parse((await readBody(req)) || '{}');
      const members = Array.isArray(payload.members) ? payload.members : [];
      const parts = [
        {
          text:
            `Now (local): ${payload.now || ''}\n` +
            `Timezone offset minutes: ${payload.timezoneOffsetMinutes ?? ''}\n` +
            `Language: ${payload.language || 'en'}\n` +
            `Current user: ${payload.currentUser ? JSON.stringify(payload.currentUser) : ''}\n` +
            `Family members: ${JSON.stringify(members)}\n` +
            `Message:\n${payload.text || ''}`,
        },
      ];
      if (payload.imageBase64) {
        parts.push({
          inlineData: {
            mimeType: payload.mimeType || 'image/jpeg',
            data: payload.imageBase64,
          },
        });
      }
      const result = await gemini(parts);
      send(res, 200, result);
      return;
    }
    if (req.method === 'POST' && req.url === '/ask') {
      const payload = JSON.parse((await readBody(req)) || '{}');
      const parts = [
        {
          text:
            'Answer using ONLY this family-visible information. Never invent private items.\n' +
            `Items:\n${JSON.stringify(payload.items || [])}\n\nQuestion: ${payload.question || ''}`,
        },
      ];
      const result = await gemini(parts);
      send(res, 200, { answer: result.answer || result.clarification || JSON.stringify(result) });
      return;
    }
    send(res, 404, { error: 'not_found' });
  } catch (error) {
    send(res, error.status || 500, { error: error.message || 'ai_failed' });
  }
});

server.listen(PORT, () => {
  console.log(`Family Brain AI gateway on ${PORT}`);
});
