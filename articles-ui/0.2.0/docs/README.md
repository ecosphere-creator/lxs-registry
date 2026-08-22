# articles-ui

Standalone native SSR UI for the **articles** domain — ships the article list
and article-detail pages (`/articles/` and `/articles/[slug]/`) with SEO +
OpenGraph, rendered against the articles REST API. Built by `eco lxs build`
into a self-contained Rust binary for production and local Eco development.

## What it owns

Only the public article browsing surface (list + detail). It does **not** own
article authoring/admin, identity, or any CRM data — those stay in the
`articles` backend and other domains.

## Compose

```yaml
services:
  articles-ui:
    lxs: articles-ui@0.2.0
    env:
      ARTICLES_API_URL: http://<articles-backend>:<port>
      PUBLIC_SITE_URL: https://<estate-host>
```

- `ARTICLES_API_URL` — API prefix of the `articles` backend (for example
  `http://articles-backend:20018/api`); the UI appends `/articles` safely.
- `PUBLIC_SITE_URL` — public origin used for canonical / OpenGraph URLs.

## Routes

- `GET /articles/` — published article list.
- `GET /articles/:slug` — one published article (reader-safe not-found page
  if unpublished/missing).

## Runtime

The compiled binary runs on each supported platform with no node_modules.
Logs are NDJSON to stdout per the platform LXS logging contract.
