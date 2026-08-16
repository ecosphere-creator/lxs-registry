# profile changelog

## 1.1.0 — avatar ownership (2026-08-16)

- **Profile is now the writer of avatar/cover URLs.** Added
  `POST /users/{id}/avatar` and `POST /users/{id}/upload-cover-photo`
  (multipart `file`), which proxy the bytes to the `storage` LXS and store the
  resulting content URL on the local profile row.
- Auth no longer owns avatar/cover (auth@1.1.0 is pure identity). Profile's
  identity sync no longer overwrites `avatarUrl`/`coverPhotoUrl`.
- New dependency: the `storage` LXS via `STORAGE_BASE_URL` (resolved by
  `eco configure`). If unset, avatar uploads return 503.

## 1.0.x — previous

Profile sync of avatar/cover from auth; no upload endpoint (see 1.0.2 docs).
