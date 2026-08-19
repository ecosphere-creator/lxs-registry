# chat — LXS docs

## Capability

Reusable bounded context for persistent private conversations. Gives a composed
estate REST CRUD for conversations and messages, a per-conversation WebSocket
stream (messages + typing), a sticker catalog, and attachment uploads that
proxy to the Storage domain. Pick this LXS when you need durable 1:1 or group
threads with realtime delivery backed by MongoDB + Redis, where caller identity
is supplied by the estate's own auth layer.

## What it owns / never owns

- **Owns:** conversations, participants, message ordering, sticker metadata
  (MongoDB `conversations` + `messages` collections), the realtime stream per
  conversation (in-process broadcast + Redis stream `chat:messages`),
  in-app notification triggers on new messages.
- **Never owns:** object storage — attachments are uploaded through
  `POST /api/chat/conversations/:id/attachments`, which proxies to the
  configured Storage domain and persists only the returned object key.
  Auth/session — caller identity is explicit (`sender_id` / `participant_id`)
  at the boundary; the estate must authenticate the caller first. Marketplace
  persistence — listing IDs live only as `context.reference_id`.

## Compose it

```yaml
# ecompose.yml
services:
  chat-backend:
    lxs: chat@1.0.2
    grants:
      secrets: [SERVER_PORT, API_BASE_PATH, MONGODB_URI, REDIS_URL, JWT_SECRET]
```

## Quick usage

```bash
BASE=http://127.0.0.1:26377
TOKEN=$(mint_jwt "$JWT_SECRET" "$USER_ID")   # HS512, sub = user id

curl -s "$BASE/api/chat/conversations" -H "Authorization: Bearer $TOKEN"

# create a conversation (creator must be a participant)
curl -s -X POST "$BASE/api/chat/conversations" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"participant_ids":["u1","u2"],"kind":"direct",
       "context":{"domain":"marketplace","reference_id":"item-1"}}'

# realtime stream (token in query string)
wscat -c "$BASE/api/chat/conversations/<id>/ws?token=$TOKEN"
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
`docs/gotchas.md` for constraints that are invisible in the binary.
