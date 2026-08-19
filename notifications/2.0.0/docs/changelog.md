# Changelog

## 2.0.0 (2026-08-19)
- Logging contract: service logs now emitted as newline-delimited JSON (NDJSON) to stdout per the platform LXS logging contract (`ts`/`level`/`msg` + optional `service`,`request_id`,`status`,`latency_ms`,`user_id`,`error`). Breaking change — log output format changed.

Versions tracked from `git log`, the domain README.md, and the registry
manifest (`lxs.yml`). The manifest's `release:` list is empty and no git tags
exist, so only versions explicitly recorded are listed; 1.0.1 has no record.

## 1.0.2 (next release)
- i18n: translate user-facing API/error messages to English
- chore: add `category: Communication` to the LXS manifest

## 1.0.1
- No notes on record (registry `release:` list is empty; no git tags).

## 1.0.0
- initial release
- Scaffold Go notifications backend, then rewritten to Rust (axum + WebSocket + MongoDB)
- Fix notification `userId`/`referenceId` serialization so list queries match stored documents
- Serve the bare `/api/notifications` list without a redirect
- Add LXS manifest (`notifications@1.0.0`)
