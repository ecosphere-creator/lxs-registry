# articles API

Base path: `/api`. Auth: read endpoints are public; write endpoints require a
Bearer JWT with an admin role (`ARTICLES_ADMIN_ONLY=true` by default). Errors:
`{ "error": "..." }` JSON.

## Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/articles/health` | public | Health check. |
| GET | `/api/articles` | public | List published articles. |
| GET | `/api/articles/all` | admin | List all articles incl. drafts. |
| GET | `/api/articles/slug/:slug` | public | One published article by slug. |
| POST | `/api/articles` | admin | Create. Body: `{ title, content_md, excerpt?, cover_image_url?, tags?, status?, seo_title?, seo_description?, og_image_url? }`. |
| PUT | `/api/articles/:id` | admin | Update. |
| DELETE | `/api/articles/:id` | admin | Delete. |

## Errors

| Code | Meaning |
|---|---|
| 401 | Missing/invalid Bearer token on a write endpoint. |
| 403 | Valid token but role is not admin. |
| 404 | Article/slug not found. |
