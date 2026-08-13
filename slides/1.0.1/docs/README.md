# slides — LXS docs

## Capability

Slide-deck CMS ("books"): authors create/publish/edit rich slide decks, then
readers view them in the public catalog and in interactive "book sessions"
(per-reader state, history, branching flows, guided reveals) with embedded
polls. Also provides author image libraries, poll-style templates, per-author
editor prefs, and upload/serving of slide images (WebP) and guided-narration
audio. If you need to store, publish, read, and poll slides for an estate, this
is the LXS.

## What it owns / never owns

- **Owns:** slide decks (`SlideDeck` — slides/elements/flows/guided reveals),
  author editor prefs, author image assets, author poll templates, poll votes,
  book sessions, and slide image/narration file records. Mongo-backed.
- **Never owns:** user identity/auth (validates tokens issued by `auth`,
  never issues them), payments/entitlement records (checked via `payments`),
  event registration state (checked via `community`), or the general object
  store (that is `storage`/photos). The paywall access chain is compiled in
  but currently disabled (`PAYWALL_ACTIVE = false` — all published decks are
  fully public).

## Compose it

```yaml
# ecompose.yml
services:
  slides-backend:
    lxs: slides@1.0.1
    grants:
      secrets: [SERVER_PORT, MONGODB_URI, JWT_SECRET]
```

Requires `auth` (JWT validation + `is_platform_owner`), and if the paywall is
ever re-enabled, `payments` and `community`. For S3 file storage set
`STORAGE_BACKEND=s3` plus the `S3_*` vars (and a MinIO/S3-compatible endpoint);
otherwise files land on local disk under `STORAGE_LOCAL_PATH`.

## Quick usage

```sh
# Health (no auth)
curl http://localhost:9015/api/health

# Public catalog (no auth) — published decks only
curl http://localhost:9015/api/book/catalog

# Authenticated endpoints need the estate's shared-secret JWT (HS512):
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"My Deck","status":"draft"}' \
     http://localhost:9015/api/book
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
`docs/gotchas.md` for constraints that are invisible in the binary (paywall
disabled, 501 stubs, peer-service coupling, JWT length rules).
