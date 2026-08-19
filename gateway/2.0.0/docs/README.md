# gateway — LXS docs

## Capability

The estate **front door**. A plain HTTP reverse-proxy + authorization engine,
all **deny by default**: routes are declared in `gateway.json` (written by eco's
`configgen` from `ecompose.yml` `access:` declarations), a request matching no
route returns `404`, `public` routes forward as-is, `auth` routes require a
valid Bearer JWT with an authenticated role, and `role:<name>` routes require a
JWT whose role claim equals `<name>`. The gateway verifies the token ONCE at the
edge and injects `X-Eco-User: <sub>,roles=<role>` upstream (any client-supplied
`X-Eco-User` is stripped), and supports `strip`/`rewrite` path-prefix
transforms (e.g. `/auth-api/*` → `/api/*`).

Gateway-origin errors are **content-negotiated**: API clients that ask for JSON
(`Accept: application/json`, or a `/api/*` path without an explicit HTML Accept)
get a machine-readable `{"error": ...}` body; browsers get a styled HTML page
following the Ecosphere design system. An estate can override the default page
with its own template via `error_page:` in `ecompose.yml` (see `api.md`).

TLS is deliberately absent: Cloudflare Tunnel terminates TLS at the edge.

## Compose it

```yaml
# ecompose.yml — declaring a `gateway` service flips the estate onto the
# middleware model: configgen writes gateway.json from access.routes + roles.
services:
  gateway:
    lxs: gateway@0.1.0
    grants:
      secrets: [SERVER_PORT, JWT_SECRET, GATEWAY_CONFIG]
```

Then declare `access.routes` on every HTTP service and an `auth.roles` block.
`eco up --remote` writes `gateway.json` + the service `.env` and exposes the
estate through the gateway port.

To replace the built-in error page with the estate's own design, declare it on
the main estate:

```yaml
estates:
  myestate:
    hostname: myestate.com
    error_page: error.html   # relative to the estate root, {{PLACEHOLDER}} template
```

## Environment

| Variable | Required | Purpose |
|---|---|---|
| `SERVER_PORT` | yes | Listen port (plain HTTP). |
| `JWT_SECRET` | yes | HS512 signing key; refuses to start without it. |
| `GATEWAY_CONFIG` | yes | Path to the `gateway.json` route table. |

## Docs index

- `api.md` — the gateway.json config schema + behavior/response codes
- `changelog.md` — version history
- `examples.sh` — local run smoke test
- `gotchas.md` — operational constraints

## Source

- Repo: https://github.com/getecosphere/gateway
