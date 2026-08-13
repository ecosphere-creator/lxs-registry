# Gotchas

Production-learned constraints not visible in the binary:

- **`JWT_SECRET` has no default** and the binary does not refuse to start with
  it empty (`std::env::var("JWT_SECRET").unwrap_or_default()`). An empty secret
  verifies any HS512 token signed with the empty key — tokens are then trivially
  forgeable. The operator **must** set a real `JWT_SECRET`.
- **`API_BASE_PATH` and `CORS_ALLOWED_ORIGINS` are declared but ignored.**
  Routes are hardcoded as `/api/chat/...` (and bare `/health`) in
  `build_router`, and CORS is `allow_origin(Any)` / allow-methods / allow-
  headers `Any`. Changing `API_BASE_PATH` in `.env` has no effect on routing.
- **WebSocket has no keep-alive.** The server never sends ping frames; idle
  connections are dropped by the infra chain (Caddy gateway + Cloudflare
  Tunnel). The frontend must reconnect with exponential backoff (1s → 15s cap)
  and re-validate its session token first.
- **WS token checked once, at connect.** No expiry re-check for the lifetime
  of the connection; a 30-day token holds the socket open until TCP dies.
- **WS broadcast buffer is 100 frames; lagging clients silently lose frames**
  (`RecvError::Lagged` is swallowed, no resend). Realtime is best-effort —
  `GET /api/chat/conversations/:id/messages` is the source of truth.
- **Redis is in the hot path for every message.** `POST messages` XADDs to the
  `chat:messages` stream and fails with 502 if Redis is unreachable; messages
  are not spooled elsewhere. A background worker (~50ms loop) drains the stream
  to MongoDB with `$setOnInsert` upserts and bumps `conversations.updated_at`.
- **Message timestamps are hybrid-decoded.** `created_at`/`updated_at` accept
  BSON DateTime, RFC3339 strings, and extended JSON forms (legacy data). When
  reading old collections, treat both shapes as valid.
- **Attachment uploads require the Storage domain.** Proxies to
  `{STORAGE_API_URL}/storage/objects` as multipart with `namespace=chat` and
  `reference_id=<conversation id>`; the Storage service's status is forwarded
  verbatim. Only the returned object key is persisted (no S3 creds here).
  Attachment size is hard-capped at 2 MB. Only the `politik-indonesia` and
  `internet-klasik` packs ship a sheet file — `emoji-reaksi` returns 404.
- **`sender_id` is always overridden** by the authenticated user on `POST
  messages`; the `offer_amount` must be finite and positive; a message needs
  at least one of body/sticker/offer/attachments or it is rejected.
- **In-app notifications are best-effort.** After a successful send, chat
  POSTs to `{NOTIFICATIONS_API_URL}/ingest` reusing the caller's bearer token;
  failures only log a warning and never fail the request. `NOTIFICATIONS_API_URL`
  is optional (defaults to `http://127.0.0.1:8090/api/notifications`).
- **No rate limiting / throttling.** No per-IP or per-user caps in code; a
  composed estate that needs limits must enforce them at the gateway.
- **MongoDB URI must name a database.** `bootstrap()` fails to start if
  `MONGODB_URI` has no database segment. Unique indexes are created on
  `conversations.conversation_id` and `suppressions.email` at startup.
- **Sticker content is compiled into the binary** (via `include_bytes!`), not
  served from disk at runtime.
