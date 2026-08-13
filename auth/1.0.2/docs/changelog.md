# Changelog

## 1.0.2 (next)

- `POST /api/auth/verify-password` added — verify the authenticated user's
  password for sensitive-action confirmations (e.g. deleting an account).
- Email verification disabled until Brevo is configured: registration now
  returns 400 when verification is required but `BREVO_API_KEY` /
  `MAIL_FROM_EMAIL` / public URL are missing, so a misconfigured install can
  never create an unusable account. `.env.example` ships
  `EMAIL_VERIFICATION_REQUIRED=false` until a sending key is set.
- i18n: user-facing API and error messages translated to English.
- Single-binary composition: `bootstrap()` added to the `lib` crate so the
  service can be embedded as one LXS binary.

## 1.0.1

Registry-published build (linux/amd64, built 2026-08-12 by eco@0.2.0). This
release carried the mainline Rust rewrite through its first published LXS
artifact:

- Reusable email verification contract: `verification-status`,
  `resend-verification`, `verify-email` (single-use links, TTL
  `EMAIL_VERIFICATION_TTL_HOURS`, default 24 h).
- Generic content-agnostic transactional mail contract (`POST /api/auth/mail`)
  with Stuff8-branded templates for Auth's own verification mail.
- `GET /api/auth/session` — authenticated identity for sibling domains.
- `GET /api/auth/access-rights` — permission tokens (`verified_user` grant
  derived from email verification).
- Default JWT expiration bumped from 24 h to 30 days (`JWT_EXPIRATION`,
  default `2_592_000_000` ms); JWT lifetime/rotation documented.
- S3/MinIO storage backend (`STORAGE_BACKEND=s3`) alongside the default local
  disk storage; avatar/cover re-encode switched from lossless to lossy WebP
  (quality 80), fixing 5x+ size inflation.
- Per-source-IP rate limiting with separate auth and general budgets; usable
  JSON 429 responses; security headers restored (nosniff, frame DENY, etc.).
- Prevent unusable accounts when email delivery is unavailable (rollback of
  unverified new users); static-safe verification URLs routed through the
  public frontend; Brevo acceptance logging.

## v1.0.0

- initial release — first LXS manifest publish (`auth@1.0.0`) of the Rust
  rewrite of the Java auth service (accounts, passwords, JWT, profile
  identity fields, avatar/cover storage, throttling).
