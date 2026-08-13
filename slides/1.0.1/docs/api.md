# slides API

Base path: `/api`. Auth: `Authorization: Bearer <JWT>` — the token is issued by
`auth` (HS512, claims `sub`/`username`/`role`/`iat`/`exp`) and validated with
the estate's shared `JWT_SECRET`. This service never issues tokens. Endpoints
that take `auth` as required return **401** (`{"error":"Unauthorized",
"message":"Unauthorized: ..."}`) when the header is missing/invalid/expired,
and **403** when a valid token's role is not permitted. Endpoints marked
"auth optional" work with or without a token. Errors are the AppError shape:
`{ "code", "message", "details"? (object), "timestamp" }` (camelCase).

Author roles (used by most write endpoints): `OWNER`, `MENTOR`, `MEMBER`.
Poll-template endpoints require platform `OWNER` only. A valid token with a
non-permitted role gets 403.

## Endpoints

### GET /health
- **Purpose:** liveness probe.
- **Auth required:** no
- **Success 200:** `{ "status": "UP" }`

### POST /book
- **Purpose:** create a new slide deck. The `ownerId` in any request body is
  ignored — the owner is always the authenticated caller (security fix).
- **Auth required:** yes (`OWNER`/`MENTOR`/`MEMBER`)
- **Body:** `SlideDeckInput` (JSON, camelCase). All fields optional except
  none strictly required. Key fields: `name`, `slug` (derived from name if
  absent, uniquified), `status` (`"draft"` default or `"published"`),
  `coverUrl`, `description`, `slides` (array of Slide), `flow`, `tags`,
  `price`, `paywallStartSlideIndex`, `guidedAudioLibrary`, etc. No
  `id`/`ownerId`/`createdAt`/`updatedAt` — server-controlled.
- **Success 201:** full `SlideDeckDto` (see schema below).
- **Errors:** 401/403 → invalid token / non-author role. (No publish-field
  validation on create — that only runs on `PUT /book/:id`.)

### GET /book/catalog
- **Purpose:** list all *published* decks for the public catalog (summary
  fields only, no slides).
- **Auth required:** no
- **Success 200:** array of `SlideDeckCatalogItemDto`:
  `{ "id", "slug"?, "name"?, "subtitle"?, "coverUrl"?, "description"?,
    "level"?, "language"?, "instructorName"?, "price"?, "compareAtPrice"?,
    "estimatedDurationMinutes"?, "slideCount", "tags": [], "updatedAt" }`

### POST /book/import
- **Purpose:** `.ktt` archive import (KttArchiveService) — deliberately not
  ported.
- **Auth required:** n/a (always 501)
- **Errors:** 501 Not Implemented (empty body)

### GET /book/owner/:owner_id
- **Purpose:** list decks owned by a user. Security fix: only the owner
  themselves or a platform `OWNER` may list; everyone else is rejected. Full,
  un-redacted `SlideDeckDto` per deck (including drafts and paywalled content
  for entitled callers).
- **Auth required:** yes (caller must be `:owner_id` or platform `OWNER`)
- **Success 200:** array of `SlideDeckDto`
- **Errors:** 403 `{"code":"ACCESS_DENIED","message":"Anda tidak memiliki akses untuk melihat book ini","timestamp":"..."}` for anyone else.

### GET /book/event/:event_id
- **Purpose:** list decks linked to an event, filtered by the caller's
  `can_access` (owner / platform owner / paid / event-registered). With the
  paywall disabled every deck the caller can see is returned.
- **Auth required:** yes
- **Success 200:** array of `SlideDeckDto`

### GET /book/:id_or_slug/public
- **Purpose:** public deck detail page. Accepts slug or 24-hex ObjectId.
  Only `status == "published"` decks; drafts/unknown → 404. Includes
  `curriculum` (per-slide index/title/level/locked) and `hasAccess`.
