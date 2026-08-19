# articles-ui

Standalone Astro SSR UI for the **articles** domain — ships the article list
and article-detail pages (`/articles/` and `/articles/[slug]/`) with SEO +
OpenGraph, rendered against the articles REST API. Built by `eco lxs build`
into a single self-contained linux-x64 binary via bun-compile.

## What it owns

Only the public article browsing surface (list + detail). It does **not** own
article authoring/admin, identity, or any CRM data — those stay in the
`articles` backend and other domains.

## Compose

```yaml
services:
  articles-ui:
    lxs: articles-ui@0.1.0
    env:
      ARTICLES_API_URL: http://<articles-backend>:<port>
      PUBLIC_SITE_URL: https://<estate-host>
```

- `ARTICLES_API_URL` — base URL of the `articles` backend REST API (default
  `/api/articles`, i.e. the estate gateway route).
- `PUBLIC_SITE_URL` — public origin used for canonical / OpenGraph URLs.

## Routes

- `GET /articles/` — published article list.
- `GET /articles/[slug]/` — one published article (404 if unpublished/missing).

## Runtime

The compiled binary runs on any glibc Linux (Debian CT) with no node_modules.
Logs are NDJSON to stdout per the platform LXS logging contract.
