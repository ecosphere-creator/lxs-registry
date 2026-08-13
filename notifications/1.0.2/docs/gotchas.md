# Gotchas

Production constraints that are NOT visible in the binary. Source: code
comments in `backend/src/lib.rs`, `main.rs`, `.env.example`, and CLAUDE.md.

- **CLAUDE.md says Go; the code is Rust.** CLAUDE.md still describes
  `backend/` as "Go 1.19 with MongoDB". It was rewritten to Rust (axum 0.7 +
  tokio + mongodb) in commit `816bdbd`. Trust the Rust source, not the doc.
- **`CORS_ALLOWED_ORIGINS`, `API_BASE_PATH`, `AUTH_BASE_URL` are declared but
  unused.** `.env.example` and `lxs.yml` list them, but the Rust code never
  reads them: CORS is hardcoded to allow **any** origin/method/header
  (`CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any)`),
  and routes are hardcoded under `/api/notifications`. If you need locked-down
  CORS, this binary cannot provide it via env.
- **The WS hub is in-memory and per-instance.** `Hub` lives in `AppState`;
  broadcasts are lost on restart and are not shared across replicas. If the
  service is scaled to multiple instances, swap the in-memory `broadcast`
  channel for a Redis pub/sub channel (the producer-facing REST contract is
  unchanged). A user's live push only works while connected to the instance
  that received the ingest.
- **WebSocket backpressure is silently lossy.** Each user channel is a
  `tokio::sync::broadcast` channel with capacity **100**. A slow consumer
  causes `RecvError::Lagged` which is swallowed (`Err(_) => {}`), so missed
  frames are dropped. Clients must re-sync from `GET /api/notifications` /
  `unread-count` (the `init` frame only fires once, on connect).
- **`JWT_SECRET` empty ⇒ everything protected 401s.** bootstrap defaults it
  to `""`; with an empty key, HS512 decode fails for every token. There is no
  startup guard (unlike profile, which refuses to boot).
- **`MONGODB_URI` default points at localhost.** Default is
  `mongodb://127.0.0.1:27017/notifications`; the database name comes from the
  connection string (else `notifications`). A unique index on `id` and a
  compound `{userId:1, createdAt:-1}` index are created at bootstrap.
- **Notification `id` is not a UUID.** It is 12 random bytes hex-encoded
  (24 chars) generated server-side via `rand::random()`. It is the key for
  `POST /api/notifications/{id}/read` and must not be confused with the Mongo
  `_id` (ObjectId, also 24-hex).
- **`mark_one_read` and `mark_all_read` always return `ok:true`** even when
  nothing matched — they do not report a 404 or a matched-count.
- **No rate limiting** anywhere in the service; only the `limit` query cap
  (`100`) bounds a list response.
- **Ingest accepts an empty recipient list** and returns
  `{"ok":true,"notified":0}` rather than an error. `recipient_ids` are
  trimmed, sorted, and deduped server-side; duplicates across producers are
  collapsed into one row per recipient per ingest call.
- **Ingest has no role or ownership check** — any valid JWT can create
  notifications addressed to anyone in the estate. Producers must
  authenticate the acting user themselves before calling ingest.
- **Recipients are never inferred from the token.** The acting user's `sub`
  is discarded after verification (`let _user_id = auth_user(...)?`); only
  `recipient_ids` decides delivery.
- **No email / Web Push** — in-app only by design; email lives in the Auth
  domain.