- **Auth required:** optional (token refines `hasAccess`)
- **Success 200:** `SlideDeckPublicDetailDto`:
  `{ "id", "slug"?, "name"?, "subtitle"?, "coverUrl"?, "description"?,
    "longSummary"?, "learningObjectives": [], "requirements": [],
    "targetAudience": [], "tags": [], "level"?, "language"?, "instructorName"?,
    "price"?, "compareAtPrice"?, "estimatedDurationMinutes"?, "slideCount",
    "paywallStartSlideIndex"?, "hasAccess": bool,
    "curriculum": [{ "index", "title", "level", "locked" }], "updatedAt" }`
- **Errors:** 404 → `{"code":"RESOURCE_NOT_FOUND","message":"Slide deck not found","timestamp":"..."}`

### GET /book/:id/export
- **Purpose:** `.ktt` archive export (KttArchiveService) — deliberately not
  ported.
- **Auth required:** n/a (always 501)
- **Errors:** 501 Not Implemented (empty body)

### GET /book/:id
- **Purpose:** fetch a deck by id or slug for the authoring/reading UI. If
  the caller lacks access (`can_access`), returns a redacted paywall preview
  (slides after `paywallStartSlideIndex` emptied). Paywall is currently
  disabled, so this returns the full deck.
- **Auth required:** optional
- **Success 200:** `SlideDeckDto`
- **Errors:** 404 via `RESOURCE_NOT_FOUND`

### PUT /book/:id
- **Purpose:** update a deck. Caller must be owner or platform `OWNER`.
  Slug is immutable once `published`; publishing requires non-empty `name`,
  `coverUrl`, `description` (Indonesian messages below). Sets `status` to
  lowercase, derives/ensures a unique slug.
- **Auth required:** yes (owner or platform `OWNER`)
- **Body:** `SlideDeckInput` (same shape as POST /book)
- **Success 200:** `SlideDeckDto`
- **Errors:**
  - 403 → `{"code":"ACCESS_DENIED","message":"Anda tidak memiliki akses untuk mengubah book ini","timestamp":"..."}`
  - 400 → `INVALID_ARGUMENT` with "Judul wajib diisi sebelum publish" /
    "Cover wajib diisi sebelum publish" / "Deskripsi singkat wajib diisi
    sebelum publish" / "URL slug tidak bisa diubah setelah publish"
  - 500 → `INTERNAL_SERVER_ERROR` "An unexpected error occurred" if the deck
    does not exist (the update handler reports a missing deck as Internal, not
    404)

### DELETE /book/:id
- **Purpose:** delete a deck. Caller must be owner or platform `OWNER`.
- **Auth required:** yes
- **Success 204:** empty body
- **Errors:** 403 `ACCESS_DENIED` ("Anda tidak memiliki akses untuk menghapus book ini"); 404 if not found

### GET /book/:deck_id/editor-prefs
- **Purpose:** get the caller's editor prefs for a deck. Returns defaults
  (grid off, `gridDensity: "medium"`, padding 64) if none saved.
- **Auth required:** yes (author roles)
- **Success 200:** `SlideEditorPrefsDto`:
  `{ "deckId", "userId", "showGrid", "gridDensity", "showPaddingGuides",
    "snapToGrid", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
    "createdAt", "updatedAt" }`

### PUT /book/:deck_id/editor-prefs
- **Purpose:** upsert the caller's editor prefs. `gridDensity` is normalized
  to `coarse|medium|fine` (anything else → `medium`); paddings are clamped to
  `[0, 400]`.
- **Auth required:** yes (author roles)
- **Body:** `{ "showGrid": bool, "gridDensity": string?, "showPaddingGuides": bool, "snapToGrid": bool, "paddingTop": int, "paddingRight": int, "paddingBottom": int, "paddingLeft": int }` (camelCase; all have defaults)
- **Success 200:** `SlideEditorPrefsDto`

### GET /book/:deck_id/session
- **Purpose:** get (creating if absent) the current book session. For an
  authenticated caller, keyed by `userId`; otherwise by `anonSessionId`
  query param.
