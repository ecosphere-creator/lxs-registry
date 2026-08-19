# articles — LXS docs

## Capability

Publishes and serves markdown articles with SSR-friendly SEO/OpenGraph
metadata: title, slug, excerpt, markdown body, cover image, tags, draft/
published status, author attribution, and SEO fields. Read API is public;
write API requires an admin role (validated locally against the estate's
shared HS512 JWT).

## Compose it

```yaml
# ecompose.yml
services:
  articles-backend:
    lxs: articles@1.0.1
    grants:
      secrets: [SERVER_PORT, DATABASE_URL, JWT_SECRET]
```

## Docs index

- `api.md` — endpoints, request/response JSON, errors
- `changelog.md` — version history
- `gotchas.md` — operational constraints
