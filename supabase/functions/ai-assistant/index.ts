// CycleCare AI Assistant — Supabase Edge Function
// Calls Groq server-side. GROQ_API_KEY is stored in Supabase secrets, never in the client.
// Deploy: supabase functions deploy ai-assistant

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama3-8b-8192";

const SYSTEM_PROMPT = `You are CycleCare AI, a friendly, knowledgeable health-education assistant 
specialized in menstrual health, hormonal cycles, fertility awareness, and general wellness.

IMPORTANT RULES:
- You are NOT a medical doctor. Never diagnose conditions or prescribe treatments.
- Always encourage users to consult qualified healthcare professionals for medical concerns.
- Keep responses concise, warm, and easy to understand.
- Always include a brief disclaimer that this is educational, not medical advice.
- If the user reports severe pain, very heavy bleeding, unusual symptoms, missed periods with 
  concern, pregnancy concerns, fainting, fever, or anything urgent — recommend speaking with 
  a doctor, guardian, or trusted adult promptly.
- Use inclusive language.
- Avoid explicit sexual content beyond general health context.`;

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    // Verify Supabase JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Parse request
    const { question, context } = await req.json();
    if (!question || typeof question !== "string") {
      return new Response(JSON.stringify({ error: "question is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Build messages
    const messages: Array<{ role: string; content: string }> = [];
    if (context) {
      messages.push({ role: "user", content: `My cycle context:\n${context}` });
      messages.push({ role: "assistant", content: "Thank you for sharing. I'll keep this in mind." });
    }
    messages.push({ role: "user", content: question });

    // Call Groq
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured. Contact support." }),
        { status: 503, headers: { "Content-Type": "application/json" } }
      );
    }

    const groqResponse = await fetch(GROQ_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [{ role: "system", content: SYSTEM_PROMPT }, ...messages],
        temperature: 0.7,
        max_tokens: 1024,
      }),
    });

    if (!groqResponse.ok) {
      const err = await groqResponse.text();
      console.error("Groq error:", err);
      return new Response(
        JSON.stringify({ error: "AI service temporarily unavailable." }),
        { status: 503, headers: { "Content-Type": "application/json" } }
      );
    }

    const groqData = await groqResponse.json();
    const reply = groqData.choices?.[0]?.message?.content ?? "I couldn't generate a response.";

    const safeReply = `${reply}\n\n_⚕️ Educational only — not medical advice. Consult a healthcare professional for medical concerns._`;

    return new Response(JSON.stringify({ reply: safeReply }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