- **Auth required:** optional
- **Query params:** `anonSessionId` (optional, required when unauthenticated)
- **Success 200:** `BookSessionDto`:
  `{ "id", "deckId", "userId"?, "anonSessionId"?, "variables": {},
    "history": [], "currentSlideId"?, "createdAt", "updatedAt" }`
- **Errors:** 400 `INVALID_ARGUMENT` "userId or anonSessionId is required"

### POST /book/:deck_id/session
- **Purpose:** upsert the current book session (variables, history stack,
  current slide). History is trimmed + de-duped in order.
- **Auth required:** optional
- **Query params:** `anonSessionId` (optional, required when unauthenticated)
- **Body:** `{ "variables"?: object, "history"?: string[], "currentSlideId"?: string }` (camelCase)
- **Success 200:** `BookSessionDto`
- **Errors:** 400 `INVALID_ARGUMENT` "userId or anonSessionId is required"

### POST /book/:deck_id/session/merge
- **Purpose:** merge an anonymous session into the authenticated caller's
  user session (anon fills only missing values; history concatenated +
  de-duped; user values win). Deletes the anon session afterwards.
- **Auth required:** yes
- **Body:** `{ "anonSessionId": string }`
- **Success 200:** `{ "id", "deckId", "userId", "variables", "history", "currentSlideId" }`
- **Errors:** 400 `INVALID_ARGUMENT` "anonSessionId is required"

### GET /book/:deck_id/slides/:slide_id/elements/:element_id/poll-votes
- **Purpose:** anonymous poll-result aggregation for one poll element:
  total voter count and per-choice counts. `myChoiceIds` is included when
  authenticated.
- **Auth required:** optional
- **Success 200:** `{ "totalVoters": int, "countsByChoiceId": {<choiceId>: int}, "myChoiceIds": [] }`

### POST /book/:deck_id/slides/:slide_id/elements/:element_id/poll-votes
- **Purpose:** submit/replace the caller's vote (one vote per user per
  element; re-submitting overwrites `choiceIds`). Returns the same aggregate
  including the caller's choices.
- **Auth required:** yes (`OWNER`/`MENTOR`/`MEMBER` voter roles)
- **Body:** `{ "choiceIds": string[] }`
- **Success 200:** `{ "totalVoters", "countsByChoiceId", "myChoiceIds" }`

### GET /author-assets/images
- **Purpose:** list the caller's personal image-library entries.
- **Auth required:** yes (author roles)
- **Success 200:** array of `AuthorImageAssetDto`:
  `{ "id", "ownerId", "fileUrl", "createdAt", "updatedAt" }`

### POST /author-assets/images
- **Purpose:** add (or touch/refresh if `fileUrl` already exists) an entry
  to the caller's image library.
- **Auth required:** yes (author roles)
- **Body:** `{ "fileUrl": string }`
- **Success 200:** `AuthorImageAssetDto` (idempotent upsert, 200 not 201)

### DELETE /author-assets/images?fileUrl=...
- **Purpose:** remove an entry from the caller's image library by file URL.
- **Auth required:** yes (author roles)
- **Query params:** `fileUrl` (required)
- **Success 204:** empty body

### GET /author-assets/images/usage?fileUrl=...
- **Purpose:** find every deck/slide/element where the given image URL is
  used as an `image` element's content (scoped to the caller's decks).
- **Auth required:** yes (author roles)
- **Query params:** `fileUrl` (required)
- **Success 200:** array of `{ "deckId", "deckName"?, "slideId", "slideIndex", "elementId" }`

### GET /author-poll-templates
- **Purpose:** list the caller's poll templates.
- **Auth required:** yes (`OWNER` only)
- **Success 200:** array of `AuthorPollTemplateDto`:
  `{ "id", "ownerId", "title", "pollStyleJson"?, "createdAt", "updatedAt" }`

### POST /author-poll-templates
- **Purpose:** create a poll template. Title defaults to "Poll Template";
  `pollStyleJson` is JSON-parsed, normalized (a `pollTemplateId` is injected
  only on update), re-serialized.
- **Auth required:** yes (`OWNER` only)
- **Body:** `{ "title"?: string, "pollStyleJson"?: string }`
- **Success 200:** `AuthorPollTemplateDto`

