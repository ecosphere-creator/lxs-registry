# notifications — LXS docs

## Capability

Persistent, realtime in-app notifications. Stores notifications, per-user
read/unread state, and unread counts in MongoDB, exposes a REST API for
history / read / unread-count, and streams live push to each user over a
per-user WebSocket (`/api/notifications/ws?token=…`). Producers push
notifications to explicit `recipient_ids`; consumers subscribe per user and
get count + notification updates in realtime.

## What it owns / never owns

- **Owns:** notification documents, read/unread state, unread counts in
  MongoDB; the per-user realtime WebSocket stream.
- **Never owns:** email delivery (stays in the Auth domain — this domain is
  in-app only). Web Push (FCM/APNs) — can be added behind the same boundary
  later. Recipient inference — a producing domain authenticates the acting
  user and lists the target `recipient_ids`; this domain never infers
  recipients from a token. Notification content is generic (`kind` +
  `title`/`body` + optional `link`/`referenceId` to the destination resource).

## Compose it

```yaml
# ecompose.yml
services:
  notifications-backend:
    lxs: notifications@1.0.2
    grants:
      secrets: [PORT, API_BASE_PATH, MONGODB_URI, JWT_SECRET]
```

## Quick usage

```bash
# Health (two aliases, both unauthenticated)
curl -s http://localhost:8090/health                      # {"status":"OK"}
curl -s http://localhost:8090/api/notifications/health    # {"status":"OK"}

# Per-user history (Bearer HS512 JWT from auth)
curl -s http://localhost:8090/api/notifications \
  -H "Authorization: Bearer $TOKEN"                       # [Notification]

# Unread count
curl -s http://localhost:8090/api/notifications/unread-count \
  -H "Authorization: Bearer $TOKEN"                       # {"unread_count":3}

# Realtime stream (token in query string, per user)
wscat -c "ws://localhost:8090/api/notifications/ws?token=$TOKEN"
# first frame: {"type":"init","unread_count":3,"notifications":[...last 50...]}
```

## Docs index

- `api.md` — full endpoint reference with request/response JSON and errors
- `examples.sh` — executable smoke test (golden request→response pairs)
- `openapi.json` — machine-readable OpenAPI 3.0 spec
- `changelog.md` — version history + breaking changes
- `gotchas.md` — production-learned constraints and operational gotchas

## For AI agents

This LXS is distributed as a **binary only** — these docs are the entire
interface. Match `api.md` shapes exactly; run `examples.sh` against a pulled
binary or live estate URL before trusting behavior. See
`docs/gotchas.md` for constraints that are invisible in the binary (notably:
the in-memory WS hub is per-instance, and `CORS_ALLOWED_ORIGINS` /
`API_BASE_PATH` are declared but not read by the code).
