# Gotchas

Production constraints that are NOT visible in the binary — from code comments
and `CLAUDE.md`.

- **Paywall is disabled.** `PAYWALL_ACTIVE = false` in
  `handlers/slide_decks.rs` makes `can_access` short-circuit to `true`: every
  published deck is fully public, and `GET /book/:id` returns the full deck to
  anyone (no redaction). The `payments`/`community` access chain is retained
  and type-checked but never consulted. Flip the const to `true` when the
  paywall ships — that also makes `auth`/`payments`/`community` reachability
  matter again (see below).
- **`GET /book/import` and `GET /book/:id/export` are explicit 501s.** The
  `.ktt` ZIP archive export/import (`KttArchiveService`) was deliberately not
  ported. Routes return 501, not 404 — treat them as unsupported.
- **`JWT_SECRET` is required and length-checked at startup.** Must be ≥ 32
  bytes (HS512; ≥ 64 recommended — warned, not rejected) and must match the
  estate's shared secret because this service only *validates* auth-issued
  tokens. Known placeholder values (`secret`, `your-secret-key-change-in-production`,
  `change-this-secret`) refuse to start. Missing/short/placeholder secret =
  no boot.
- **Peer services must be reachable.** `can_access` (when the paywall is on)
  calls `auth` (`GET {AUTH_BASE_URL}/auth/users/{id}`), `payments`
  (`GET {PAYMENTS_BASE_URL}/payments/access/slide-deck/{deckId}/user/{userId}`),
  and `community` (`GET {COMMUNITY_BASE_URL}/events/{eventId}/registration/{userId}`).
  Peer failures degrade to "no access" (false), not 500. These are plain HTTP
  calls with no end-user auth forwarded — they must run inside the estate's
  private network, never exposed to the public frontend. Peer URLs default to
  `localhost` ports (9001/9014/9011) — wrong outside a single host.
- **`GET /book/owner/:owner_id` requires being that owner or a platform
  `OWNER`.** This was the most serious fix in the port (the Java version
  returned any author's full draft/paid content to anyone). An anonymous or
  third-party caller gets 403.
- **`ownerId` in a deck body is ignored.** Deck ownership is always the
  authenticated caller; clients cannot spoof it.
- **Slug is immutable once `published`.** `PUT /book/:id` on a published deck
  with a changed `slug` fails with 400. Publishing itself requires non-empty
  `name`, `coverUrl`, and `description` (Indonesian error messages).
- **Rate limiting is per source IP** (tower_governor, `SmartIpKeyExtractor`),
  shared across all routes. Defaults: burst 120, refill 1/sec. Behind a shared
  gateway or NAT, all users collapse into one bucket — tune
  `RATE_LIMIT_GENERAL_BURST` for estate traffic or the 429s will be confusing.
- **Request body limit is a hardcoded 10 MB** (`MAX_BODY_BYTES`), NOT
  env-driven. File uploads are buffered fully in memory (`field.bytes()`), so
  a large slide image/audio under 10 MB works, above gets a generic 413 from
  the middleware (not the AppError shape). Slide images are re-encoded to
  lossy WebP (quality 80) and pixel-capped at 30,000,000 px (`MAX_IMAGE_PIXELS`).
- **File view endpoints are unauthenticated** (`GET /files/view/:id` and
  `/slides-files/view/:id`) — deck image/audio URLs are public by design. Do
  not put private content there.
- **File URLs are gateway-routable under `/slides-files`.** Uploads return
  `{API_BASE_URL}/slides-files/view/{fileId}`, not `/files/view/{fileId}`, so
  the shared estate gateway can route to this domain by path. Both route sets
  work; prefer `/slides-files/*`.
- **Storage is local disk by default.** `STORAGE_BACKEND` defaults to `local`
  (files under `STORAGE_LOCAL_PATH`, default `./storage`). Set
  `STORAGE_BACKEND=s3` + `S3_ENDPOINT`/`S3_BUCKET`/`S3_ACCESS_KEY`/
  `S3_SECRET_KEY` for MinIO/S3; startup fails fast if S3 is misconfigured.
  MinIO requires `force_path_style` (path-style addressing) — the client is
  built that way.
- **The frontend (Leptos) is external.** This LXS repo ships the backend and
  the shared-secret consumer contract only; the Leptos frontend referenced in
  `CLAUDE.md` lives elsewhere and must be composed separately.
- **Logs are structured JSON** with a per-request `x-request-id` (reused from
  the incoming header, echoed back, and forwarded to auth/payments/community).
  Set `RUST_LOG` (default `info`) to tune verbosity.
- **`RATE_LIMIT_*` / body-limit / JWT values differ between the shipped
  binary and the `.env.example`** (`.env.example` uses port 9015). Verify the
  deployed env matches what the estate gateway expects.
