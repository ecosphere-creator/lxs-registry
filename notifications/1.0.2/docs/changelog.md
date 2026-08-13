# Changelog

Versions tracked from `git log`, the domain CLAUDE.md, and the registry
manifest (`lxs.yml`). The manifest's `release:` list is empty and no git tags
exist, so only versions explicitly recorded are listed; 1.0.1 has no record.

## 1.0.2 (next release)
- i18n: translate user-facing API/error messages to English
- chore: add `category: Communication` to the LXS manifest

## 1.0.1
- No notes on record (registry `release:` list is empty; no git tags).

## 1.0.0
- initial release
- Scaffold Go notifications backend, then rewritten to Rust (axum + WebSocket + MongoDB)
- Fix notification `userId`/`referenceId` serialization so list queries match stored documents
- Serve the bare `/api/notifications` list without a redirect
- Add LXS manifest (`notifications@1.0.0`)
