require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.0-flash';

// Middleware
app.use(cors());
app.use(express.json({ limit: '100kb' }));

// Rate limiting: 20 requests per minute per IP to protect tokens and prevent abuse
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX || '20', 10),
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Rate limit reached. Please wait a moment before trying another Smart Action.',
  },
});

app.use('/api/', apiLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    app: 'Tack AI Server',
    model: GEMINI_MODEL,
    hasApiKey: Boolean(GEMINI_API_KEY && GEMINI_API_KEY.length > 5),
  });
});

// Helper to call Google Gemini REST API
async function callGemini(promptText, isJson = false) {
  if (!GEMINI_API_KEY || GEMINI_API_KEY.includes('your_gemini_api_key')) {
    throw new Error('Gemini API key is not configured in server/.env');
  }

  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

  const requestBody = {
    contents: [
      {
        parts: [{ text: promptText }],
      },
    ],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 2048,
    },
  };

  if (isJson) {
    requestBody.generationConfig.responseMimeType = 'application/json';
  }

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errText = await response.text();
    let parsedErr = errText;
    try {
      const jsonErr = JSON.parse(errText);
      parsedErr = jsonErr.error?.message || errText;
    } catch (_) {}
    throw new Error(`Gemini API error (${response.status}): ${parsedErr}`);
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error('No content returned from AI provider');
  }
  return text.trim();
}

// Main Smart Actions Endpoint
app.post('/api/ai/smart-action', async (req, res) => {
  try {
    const { action, content, title } = req.body;

    if (!content || typeof content !== 'string' || !content.trim()) {
      return res.status(400).json({ error: 'Note content is required' });
    }

    if (content.length > 8000) {
      return res.status(400).json({ error: 'Note exceeds 8,000 character limit' });
    }

    const cleanContent = content.trim();

    switch (action) {
      case 'tidy': {
        const prompt = `You are a quiet, expert editor for Tack, a minimal tactile notes app.
Clean up the following note text: fix typos, improve punctuation, grammar, and clean markdown structure.
STRICT RULES:
1. Preserve the author's exact tone, voice, and meaning.
2. Do not omit any details, code blocks, or links.
3. Do not add conversational remarks, greetings, notes, or intros/outros.
4. Output only the improved text.

Note text:
${cleanContent}`;

        const result = await callGemini(prompt, false);
        return res.json({ result });
      }

      case 'checklist': {
        const prompt = `You are an assistant for Tack note app.
Analyze the following text and extract all actionable tasks, todo items, or action points into an interactive markdown checklist format.
Use "- [ ] Task description".
STRICT RULES:
1. Output ONLY checklist lines starting with "- [ ] ".
2. Keep tasks clear, direct, and actionable.
3. Do not include markdown codeblocks (\`\`\`), conversational commentary, or headings.

Note text:
${cleanContent}`;

        const result = await callGemini(prompt, false);
        return res.json({ result });
      }

      case 'summarize': {
        const prompt = `You are an assistant for Tack note app.
Provide a concise, high-value summary of the following note in exactly 3 bullet points using "- Bullet text".
STRICT RULES:
1. Output ONLY the 3 bullet points.
2. Keep each bullet under 18 words.
3. Do not add intro, title, or conversational commentary.

Note text:
${cleanContent}`;

        const result = await callGemini(prompt, false);
        return res.json({ result });
      }

      case 'title_tags': {
        const prompt = `Analyze this note and suggest:
1. A concise, punchy title (2 to 5 words, title case).
2. 2 to 4 single-word lowercase tags without '#' symbol.

Return ONLY valid JSON matching this schema:
{
  "title": "string",
  "tags": ["string", "string"]
}

Note text:
${cleanContent}`;

        const rawJson = await callGemini(prompt, true);
        try {
          const cleaned = rawJson.replace(/```json/g, '').replace(/```/g, '').trim();
          const parsed = JSON.parse(cleaned);
          return res.json({
            title: parsed.title || 'Untitled Note',
            tags: Array.isArray(parsed.tags) ? parsed.tags.map(t => String(t).toLowerCase().replace('#', '').trim()) : [],
          });
        } catch (_) {
          return res.json({
            title: title || 'Updated Note',
            tags: ['ideas'],
          });
        }
      }

      default:
        return res.status(400).json({ error: `Unsupported smart action: ${action}` });
    }
  } catch (err) {
    console.error('Smart Action error:', err.message);
    res.status(500).json({ error: err.message || 'Failed to process Smart Action' });
  }
});

// Modular endpoint for future Whiteboard Flowchart generation
app.post('/api/ai/flowchart', async (req, res) => {
  try {
    const { prompt } = req.body;
    if (!prompt || typeof prompt !== 'string') {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    const aiPrompt = `Generate a flowchart with 4 to 6 connected steps for: "${prompt.trim()}".
Return JSON with nodes and edges matching Tack canvas:
{
  "nodes": [
    { "id": "n1", "text": "Start", "shapeType": "startEnd", "x": 2800, "y": 2800, "paletteId": "amber" }
  ],
  "edges": [
    { "id": "e1", "fromNodeId": "n1", "toNodeId": "n2", "label": "" }
  ]
}
Allowed shapeTypes: "startEnd", "process", "decision", "io".
Return ONLY valid JSON.`;

    const rawJson = await callGemini(aiPrompt, true);
    const cleaned = rawJson.replace(/```json/g, '').replace(/```/g, '').trim();
    const parsed = JSON.parse(cleaned);
    res.json(parsed);
  } catch (err) {
    res.status(500).json({ error: err.message || 'Flowchart generation failed' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Tack AI Server running on http://localhost:${PORT}`);
  console.log(`Configured model: ${GEMINI_MODEL}`);
  console.log(`Rate limit: ${process.env.RATE_LIMIT_MAX || 20} requests/min per IP`);
});
