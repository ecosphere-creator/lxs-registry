# articles-ui API

The binary serves Astro SSR pages. There is no separate REST API — it renders
HTML server-side against the `articles` backend.

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/articles/` | Rendered list of published articles |
| GET | `/articles/[slug]/` | Rendered single article (SEO + OpenGraph) |

## Env contract

| Var | Required | Default | Purpose |
|---|---|---|---|
| `SERVER_PORT` | yes | — | Listen port (eco fills it) |
| `ARTICLES_API_URL` | no | `/api/articles` | Articles REST API base URL |
| `PUBLIC_SITE_URL` | no | — | Canonical/OG origin |

## Runtime

- Binary: self-contained bun-compiled linux-x64 (glibc).
- Static client assets ship next to the binary in `client/`.
- Health: HTTP 200 on any served route; errors render in-page.
