# Changelog

## 2.0.0 (2026-08-19)
- Logging contract: service logs now emitted as newline-delimited JSON (NDJSON) to stdout per the platform LXS logging contract (`ts`/`level`/`msg` + optional `service`,`request_id`,`status`,`latency_ms`,`user_id`,`error`). Breaking change — log output format changed.

## 1.0.2 (next release)
- English translations for user-facing API/error messages (`05496ad`)
- Add Communication category to the LXS manifest (`31dc6c1`)

## 1.0.0
- initial release — LXS manifest `chat@1.0.0` published with MongoDB
  persistence, REST + WebSocket API, sticker catalog, and attachment proxy
  (`f6e1dbf`). No release notes recorded upstream; pre-manifest development
  history includes:
  - WebSocket auth via JWT (`72efe76`) with 401 (not 403) for
    missing/invalid tokens (`0c5b889`)
  - WS stays open when a client lags the broadcast buffer; keep-alive is
    infra-owned, frontend reconnect uses exponential backoff (`f9e6223`,
    `d412d3e`)
  - Message persistence through Redis stream `chat:messages` with
    background drain to MongoDB (`d18b922`, `7b1aa69`, `130f8ec`,
    `19c4a90` — mixed legacy timestamp decode)
  - Attachments: persist across participants (`a3f905c`), align with storage
    response (`d5e32f0`), report failures (`44e7aac`), 2 MB cap (`baa1c1e`)
  - Typing events (`9e27f3b`), sale announcements with role-aware metadata
    (`8fddc64`, `9713b68`), in-app push notifications for new messages
    (`4d324f8`), i64 `exp` claim (`ea726cf`), chat API base path (`65e845b`),
    single-binary composition via `bootstrap()` (`a20c66c`), initial commit
    (`ef9f964`)
