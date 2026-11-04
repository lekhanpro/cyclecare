# Partner connection deployment and verification

The partner experience now has a separate Home, read-only Calendar and Settings,
with explicit page grants, field consent, freshness and received-update history.
Offline one-off CC1 updates remain available without an account. CC1 is encoded
JSON with a typo checksum, **not encryption or authentication**. It cannot be
remotely recalled. Existing codes and their old screens remain readable.

Ongoing sharing uses real Supabase Auth sessions and authenticated PostgreSQL RPCs.
It is not connected until a configured server accepts the device session and the
owner explicitly creates a paired connection and enables ongoing field updates.
No health upload occurs simply by launching CycleCare or entering a URL/key.

## Deployment

1. Review and apply `supabase/migrations/002_partner_live_sync.sql` to the intended
   Supabase project after the existing initial migration. This changes the remote
   database and needs the project owner's deployment approval.
2. Enable anonymous sign-ins in Supabase Auth. Follow Supabase guidance on rate
   limits and CAPTCHA/abuse prevention for the deployment's expected audience.
3. Replace/deploy the old `partner-sync` edge function with the retired HTTP 410
   implementation. New clients do not call it; the old header-only/service-role
   lookup must not remain available as a parallel pairing path.
4. Both phones use the same HTTPS project URL and publishable/anon public key in
   **Together → Manage partner connection → Set up partner sync**. The current
   public project URL is prefilled. Never put a secret or service-role key in the
   app, source, issue, README or chat.
5. Connect each device explicitly. Its authenticated anonymous session tokens are
   persisted using Flutter secure storage; the public server configuration is
   stored separately. Existing Firebase sign-in is not silently reused as a
   Supabase identity. Losing/uninstalling the anonymous identity can make its old
   connections unmanageable from that phone. Reauthorization warns about this.

The repository uses the Supabase Auth and PostgREST endpoints directly. The
project's service-role key is not needed by the app or these RPCs. Every write
requires `auth.uid()`, owner/recipient membership checks and a locked connection.
Direct writes are not granted to client roles. Snapshot reads use RLS and require
an active, unexpired link with an allowed page. Database functions also check the
same boundaries because security-definer functions execute with elevated rights.

Invitations use a random 192-bit token, store its SHA-256 hash only, expire after
24 hours and can be accepted once by a different authenticated identity. Links
expire after 90 days. Selected snapshots expire after seven days. Only allowlisted
fields enter the HTTP body, and the server filters again. No raw log or period
history, reproductive measurements, medication or general notes are uploaded.
A separately selected written partner note is the only free-text note field.

## Lifecycle and privacy

Mount `PartnerSyncBoundary` once around routed app content. It reacts to local
record changes and periodically synchronizes while the app is foregrounded.
It publishes only owner links with saved ongoing-sharing consent. It does not
install a background service and does not promise OS-level background delivery.
Recipients check for updates while the app is open or with Refresh. Failed
requests stay visible and never become a fabricated Connected/Delivered result.

The receiver shows the latest received date rather than advancing a received
cycle into imagined new periods. Calendar dates are shared estimates. History is
only updates this phone received, not private owner history. Online permission
withdrawals filter or purge cached history on the next successful server check.
Every opened history screen rechecks current grants, revocation and actual expiry.

Deleting tracking records first persists a local upload pause, waits for an
already-running sync, refreshes the server's connection list and revokes every
connection owned by this identity. If that cannot be confirmed, deletion is
blocked and records and credentials remain available for retry. A failed pause
write is reported separately; the app does not claim it survived a restart.
Explicitly creating a new invitation or saving permissions with updates enabled
is required to resume this device's uploads. Other app data and prior exported or
offline copies are not erased by deleting tracking records.

Revocation removes the server snapshot and prevents future reads immediately.
An offline phone cannot learn that a server-side revocation happened until it
reconnects; its existing copy can remain until expiry. Copied/exported data cannot
be remotely erased. Settings remain available after data access is withdrawn.

## Two-phone acceptance checks

These checks require a deployed project; local mocked transport tests alone do
not establish a working two-phone connection.

- With all fields/pages off, create an invite. Accept it on phone B; confirm no
  private values appear. Reject reuse, expired codes, self-accept and a third
  identity trying to fetch/publish/revoke another pair.
- On phone A select only Home, phase and mood, review the exact preview and save
  ongoing-sharing consent. Phone B refreshes and sees only those fields. Neither
  fertile dates, pain, symptoms, name nor notes appear unless individually enabled.
- Change a recorded mood on A while the app is open. B receives the update after
  refresh/foreground polling. Stop ongoing updates: no new snapshot is served.
- Enable Calendar separately and verify only shared dates appear as estimates.
  Switching Calendar off immediately blocks server access and the client page
  after refresh; the partner's own Settings stay accessible.
- Disable a field and refresh B. Check current and earlier received updates no
  longer expose that field. Open an older update before revocation; revoke on A,
  refresh B and confirm the already-open archive route also withdraws access.
- Test airplane mode, expired snapshots, timeout, rejected JWT and token refresh.
  Cache shows its actual age and never claims a fresh network check after failure.
- Revoke A's connection; B loses server access. Disconnect on B; further owner
  publishing fails. Confirm every pair's records remain inaccessible to a third UID.

## Evidence boundary

During local implementation the Supabase CLI reported that no access token was
provided. No migration or edge function was deployed by the agent at that point.
The public project URL alone does not authorize deployment. Record actual deployed
SQL tests and two-phone results separately before calling ongoing sync verified.

Sources: [Supabase anonymous sign-ins](https://supabase.com/docs/guides/auth/auth-anonymous),
[row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security),
[API security](https://supabase.com/docs/guides/api/securing-your-api).
