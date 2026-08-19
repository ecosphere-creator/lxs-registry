# Changelog

## 3.0.0 (2026-08-19)
- **Single-session enforcement at the edge.** The gateway re-validates each
  protected request's `sid` against auth's `session-status` endpoint
  (`AUTH_SESSION_CHECK_URL`, injected by configgen). A token whose session was
  revoked by a newer login is denied 401 — the same account can no longer be
  signed in on two devices anywhere in the estate. Fails closed: without the
  check URL the gateway denies rather than trusts.
- **Breaking:** bearer tokens without a `sid` claim are rejected when
  `SESSION_REQUIRED` is true (default) — every client must re-login once after
  upgrade. Set `SESSION_REQUIRED=false` for a graceful legacy window.
- Contract: added optional `AUTH_SESSION_CHECK_URL` (managed:
  auth-session-check) and `SESSION_REQUIRED`; contract upgraded to v2
  `fields` schema.

## 2.0.0 (2026-08-19)
- Logging contract: service logs now emitted as newline-delimited JSON (NDJSON) to stdout per the platform LXS logging contract (`ts`/`level`/`msg` + optional `service`,`request_id`,`status`,`latency_ms`,`user_id`,`error`). Breaking change — log output format changed.

## 0.4.0

- the built-in 401 error page now renders a "Sign in" button linking to
  `/signin`; the new `{{ACTION}}` token lets custom error pages show a
  status-appropriate recovery link (empty when there's nothing to recover to)

## 0.2.0

- content-negotiated error pages: API clients get JSON, browsers get a styled
  HTML error page following the Ecosphere design system (default built in)
- undeclared routes now return `404` instead of `403` (the resource simply
  isn't routed; `401`/`403` still mean authorization failures)
- `error_page` config field: estate templates with `{{STATUS}}`/`{{TITLE}}`/
  `{{MESSAGE}}`/`{{METHOD}}`/`{{PATH}}`/`{{ESTATE}}` tokens, wired by configgen
  from `error_page:` in `ecompose.yml`; HTML pages never leak internal topology

## 0.1.0

- initial publish — the estate front door (default-deny reverse-proxy + JWT/role authorization)
- multi-arch artifacts: linux/amd64, linux/arm64, darwin/arm64, darwin/amd64, windows/amd64
