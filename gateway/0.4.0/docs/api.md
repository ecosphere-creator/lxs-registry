# gateway API / behavior

The gateway exposes no REST endpoints of its own — every request goes through
the route table. This document defines the `gateway.json` config and the
observable behavior.

## Config (`GATEWAY_CONFIG`)

```json
{
  "roles": { "public": "public", "authenticated": "auth" },
  "routes": [
    {
      "path": "/auth-api/auth/login",
      "upstream": "127.0.0.1:20605",
      "level": "public",
      "strip": "/auth-api",
      "rewrite": "/api"
    },
    {
      "path": "/api/auth/*",
      "upstream": "127.0.0.1:20605",
      "level": "auth"
    },
    {
      "path": "/api/v1/*",
      "upstream": "127.0.0.1:20606",
      "level": "public"
    }
  ]
}
```

### RouteRule fields

| Field | Required | Meaning |
|---|---|---|
| `path` | yes | Pattern. Ends with `/*` for a prefix match, `*` for a stem match, otherwise exact. |
| `upstream` | yes | `127.0.0.1:<port>` target. |
| `level` | yes | `public` \| `auth` \| `role:<name>`. |
| `strip` | no | Path prefix to strip before forwarding (with `rewrite`). |
| `rewrite` | no | Replacement prefix (used with `strip`). |
| `cookie` | no | Session cookie name to fall back to when no Bearer token is sent. |

### Route matching

Longest-prefix wins; an exact path beats a wildcard of the same length;
longer prefixes beat shorter ones.

## Behavior / response codes

| Case | Status | Body |
|---|---|---|
| No route matches the path | `404` | JSON `{"error":"no route declared for this path (deny by default)"}` or HTML error page |
| `auth` route, missing/invalid token | `401` | `{"error":"missing or invalid bearer token"}` |
| `auth` route, token role not authenticated | `403` | `{"error":"access denied for this role"}` |
| `role:<name>` route, role mismatch | `403` | `{"error":"access denied for this role"}` |
| Upstream unreachable / bad response | `502` | `{"error":"..."}` |
| Authorized / public request | `200` (upstream status) | upstream body |

### Error pages & content negotiation

Gateway-origin errors are rendered as JSON when the client asks for JSON and as
a styled HTML page otherwise:

- **JSON**: `Accept` contains `application/json` (or `application/*+json`), OR
  the path starts with `/api/` and `Accept` does not explicitly ask for HTML.
  Body is `{"error": "<message>"}` — includes the technical detail (upstream
  addresses, etc.).
- **HTML**: everything else. Uses the built-in Ecosphere design page unless the
  estate declares its own template. HTML bodies never leak internal topology —
  the message is a friendly generic text; the requested path is shown as
  `METHOD /path`.

### Custom error page (`error_page`)

Set `error_page` in `gateway.json` to an absolute path of an HTML template, or
declared `error_page:` under the main `estates:` entry in `ecompose.yml`
(configgen ships the file next to `gateway.json` and wires the path). The
template may use these tokens (all HTML-escaped by the gateway):

| Token | Meaning |
|---|---|
| `{{STATUS}}` | Numeric status code, e.g. `404` |
| `{{TITLE}}` | Status title, e.g. `Not found` |
| `{{MESSAGE}}` | Friendly message for the status |
| `{{METHOD}}` | Request method, e.g. `GET` |
| `{{PATH}}` | Requested path |
| `{{ESTATE}}` | Estate name |
| `{{ACTION}}` | Status-appropriate recovery link (raw HTML, not escaped): a "Sign in" button linking to `/signin` on `401`, empty otherwise |

If the file is missing/unreadable the gateway logs a warning and falls back to
the built-in page.

## Identity propagation

On authorized requests the gateway injects:

```
X-Eco-User: <sub>,roles=<role>
```

Any client-supplied `X-Eco-User` is stripped before forwarding. The
`Authorization` header is preserved so upstream services that verify the token
themselves (articles, storage, profile, ...) keep working unchanged.

## Path rewriting

When a request path starts with `strip`, it is replaced with `rewrite` before
forwarding — `/auth-api/auth/login` + `strip:/auth-api` + `rewrite:/api`
becomes `/api/auth/login` upstream.
