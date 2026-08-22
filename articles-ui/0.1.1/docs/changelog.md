# articles-ui changelog

## 0.1.1 (2026-08-22)

- Add a darwin/arm64 artifact so the pluggable SSR UI works in `eco up dev`
  on the Mac build farm as well as on the Linux production target.

## 0.1.0 (2026-08-20)

- Initial release: `articles-ui` standalone Astro SSR binary.
- Splits the pluggable `@articles/frontend` library into a deployable UI
  service: `/articles/` + `/articles/[slug]/` rendered server-side with
  SEO/OpenGraph, bun-compiled into a single self-contained linux-x64 binary.
- `eco lxs build` gains Astro/Node bun-compile support for UI LXS.
