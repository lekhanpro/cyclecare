# Partner database contract checks

Run from the repository root:

```sh
npm ci --prefix test/backend/partner-db
node test/backend/partner-db/validate.mjs
```

This runs migration 002 against an isolated in-memory PGlite PostgreSQL engine
with the real pgcrypto extension, fictional users, authenticated/anonymous roles,
and a test implementation of Supabase's `auth.uid()`. It checks pairing,
participant isolation, selected fields and page grants, paused and revoked
sharing, token reuse, malformed consent, and expiration. It does not connect to
or change a Supabase project, exercise GoTrue authentication, or replace testing
the deployed migration and policies on two actual devices.
