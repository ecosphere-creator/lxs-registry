# Changelog

Version history for `slides`. The next release is **1.0.1**; the currently
published LXS is **1.0.0** (registry `lxs.yml` version field). Release
boundaries below are approximated from the git log since the registry
`release:` list is empty.

## 1.0.1 (next release)

- `scripts/convert_eco_docs.py` + `scripts/import_decks.py`: markdown → SlideDeck converter and Mongo seeder for example content (getecosphere homepage demo).

## 1.0.0 — packaged as reusable LXS

- Package `slides` as a reusable LXS (`slides@1.0.0`) for Eco Creator,
  consumable via `ecompose.yml` (`0bed3fa`).
- Switch slide-image WebP re-encoding from lossless to **lossy quality 80** —
  lossless was inflating recompressed JPEGs 5x+ instead of shrinking them
  (`e6890e5`).
- Add S3/MinIO storage backend for slide files, selectable via
  `STORAGE_BACKEND` (local disk remains the default) (`cdfeb97`).
- Fix author image library being gated on platform `OWNER` — now uses the
  same `OWNER`/`MENTOR`/`MEMBER` author roles as the rest of the domain, so
  non-owner authors can use their own image library (`f700675`).
- Add per-source-IP rate limiting (burst + refill tunable via env) (`95c6cda`).
- Switch to structured JSON logs + per-request correlation ids
  (`x-request-id`), forwarded to auth/payments/community peers (`49ef98a`).
- Add the integration test suite (`00ec217`).
- Register domain-prefixed `/slides-files/*` file routes alongside the bare
  `/files/*` so the estate gateway can route file requests by path (`f09c6cf`).
- Add guided-narration audio upload (`type=slide-narration`), stored raw
  (`7d6183e`).
- Initial port of the full deck/editor/poll/session domain from `lms-backend`
  Java, including the ownerId-spoofing and unauthenticated `GET /book/owner/{id}`
  security fixes and the DTO/bson conversions (`0a59e5f`, `cf280da`,
  `8b9a7a5`).
- Fix malformed peer-dependency line in `.env.example` (`0d51db0`).

## 0.x — scaffold

- Scaffold the slides domain service (Rust/axum): boots, connects to MongoDB,
  validates JWTs issued by `auth`, estate standard security baseline
  (`8b9a7a5`).
