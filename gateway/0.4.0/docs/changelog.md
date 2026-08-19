# Changelog

## 0.4.0

- the built-in 401 error page now renders a "Sign in" button linking to
  `/signin`; the new `{{ACTION}}` token lets custom error pages show a
  status-appropriate recovery link (empty when there's nothing to recover to)

## 0.2.0

- content-negotiated error pages: API clients get JSON, browsers get a styled
  HTML error page following the Ecosphere design system (default built in)
- undeclared routes now return `404` instead of `403` (the resource simply
  isn't routed; `401`/`403` still mean authorization failures)
- `error_page` config field: estate templates with `{{STATUS}}`/`{{TITLE}}`/
  `{{MESSAGE}}`/`{{METHOD}}`/`{{PATH}}`/`{{ESTATE}}` tokens, wired by configgen
  from `error_page:` in `ecompose.yml`; HTML pages never leak internal topology

## 0.1.0

- initial publish — the estate front door (default-deny reverse-proxy + JWT/role authorization)
- multi-arch artifacts: linux/amd64, linux/arm64, darwin/arm64, darwin/amd64, windows/amd64
