// CycleCare Partner Sync — Supabase Edge Function
// Handles partner invite validation and shared data push
// Deploy: supabase functions deploy partner-sync

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  const { action, code, sharedData } = await req.json();

  if (action === "accept_invite") {
    const { data, error } = await supabase
      .from("partner_invites")
      .select("*")
      .eq("invite_code", code)
      .gt("expires_at", new Date().toISOString())
      .single();

    if (error || !data) {
      return new Response(JSON.stringify({ error: "Invalid or expired invite code" }), { status: 404 });
    }

    return new Response(JSON.stringify({ success: true, ownerId: data.owner_id }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ error: "Unknown action" }), { status: 400 });
});
