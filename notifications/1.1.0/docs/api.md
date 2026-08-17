# notifications API

Base path: `/api/notifications` (plus a bare `/health` alias). Auth: every
data endpoint requires a `Authorization: Bearer <JWT>` header; tokens are
HS512-signed with the estate-shared `JWT_SECRET` and must carry `sub`
(required) and `exp` (required). The WebSocket endpoint takes the token in a
`?token=` query param instead. Errors: `{ "error": "message" }` for auth and
internal failures (there is no structured error body in this service).

## Endpoints

### GET /health
- **Purpose:** liveness probe (alias of `/api/notifications/health`).
- **Auth required:** no
- **Success 200:** `{"status":"OK"}`

### GET /api/notifications/health
- **Purpose:** liveness probe (alias of `/health`).
- **Auth required:** no
- **Success 200:** `{"status":"OK"}`

### GET /api/notifications
- **Purpose:** list the authenticated user's notifications, newest first.
- **Auth required:** yes (Bearer HS512 JWT)
- **Query params:**
  | Param | Type | Required | Notes |
  |---|---|---|---|
  | `limit` | int | optional | default `50`, capped at `100` |
- **Success 200:** JSON array, sorted `createdAt` desc:

  ```json
  [
    {
      "_id": "66f1a2b3c4d5e6f708192021",
      "id": "5f1d2c9a04f3b0e1d2c3b4a5",
      "userId": "507f1f77bcf86cd799439011",
      "kind": "message",
      "title": "New message from Alice",
      "body": "Alice sent you a message",
      "link": "https://example.com/conversations/123",
      "referenceId": "conv_123",
      "read": false,
      "createdAt": "2026-08-12T10:00:00Z"
    }
  ]
  ```

  Field notes: `_id` is the Mongo ObjectId (present on stored docs),
  `id` is the domain notification id (24-hex random) used for
  `/:id/read`, `link`/`referenceId` are omitted when absent.
- **Errors:**
  - 401 → `{"error":"Please provide a Bearer token"}`
  - 401 → `{"error":"Token is invalid or expired"}`
  - 500 → `{"error":"Notification storage is currently experiencing issues."}`

### GET /api/notifications/unread-count
- **Purpose:** count of the authenticated user's unread notifications.
- **Auth required:** yes
- **Success 200:**

  ```json
  { "unread_count": 3 }
  ```
- **Errors:** same 401/500 bodies as list.

### POST /api/notifications/read-all
- **Purpose:** mark all of the authenticated user's notifications as read;
  pushes a live `unread` event to the user's WebSocket.
- **Auth required:** yes
- **Success 200:**

  ```json
  { "ok": true }
  ```
- **Realtime side effect:** sends `{"type":"unread","unread_count":0}` to the
  user's WS channel.
- **Errors:** same 401/500 bodies as list.

### POST /api/notifications/{id}/read
- **Purpose:** mark one notification as read; pushes a live `unread` event
  with the recomputed count. Matches on `id` **and** `userId`, so a user can
  only mark their own.
- **Auth required:** yes
- **Path params:** `id` — the notification `id` (24-hex random id), not the
  Mongo `_id`.
- **Success 200:**

  ```json
  { "ok": true }
  ```
- **Realtime side effect:** sends `{"type":"unread","unread_count":<recounted>}`
  to the user's WS channel.
- **Errors:** same 401/500 bodies as list. Returns `ok:true` even if no
  document matched (upsert semantics are not used; the match simply updates
  zero rows silently).

### POST /api/notifications/ingest
- **Purpose:** producer-facing bulk create. Any valid token may ingest;
  there is no role check. Recipients are explicit — this domain never infers
  them from the token. Recipients may be anyone in the estate.
- **Auth required:** yes (any valid token)
- **Body:**

  ```json
  {
    "recipient_ids": ["507f1f77bcf86cd799439011", "507f191e810c19729de860ea"],
    "kind": "message",
    "title": "New message from Alice",
    "body": "Alice sent you a message",
    "link": "https://example.com/conversations/123",
    "reference_id": "conv_123"
  }
  ```
  | Field | Type | Required | Notes |
  |---|---|---|---|
  | `recipient_ids` | string[] | yes | trimmed, sorted, deduped; empty list is accepted |
  | `kind` | string | yes | free-form category |
  | `title` | string | yes | |
  | `body` | string | yes | |
  | `link` | string | optional | omitted when absent |
  | `reference_id` | string | optional | omitted when absent |
- **Success 200:**

  ```json
  { "ok": true, "notified": 2 }
  ```
  `notified` = number of deduped recipient rows created. If `recipient_ids`
  is empty after cleanup, returns `{"ok":true,"notified":0}` (still 200).
- **Realtime side effect:** for each recipient, sends to that user's WS
  channel `{"type":"unread","unread_count":<recounted>}` followed by
  `{"type":"notification","notification":{...Notification}}`.
- **Errors:** same 401/500 bodies as list.

### GET /api/notifications/ws?token=…
- **Purpose:** per-user WebSocket stream. Upgrades to WS (must send standard
  upgrade headers). On connect the server immediately sends a snapshot, then
  streams live events. This is the only endpoint that authenticates via query
  string, not header.
- **Auth required:** yes — valid HS512 JWT in `?token=` (else 401 JSON).
- **Query params:** `token` (required) — the user's JWT; the stream is for
  `claims.sub`.
- **Success 101 (WebSocket upgrade):**
  1. Initial frame, first message after connect:
     ```json
     {
       "type": "init",
       "unread_count": 3,
       "notifications": [ "...last 50, newest first..." ]
     }
     ```
  2. Live events (one per WS text frame):
     ```json
     { "type": "unread", "unread_count": 0 }
     ```
     ```json
     { "type": "notification", "notification": { "...Notification shape..." } }
     ```
- **Keepalive:** server sends a WS `Ping` every 30s. If the channel lags
  (broadcast capacity 100), missed events are dropped silently; the stream
  survives.
- **Errors:** 401 → `{"error":"Token is invalid or expired"}` (invalid token);
  a non-upgrade request without WS headers is rejected (400, axum default).

## Error reference

| Status | Body | When |
|---|---|---|
| 401 | `{"error":"Please provide a Bearer token"}` | missing/malformed Authorization header |
| 401 | `{"error":"Token is invalid or expired"}` | JWT decode/verify failed |
| 500 | `{"error":"Notification storage is currently experiencing issues."}` | any Mongo error |

## Rate limiting / limits

None documented — the service has no rate limiter. `limit` on list is capped
at `100`; the WS broadcast channel holds `100` queued messages per user.

## Env vars (code-read)

| Var | Default | Read in |
|---|---|---|
| `PORT` | `8090` | main.rs |
| `SERVER_PORT` | — (fallback if `PORT` unset) | main.rs |
| `MONGODB_URI` | `mongodb://127.0.0.1:27017/notifications` | lib.rs bootstrap |
| `JWT_SECRET` | `""` (empty → all authed endpoints 401) | lib.rs bootstrap |

Declared in `lxs.yml` / `.env.example` but **not read** by the Rust code:
`API_BASE_PATH`, `CORS_ALLOWED_ORIGINS`, `AUTH_BASE_URL` (see gotchas.md).
