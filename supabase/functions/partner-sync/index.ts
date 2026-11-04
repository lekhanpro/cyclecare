// Retired legacy endpoint: the old implementation trusted header presence and
// used service-role access. Pairing now uses authenticated, participant-checked
// SQL RPCs in migration 002. No privileged credential is used here.
Deno.serve((req) => {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  };
  if (req.method === "OPTIONS") return new Response(null, { headers });
  return new Response(JSON.stringify({ error: "This legacy endpoint is retired. Update CycleCare to use authenticated partner pairing." }), { status: 410, headers });
});