### PUT /author-poll-templates/:template_id?syncLinked=...
- **Purpose:** update a template. When `syncLinked=true` (default), every
  `poll` element in the caller's decks whose style carries this
  `pollTemplateId` is re-styled with the new `pollStyleJson`.
- **Auth required:** yes (`OWNER` only)
- **Query params:** `syncLinked` (bool, default `true`)
- **Body:** `{ "title"?: string, "pollStyleJson"?: string }`
- **Success 200:** `AuthorPollTemplateDto`
- **Errors:** 404 `RESOURCE_NOT_FOUND` if not the caller's / missing

### DELETE /author-poll-templates/:template_id
- **Purpose:** delete a poll template (owned by caller).
- **Auth required:** yes (`OWNER` only)
- **Success 204:** empty body

### GET /author-poll-templates/:template_id/usage
- **Purpose:** find every deck/slide/element whose `poll` element references
  this template id (scoped to the caller's decks).
- **Auth required:** yes (`OWNER` only)
- **Success 200:** array of `{ "deckId", "deckName"?, "slideId", "slideIndex", "elementId" }`

### POST /author-poll-templates/:template_id/sync
- **Purpose:** push the template's current `pollStyleJson` into every linked
  `poll` element across the caller's decks.
- **Auth required:** yes (`OWNER` only)
- **Success 200:** `{ "updatedElements": int }`

### POST /files/upload  ·  POST /slides-files/upload
- **Purpose:** upload a slide image or guided-narration audio. Mirrors the
  monolith's `type=` contract. `type=slide-narration` is stored raw (no
  conversion); anything else is treated as an image, recompressed to lossy
  WebP (quality 80), stored at `slide-image/{ownerId}/{uuid}.webp`. Returns
  the gateway-routable URL under `/slides-files/view/{fileId}` (both route
  prefixes hit the same handler; the `/slides-files/*` set exists so the
  estate gateway can route file requests to this domain by path).
- **Auth required:** yes (author roles)
- **Body:** multipart/form-data — `file` (bytes, required; must be
  `image/*` for image uploads) and optional `type` field
  (`slide-narration` or anything else).
- **Success 201:** `{ "fileUrl": "https://.../api/slides-files/view/<fileId>", "fileId": "<24-hex>" }`
- **Errors:**
  - 400 → `{"code":"INVALID_ARGUMENT","message":"Missing 'file' field"|"Invalid file type. Expected an image upload."|"Image is too large (WxH); maximum is 30000000 pixels",...}`
  - 413 → request body over the 10 MB limit is rejected by the body-size
    middleware (not the AppError shape)

### GET /files/view/:file_id  ·  GET /slides-files/view/:file_id
- **Purpose:** serve an uploaded file's bytes with its stored content-type.
  No auth (image/audio URLs are public and referenced from decks).
- **Auth required:** no
- **Success 200:** raw file bytes (`Content-Type` set from the record)
- **Errors:** 404 → `RESOURCE_NOT_FOUND` "File not found: <fileId>"; 400 if `fileId` is not a valid 24-hex ObjectId

### DELETE /files/:file_id  ·  DELETE /slides-files/:file_id
- **Purpose:** delete an uploaded file. Caller must be the uploader.
- **Auth required:** yes (author roles)
- **Success 204:** empty body
- **Errors:** 403 `ACCESS_DENIED` "Cannot delete another user's file"; 404/400 as above

## SlideDeckDto (full response shape)

