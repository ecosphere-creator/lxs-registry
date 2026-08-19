# profile-ui changelog

## 1.0.0 (2026-08-19)
- Logging contract: service logs now emitted as newline-delimited JSON (NDJSON) to stdout per the platform LXS logging contract (`ts`/`level`/`msg` + optional `service`,`request_id`,`status`,`latency_ms`,`user_id`,`error`). Breaking change — log output format changed.

## 0.1.0 — initial

White-label profile edit page (name, avatar, cover) for the profile LXS. 1.2 MB binary.
