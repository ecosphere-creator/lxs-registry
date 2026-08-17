# Gotchas

- `JWT_SECRET` is required and must be the **shared estate secret** (configgen
  injects it); the gateway refuses to start without it.
- The gateway is **deny by default** — every path a service must serve has to be
  declared in `access.routes`. Miss one and it is a `403`, not a 404.
- `auth` routes treat any role not declared `public` as authenticated, so
  declare the `public` role explicitly in `auth.roles` if you have one.
- The gateway forwards the `Authorization` header unchanged, so upstream
  services that validate JWTs themselves keep working.
- TLS is not handled here — Cloudflare Tunnel terminates TLS in front.
- The gateway must be reachable only from the reverse-proxy/tunnel layer on a
  localhost-reachable port; never expose it directly on a public interface.
