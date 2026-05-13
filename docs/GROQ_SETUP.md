# Groq AI Setup Guide

The AI assistant uses Groq's Llama model, called **server-side only** via a Supabase Edge Function.
The Groq API key is **never** in the Flutter client.

## 1. Get a Groq API key

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up / log in
3. Create an API key

## 2. Set the secret in Supabase

```bash
supabase secrets set GROQ_API_KEY=gsk_your_groq_key_here
```

## 3. Deploy the Edge Function

```bash
supabase functions deploy ai-assistant
```

## 4. Test it

```bash
curl -X POST https://your-project.supabase.co/functions/v1/ai-assistant \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the fertile window?"}'
```

## Model used

`llama3-8b-8192` — fast, free tier available, good for health Q&A.

You can change the model in `supabase/functions/ai-assistant/index.ts`:
```typescript
const GROQ_MODEL = "llama3-8b-8192"; // or "llama3-70b-8192" for better quality
```

## Safety

The Edge Function:
- Verifies the Supabase JWT before calling Groq
- Appends a medical disclaimer to every response
- Never exposes the Groq API key to the client
- Refuses to provide medical diagnoses
