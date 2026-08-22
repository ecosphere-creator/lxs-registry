# profile-ui changelog

## 3.0.1 (2026-08-23)
- Recover the browser session from the gateway `eco_token` cookie when
  `localStorage.eco_session` is missing. A user authenticated through an
  SSR/Gateway page can now open profile settings without an erroneous redirect
  to sign-in.

## 3.0.0 (2026-08-22)
- Settings now update name, bio, and avatar through the canonical
  `/api/profile/users/<id>` gateway prefix.
- Added signed-in password change through Auth and removed LXS-branded
  decorative copy from the white-label UI.

## 1.0.0 (2026-08-19)
- Logging contract: service logs now emitted as newline-delimited JSON (NDJSON) to stdout per the platform LXS logging contract (`ts`/`level`/`msg` + optional `service`,`request_id`,`status`,`latency_ms`,`user_id`,`error`). Breaking change — log output format changed.

## 0.1.0 — initial

White-label profile edit page (name, avatar, cover) for the profile LXS. 1.2 MB binary.
