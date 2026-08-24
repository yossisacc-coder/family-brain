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
Each item: type (task|event|reminder|list|information), title, description, date (YYYY-MM-DD),
time (HH:MM 24h), endTime, reminderTime, people[], assignee, location, listName, listItems[],
confidence (0-1), explanation, space (family|personal).
ONE message may become MULTIPLE items. Never dump everything into a single task.
Use member names only when they clearly match. Prefer family space unless the user says private/my space.
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
            `Now: ${payload.now || ''}\n` +
            `Family first names only: ${members.map((m) => m.name).join(', ')}\n` +
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
