# CycleCare 2.3.0 test preview

This is a review build. The owner has not approved a final release.

The side-by-side Android preview is built with `cyclecareSideBySide=true`,
application ID `com.lekhanpro.cyclecare.debug` and the development signing key.
It installs separately from the public `com.lekhanpro.cyclecare` release and
therefore has its own local records. The normal release build retains the public
application ID and the configured release signing key.

## Changes under review

- Constraint-driven layout respects asymmetric display cutouts, keyboard
  insets, compact widths and large text; the navigation floats in a bounded
  translucent surface. A specific Vivo model was not available to test.
- Each tracking goal has an introduction and dashboard; changes require
  confirmation, preserve existing records, and do not activate pregnancy mode.
  The optional ten-step tour opens real screens and keeps navigation accessible.
- The four original companions retain their 36 local action films and touch
  responses. Optional care tasks use actual daily observations, an explicit
  water-entry confirmation and a once-per-day reward claim.
- The assistant supports a private offline article search, plus explicitly
  configured Gemini or an HTTPS-hosted compatible model using a user-supplied
  key. See [model research](assistant-models.md).
- A separate partner dashboard supports manually received snapshots and a
  consent-based online connection. Online synchronization requires the
  project's migration and safe endpoint to be deployed, anonymous Auth enabled,
  a publishable key and successful two-device verification. No service-role key
  belongs in the app. The source is prepared; deployment is not asserted here.

## Evidence and boundaries

The full local suite passed 501 tests with 65 optional screenshot cases skipped;
the explicit light/dark Flutter screenshot matrix passed all 54 cases. Focused
tests cover 320–844dp layouts, 1–2× text, asymmetric safe insets, navigation,
keyboard clearance, onboarding, consent and pet reward persistence. The partner
SQL was executed against a local PostgreSQL-compatible engine with `pgcrypto`;
participant isolation, page/field filtering, withdrawal, single-use pairing,
expiry and revocation were checked. It is not a deployed Supabase integration
test. The CI and release workflows run that same database contract suite.

The pet task concept uses self-monitoring and optional rewards. A [systematic
review](https://pubmed.ncbi.nlm.nih.gov/37794916/) found associations between
some behavior-change techniques and app engagement, but this does not establish
that CycleCare improves adherence or health outcomes. No universal water or
sleep target is imposed. Reward animations never imply a health action occurred.

Android emulator captures use fictional, isolated records. Real-device rendering,
screen-reader behavior, provider generation with a valid key and live two-phone
sync remain separate verification steps. Cycle and fertility figures are estimates.
