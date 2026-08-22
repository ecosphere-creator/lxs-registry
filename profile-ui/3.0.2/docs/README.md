# profile-ui

White-label SSR settings page for the Profile domain. It reads the Auth UI
session, lets the signed-in user update their name and bio, uploads their
avatar via Profile + Storage, and changes their password through Auth.

## Compose it

Compose `profile-ui` with `profile`, `storage`, `auth`, and `gateway`. The
gateway must expose `/profile`, `/profile-edit`, and
`/static/profile-ui.css`, protect the pages with `cookie: eco_token`, and
rewrite `/api/profile/*` to Profile's `/api/*` routes.

| Variable | Default | Purpose |
|---|---|---|
| `PROFILE_API_BASE` | `/api/profile` | Browser-visible Profile API prefix. |
| `AUTH_API_BASE` | `/auth-api` | Browser-visible Auth API prefix. |
| `ECO_SESSION_KEY` | `eco_session` | Local storage cache written by auth-ui; recovered from the gateway cookie when absent. |

The full step-by-step gateway contract is in `../AGENTS.md`.