```json
{
  "id": "507f1f77bcf86cd799439011",
  "name": "My Deck",
  "slug": "my-deck",
  "subtitle": null,
  "coverUrl": "https://.../api/slides-files/view/abc",
  "description": "…",
  "longSummary": null,
  "learningObjectives": [],
  "requirements": [],
  "targetAudience": [],
  "tags": [],
  "level": null,
  "language": null,
  "instructorName": null,
  "estimatedDurationMinutes": null,
  "status": "draft",
  "ownerId": "u_123",
  "communityId": null,
  "eventId": null,
  "theme": null,
  "transition": null,
  "layoutFormat": null,
  "price": null,
  "compareAtPrice": null,
  "paywallStartSlideIndex": null,
  "slides": [
    {
      "id": "slide-1",
      "name": null,
      "elements": [
        { "id": "el-1", "type": "text", "x": 0, "y": 0, "width": 0, "height": 0, "content": "Title", "style": null }
      ],
      "background": null,
      "level": 0
    }
  ],
  "flow": null,
  "galleryImages": [],
  "guidedAudioLibrary": [],
  "createdAt": "2026-08-13T00:00:00Z",
  "updatedAt": "2026-08-13T00:00:00Z"
}
```

`Slide` = `{ id, name?, elements[] }`; `Element` =
`{ id, type? ("text"|"image"|"link"|"paragraph"|"poll"|"callout"|"input"|"choice"), x, y, width, height, content?, label?, style? (JSON string; carries "pollTemplateId" for linked polls), linkUrl?, flipH?, flipV? }`.
`Flow` = `{ startSlideId?, edges[], nodePositions?, layoutMode?, editorState? }` with `FlowEdge = { fromSlideId?, toSlideId?, condition (opaque), label?, priority? }`.

## Error reference

| Code | Status | Body | When |
|---|---|---|---|
| — | 401 | `{"error":"Unauthorized","message":"Unauthorized: missing bearer token"}` | Missing/invalid/expired Bearer token |
| ACCESS_DENIED | 403 | `{"code":"ACCESS_DENIED","message":"Access denied",...}` | Role not in required set |
| INVALID_ARGUMENT | 400 | `{"code":"INVALID_ARGUMENT","message":...,...}` | Bad request body / publish-field validation / bad slug / bad file upload |
| VALIDATION_ERROR | 400 | `{"code":"VALIDATION_ERROR","message":"Validation failed","details":{...},...}` | Blank required fields |
| RESOURCE_NOT_FOUND | 404 | `{"code":"RESOURCE_NOT_FOUND","message":...,...}` | Deck/file/session/template not found |
| ALREADY_EXISTS | 409 | `{"code":"ALREADY_EXISTS",...}` | Reserved (defined, not currently raised) |
| INTERNAL_SERVER_ERROR | 500 | `{"code":"INTERNAL_SERVER_ERROR","message":"An unexpected error occurred",...}` | Unexpected error (DB, S3, peer) |
| — | 501 | (empty body) | `/book/import`, `/book/:id/export` (not ported) |
| — | 413 | (non-AppError body) | Request body > 10 MB (`RequestBodyLimitLayer`) |
| — | 429 | (tower_governor rejection) | Per-source-IP rate limit exceeded |

## Rate limiting / limits

- Every `/api/*` route is behind a per-source-IP token bucket
  (`SmartIpKeyExtractor`): burst capacity `RATE_LIMIT_GENERAL_BURST`
  (default `120`), then 1 token per `RATE_LIMIT_GENERAL_REPLENISH_SECS`
  (default `1` s). Exceeding it returns **429**. The keyed limiter store is
  periodically pruned (`retain_recent` every 60 s) to cap memory growth.
- Request body limit: hardcoded `10 * 1024 * 1024` bytes (not env-driven);
  file uploads are buffered fully in memory, so the effective per-file cap is
  ~10 MB minus multipart overhead.
- CORS: allow-list from `CORS_ALLOWED_ORIGINS` (comma-separated), credentials
  allowed, methods GET/POST/PUT/DELETE/PATCH/OPTIONS/HEAD, headers mirrored,
  `Access-Control-Max-Age: 3600`.
- Response headers on every API response: `x-content-type-options: nosniff`,
  `x-frame-options: DENY`, `x-xss-protection: 0`, `referrer-policy: no-referrer`,
  `cache-control: no-cache, no-store, max-age=0, must-revalidate`, `pragma: no-cache`,
  plus `x-request-id` (correlation id — reused from the incoming header or a
  fresh UUID, and forwarded to the `auth`/`payments`/`community` peers).
