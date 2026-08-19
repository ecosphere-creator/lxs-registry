# chat API

Base path: `/api/chat` (plus bare `/health`). Auth: `Authorization: Bearer
<HS512 JWT>` — `sub` claim is the user id, validated against `JWT_SECRET`.
Missing/invalid token → **401**; authenticated but not a conversation
participant → **403**. Errors: `{ "error": "message" }`.

## Endpoints

### GET /health
- **Purpose:** Liveness probe (also mounted at `/api/chat/health`).
- **Auth required:** no
- **Success 200:** `text/plain` — `OK - persistent chat domain`
- **Errors:** none

### GET /api/chat/health
- **Purpose:** Alias of `/health` for the estate gateway.
- **Auth required:** no
- **Success 200:** `text/plain` — `OK - persistent chat domain`

### GET /api/chat/stickers
- **Purpose:** Return the sticker catalog (packs + sticker ids/labels).
- **Auth required:** no
- **Success 200:** JSON
  ```json
  {
    "packs": [
      {
        "id": "politik-indonesia",
        "name": "Indonesian Politics",
        "preview_url": "/api/chat/stickers/politik-indonesia.webp",
        "stickers": [ { "id": "politik-bung-karno", "label": "Freedom!" } ]
      },
      {
        "id": "internet-klasik",
        "name": "Classic Internet Memes",
        "preview_url": "/api/chat/stickers/internet-klasik.webp",
        "stickers": [ { "id": "classic-you-dont-say", "label": "You don't say" } ]
      },
      {
        "id": "emoji-reaksi",
        "name": "Emoji Reactions",
        "stickers": [ { "id": "emoji-thumbsup", "label": "👍" } ]
      }
    ]
  }
  ```
  Note: the `emoji-reaksi` pack has no `preview_url` (no sheet file exists).
- **Errors:** none

### GET /api/chat/stickers/:pack.webp
- **Purpose:** Serve the sticker sheet image for a pack. Only
  `politik-indonesia` and `internet-klasik` have sheets compiled into the
  binary.
- **Auth required:** no
- **Path param:** `pack` (e.g. `politik-indonesia.webp`)
- **Success 200:** `image/webp`, `Cache-Control: public, max-age=86400`
- **Errors:**
  - 404 — pack has no sheet (e.g. `emoji-reaksi.webp`)

### GET /api/chat/conversations
- **Purpose:** List conversations the authenticated user is a participant of,
  newest `updated_at` first.
- **Auth required:** yes
- **Success 200:** JSON array
  ```json
  [
    {
      "conversation_id": "c4c74d7d-3a4b-4b4f-9f0c-...",
      "kind": "direct",
      "participant_ids": ["u1", "u2"],
      "context": { "domain": "marketplace", "reference_id": "item-1", "title": null },
      "created_at": "2026-08-02T15:01:01.914538Z",
      "updated_at": "2026-08-02T15:01:01.914538Z"
    }
  ]
  ```
- **Errors:**
  - 401 — `Missing bearer token` / `Invalid or expired token`

### POST /api/chat/conversations
- **Purpose:** Create a conversation.
- **Auth required:** yes
- **Body params:**
  | Param | Type | Required | Notes |
  |---|---|---|---|
  | `participant_ids` | string[] | yes | sorted + deduped server-side; must be ≥2 |
  | `kind` | string | no | default `"direct"` |
  | `context.domain` | string | yes | e.g. `marketplace` |
  | `context.reference_id` | string | yes | non-empty required (e.g. listing id) |
  | `context.title` | string | no | nullable |
- **Success 201:** the created conversation (same shape as list item), with
  server-generated UUID `conversation_id`.
- **Errors:**
  - 400 — `At least two participants and a context reference are required`
  - 403 — `Conversation creator must be a participant`
  - 401 — missing/invalid token

### GET /api/chat/conversations/:id/messages
- **Purpose:** List messages in a conversation, oldest first.
- **Auth required:** yes (+ participant)
- **Query params:**
  | Param | Type | Required | Notes |
  |---|---|---|---|
  | `before` | string (RFC3339) | no | return only messages older than this timestamp; ignored if unparseable |
  | `limit` | int | no | default 50, clamped to 1..100 |
- **Success 200:** JSON array of messages (see `ChatMessage` shape under
  POST messages), `created_at` ascending.
- **Errors:**
  - 404 — `Conversation not found`
  - 403 — `Only conversation participants may access this resource`
  - 401 — missing/invalid token

### POST /api/chat/conversations/:id/messages
- **Purpose:** Send a message to a conversation. Persists to the Redis stream
  `chat:messages` (drained to MongoDB by a background worker) and broadcasts
  it to the conversation's WebSocket subscribers.
- **Auth required:** yes (+ participant)
- **Body params:**
  | Param | Type | Required | Notes |
  |---|---|---|---|
  | `sender_id` | string | ignored | always overridden with the authenticated user |
  | `body` | string | no | trimmed; at least one of body/sticker/offer/attachments required |
  | `sticker_id` | string | no | nullable |
  | `offer_amount` | number | no | nullable; must be finite and > 0 if present |
  | `attachments` | object[] | no | `{ key, filename, content_type, size }` |
  | `kind` | string | no | e.g. `"sale"` |
  | `sale` | object | no | `{ title, buyer_id, buyer_name, final_price }` |
