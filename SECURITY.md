# Security Policy

CycleCare handles sensitive personal health data. All data is stored locally
on-device (see [README.md → Privacy](README.md#privacy)), which limits the
attack surface considerably, but app-lock, PIN hashing, and biometric auth are
all real security boundaries worth reporting issues against.

## Supported Versions

Only the latest published release receives security fixes.

| Version | Supported |
| --- | --- |
| Latest release (see [Releases](https://github.com/lekhanpro/cyclecare/releases)) | ✅ |
| Older releases | ❌ |

## Reporting a Vulnerability

**Do not open a public GitHub issue for a security vulnerability.**

Report privately using one of these methods, in order of preference:

1. [GitHub Security Advisories](https://github.com/lekhanpro/cyclecare/security/advisories/new)
   for this repository (preferred — keeps the report private until resolved).
2. Open a regular issue titled only "Security contact requested" with no
   details, and the maintainer will follow up for a private channel.

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce, or a proof of concept
- The affected version/commit

## What to expect

- Acknowledgement within a few days.
- An assessment of severity and, if confirmed, a fix targeted for the next
  release. This is a solo-maintained project without a dedicated security
  team, so response times are best-effort rather than SLA-backed.
- Credit in the release notes if you'd like it, once the fix ships.

## Scope

In scope:
- The Flutter app in `lib/` (data storage, app lock, PIN/biometric auth,
  encryption in `lib/core/utils/encryption_util.dart`)
- The GitHub Actions workflows in `.github/workflows/`
- The Supabase Edge Functions in `supabase/functions/` (currently unused by
  the client — see the README's [Project status](README.md#project-status) —
  but still live code)

Out of scope:
- Denial of service against your own local device
- Issues that require physical access to an unlocked, unencrypted device
- Third-party dependencies — please report those upstream (though a heads-up
  here is still appreciated if CycleCare is affected)