- **Success 201:** JSON
  ```json
  {
    "message_id": "9d3d77b3-8d7e-4e7e-8a3f-...",
    "conversation_id": "c4c74d7d-3a4b-4b4f-9f0c-...",
    "sender_id": "u1",
    "body": "hello",
    "sticker_id": null,
    "offer_amount": null,
    "attachments": [],
    "kind": null,
    "sale": null,
    "created_at": "2026-08-02T15:01:01.914538Z"
  }
  ```
  (`kind`/`sale` are omitted when null; `sticker_id`/`offer_amount` serialize
  as `null`.)
- **Errors:**
  - 400 — `Message content is required` or `Offer amount must be a positive number`
  - 404 — `Conversation not found`
  - 403 — `Only conversation participants may access this resource`
  - 502 — `Redis service unavailable` / `Redis stream write failed`
  - 401 — missing/invalid token

### POST /api/chat/conversations/:id/attachments
- **Purpose:** Upload an attachment for a conversation. Proxies the file to
  the configured Storage domain (`{STORAGE_API_URL}/storage/objects`) with
  `namespace=chat` and `reference_id=<conversation id>`, then persists only
  the returned object key.
- **Auth required:** yes (+ participant)
- **Multipart fields:**
  | Field | Type | Required | Notes |
  |---|---|---|---|
  | `owner_id` | string | yes | must equal the authenticated user |
  | `file` | file | yes | size capped at 2 MB |
- **Success 201:** JSON
  ```json
  {
    "key": "<storage object key>",
    "filename": "photo.jpg",
    "content_type": "image/jpeg",
    "size": 1048576
  }
  ```
- **Errors:**
  - 400 — `Invalid multipart form`, `owner_id is required`, `file is required`,
    `Chat attachment size is limited to 2 MB`, `Invalid content type`
  - 403 — `owner_id must match the signed-in user`
  - 404 — `Conversation not found`
  - 502 — `Storage service unavailable` / `Storage returned an invalid response`
  - other — Storage rejection is forwarded with its status + `error` body

### POST /api/chat/marketplace/sale-announcement
- **Purpose:** Announce a completed marketplace sale. For every marketplace
  conversation whose `context.reference_id == item_id` and that includes the
  seller, posts a system message (`kind: "sale"`); the buyer gets a
  congratulations message, other participants get a negotiation-closed message.
- **Auth required:** yes (seller)
- **Body params:**
  | Param | Type | Required |
  |---|---|---|
  | `item_id` | string | yes |
  | `title` | string | yes |
  | `buyer_id` | string | yes |
  | `buyer_name` | string | yes |
  | `final_price` | number | yes |
- **Success 200:** `{ "notified": 2 }`
- **Errors:** same auth/error shape as other endpoints.

### GET /api/chat/conversations/:id/ws
- **Purpose:** WebSocket stream for one conversation. Upgrade with
  `?token=<HS512 JWT>` (query param, not header).
- **Auth required:** yes (token in query) (+ participant)
- **Server → client frames** (JSON, tagged):
  ```json
  { "type": "message", "message": { "...ChatMessage..." } }
  { "type": "typing", "sender_id": "u2", "is_typing": true }
  ```
- **Client → server frames** (JSON):
  ```json
  { "type": "typing", "is_typing": true }
  ```
  or a full `SendMessage` body (no `type` field) — sent as a message.
- **Notes:** token is validated once at connect time only; the connection
  stays open until TCP dies. The server sends no ping frames. The broadcast
  buffer is 100 frames; lagging clients silently skip missed frames (no
  resend) — the REST `GET messages` endpoint is the source of truth.
- **Errors before upgrade:**
  - 401 — `Invalid or expired token`
  - 404 — `Conversation not found`
  - 403 — `Only conversation participants may access this resource`

## Error reference

| Code | Status | Body | When |
|---|---|---|---|
| 401 | Unauthorized | `{"error":"Missing bearer token"}` | no `Authorization: Bearer` header |
| 401 | Unauthorized | `{"error":"Invalid or expired token"}` | JWT fails HS512 verify/expiry (REST or WS `token`) |
| 403 | Forbidden | `{"error":"Only conversation participants may access this resource"}` | authenticated but not a participant |
| 403 | Forbidden | `{"error":"Conversation creator must be a participant"}` | creator not in `participant_ids` |
| 403 | Forbidden | `{"error":"owner_id must match the signed-in user"}` | attachment `owner_id` mismatch |
| 400 | Bad Request | `{"error":"..."}` | validation failures (see endpoints) |
| 404 | Not Found | `{"error":"Conversation not found"}` | unknown conversation id |
| 500 | Internal Server Error | `{"error":"Internal chat error"}` | Mongo/DB failure |
| 502 | Bad Gateway | `{"error":"Redis service unavailable"}` / `{"error":"Redis stream write failed"}` / `{"error":"Storage service unavailable"}` / `{"error":"Storage returned an invalid response"}` | dependency down/bad reply |

## Rate limiting / limits

None in code (no per-IP or per-user throttling). Attachment uploads are capped
at 2 MB (`MAX_CHAT_ATTACHMENT_BYTES`). Message list `limit` clamped to 1..100.
WebSocket broadcast buffer is 100 frames per conversation.
